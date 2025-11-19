from datetime import datetime
from fastapi import FastAPI

app = FastAPI(
    title="nproject.site API",
    description="Простой сервис для демонстрации CI/CD с Kubernetes и HTTPS",
    version="1.0.0"
)

@app.get("/")
def read_root():
    return {
        "message": "Hello from nproject.site!",
        "timestamp": datetime.utcnow().isoformat() + "Z",
        "status": "ok"
    }

@app.get("/healthz")
def health_check():
    return {"status": "healthy"}