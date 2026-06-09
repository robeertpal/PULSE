# Diagrame UML, arhitectură și workflow-uri

## 1. Context

Proiectul PULSE folosește diagrame pentru a documenta atât structura sistemului, cât și comportamentul aplicației în scenarii reale de utilizare. Fiind o platformă medicală care include aplicație Flutter, backend FastAPI, Management System, bază de date, servicii externe și funcționalități asistate de inteligență artificială, reprezentarea vizuală a arhitecturii este esențială pentru înțelegerea completă a proiectului.

Documentația vizuală a proiectului include:

- diagrame UML;
- arhitectura componentelor;
- workflow-uri funcționale;
- diagrame de stări;
- diagrame de secvență;
- organizarea domeniilor principale ale aplicației.

Documentul de bază pentru aceste diagrame este:

```text
docs/diagrame_uml_pulse.md
```

Acesta este completat de artefactele vizuale din:

```text
docs/Diagrame/
```

Prin aceste materiale, PULSE oferă o imagine coerentă asupra modului în care aplicația este structurată, cum comunică subsistemele și cum evoluează entitățile importante în cadrul fluxurilor funcționale.

## 2. Scopul diagramelor

Diagramele au rolul de a transforma un sistem software complex într-o reprezentare clară, ușor de analizat și ușor de comunicat. În cadrul PULSE, ele susțin atât procesul de dezvoltare, cât și procesul de evaluare tehnică a proiectului.

Diagramele ajută la:

- înțelegerea arhitecturii aplicației;
- documentarea relațiilor dintre componente;
- explicarea fluxurilor utilizatorului;
- validarea structurii backend/frontend;
- comunicarea mai clară în echipă;
- susținerea procesului de dezvoltare software.

Prin utilizarea diagramelor, proiectul demonstrează că funcționalitățile nu au fost tratate izolat, ci au fost integrate într-o arhitectură documentată și inteligibilă.

## 3. Diagrame de cazuri de utilizare

Documentația PULSE include diagrame de tip Use Case pentru actorii principali ai sistemului. Acestea descriu funcționalitățile disponibile fiecărui actor și delimitează clar zona aplicației dedicate utilizatorului final de zona de administrare.

### Utilizator / Medic

Diagrama pentru Utilizator / Medic prezintă funcționalitățile principale disponibile în aplicația mobilă. Aceasta include acțiuni precum:

- autentificare;
- înregistrare cont;
- verificare email;
- vizualizare feed principal;
- citire articole și știri;
- acces la cursuri și evenimente;
- salvare conținut;
- urmărire autori sau publicații;
- gestionare profil;
- selectare interese;
- vizualizare puncte EMC;
- gestionare abonamente.

Această diagramă arată experiența utilizatorului final și modul în care acesta interacționează cu principalele funcționalități medicale și editoriale ale platformei.

### Administrator

Diagrama pentru Administrator descrie funcționalitățile disponibile în Management System. Ea acoperă zona operațională a proiectului, în care conținutul, utilizatorii, publicațiile și procesele administrative sunt gestionate centralizat.

Funcționalitățile reprezentate includ:

- administrare conținut;
- creare și editare articole;
- administrare cursuri;
- administrare evenimente;
- administrare publicații;
- administrare utilizatori;
- administrare reclame;
- notificări;
- review pentru submisii de conținut;
- audit log;
- aprobare credite EMC.

Prin aceste diagrame, PULSE demonstrează separarea clară dintre experiența publică a aplicației și interfața de administrare.

## 4. Diagrame de clase

Diagramele de clase descriu structura statică a sistemului. Ele evidențiază entitățile principale, atributele relevante, relațiile dintre clase, multiplicitățile și dependențele dintre domenii.

În documentația PULSE sunt acoperite mai multe domenii importante:

- Content Domain;
- Events;
- Courses;
- Users;
- Ads;
- Subscriptions & Payments.

### Content Domain

Diagrama pentru domeniul de conținut descrie entități precum `ContentItem`, `ContentCategory`, `Specialization`, `Event`, `Course` și `Publication`. Aceasta arată că un element de conținut poate reprezenta un articol, o știre, un curs, un eveniment sau o publicație, iar tipul de conținut determină relațiile specifice activate în sistem.

### Events

Diagrama pentru evenimente documentează relațiile dintre `Event`, sesiunile evenimentului, parteneri și înregistrările utilizatorilor. Ea clarifică modul în care un eveniment este compus din informații editoriale, locație, program, parteneri și participanți.

### Courses

Diagrama pentru cursuri prezintă structura conținutului educațional, incluzând modulele de curs, statusul cursului, perioada de validitate și creditele EMC asociate.

### Users

Diagrama pentru utilizatori descrie relațiile dintre contul de utilizator, profil, interese, specializare, autentificare, activitate și entitățile asociate experienței personalizate.

### Ads

Diagrama pentru reclame descrie structura campaniilor publicitare și modul în care acestea pot fi legate de conținut, parteneri sau zone de afișare din aplicație.

### Subscriptions & Payments

Diagrama pentru abonamente și plăți explică relațiile dintre `SubscriptionPlan`, `UserSubscription`, `Payment` și utilizator. Aceasta este importantă pentru înțelegerea accesului la conținut premium și a fluxurilor comerciale ale aplicației.

Împreună, aceste diagrame oferă o vedere solidă asupra modelului de domeniu al aplicației PULSE.

## 5. Diagrama de pachete

Diagrama de pachete organizează sistemul pe domenii logice. Această organizare ajută la înțelegerea separării responsabilităților și a modului în care entitățile proiectului sunt grupate conceptual.

Pachetele principale documentate sunt:

- `auth`;
- `profile`;
- `nomenclature`;
- `content`;
- `events`;
- `courses`;
- `publications`;
- `ads`;
- `subscriptions`;
- `emc`;
- `audit`.

Această diagramă arată că sistemul nu este o colecție informală de clase, ci un model organizat pe domenii funcționale clare.

## 6. Diagrame de secvență / workflow-uri

Diagramele de secvență descriu workflow-uri concrete și ordinea interacțiunilor dintre componente. În PULSE, ele sunt importante deoarece arată cum colaborează utilizatorul, aplicația Flutter, backend-ul FastAPI, baza de date și serviciile externe.

Documentația include workflow-uri pentru:

- înregistrare utilizator;
- autentificare și sesiune;
- publicare conținut de către administrator;
- înregistrare la eveniment;
- submisie conținut de contributor.

### Înregistrare utilizator

Acest workflow descrie pașii prin care un utilizator își creează contul, completează datele necesare, transmite informațiile către backend, primește verificarea prin email și devine eligibil pentru utilizarea aplicației.

### Autentificare și sesiune

Acest workflow arată cum datele de autentificare sunt transmise din Flutter către backend, cum sunt validate în baza de date și cum este creată sesiunea sau autentificarea necesară pentru accesarea funcționalităților personale.

### Publicare conținut de către administrator

Acest workflow descrie procesul prin care administratorul creează sau editează conținut în Management System, trimite datele către backend, atașează imagini sau documente și publică materialul în aplicație.

### Înregistrare la eveniment

Acest workflow arată interacțiunea dintre utilizator, aplicația Flutter, backend și baza de date în momentul înscrierii la un eveniment. Pentru evenimentele plătite, fluxul poate include și interacțiunea cu sistemul de plată.

### Submisie conținut de contributor

Acest workflow descrie traseul unui material trimis de un contributor: completarea formularului, transmiterea către backend, salvarea în baza de date, review-ul administrativ și eventuala publicare.

Prin aceste diagrame, proiectul documentează comportamentul dinamic al aplicației, nu doar structura sa statică.

## 7. Diagrame de stări

Diagramele de stări arată ciclul de viață al entităților importante și tranzițiile posibile între stări. Ele sunt utile mai ales pentru entitățile care trec prin procese de aprobare, activare, expirare sau publicare.

Documentația PULSE include diagrame de stări pentru:

- `ContentItem`;
- `Ad`;
- `UserSubscription`;
- `UserEventRegistration`;
- `ContentSubmission`.

### ContentItem

Diagrama de stări pentru `ContentItem` descrie evoluția unui material editorial de la draft la publicare, arhivare sau ștergere logică.

### Ad

Diagrama pentru `Ad` descrie ciclul de viață al unei reclame, inclusiv pregătirea, activarea, dezactivarea sau expirarea campaniei.

### UserSubscription

Diagrama pentru `UserSubscription` arată stările posibile ale unui abonament: inițiere, activare, anulare, expirare sau suspendare.

### UserEventRegistration

Diagrama pentru `UserEventRegistration` descrie procesul de înscriere la eveniment, confirmare, anulare sau finalizare.

### ContentSubmission

Diagrama pentru `ContentSubmission` arată workflow-ul editorial al materialelor trimise de contribuitori, de la trimitere la review, aprobare, respingere sau publicare.

Aceste diagrame clarifică regulile de business și limitele tranzițiilor valide pentru entitățile centrale ale sistemului.

## 8. Arhitectura componentelor

Documentația include o diagramă de arhitectură a componentelor și de deployment, disponibilă și ca artefact vizual:

```text
docs/Diagrame/Diagrama de arhitectura.svg
```

Această diagramă prezintă componentele principale ale sistemului PULSE:

- Flutter App;
- ManagementSystem;
- Firebase Hosting;
- Render;
- FastAPI Backend;
- PostgreSQL;
- Azure Blob Storage;
- Brevo Email API;
- GitHub Actions.

Comunicarea dintre componente este structurată astfel:

- Flutter App comunică cu API-ul public și cu endpoint-urile de autentificare;
- ManagementSystem comunică cu API-ul de admin;
- FastAPI Backend comunică cu baza de date PostgreSQL;
- FastAPI Backend folosește servicii externe pentru email și stocare de fișiere;
- Azure Blob Storage susține stocarea de imagini, documente și alte resurse media;
- Brevo Email API susține trimiterea emailurilor tranzacționale;
- Firebase Hosting găzduiește aplicația Flutter Web și resursele frontend;
- Render găzduiește backend-ul FastAPI;
- GitHub Actions susține procesele de build, testare și deploy.

Prin această diagramă, proiectul demonstrează separarea clară între client, administrare, API, date, stocare externă și automatizare.

## 9. CI/CD și infrastructură

GitHub Actions apare în arhitectura proiectului deoarece susține pipeline-ul CI/CD. Acesta automatizează testarea, auditul de securitate, build-ul aplicației Flutter Web și deploy-ul prin Firebase Hosting.

Pentru detalierea completă a pipeline-ului CI/CD, proiectul include document separat:

```text
docs/pipeline_ci_cd.md
```

Această separare menține documentația clară: arhitectura componentelor explică rolul infrastructural al GitHub Actions, iar documentul dedicat CI/CD descrie workflow-urile, comenzile și evenimentele de declanșare.

## 10. ERD și modelul bazei de date

Modelarea bazei de date completează documentația de arhitectură. Pe lângă diagramele UML și de componente, PULSE documentează structura datelor prin ERD-uri și artefacte de schemă/design.

Artefactele relevante pentru această zonă includ:

- ERD USER;
- ERD CONTENT;
- `PULSE_schema.sql`;
- `PULSE_models.py`;
- `PULSE_db_design.md`.

Aceste materiale descriu structura persistentă a aplicației: utilizatori, profiluri, conținut, evenimente, cursuri, publicații, abonamente, plăți, activitate și relațiile dintre ele.

ERD-urile nu sunt refăcute în acest document, deoarece rolul prezentei secțiuni este de a arăta cum modelarea bazei de date completează documentația UML și arhitecturală.

## 11. Concluzie

Proiectul PULSE respectă cerința:

```text
diagrame — diagrame UML, arhitectura componentelor, workflow-uri
```

Prin includerea diagramelor UML, a arhitecturii componentelor, a workflow-urilor funcționale, a diagramelor de stări și a modelării bazei de date, proiectul PULSE demonstrează o documentare vizuală completă și coerentă a sistemului software.

Aceste diagrame susțin înțelegerea tehnică a proiectului, facilitează comunicarea în echipă și oferă o bază clară pentru evaluarea arhitecturii, a fluxurilor și a structurii aplicației.
