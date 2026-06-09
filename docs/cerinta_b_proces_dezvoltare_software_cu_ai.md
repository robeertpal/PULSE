# Cerința B — Procesul de dezvoltare software cu AI

## 1. Context

Proiectul PULSE a fost dezvoltat printr-un proces software asistat de AI, în care instrumentele de inteligență artificială au fost folosite pentru analiză, planificare, implementare, debugging, testare, documentare și validare. AI-ul a avut rol de sprijin în luarea deciziilor tehnice, în structurarea materialelor și în accelerarea activităților repetitive, iar rezultatele au fost verificate și adaptate de echipă înainte de integrare.

Scopul acestui document este să centralizeze dovezile relevante pentru cerința B și să arate, într-o formă coerentă, cum proiectul PULSE acoperă procesul de dezvoltare software cu AI: de la backlog și diagrame până la Git, teste automate, evals, bug reporting, CI/CD și documentarea tool-urilor folosite.

## 2. User stories și backlog creation

User stories și backlog-ul proiectului PULSE sunt gestionate în Jira. Există minimum 10 user stories, iar backlog-ul este organizat astfel încât să urmărească fluxul principal al aplicației și funcționalitățile esențiale ale proiectului: autentificare, onboarding, feed principal, conținut medical, cursuri, evenimente, publicații, abonamente, funcționalități AI și administrare.

User stories au fost formulate și rafinate cu ajutorul tool-urilor AI, care au sprijinit clarificarea cerințelor, împărțirea funcționalităților în task-uri mai mici și organizarea lor într-o formă mai ușor de urmărit în procesul de dezvoltare.

Referință: Jira workspace / board PULSE — link disponibil intern.

## 3. Diagrame UML, arhitectură și workflow-uri

PULSE include documentație vizuală completă pentru arhitectură și comportamentul aplicației. Documentația acoperă diagrame UML, arhitectura componentelor, diagrame de secvență, diagrame de stări, workflow-uri funcționale și modelarea bazei de date.

Materialele relevante sunt:

- [Diagrame UML, arhitectură și workflow-uri](./diagrame_uml_arhitectura_workflowuri.md)
- [Diagrame UML detaliate PULSE](./diagrame_uml_pulse.md)
- [Diagrame vizuale](./Diagrame/)

Aceste diagrame descriu atât structura statică a sistemului, prin clase, pachete și componente, cât și comportamentul aplicației în fluxurile principale: înregistrare, autentificare, administrare conținut, înscriere la evenimente și submisii de conținut.

## 4. Source control cu Git

Proiectul folosește Git și GitHub pentru controlul versiunilor, lucru pe branch-uri, commit-uri, pull request-uri și integrarea modificărilor. Dezvoltarea a fost organizată prin branch-uri dedicate pentru funcționalități sau bug fix-uri, urmate de Pull Request-uri și merge-uri în istoricul proiectului.

În repository există branch-uri dedicate precum `fix/register-flow-backend-connection`, alături de numeroase branch-uri de tip `feature/...`, folosite pentru dezvoltarea incrementală a funcționalităților. Istoricul Git conține Pull Request-uri merge-uite, inclusiv `#17`, `#74` și `#75`, iar istoricul commit-urilor arată minimum 5 commit-uri pentru studenții principali implicați în dezvoltare.

AI-ul a fost folosit și în zona de source control pentru suport în interpretarea comenzilor Git, structurarea branch-urilor, înțelegerea diferențelor dintre modificări, rezolvarea conflictelor și pregătirea mesajelor sau descrierilor de Pull Request.

## 5. Teste automate și evals pentru agenți

Proiectul include teste automate pentru backend, teste automate pentru aplicația Flutter și evals dedicate agenților AI. Această acoperire este documentată în:

- [Teste automate și evals pentru agenții AI](./teste_automate_si_evals_agenti.md)
- [Teste backend](../backend/tests/)
- [Evals agenți AI](../backend/tests/ai_evals/test_ai_agents.py)
- [Teste Flutter](../mobile/test/)

Backend-ul include 31 de teste automate `unittest`, care acoperă flow-uri funcționale, securitate, endpoint-uri AI și comportamente importante ale API-ului. Comanda principală de rulare este:

```bash
cd backend
source venv/bin/activate
python -m unittest discover -s tests
```

Rezultatul verificării este:

```text
Ran 31 tests ... OK
```

Aplicația Flutter include 25 de teste automate pentru validatori, modele, widget tests și verificări de interfață, inclusiv UI premium blur. Comanda principală este:

```bash
cd mobile
flutter test
```

Rezultatul verificării este:

```text
All tests passed!
```

În plus, proiectul include evals pentru `Agent 1 — recomandări personalizate` și `Agent 2 — rezumare și răspuns rapid despre articol`. Aceste evaluări verifică relevanța recomandărilor, existența explicațiilor, folosirea contextului utilizatorului, existența rezumatului, concizia acestuia și includerea ideilor-cheie relevante.

## 6. Raportare bug și rezolvare prin Pull Request

Proiectul documentează un exemplu concret de bug raportat și rezolvat prin Pull Request:

- [Raportare bug și rezolvare prin Pull Request](./raportare_bug_si_rezolvare_pr.md)

Bug-ul a fost identificat în flow-ul de register din aplicația Flutter Web. La apăsarea butonului „Finalizează înregistrarea”, aplicația afișa o eroare de conectare la backend. Problema a fost investigată prin verificarea flow-ului de register, a comunicării dintre Flutter Web și backend-ul FastAPI și a configurării API/CORS.

Rezolvarea a fost făcută pe branch-ul dedicat `fix-register-flow-backend-connection`, iar modificările au fost propuse prin Pull Request-ul `Fix register flow backend connection #17`. După implementare, flow-ul a fost validat pentru a confirma conectarea corectă la backend, eliminarea erorii și păstrarea comportamentului vizual al paginii.

## 7. Pipeline CI/CD

PULSE are pipeline CI/CD configurat prin GitHub Actions. Documentul dedicat este:

- [Pipeline CI/CD](./pipeline_ci_cd.md)

Workflow-urile relevante sunt:

- [.github/workflows/security-ci.yml](../.github/workflows/security-ci.yml)
- [.github/workflows/firebase-hosting-pull-request.yml](../.github/workflows/firebase-hosting-pull-request.yml)
- [.github/workflows/firebase-hosting-merge.yml](../.github/workflows/firebase-hosting-merge.yml)

Pipeline-ul rulează automat la `pull_request` și la `push` pe `main`. Acesta acoperă testele backend, testele Flutter, auditul de securitate pentru dependențele Python, build-ul Flutter Web, preview deploy pentru Pull Request și deploy live în Firebase Hosting după integrarea în branch-ul principal.

Prin această configurație, verificările importante sunt integrate direct în fluxul de dezvoltare, iar rezultatele sunt vizibile în GitHub Actions.

## 8. Raport despre folosirea tool-urilor AI

Proiectul include un raport dedicat despre utilizarea tool-urilor AI în dezvoltarea software:

- [Raport utilizare tool-uri AI](./raport-utilizare-tooluri-ai.md)

Raportul menționează explicit instrumentele folosite:

- ChatGPT 5.5 prin Codex;
- aplicația ChatGPT;
- Gemini 3.1 Pro (High) prin Antigravity;
- platforma Gemini.

Aceste tool-uri au fost folosite pentru analiză, implementare, debugging, testare, documentație și generarea materialelor de prezentare. Ele au sprijinit echipa în clarificarea cerințelor, explorarea soluțiilor, verificarea structurii proiectului și redactarea documentației oficiale.

## 9. Utilizarea AI în toate aspectele procesului

Utilizarea AI în PULSE nu a fost limitată la o singură etapă a proiectului, ci a fost transversală pe întregul proces de dezvoltare software. AI-ul a sprijinit structurarea user stories și a backlog-ului în Jira, documentarea diagramelor și arhitecturii, lucrul cu Git, branch-uri și Pull Request-uri, testarea automată și evals-urile, debugging-ul, raportarea bug-urilor, verificarea pipeline-ului CI/CD și redactarea raportului privind tool-urile AI.

În toate aceste zone, output-ul generat sau sugerat de AI a fost verificat, adaptat și validat de echipă înainte de integrare. Astfel, AI-ul a funcționat ca instrument de asistență și accelerare, păstrând controlul tehnic și responsabilitatea finală la nivelul echipei de dezvoltare.

## 10. Concluzie

Proiectul PULSE respectă cerința B — Procesul de dezvoltare software cu AI.

Prin combinarea backlog-ului gestionat în Jira, a documentației UML și arhitecturale, a controlului versiunilor prin Git, a testelor automate și evals-urilor AI, a raportării bug-urilor prin Pull Request, a pipeline-ului CI/CD și a raportului dedicat utilizării tool-urilor AI, proiectul PULSE demonstrează un proces de dezvoltare software complet, coerent și asistat de inteligență artificială.
