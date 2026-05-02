# PULSE / MedicHub

PULSE este o platformă medicală digitală construită pentru ecosistemul MedicHub. Platforma centralizează conținut editorial, reviste, știri, evenimente, cursuri și reclame într-o experiență unitară pentru medici și profesioniști din domeniul sănătății.

Proiectul este un sistem complet format din:

- aplicație Flutter pentru utilizatori și medici;
- backend FastAPI pentru API public și API administrativ;
- bază de date PostgreSQL găzduită pe Azure;
- ManagementSystem web pentru administrarea conținutului;
- Azure Blob Storage pentru imagini și PDF-uri;
- Firebase Hosting pentru aplicația web și panoul admin;
- Render pentru găzduirea backend-ului.

---

## Overview Arhitectural

PULSE este organizat în mai multe componente independente, conectate prin API-uri și servicii cloud.

### Flutter App

Aplicația din `mobile/` este produsul principal pentru utilizatori. Suportă web, iOS și Android și afișează Main Feed-ul cu carousel, articole, știri, reviste, evenimente, cursuri și reclame.

Aplicația consumă endpoint-urile publice din backend și poate primi URL-ul API prin `PULSE_API_BASE_URL`.

### FastAPI Backend

Backend-ul din `backend/` este stratul API al platformei. Este construit cu Python, FastAPI, SQLAlchemy și PostgreSQL.

Roluri principale:

- expune endpoint-uri publice pentru aplicația Flutter;
- expune endpoint-uri admin pentru ManagementSystem;
- gestionează conținut, publicații, evenimente, cursuri și reclame;
- validează și încarcă imagini/PDF-uri în Azure Blob Storage;
- comunică cu baza de date PostgreSQL prin SQLAlchemy.

### PostgreSQL pe Azure

Baza de date de producție este PostgreSQL găzduită pe Azure. Backend-ul citește conexiunea din `DATABASE_URL` și folosește configurare compatibilă cu conexiuni SSL pentru PostgreSQL.

### ManagementSystem

`ManagementSystem/` conține panoul administrativ static, construit cu HTML, CSS și JavaScript. Este folosit pentru administrarea conținutului editorial, a publicațiilor, evenimentelor, cursurilor, reclamelor și fișierelor media.

ManagementSystem comunică direct cu endpoint-urile admin ale backend-ului.

### Azure Blob Storage

Azure Blob Storage este folosit pentru fișiere încărcate din admin: imagini și PDF-uri. Backend-ul validează tipul și dimensiunea fișierelor, încarcă fișierul în Azure și returnează URL-ul public.

### Firebase Hosting

Firebase Hosting servește build-ul web Flutter și panoul admin. În workflow-ul GitHub Actions, `ManagementSystem/` este copiat în build-ul Flutter sub ruta `/admin`.

### Render

Render găzduiește backend-ul FastAPI. Variabilele de producție pentru baza de date și Azure Blob Storage sunt configurate în Render.

---

## Structura Folderelor

```text
PULSE/
├── backend/
│   ├── main.py
│   ├── database.py
│   ├── models.py
│   └── requirements.txt
├── mobile/
│   ├── lib/
│   ├── test/
│   ├── web/
│   ├── android/
│   ├── ios/
│   ├── firebase.json
│   └── pubspec.yaml
├── ManagementSystem/
│   ├── css/
│   ├── js/
│   ├── assets/
│   ├── ad-form.html
│   ├── ads.html
│   ├── content-form.html
│   └── index.html
├── Deploy/
│   └── admin/
├── .github/
│   └── workflows/
│       ├── firebase-hosting-merge.yml
│       └── firebase-hosting-pull-request.yml
└── README.md
```

---

## Backend

### Tehnologii

- Python
- FastAPI
- SQLAlchemy
- PostgreSQL
- Azure Blob Storage SDK
- Uvicorn

### Rol

Backend-ul este responsabil pentru:

- API-ul public consumat de aplicația Flutter;
- API-ul administrativ consumat de ManagementSystem;
- operațiuni CRUD pentru conținut, reviste, evenimente, cursuri și reclame;
- upload de imagini și PDF-uri în Azure Blob Storage;
- acces la baza de date prin SQLAlchemy.

### Rulare Locală

Backend-ul rulează local, în mod uzual, la:

```text
http://127.0.0.1:8000
```

Health check:

```text
http://127.0.0.1:8000/health
```

Comenzi locale:

```bash
cd backend
source venv/bin/activate
python3 -m uvicorn main:app --reload
```

Dacă mediul virtual nu există:

```bash
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python3 -m uvicorn main:app --reload
```

### Variabile de Mediu

Backend-ul citește configurarea din `backend/.env` local sau din variabilele setate în platforma de hosting.

```bash
DATABASE_URL=postgresql://...
AZURE_STORAGE_CONNECTION_STRING=...
AZURE_STORAGE_CONTAINER_NAME=...
AZURE_STORAGE_PUBLIC_BASE_URL=...
ENVIRONMENT=development
```

Secretele de producție nu trebuie salvate în repository.

### Deploy

Backend-ul se deployează separat pe Render. Render trebuie să aibă configurate variabilele de mediu pentru PostgreSQL și Azure Blob Storage.

Start command recomandat:

```bash
python3 -m uvicorn main:app --host 0.0.0.0 --port $PORT
```

URL-ul backend-ului de producție folosit implicit de aplicație și admin este:

```text
https://pulse-backend-5f9b.onrender.com
```

---

## Mobile / Flutter App

### Tehnologii

- Flutter
- Dart
- Material UI
- HTTP API integration
- Web, iOS și Android

### Rol

Aplicația Flutter este experiența principală pentru utilizatori. Include:

- ecrane de login și onboarding;
- Main Feed;
- carousel de conținut featured;
- articole și știri;
- reviste;
- evenimente și cursuri;
- carduri de reclamă;
- stări de loading, empty state și eroare.

### Rulare Locală

```bash
cd mobile
flutter pub get
flutter run
```

Pentru web:

```bash
cd mobile
flutter run -d chrome
```

Pentru rulare web cu backend local:

```bash
cd mobile
flutter run -d chrome --dart-define=PULSE_API_BASE_URL=http://127.0.0.1:8000
```

Pentru build web cu backend de producție:

```bash
cd mobile
flutter build web --dart-define=PULSE_API_BASE_URL=https://pulse-backend-5f9b.onrender.com
```

Dacă `PULSE_API_BASE_URL` nu este setat, aplicația folosește implicit backend-ul de producție de pe Render.

### Verificare

```bash
cd mobile
flutter analyze
flutter test
```

---

## ManagementSystem

### Tehnologii

- HTML static
- CSS
- JavaScript
- FastAPI admin endpoints

### Rol

ManagementSystem este interfața administrativă pentru operațiunile MedicHub/PULSE. Permite:

- vizualizarea dashboard-ului;
- administrarea conținutului editorial;
- administrarea evenimentelor;
- administrarea cursurilor;
- administrarea publicațiilor;
- administrarea reclamelor;
- upload de imagini și PDF-uri în Azure Blob Storage;
- configurarea și preview-ul reclamelor.

### Rulare Locală

Panoul admin poate fi servit ca set de fișiere statice.

```bash
cd ManagementSystem
python3 -m http.server 5500 --bind 127.0.0.1
```

Deschidere locală:

```text
http://127.0.0.1:5500
```

Formular reclame:

```text
http://127.0.0.1:5500/ad-form.html
```

### Configurare API

ManagementSystem citește URL-ul API din `window.PULSE_API_BASE_URL`, dacă acesta este definit. În lipsa lui, folosește backend-ul de producție:

```text
https://pulse-backend-5f9b.onrender.com
```

Fișier relevant:

```text
ManagementSystem/js/config.js
```

---

## Deploy/admin

`Deploy/admin/` este o copie statică a panoului admin, pregătită pentru scenarii de deploy sau testare sub ruta `/admin`.

În workflow-ul Firebase activ, sursa copiată în build-ul web este `ManagementSystem/`:

```bash
rm -rf build/web/admin
mkdir -p build/web/admin
cp -r ../ManagementSystem/* build/web/admin/
```

Când se modifică fișiere admin, copiile locale din `Deploy/admin/` și `mobile/build/web/admin/` pot necesita sincronizare dacă sunt folosite pentru testare sau deploy manual.

---

## Firebase Hosting

Firebase Hosting este configurat din directorul `mobile/`.

Proiect Firebase:

```text
pulse-medichub
```

Config hosting:

```text
mobile/firebase.json
```

Deploy-ul de producție este rulat prin GitHub Actions la push pe `main`:

```text
.github/workflows/firebase-hosting-merge.yml
```

Preview deploy pentru pull request-uri:

```text
.github/workflows/firebase-hosting-pull-request.yml
```

Workflow-ul de deploy:

1. face checkout la repository;
2. instalează Flutter;
3. rulează `flutter pub get`;
4. construiește aplicația web Flutter;
5. copiază `ManagementSystem/` în `build/web/admin`;
6. publică rezultatul pe Firebase Hosting.

---

## Render

Backend-ul FastAPI este deployat separat pe Render.

Render trebuie să aibă configurate:

```bash
DATABASE_URL=...
AZURE_STORAGE_CONNECTION_STRING=...
AZURE_STORAGE_CONTAINER_NAME=...
AZURE_STORAGE_PUBLIC_BASE_URL=...
ENVIRONMENT=production
```

Schimbările în `backend/` necesită, în general, redeploy pe Render. Schimbările limitate la Flutter, ManagementSystem, CSS/JS static sau workflow-uri Firebase nu necesită deploy pe Render, cu excepția cazului în care contractul API se schimbă.

---

## Azure Blob Storage

Upload-ul media se face prin backend, folosind endpoint-uri admin:

```text
POST /admin/uploads/image
POST /admin/uploads/pdf
```

Reguli de upload implementate în backend:

- imagini: JPEG, PNG, WebP;
- dimensiune maximă imagini: 5 MB;
- documente: PDF;
- dimensiune maximă PDF: 25 MB.

Backend-ul returnează URL-ul public construit pe baza `AZURE_STORAGE_PUBLIC_BASE_URL`.

---

## Endpoint-uri Publice

Backend-ul expune endpoint-uri publice consumate de aplicația Flutter:

```text
GET /health
GET /content-items
GET /featured-content
GET /articles
GET /news
GET /publications
GET /events
GET /courses
GET /courses-events
GET /ads
```

Aceste endpoint-uri livrează date de prezentare pentru aplicația mobilă/web.

---

## Endpoint-uri Admin

ManagementSystem folosește endpoint-uri sub `/admin/*`, inclusiv:

```text
GET    /admin/dashboard/stats
GET    /admin/content-items
POST   /admin/content-items
PUT    /admin/content-items/{id}
GET    /admin/ads
POST   /admin/ads
PUT    /admin/ads/{id}
DELETE /admin/ads/{id}
POST   /admin/uploads/image
POST   /admin/uploads/pdf
```

Backend-ul include și endpoint-uri admin pentru evenimente, cursuri, publicații, categorii, specializări, orașe și utilizatori.

---

## Workflow Local Recomandat

### 1. Pornește Backend-ul

```bash
cd backend
source venv/bin/activate
python3 -m uvicorn main:app --reload
```

### 2. Pornește ManagementSystem

```bash
cd ManagementSystem
python3 -m http.server 5500 --bind 127.0.0.1
```

Deschide:

```text
http://127.0.0.1:5500
```

### 3. Pornește Aplicația Flutter

```bash
cd mobile
flutter pub get
flutter run -d chrome --dart-define=PULSE_API_BASE_URL=http://127.0.0.1:8000
```

### 4. Rulează Verificări

```bash
cd mobile
flutter analyze
flutter test
```

```bash
node --check ManagementSystem/js/ad-form.js
```

---

## Model de Conținut

PULSE organizează conținutul editorial și promoțional în jurul următoarelor zone:

- articole;
- știri;
- publicații și numere de revistă;
- evenimente și sesiuni;
- cursuri, module și lecții;
- reclame și template-uri de design;
- utilizatori și metadate profesionale.

Aplicația Flutter consumă date publice, pregătite pentru afișare. ManagementSystem lucrează cu fluxuri administrative, formulare și upload-uri.

---

## Sistemul de Reclame

Reclamele sunt administrate din ManagementSystem și afișate în aplicația Flutter.

Concepte suportate:

- placement;
- status;
- sponsor name;
- sponsor logo;
- main image;
- mobile image;
- background image;
- CTA label și URL;
- design template;
- design config;
- badge;
- accent color.

Randarea reclamelor în Flutter:

```text
mobile/lib/widgets/advertisement_card.dart
```

Formularul și preview-ul din admin:

```text
ManagementSystem/ad-form.html
ManagementSystem/js/ad-form.js
ManagementSystem/css/styles.css
```

---

## CORS

Backend-ul permite în prezent request-uri din:

```text
http://localhost:5500
http://127.0.0.1:5500
https://pulse-medichub.web.app
```

Dacă se adaugă un domeniu nou pentru frontend sau admin, configurația CORS din backend trebuie actualizată înainte de deploy.

---

## Securitate

- Nu salva secrete de producție în repository.
- Păstrează fișierele `.env` local sau în platforma de hosting.
- Credentialele Azure Blob Storage aparțin backend-ului.
- Service account-ul Firebase aparține secretelor GitHub Actions.
- Variabilele de producție Render trebuie configurate în dashboard-ul Render.

---

## Rezumat Deploy

### Firebase

Firebase Hosting publică aplicația web Flutter și ManagementSystem sub `/admin`.

Push pe `main` declanșează deploy live:

```text
.github/workflows/firebase-hosting-merge.yml
```

Pull request-urile declanșează preview deploy:

```text
.github/workflows/firebase-hosting-pull-request.yml
```

### Render

Render găzduiește backend-ul FastAPI.

Este necesar deploy pe Render atunci când se modifică backend-ul, schema de date, contractul API sau logica de upload. Nu este necesar deploy pe Render pentru schimbări strict vizuale în Flutter sau ManagementSystem.

---

## Note pentru Mentenanță

Păstrează limitele componentelor clare:

- schimbările de aplicație aparțin în `mobile/`;
- schimbările backend/API/database aparțin în `backend/`;
- schimbările de admin aparțin în `ManagementSystem/`;
- copiile statice pot necesita sincronizare în `Deploy/admin/` și `mobile/build/web/admin/`;
- comportamentul de deploy Firebase este definit în `.github/workflows/` și `mobile/firebase.json`.

Înainte de release, rulează verificările relevante pentru componenta modificată și testează fluxul end-to-end afectat.
