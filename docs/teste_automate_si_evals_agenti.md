# Teste automate și evaluări pentru agenții AI

## 1. Context

PULSE este o aplicație medicală construită în jurul unui backend FastAPI, al unei aplicații mobile dezvoltate în Flutter și al unor funcționalități asistate de inteligență artificială. Într-un astfel de ecosistem, testarea automată nu este doar o etapă tehnică, ci o garanție de stabilitate, calitate software și încredere în comportamentul funcționalităților critice.

Prin testele automate, proiectul verifică în mod repetabil că fluxurile principale ale aplicației continuă să funcționeze corect după modificări. Prin evaluările dedicate agenților AI, proiectul validează nu doar existența funcționalităților inteligente, ci și faptul că acestea produc rezultate relevante, coerente și utile pentru utilizatorii aplicației.

## 2. Teste automate pentru backend

Backend-ul PULSE include 31 de teste automate scrise cu `unittest`, organizate în directorul:

```text
backend/tests/
```

Aceste teste acoperă zone importante ale aplicației, inclusiv:

- flow-uri funcționale;
- securitate;
- endpoint-uri AI;
- comportamentul principal al aplicației.

Comanda de rulare pentru demonstrarea suitei backend este:

```bash
cd backend
source venv/bin/activate
python -m unittest discover -s tests
```

Rezultatul verificării a fost:

```text
Ran 31 tests ... OK
```

Acest rezultat confirmă că suita backend este descoperită automat, rulează complet și validează comportamentele esențiale ale API-ului.

## 3. Teste automate pentru aplicația mobile Flutter

Aplicația Flutter include 25 de teste automate, integrate în directorul standard de testare al proiectului mobile.

Aceste teste acoperă:

- validatori;
- modele;
- widget tests;
- elemente de interfață;
- verificări pentru UI premium blur.

Comanda de rulare pentru demonstrarea suitei mobile este:

```bash
cd mobile
flutter test
```

Rezultatul verificării a fost:

```text
All tests passed!
```

Prin această suită, aplicația mobile demonstrează că logica de prezentare, validările și componentele importante de interfață sunt verificate automat.

## 4. Evaluări automate pentru agenții AI

Proiectul include evaluări automate dedicate agenților AI în fișierul:

```text
backend/tests/ai_evals/test_ai_agents.py
```

Directorul:

```text
backend/tests/ai_evals/
```

conține fișierul:

```text
__init__.py
```

Prin urmare, acest director este recunoscut ca pachet Python valid și este inclus automat în mecanismul de discovery al suitei `unittest`. Astfel, evaluările pentru agenții AI sunt rulate împreună cu testele backend obișnuite prin aceeași comandă:

```bash
python -m unittest discover -s tests
```

Această integrare este importantă deoarece transformă evaluarea agenților AI într-o parte naturală a procesului de verificare software, nu într-un pas manual sau separat.

## 5. Agentul AI 1 — Recomandări personalizate

Primul agent AI este responsabil pentru generarea de recomandări personalizate. Rolul său este de a identifica articole, cursuri sau evenimente relevante pentru utilizator, folosind contextul disponibil în aplicație: profilul, specializarea, interesele declarate și activitatea anterioară.

Evaluările automate verifică faptul că agentul produce recomandări justificate și conectate la profilul utilizatorului. În mod concret, evals-urile urmăresc:

- relevanța recomandării;
- existența unei explicații;
- legătura dintre recomandare și contextul utilizatorului.

Această abordare demonstrează că sistemul nu oferă doar conținut generic, ci încearcă să explice de ce o recomandare este potrivită pentru un anumit utilizator.

## 6. Agentul AI 2 — Rezumare și răspuns rapid despre articol

Al doilea agent AI sprijină utilizatorul în înțelegerea rapidă a conținutului medical. Acesta poate genera un rezumat sau un răspuns scurt legat de articol, pentru a evidenția ideile importante și pentru a reduce timpul necesar parcurgerii conținutului.

Evaluările automate verifică dacă rezultatul generat este util, concis și orientat către informația relevantă. În mod concret, evals-urile urmăresc:

- existența unui rezumat generat;
- faptul că rezumatul este mai scurt decât articolul original;
- includerea unor idei-cheie relevante.

Prin aceste verificări, proiectul validează comportamentul de bază al agentului de rezumare și confirmă că acesta produce un output adecvat scopului său.

## 7. Concluzie

Proiectul PULSE respectă cerința:

```text
teste automate, inclusiv evals pentru agenți
```

Prin existența testelor automate pentru backend, a testelor automate pentru aplicația Flutter și a evaluărilor dedicate pentru agenții AI, proiectul PULSE demonstrează că respectă cerința privind testarea automată și validarea comportamentului agenților inteligenți.

Această acoperire oferă o bază solidă pentru menținerea calității proiectului, pentru prevenirea regresiilor și pentru prezentarea riguroasă a modului în care funcționalitățile clasice și cele asistate de AI sunt verificate automat.
