from fastapi import FastAPI

app = FastAPI()

@app.get("/")
def root():
    return {"message": "Hello from PULSE backend"}

@app.get("/health")
def health():
    return {"status": "ok"}

@app.get("/articles")
def get_articles():
    return [
        {"id": 1, "title": "Noutăți în cardiologie", "type": "article"},
        {"id": 2, "title": "Actualizări în pediatrie", "type": "article"}
    ]

@app.get("/courses-events")
def get_courses_events():
    return [
        {"id": 1, "type": "course", "title": "Curs ECG"},
        {"id": 2, "type": "event", "title": "Congres cardiologie"}
    ]