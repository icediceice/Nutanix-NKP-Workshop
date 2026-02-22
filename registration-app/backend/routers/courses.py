import os
import yaml
from fastapi import APIRouter

router = APIRouter()

COURSES_YAML = os.path.join(os.path.dirname(__file__), "..", "..", "..", "courses.yaml")


def _load_courses() -> dict:
    path = os.path.abspath(COURSES_YAML)
    if not os.path.exists(path):
        # Fallback: look relative to CWD
        path = "courses.yaml"
    with open(path) as f:
        return yaml.safe_load(f)


@router.get("/courses")
def get_courses():
    """Return track and workshop definitions from courses.yaml."""
    return _load_courses()
