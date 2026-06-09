<p align="center">
  <img src="https://storageforpulse.blob.core.windows.net/content-images/images/2026/05/Screenshot%202026-05-11%20at%2005.02.31.png" alt="PULSE / MedicHub preview" width="100%">
</p>

<h1 align="center">PULSE</h1>

<p align="center">
  Platforma medicala digitala MedicHub pentru continut editorial, reviste, stiri, evenimente, cursuri si administrare integrata.
</p>

<p align="center">
  <strong>Live app:</strong>
  <a href="https://pulse-medichub.web.app">https://pulse-medichub.web.app</a>
</p>

---

## Despre Proiect

PULSE este o platforma digitala construita pentru ecosistemul MedicHub, cu scopul de a centraliza continut medical relevant pentru medici si profesionisti din domeniul sanatatii. Aplicatia reuneste articole, stiri, reviste, evenimente, cursuri, notificari si zone promotionale intr-o experienta unitara, sustinuta de un backend API si de un sistem administrativ dedicat.

Proiectul este organizat ca un produs complet:

- aplicatie Flutter pentru utilizatori, disponibila pentru web, iOS si Android;
- backend FastAPI pentru API public, API administrativ, persistenta si integrari;
- ManagementSystem web pentru administrarea continutului;
- PostgreSQL pentru date relationale;
- Azure Blob Storage pentru imagini si documente PDF;
- Firebase Hosting pentru aplicatia web si zona admin;
- Render pentru gazduirea backend-ului;
- GitHub Actions pentru CI/CD, preview deploy si verificari de securitate.

---

## Functionalitati Principale

- Main feed cu continut editorial, noutati, reviste, cursuri, evenimente si reclame.
- Sectiuni dedicate pentru articole, stiri, publicatii, cursuri si evenimente.
- Vizualizare PDF pentru reviste si materiale editoriale.
- Notificari si zone de profil pentru utilizatori.
- Continut premium si stari UI pentru acces restrictionat.
- Carduri promotionale configurabile din zona admin.
- ManagementSystem pentru creare, editare, upload si publicare continut.
- Upload de imagini si PDF-uri prin backend, cu validare de tip si dimensiune.
- Teste automate pentru backend, Flutter si evals pentru agenti AI.
- Pipeline CI/CD pentru build, testare, preview/deploy si verificari de securitate.

---

## Arhitectura Pe Scurt

### Backend FastAPI

Backend-ul din `backend/` este stratul API al platformei. Este construit cu Python, FastAPI, SQLAlchemy si PostgreSQL.

Roluri principale:

- expune endpoint-uri publice consumate de aplicatia Flutter;
- expune endpoint-uri administrative consumate de ManagementSystem;
- gestioneaza continut editorial, publicatii, evenimente, cursuri, reclame, utilizatori si notificari;
- valideaza si incarca imagini/PDF-uri in Azure Blob Storage;
- foloseste `DATABASE_URL` pentru conectarea la PostgreSQL.

### Mobile Flutter

Aplicatia din `mobile/` este produsul principal pentru utilizatori. Foloseste Flutter si Dart si poate rula pe web, iOS si Android.

Aplicatia consuma API-ul public al backend-ului. URL-ul API poate fi configurat prin:

```bash
--dart-define=PULSE_API_BASE_URL=http://127.0.0.1:8000
```

Daca `PULSE_API_BASE_URL` nu este setat, aplicatia foloseste implicit backend-ul de productie configurat in proiect.

### ManagementSystem Si Deploy

`ManagementSystem/` contine panoul administrativ static, construit cu HTML, CSS si JavaScript. Acesta comunica direct cu endpoint-urile admin ale backend-ului si este folosit pentru administrarea continutului, publicatiilor, cursurilor, evenimentelor si reclamelor.

Deploy-ul este impartit astfel:

- Firebase Hosting publica aplicatia Flutter web si panoul admin sub ruta `/admin`;
- Render gazduieste backend-ul FastAPI;
- Azure Blob Storage gazduieste fisierele media incarcate din admin;
- GitHub Actions automatizeaza build-ul, preview deploy-ul, deploy-ul si verificarile de securitate.

### CI/CD

Workflow-urile GitHub Actions sunt definite in `.github/workflows/`:

- `.github/workflows/firebase-hosting-merge.yml` - build si deploy Firebase la merge/push pe ramura principala;
- `.github/workflows/firebase-hosting-pull-request.yml` - preview deploy pentru pull request-uri;
- `.github/workflows/security-ci.yml` - verificari de securitate relevante pentru proiect.

Documentatia completa a pipeline-ului este in [docs/pipeline_ci_cd.md](docs/pipeline_ci_cd.md).

---

## Structura Repository-ului

```text
PULSE/
├── backend/
│   ├── main.py
│   ├── database.py
│   ├── models.py
│   ├── requirements.txt
│   └── tests/
│       └── ai_evals/
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
│   └── index.html
├── Deploy/
│   └── admin/
├── docs/
│   └── Diagrame/
├── .github/
│   └── workflows/
└── README.md
```

---

## Setup Si Rulare

### 1. Backend Local

```bash
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python3 -m uvicorn main:app --reload
```

Backend-ul ruleaza local la:

```text
http://127.0.0.1:8000
```

Health check:

```text
http://127.0.0.1:8000/health
```

Variabile de mediu uzuale:

```bash
DATABASE_URL=postgresql://...
AZURE_STORAGE_CONNECTION_STRING=...
AZURE_STORAGE_CONTAINER_NAME=...
AZURE_STORAGE_PUBLIC_BASE_URL=...
ENVIRONMENT=development
```

Secretele de productie nu trebuie salvate in repository.

### 2. Aplicatia Flutter

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

Pentru build web cu backend de productie:

```bash
cd mobile
flutter build web --dart-define=PULSE_API_BASE_URL=https://pulse-backend-5f9b.onrender.com
```

### 3. ManagementSystem Local

```bash
cd ManagementSystem
python3 -m http.server 5500 --bind 127.0.0.1
```

Deschidere locala:

```text
http://127.0.0.1:5500
```

Fisier de configurare API:

```text
ManagementSystem/js/config.js
```

### 4. Workflow Local Recomandat

```bash
cd backend
source venv/bin/activate
python3 -m uvicorn main:app --reload
```

```bash
cd ManagementSystem
python3 -m http.server 5500 --bind 127.0.0.1
```

```bash
cd mobile
flutter run -d chrome --dart-define=PULSE_API_BASE_URL=http://127.0.0.1:8000
```

---

## Testare

Proiectul include teste automate pentru backend, Flutter si evaluari pentru agenti AI.

### Backend

```bash
cd backend
./venv/bin/python -m unittest discover -s tests
```

Teste relevante:

- `backend/tests/` - teste unitare si de integrare pentru backend;
- `backend/tests/ai_evals/` - evals pentru agenti AI.

### Flutter

```bash
cd mobile
flutter test
```

Teste relevante:

- `mobile/test/` - teste Flutter pentru modele, widget-uri si comportamente UI.

### Verificari Suplimentare

```bash
cd mobile
flutter analyze
```

```bash
ruby -e 'require "yaml"; ARGV.each { |f| YAML.load_file(f); puts "OK #{f}" }' .github/workflows/*.yml
```

Documentatia testelor si a evals pentru agenti este in [docs/teste_automate_si_evals_agenti.md](docs/teste_automate_si_evals_agenti.md).

---

## CI/CD

Pipeline-ul proiectului este configurat prin GitHub Actions si acopera scenariile principale de lucru:

- build si deploy Firebase pentru aplicatia web;
- preview deploy pentru pull request-uri;
- verificari de securitate;
- validari relevante pentru predare si mentenanta.

Workflow-uri:

- `.github/workflows/firebase-hosting-merge.yml`
- `.github/workflows/firebase-hosting-pull-request.yml`
- `.github/workflows/security-ci.yml`

Documentatie:

- [docs/pipeline_ci_cd.md](docs/pipeline_ci_cd.md)
- [docs/security-hardening.md](docs/security-hardening.md)

---

## Documentatie Pentru Predare

Livrabilele si dovezile pentru cerintele proiectului sunt centralizate in `docs/`.

### Diagrame UML, Arhitectura Si Workflow-uri

- [docs/diagrame_uml_pulse.md](docs/diagrame_uml_pulse.md)
- [docs/diagrame_uml_arhitectura_workflowuri.md](docs/diagrame_uml_arhitectura_workflowuri.md)
- [docs/Diagrame/README.md](docs/Diagrame/README.md)

### Teste Automate Si Evals Pentru Agenti

- [docs/teste_automate_si_evals_agenti.md](docs/teste_automate_si_evals_agenti.md)

### Raportare Bug Si Rezolvare Prin Pull Request

- [docs/raportare_bug_si_rezolvare_pr.md](docs/raportare_bug_si_rezolvare_pr.md)

### Pipeline CI/CD

- [docs/pipeline_ci_cd.md](docs/pipeline_ci_cd.md)

### Folosirea Toolurilor AI In Dezvoltare

- [docs/raport-utilizare-tooluri-ai.md](docs/raport-utilizare-tooluri-ai.md)
- [docs/cerinta_b_proces_dezvoltare_software_cu_ai.md](docs/cerinta_b_proces_dezvoltare_software_cu_ai.md)

### Securitate

- [docs/security-hardening.md](docs/security-hardening.md)

---

## Endpoint-uri Publice

Backend-ul expune endpoint-uri publice consumate de aplicatia Flutter:

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

---

## Endpoint-uri Admin

ManagementSystem foloseste endpoint-uri sub `/admin/*`, inclusiv:

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

Backend-ul include si endpoint-uri admin pentru evenimente, cursuri, publicatii, categorii, specializari, orase si utilizatori.

---

## Model De Continut Si Reclame

PULSE organizeaza continutul editorial si promotional in jurul urmatoarelor zone:

- articole si stiri;
- publicatii si numere de revista;
- evenimente si sesiuni;
- cursuri, module si lectii;
- reclame si template-uri de design;
- utilizatori si metadate profesionale.

Reclamele sunt administrate din ManagementSystem si afisate in aplicatia Flutter. Configurarea suporta placement, status, sponsor name, sponsor logo, imagini principale/mobile/background, CTA, design template, design config, badge si accent color.

Fisiere relevante:

```text
mobile/lib/widgets/advertisement_card.dart
ManagementSystem/ad-form.html
ManagementSystem/js/ad-form.js
ManagementSystem/css/styles.css
```

---

## Media Si Upload

Azure Blob Storage este folosit pentru fisiere incarcate din admin: imagini si PDF-uri.

Endpoint-uri principale:

```text
POST /admin/uploads/image
POST /admin/uploads/pdf
```

Reguli de upload implementate in backend:

- imagini: JPEG, PNG, WebP;
- dimensiune maxima imagini: 5 MB;
- documente: PDF;
- dimensiune maxima PDF: 25 MB.

Backend-ul returneaza URL-ul public construit pe baza `AZURE_STORAGE_PUBLIC_BASE_URL`.

---

## Securitate Si Configurare

- Nu se salveaza secrete de productie in repository.
- Fisierele `.env` raman locale sau in platformele de hosting.
- Credentialele Azure Blob Storage sunt folosite doar de backend.
- Service account-ul Firebase trebuie configurat ca secret GitHub Actions.
- Variabilele Render trebuie configurate in dashboard-ul Render.
- CORS este controlat prin `ALLOWED_ORIGINS`.
- Verificarile de securitate sunt documentate in [docs/security-hardening.md](docs/security-hardening.md) si [docs/pipeline_ci_cd.md](docs/pipeline_ci_cd.md).

Origin-uri locale/de productie folosite uzual:

```text
http://localhost:5500
http://127.0.0.1:5500
https://pulse-medichub.web.app
```

---

## Deploy

### Firebase Hosting

Firebase Hosting publica aplicatia Flutter web si ManagementSystem sub `/admin`.

Config hosting:

```text
mobile/firebase.json
```

Workflow-uri:

```text
.github/workflows/firebase-hosting-merge.yml
.github/workflows/firebase-hosting-pull-request.yml
```

### Render

Render gazduieste backend-ul FastAPI. Variabilele de productie pentru baza de date, Azure Blob Storage si email trebuie configurate in Render.

Variabile relevante:

```bash
DATABASE_URL=...
AZURE_STORAGE_CONNECTION_STRING=...
AZURE_STORAGE_CONTAINER_NAME=...
AZURE_STORAGE_PUBLIC_BASE_URL=...
ENVIRONMENT=production
EMAIL_PROVIDER=brevo_api
BREVO_API_KEY=<BREVO_API_KEY>
BREVO_API_TIMEOUT_SECONDS=20
EMAIL_FROM=pulse.medichub@gmail.com
SMTP_FROM=pulse.medichub@gmail.com
FROM_EMAIL=pulse.medichub@gmail.com
EMAIL_FROM_NAME=PULSE
EMAIL_REPLY_TO=pulse.medichub@gmail.com
```

Start command recomandat:

```bash
python3 -m uvicorn main:app --host 0.0.0.0 --port $PORT
```

Pentru Render production se foloseste Brevo Transactional Email API peste HTTPS: `EMAIL_PROVIDER=brevo_api`. SMTP ramane fallback/local. Dupa deploy, logurile Render trebuie sa confirme configurarea email si rezultatul trimiterilor.

Este necesar redeploy pe Render atunci cand se modifica backend-ul, schema de date, contractul API sau logica de upload. Schimbarile strict vizuale in Flutter sau ManagementSystem nu necesita redeploy pe Render.

---

## Note Pentru Mentenanta

Pastreaza limitele componentelor clare:

- schimbarile de aplicatie apartin in `mobile/`;
- schimbarile backend/API/database apartin in `backend/`;
- schimbarile de admin apartin in `ManagementSystem/`;
- documentatia si livrabilele de predare apartin in `docs/`;
- comportamentul de deploy Firebase este definit in `.github/workflows/` si `mobile/firebase.json`.

Inainte de predare sau release, ruleaza testele relevante si verifica documentatia asociata cerintelor evaluate.
