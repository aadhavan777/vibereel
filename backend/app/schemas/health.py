from pydantic import BaseModel


class HealthResponse(BaseModel):
    status: str
    project: str
    version: str
    environment: str
    database: str
