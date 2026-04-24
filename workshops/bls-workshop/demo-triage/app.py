import asyncio
import json
import subprocess
from typing import AsyncGenerator

import anthropic
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
from fastapi.staticfiles import StaticFiles

app = FastAPI(title="Cluster Triage AI")
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])

client = anthropic.Anthropic()

TOOLS = [
    {
        "name": "kubectl",
        "description": (
            "Run a kubectl command against the cluster. "
            "Use get, describe, logs, events for discovery. "
            "Use 'set image' or 'patch' to fix broken deployments. "
            "Use 'delete pod' to restart a pod after fixing its deployment. "
            "Always scope to the demo-triage namespace unless reading cluster-wide events."
        ),
        "input_schema": {
            "type": "object",
            "properties": {
                "args": {
                    "type": "array",
                    "items": {"type": "string"},
                    "description": "kubectl arguments e.g. ['get', 'pods', '-n', 'demo-triage']",
                }
            },
            "required": ["args"],
        },
    }
]

SYSTEM_PROMPT = """You are an expert Kubernetes cluster administrator.

Your job: audit the demo-triage namespace, find any failing pods, diagnose the root cause, fix it, then verify the fix worked.

Workflow:
1. List all pods in demo-triage — identify anything not Running
2. Describe the failing pod to read events and container state
3. Check pod logs if the container started
4. Diagnose the root cause in one clear sentence
5. Apply the fix (kubectl set image, patch, etc.)
6. Verify the pod comes up healthy

Keep text responses tight and direct. No filler. Show reasoning as you go."""


BLOCKED_PATTERNS = [
    "delete namespace",
    "delete node",
    "drain",
    "cordon",
    "delete deployment/triage-app",
    "delete deploy/triage-app",
]


def run_kubectl(args: list) -> str:
    cmd_str = " ".join(args)
    for pattern in BLOCKED_PATTERNS:
        if pattern in cmd_str:
            return f"BLOCKED: '{pattern}' is not permitted in this demo"

    try:
        result = subprocess.run(
            ["kubectl"] + args,
            capture_output=True,
            text=True,
            timeout=30,
        )
        output = (result.stdout + result.stderr).strip()
        return output[:3000] if output else "(no output)"
    except subprocess.TimeoutExpired:
        return "ERROR: kubectl timed out after 30s"
    except FileNotFoundError:
        return "ERROR: kubectl not found"


async def stream_diagnosis() -> AsyncGenerator[str, None]:
    messages = [
        {
            "role": "user",
            "content": (
                "Audit the demo-triage namespace. "
                "Find any pods that are not Running or Completed. "
                "Diagnose the root cause and fix it."
            ),
        }
    ]

    while True:
        response = client.messages.create(
            model="claude-sonnet-4-6",
            max_tokens=2048,
            system=SYSTEM_PROMPT,
            tools=TOOLS,
            messages=messages,
        )

        tool_results = []

        for block in response.content:
            if block.type == "text" and block.text:
                yield f"data: {json.dumps({'type': 'text', 'text': block.text})}\n\n"
                await asyncio.sleep(0)

            elif block.type == "tool_use":
                cmd_display = "kubectl " + " ".join(block.input.get("args", []))
                yield f"data: {json.dumps({'type': 'tool_call', 'cmd': cmd_display})}\n\n"
                await asyncio.sleep(0)

                output = run_kubectl(block.input.get("args", []))
                yield f"data: {json.dumps({'type': 'tool_result', 'output': output})}\n\n"
                await asyncio.sleep(0)

                tool_results.append(
                    {
                        "type": "tool_result",
                        "tool_use_id": block.id,
                        "content": output,
                    }
                )

        if response.stop_reason == "end_turn":
            yield f"data: {json.dumps({'type': 'done'})}\n\n"
            break

        if tool_results:
            messages.append({"role": "assistant", "content": response.content})
            messages.append({"role": "user", "content": tool_results})
        else:
            yield f"data: {json.dumps({'type': 'done'})}\n\n"
            break


@app.get("/api/pods")
def get_pods():
    raw = run_kubectl(["get", "pods", "-n", "demo-triage", "-o", "json"])
    try:
        return json.loads(raw)
    except Exception:
        return {"items": [], "error": raw}


@app.get("/api/diagnose")
async def diagnose():
    return StreamingResponse(
        stream_diagnosis(),
        media_type="text/event-stream",
        headers={"Cache-Control": "no-cache", "X-Accel-Buffering": "no"},
    )


app.mount("/", StaticFiles(directory="static", html=True), name="static")
