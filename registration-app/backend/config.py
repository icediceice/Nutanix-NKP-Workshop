from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    # Database
    database_url: str = "sqlite:///./data/lab-manager.db"

    # Cluster
    kubeconfig_path: str = ""
    cluster_context: str = "nkp-workshop"

    # Dry run — default true so local dev never touches a real cluster
    dry_run: bool = True

    # Registration App
    admin_password: str = ""
    app_port: int = 8000
    app_title: str = "NKP Partner Workshop"

    # Educates Training Portal
    educates_portal_url: str = ""
    educates_portal_password: str = ""

    # S3 / NUS
    s3_endpoint: str = ""
    s3_access_key: str = ""
    s3_secret_key: str = ""

    # Harbor registry (Developer track)
    harbor_url: str = ""
    harbor_project: str = "workshop"

    # GitLab (Developer track CI/CD)
    gitlab_url: str = ""

    model_config = {"env_file": ".env", "env_file_encoding": "utf-8"}


@lru_cache()
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
