# PULSE Security Hardening

Documentul acesta descrie măsurile aplicate în repository și setările care trebuie făcute manual în Firebase, Render și Azure înainte de demo/deploy.

## Ce s-a securizat în cod

- CORS este configurat din `ALLOWED_ORIGINS`, cu valori separate prin virgulă. În production nu este permis `*`.
- Backend-ul adaugă headere de securitate: `X-Content-Type-Options`, `X-Frame-Options`, `Referrer-Policy`, `Permissions-Policy`.
- Backend-ul limitează requesturile după `Content-Length` prin `MAX_REQUEST_BODY_BYTES`.
- Endpoint-urile `/admin/*` cer token de admin emis de backend prin `/admin/auth/login`; tokenul mock din browser a fost eliminat.
- Endpoint-urile private de saved content folosesc userul extras din sesiunea server-side, nu un `user_id` trimis din client.
- Login, register, AI, upload și scrierile admin au rate limiting in-memory per IP.
- Răspunsurile de eroare `500` sunt sanitizate ca să nu expună stack traces, connection strings, SQL sau path-uri locale.
- Uploadul Azure are timeout și erori generice către client.
- Inputul AI este limitat prin `AI_MAX_INPUT_CHARS`, iar promptul tratează conținutul articolului/PDF-ului ca text neîncrezător.
- Tokenul de sesiune din aplicația Flutter este stocat în `flutter_secure_storage`; valorile vechi din `shared_preferences` sunt migrate automat.
- CI rulează teste backend, teste Flutter și audit Python de bază.

## Autentificare

Backend-ul folosește în prezent autentificare proprie cu `users` și `user_sessions`. Nu există Firebase Auth SDK integrat în codul mobil/backend în acest repository. În codul Flutter există doar câmpul `firebase_uid` trimis la register cu o valoare locală de tip `local_<hash>`, nu un token Firebase și nu un apel Firebase Auth. Firebase este folosit în repository pentru Hosting, prin `mobile/firebase.json` și workflow-urile GitHub Actions.

Dacă se decide trecerea la Firebase Auth, backend-ul trebuie să valideze ID token-urile cu Firebase Admin SDK sau o metodă standard care verifică semnătura, `aud`, `iss` și expirarea tokenului.

Admin-ul static se autentifică acum la backend:

```text
POST /admin/auth/login
```

Credentialele admin nu se pun în JavaScript. Se configurează prin environment variables.

## Endpoint-uri publice și private

Publice:

- `GET /health`
- `GET /content-items`
- `GET /content-items/{content_item_id}`
- `GET /featured-content`
- `GET /articles`
- `GET /news`
- `GET /courses`
- `GET /events`
- `GET /courses-events`
- `GET /publications`
- `GET /publications/{publication_id}/issues`
- `GET /publication-issues/{issue_id}`
- `GET /publication-issues/{issue_id}/pdf`
- nomenclatoare publice, de exemplu `/counties`, `/cities`, `/specializations`

Private user:

- `GET /api/me/profile`
- `GET /saved-content/ids`
- `GET /saved-content`
- `POST /saved-content/{content_item_id}`
- `DELETE /saved-content/{content_item_id}`

Private admin:

- toate endpoint-urile `/admin/*`, cu excepția `POST /admin/auth/login`

AI:

- `POST /content-items/{content_item_id}/ai-summary`
- `POST /publication-issues/{issue_id}/ai-summary`

Aceste endpoint-uri AI sunt publice deoarece rezumă doar conținut public: `content-items` active, neșterse și publicate, respectiv ediții de publicații legate de conținut publicat. Nu citesc date user-specific, profiluri, saved content, activity logs sau payload text arbitrar trimis de client. Ambele endpoint-uri aplică rate limiting prin `AI_RATE_LIMIT_PER_MINUTE`, iar lungimea inputului este limitată prin `AI_MAX_INPUT_CHARS`.

## Required .env variables

Adaugă sau verifică în `backend/.env`:

```bash
DATABASE_URL=postgresql://USER:PASSWORD@HOST:PORT/DBNAME?sslmode=require
ENVIRONMENT=development
ALLOWED_ORIGINS=http://localhost:5500,http://127.0.0.1:5500,http://localhost:8080,http://127.0.0.1:8080,https://pulse-medichub.web.app
TRUSTED_HOSTS=localhost,127.0.0.1,pulse-backend-5f9b.onrender.com
MAX_REQUEST_BODY_BYTES=31457280
AUTH_RATE_LIMIT_PER_MINUTE=10
WRITE_RATE_LIMIT_PER_MINUTE=60
AI_RATE_LIMIT_PER_MINUTE=10
RATE_LIMIT_WINDOW_SECONDS=60
ADMIN_USERNAME=admin@example.com
ADMIN_PASSWORD_HASH=pbkdf2_sha256$ITERATIONS$SALT_HEX$HASH_HEX
ADMIN_SESSION_TTL_MINUTES=480
AZURE_STORAGE_CONNECTION_STRING=DefaultEndpointsProtocol=https;AccountName=...;AccountKey=...;EndpointSuffix=core.windows.net
AZURE_STORAGE_CONTAINER_NAME=pulse-media
AZURE_STORAGE_PUBLIC_BASE_URL=https://ACCOUNT.blob.core.windows.net/pulse-media
AI_PROVIDER=gemini
GEMINI_API_KEY=...
GEMINI_MODEL=gemini-2.5-flash
AI_MAX_INPUT_CHARS=24000
ENABLE_API_DOCS=true
```

Formatul exact acceptat pentru `ADMIN_PASSWORD_HASH` este:

```text
pbkdf2_sha256$ITERATIONS$SALT_HEX$DERIVED_KEY_HEX
```

Backend-ul validează doar acest format prin `verify_password`; algoritmul trebuie să fie exact `pbkdf2_sha256`. Pentru generare, folosește scriptul separat de mai jos. Nu importa `hash_password` din `main.py` pentru generare, deoarece `main.py` inițializează aplicația și importă configurarea bazei de date.

```bash
cd /Users/robert/Desktop/PULSE/backend
source venv/bin/activate
python3 scripts/generate_admin_hash.py
```

Nu salva parola admin în clar în repo.

## Variabile Render

Configurează în Render aceleași valori necesare backend-ului:

- `DATABASE_URL`: conexiunea PostgreSQL. Necesar local și Render, nu Azure.
- `ENVIRONMENT=production`: necesar Render.
- `ALLOWED_ORIGINS`: domeniile web reale, de exemplu `https://pulse-medichub.web.app`. Necesar Render.
- `TRUSTED_HOSTS`: hosturile acceptate de backend, de exemplu `pulse-backend-5f9b.onrender.com` plus domeniul custom dacă există. Necesar Render.
- `MAX_REQUEST_BODY_BYTES`: limită request body. Necesar local și Render.
- `AUTH_RATE_LIMIT_PER_MINUTE`: limită login/register/admin login. Necesar local și Render.
- `WRITE_RATE_LIMIT_PER_MINUTE`: limită upload/scrieri. Necesar local și Render.
- `AI_RATE_LIMIT_PER_MINUTE`: limită endpoint-uri AI. Necesar local și Render.
- `RATE_LIMIT_WINDOW_SECONDS`: fereastra rate limit. Necesar local și Render.
- `ADMIN_USERNAME`: email/user admin pentru ManagementSystem. Necesar local și Render.
- `ADMIN_PASSWORD_HASH`: hash PBKDF2 pentru parola admin. Necesar local și Render.
- `ADMIN_SESSION_TTL_MINUTES`: TTL token admin. Necesar local și Render.
- `AZURE_STORAGE_CONNECTION_STRING`: secret Azure Storage. Necesar local și Render, valoarea vine din Azure.
- `AZURE_STORAGE_CONTAINER_NAME`: container Azure. Necesar local și Render.
- `AZURE_STORAGE_PUBLIC_BASE_URL`: URL public container/media. Necesar local și Render.
- `AI_PROVIDER`: `gemini` pentru implementarea curentă. Necesar doar dacă AI este activ.
- `GEMINI_API_KEY`: cheia Gemini. Necesar local și Render doar dacă AI este activ.
- `GEMINI_MODEL`: modelul Gemini. Necesar local și Render doar dacă AI este activ.
- `AI_MAX_INPUT_CHARS`: limită input AI. Necesar local și Render.
- `ENABLE_API_DOCS=false`: recomandat în Render production.

## Setări Render de verificat manual

- Deploy branch rămâne cel configurat în Render, nu a fost schimbat în repo.
- Root directory rămâne `backend`, dacă așa este configurat acum.
- Build command rămâne compatibil cu `pip install -r requirements.txt`.
- Start command rămâne compatibil cu `python3 -m uvicorn main:app --host 0.0.0.0 --port $PORT`.
- Health check path rămâne `/health`.
- Python version recomandat: 3.12 sau versiunea folosită deja de Render.
- Activează auto-deploy GitHub pe branch-ul existent.
- Verifică logurile Render să nu afișeze valori din `.env`.

## Firebase manual

- Authentication providers: lasă active doar providerii folosiți real.
- Authorized domains: păstrează doar domeniile Firebase/custom folosite.
- Firestore / Realtime Database rules: dacă serviciile sunt active, setează deny-by-default și reguli explicite.
- Storage rules: dacă Firebase Storage este activ, restricționează citirea/scrierea; aplicația folosește Azure Blob pentru media admin.
- App Check: activează pentru web/mobile dacă integrarea Firebase Auth/Firestore/Storage devine activă.
- API key restrictions: restricționează cheia publică Firebase unde platforma permite.
- GitHub secret `FIREBASE_SERVICE_ACCOUNT_PULSE_MEDICHUB`: rotește dacă a fost expus și păstrează-l doar în GitHub Secrets.

## Azure manual

- Rotește `AZURE_STORAGE_CONNECTION_STRING` dacă a fost expus.
- Containerul media trebuie să aibă doar nivelul de public access necesar pentru citire publică a fișierelor publice.
- Folosește RBAC/least privilege pentru conturile care administrează storage.
- Dacă este disponibil, mută secretele în Azure Key Vault și injectează-le în Render ca environment variables.
- Activează logging/monitoring fără payload-uri sensibile.
- Configurează quotas/rate limits unde serviciul permite.
- Pentru AI Azure/OpenAI viitor, folosește doar env vars de tip `AZURE_OPENAI_ENDPOINT`, `AZURE_OPENAI_API_KEY`, `AZURE_OPENAI_DEPLOYMENT`, `AZURE_OPENAI_API_VERSION`; nu sunt folosite în codul curent.

## Testare locală

```bash
cd /Users/robert/Desktop/PULSE/backend
source venv/bin/activate
pip install -r requirements.txt
python3 -m unittest discover -s tests
python3 -m uvicorn main:app --reload
```

În alt terminal:

```bash
cd /Users/robert/Desktop/PULSE/mobile
flutter pub get
flutter test
flutter run -d chrome --dart-define=PULSE_API_BASE_URL=http://127.0.0.1:8000
```

ManagementSystem:

```bash
cd /Users/robert/Desktop/PULSE/ManagementSystem
python3 -m http.server 5500
```

Deschide `http://localhost:5500` și autentifică-te cu valorile configurate în `ADMIN_USERNAME` și parola corespunzătoare lui `ADMIN_PASSWORD_HASH`.

## Limitări rămase

- Rate limiting-ul este in-memory; pe mai multe instanțe Render trebuie mutat în Redis sau alt storage comun.
- Admin session token-urile se pierd la restart/deploy Render; utilizatorii admin se reautentifică.
- Backend-ul nu validează Firebase ID Token pentru useri deoarece aplicația curentă nu folosește Firebase Auth SDK în cod.
- Nu există migrații de schemă în repository; schimbările de DB trebuie validate separat.
