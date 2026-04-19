---
title: "Certificate Setup"
---

## Before We Begin — Trust the Workshop Certificate

The NKP Kommander console runs on a private cluster with a **self-signed CA certificate**.
Your browser will show security warnings unless you install the CA cert first.

> **This takes about 60 seconds and prevents certificate errors for the entire workshop.**

---

## Step 1 — Download the Certificate

Open a terminal and run:

```bash
kubectl get secret kommander-ca -n cert-manager \
  -o jsonpath='{.data.tls\.crt}' | base64 -d > ~/kommander-ca.crt
echo "Certificate saved to ~/kommander-ca.crt"
```

Download the file to your laptop using your session file browser, or copy the text:

```bash
cat ~/kommander-ca.crt
```

Copy the full output (including `-----BEGIN CERTIFICATE-----` and `-----END CERTIFICATE-----`) and save it as `kommander-ca.crt`.

---

## Step 2 — Install the Certificate

### macOS

1. Double-click `kommander-ca.crt` — Keychain Access opens.
2. Add to **System** keychain.
3. Find **Kommander CA** in the list, double-click it.
4. Expand **Trust** → set **When using this certificate** to **Always Trust**.
5. Close the window and enter your password to confirm.
6. Restart your browser.

### Windows

1. Double-click `kommander-ca.crt`.
2. Click **Install Certificate** → **Local Machine** → **Next**.
3. Select **Place all certificates in the following store** → **Browse** → **Trusted Root Certification Authorities**.
4. Click **OK** → **Next** → **Finish**.
5. Restart your browser.

### Linux (Chrome / Edge)

1. Open **Settings** → **Privacy and security** → **Security** → **Manage certificates**.
2. Go to the **Authorities** tab → **Import**.
3. Select `kommander-ca.crt` → check **Trust this certificate for identifying websites**.
4. Restart your browser.

---

## Step 3 — Verify

Open the Kommander console URL your facilitator provided. You should see the login page with **no certificate warning**.

> If you still see a warning, try a private/incognito window first — browser cert caches sometimes need a full restart to pick up the new trust anchor.

---

## Cluster Access Details

Your facilitator will provide:

| Item | Value |
|------|-------|
| Kommander URL | `https://10.38.49.15` |
| Username | Provided by facilitator |
| Password | Provided by facilitator |
| Workload cluster | `workload01` (10.38.49.18) |

Keep these handy for all labs.
