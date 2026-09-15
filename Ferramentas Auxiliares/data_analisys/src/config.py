from dataclasses import dataclass
import os

from dotenv import load_dotenv


load_dotenv()


@dataclass(frozen=True)
class ConnectionConfig:
    host: str
    port: str
    database: str
    user: str = ""
    password: str = ""
    driver: str = "ODBC Driver 17 for SQL Server"
    trusted_connection: bool = False
    encrypt: str = "yes"
    trust_server_certificate: str = "yes"

    @classmethod
    def from_env(cls) -> "ConnectionConfig":
        return cls(
            host=os.getenv("SQLSERVER_HOST", ""),
            port=os.getenv("SQLSERVER_PORT", "1433"),
            database=os.getenv("SQLSERVER_DATABASE", ""),
            user=os.getenv("SQLSERVER_USER", ""),
            password=os.getenv("SQLSERVER_PASSWORD", ""),
            driver=os.getenv("SQLSERVER_DRIVER", "ODBC Driver 17 for SQL Server"),
            trusted_connection=os.getenv("SQLSERVER_TRUSTED_CONNECTION", "no").lower()
            in {"yes", "true", "1"},
            encrypt=os.getenv("SQLSERVER_ENCRYPT", "yes"),
            trust_server_certificate=os.getenv(
                "SQLSERVER_TRUST_SERVER_CERTIFICATE", "yes"
            ),
        )

    def connection_string(self) -> str:
        server = self.host
        if self.port:
            server = f"{server},{self.port}"

        parts = [
            f"DRIVER={{{self.driver}}}",
            f"SERVER={server}",
            f"DATABASE={self.database}",
            f"Encrypt={self.encrypt}",
            f"TrustServerCertificate={self.trust_server_certificate}",
        ]
        if self.trusted_connection:
            parts.append("Trusted_Connection=yes")
        else:
            parts.extend([f"UID={self.user}", f"PWD={self.password}"])
        return ";".join(parts)
