# PULSE Management System

Platforma web internă pentru administrarea conținutului din aplicația mobilă PULSE/MedicHub.
Această interfață comunică direct cu backend-ul existent FastAPI și folosește aceeași bază de date PostgreSQL.

## Structura Proiectului

Platforma este construită folosind tehnologii web standard (HTML, CSS, JavaScript Vanilla) pentru a fi simplu de hostat pe Firebase Hosting și ușor de întreținut, fără a necesita un build step.

## Cum rulez local?

1.  **Pornește Backend-ul**:
    Înainte de a rula frontend-ul, trebuie să te asiguri că backend-ul rulează. În terminal:
    ```bash
    cd /Users/robert/Desktop/PULSE/backend
    source ../.venv/bin/activate  # (sau sursa mediului tău virtual)
    python -m uvicorn main:app --reload
    ```
    Backend-ul va fi disponibil la `http://127.0.0.1:8000`.

2.  **Pornește Frontend-ul**:
    Deschide un nou terminal și navighează în directorul ManagementSystem:
    ```bash
    cd /Users/robert/Desktop/PULSE/ManagementSystem
    python3 -m http.server 5500
    ```

3.  **Accesează aplicația**:
    Deschide browserul și accesează: `http://localhost:5500`

    *Pentru MVP: Folosește credențialele de test: `pulse@admin` / `pulse@admin`.*

## Configurare pentru Producție

Când backend-ul este deployat pe Render (sau alt provider), trebuie să actualizezi fișierul `js/config.js` pentru a pointa către URL-ul public:

```javascript
const CONFIG = {
    API_BASE_URL: (window.PULSE_API_BASE_URL || 'https://pulse-backend-5f9b.onrender.com').replace(/\/+$/, ''),
};
```

## Deploy pe Firebase Hosting sub path-ul `/admin`

Deoarece vrei ca aplicația să ruleze direct pe site-ul existent `https://pulse-medichub.web.app/admin`, am configurat tot codul cu `<base href="/admin/">` și am creat un folder gata de deploy.

1. Am generat structura în folderul `PULSE/Deploy/admin/`.
2. Cum publici:
   * Construiește aplicația ta de mobile (Flutter Web) ca de obicei: `flutter build web`.
   * Aceasta va genera structura în folderul `PULSE/mobile/build/web`.
   * Copiază pur și simplu folderul `admin` din `PULSE/Deploy` în folderul generat de Flutter: `PULSE/mobile/build/web/admin`.
   * În final, mergi în `PULSE/mobile` și dă comanda ta standard de deploy:
     ```bash
     firebase deploy --only hosting
     ```

Firebase va servi automat interfața de admin pentru oricine accesează URL-ul `/admin/`.

## Arhitectură și Decizii Tehnice

*   **Fără framework-uri (React/Vue)**: Pentru simplitate maximă și compatibilitate directă cu Firebase Hosting MVP.
*   **CSS**: Construit pentru a respecta estetica premium (`pulse_theme.dart`) din aplicația mobilă (culori specifice pe categorii, shadows, etc.).
*   **Auth (MVP)**: Momentan simulată în `auth.js` folosind `localStorage`. API-ul FastAPI poate fi extins ulterior pentru a valida token-urile JWT. Toate request-urile din frontend deja atașează `Authorization: Bearer <token>` automat.
