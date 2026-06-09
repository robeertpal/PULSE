# Pipeline CI/CD

## 1. Context

În cadrul proiectului PULSE, pipeline-ul CI/CD reprezintă mecanismul prin care verificările tehnice importante sunt automatizate și integrate în fluxul normal de dezvoltare. Acesta susține rularea automată a testelor, verificarea securității dependențelor, construirea aplicației Flutter Web și publicarea aplicației prin Firebase Hosting.

Proiectul folosește GitHub Actions pentru automatizarea acestor pași. Astfel, fiecare modificare importantă poate fi verificată într-un mod repetabil, transparent și ușor de urmărit, atât înainte de integrarea în branch-ul principal, cât și după publicarea modificărilor.

## 2. Workflow-uri GitHub Actions

În repository există următoarele workflow-uri GitHub Actions:

```text
.github/workflows/security-ci.yml
.github/workflows/firebase-hosting-pull-request.yml
.github/workflows/firebase-hosting-merge.yml
```

Rolul fiecărui workflow este bine delimitat:

- `security-ci.yml` — rulează testele backend, testele Flutter și auditul de securitate al dependențelor Python.
- `firebase-hosting-pull-request.yml` — construiește aplicația Flutter Web și creează un preview deploy pentru Pull Request în Firebase Hosting.
- `firebase-hosting-merge.yml` — construiește aplicația Flutter Web și face deploy live în Firebase Hosting după merge sau push pe `main`.

Prin această structură, proiectul separă clar validarea tehnică de publicarea aplicației, păstrând un flux de lucru coerent și verificabil.

## 3. Integrare continuă — CI

Partea de integrare continuă validează automat calitatea proiectului înainte ca modificările să fie integrate. În acest fel, erorile pot fi identificate devreme, iar stabilitatea aplicației este protejată prin verificări executate în mod constant.

Comenzile principale rulate în pipeline sunt:

```bash
cd backend
python -m unittest discover -s tests
```

```bash
cd mobile
flutter test
```

```bash
cd backend
pip-audit --disable-pip --no-deps -r requirements.txt
```

Aceste comenzi verifică:

- testele automate backend;
- testele automate Flutter;
- dependențele Python din perspectiva securității.

Astfel, partea de CI acoperă atât comportamentul funcțional al aplicației, cât și o verificare importantă a riscurilor din lanțul de dependențe.

## 4. Livrare/Deploy continuu — CD

Partea de livrare și deploy continuu este acoperită prin workflow-urile Firebase Hosting. Acestea automatizează construirea aplicației Flutter Web și publicarea ei în medii potrivite etapei de dezvoltare.

La `pull_request`, proiectul generează un preview deploy în Firebase Hosting. Acest preview permite verificarea modificărilor înainte de integrarea în branch-ul principal.

La `push` sau merge pe `main`, proiectul construiește aplicația Flutter Web și face deploy live în Firebase Hosting.

Comanda principală de build este:

```bash
cd mobile
flutter build web
```

Prin acest mecanism, PULSE poate livra modificări într-un mod controlat, cu verificări înainte de publicare și cu deploy automat după integrarea în ramura principală.

## 5. Evenimente de declanșare

Workflow-urile rulează automat la evenimentele relevante din GitHub:

```yaml
pull_request
push:
  branches:
    - main
```

Acest lucru permite verificarea automată a modificărilor atât înainte de merge, cât și după integrarea în branch-ul principal. Pull Request-urile sunt validate înainte de acceptare, iar branch-ul `main` declanșează procesul de build și deploy pentru versiunea publicată.

## 6. Rezultate vizibile în GitHub Actions

Rezultatele pipeline-ului sunt vizibile în tab-ul Actions din GitHub. Acolo pot fi urmărite statusurile pentru testare, audit, build și deploy.

Această vizibilitate este importantă pentru colaborare, deoarece oferă o evidență clară a fiecărei rulări automate. Echipa poate vedea rapid dacă o modificare a trecut testele, dacă auditul de securitate a fost executat cu succes și dacă build-ul sau deploy-ul au fost finalizate corect.

## 7. Observație opțională

Proiectul respectă cerința privind existența unui pipeline CI/CD. Pentru o variantă și mai completă, se poate adăuga opțional un pas de analiză statică Flutter:

```bash
cd mobile
flutter analyze
```

Lipsa acestui pas nu blochează respectarea cerinței, deoarece proiectul are deja testare automată, audit de securitate, build Flutter Web și deploy Firebase Hosting configurate prin GitHub Actions.

## 8. Concluzie

Proiectul PULSE respectă cerința privind existența unui pipeline CI/CD.

Prin utilizarea workflow-urilor GitHub Actions pentru testare automată, audit de securitate, build Flutter Web și deploy Firebase Hosting, proiectul PULSE demonstrează existența unui pipeline CI/CD funcțional și integrat în procesul de dezvoltare.
