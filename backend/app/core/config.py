from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    database_url: str = "postgresql+psycopg2://mkc:mkc_dev@localhost:5432/make_kerala_clean"
    redis_url: str = "redis://localhost:6379/0"
    secret_key: str = "dev-secret-change-in-production"
    access_token_expire_minutes: int = 30
    refresh_token_expire_days: int = 7
    otp_expire_minutes: int = 10
    debug: bool = True

    smtp_host: str = ""
    smtp_port: int = 587
    smtp_user: str = ""
    smtp_password: str = ""
    smtp_from: str = "noreply@makekeralaclean.org"
    smtp_tls: bool = True
    log_otp_to_console: bool = True

    upload_dir: str = "uploads"
    max_photos_per_report: int = 3
    max_reports_per_day: int = 5
    public_base_url: str = "http://localhost:8000"

    # Camera-only capture + waste verification (see docs/DECISIONS.md)
    capture_max_age_seconds: int = 900  # 15 minutes
    waste_verification_enabled: bool = True
    waste_verification_min_confidence: float = 0.35
    min_image_width: int = 200
    min_image_height: int = 200

    @property
    def smtp_configured(self) -> bool:
        return bool(self.smtp_host and self.smtp_user and self.smtp_password)


settings = Settings()
