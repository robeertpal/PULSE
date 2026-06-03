# Caiet de practică — Activități (proiect PULSE)

Notă: intrările sunt bazate pe lucrările de dezvoltare pentru funcționalitățile de înregistrare, autentificare, editare profil și gestionare interese; activitățile pot fi identice pe mai multe zile, după cum s-a cerut.

- **17.02.2026**: Implementare formular înregistrare (frontend) cu validări client.
- **18.02.2026**: Implementare endpoint `/register` (backend) și stocare utilizator cu hashing parolă.
- **19.02.2026**: Integrare frontend↔backend pentru flux înregistrare; testare manuală.
- **25.02.2026**: Implementare formular login (frontend) și mecanism "remember me".
- **26.02.2026**: Endpoint `/login` (backend): autentificare, generare token JWT și management sesiune.
- **02.03.2026**: Politică parole: verificări minimum lungime și complexitate; adăugare rate-limit login.
- **03.03.2026**: Flux resetare parolă: generare token expirabil și endpoint pentru resetare (email mock).
- **16.03.2026**: Proiectare pagina profil (frontend): afișare date utilizator, avatar, bio.
- **17.03.2026**: Implementare editare profil (frontend) — formulare pentru nume, email, bio, avatar.
- **18.03.2026**: Endpoint update profil (backend) + validări server-side și upload avatar (temporar).
- **19.03.2026**: Modelare `interests` în baza de date; seed inițial de taguri/interese.
- **30.03.2026**: UI pentru selectare interese (tags/checkboxes) și asociere la contul utilizator.
- **31.03.2026**: Endpoint CRUD pentru interese (adăugare/ștergere/listare); testare cu Postman.
- **03.04.2026**: Asigurare persistare interese în profil; sincronizare vizuală pe pagină profil.
- **06.04.2026**: Middleware autorizare pentru rute private (verificare JWT/session).
- **15.04.2026**: Refactorizare cod autentificare: separare servicii, logging și erori standard.
- **16.04.2026**: Scriere teste unitare pentru înregistrare și autentificare (ex. validări, hashing).
- **17.04.2026**: Scriere teste pentru endpoint update profil și gestionare interese.
- **20.04.2026**: Fixare erori găsite în testare și retestare manuală a fluxurilor.
- **21.04.2026**: Documentare minimală a endpoint-urilor și a pașilor de testare în README.
- **23.04.2026**: Audit inputuri: sanitizare, prevenire XSS și verificări pentru injection.
- **24.04.2026**: Adăugare mecanism anti-bot la înregistrare (rate-limit/CAPTCHA sau flag mock).
- **27.04.2026**: Implementare funcționalitate logout și curățare sesiune/localStorage.
- **29.04.2026**: Pregătire demo final: scenarii de test, capturi de ecran și concluzii pentru caiet.

---

## Activități Mai 2026

- **04.05.2026**: Ajustări UI pentru pagina profil (layout responsive, spațiere).
- **05.05.2026**: Remediere bug upload avatar și limitare dimensiune fișier.
- **06.05.2026**: Îmbunătățiri validări client (email, parolă) și mesaje utile.
- **07.05.2026**: Optimizare accesibilitate: label-uri, aria-* și focus management.
- **08.05.2026**: Configurare bazică CI (workflow test automat pe push).
- **11.05.2026**: Gestionare variabile de mediu (`.env`) și documentare pentru dezvoltatori.
- **12.05.2026**: Scriere `Dockerfile` inițial pentru backend (build minimal).
- **13.05.2026**: Integrare minimală cu aplicația mobilă: endpoint auth compatibil.
- **14.05.2026**: Test CORS și corectare configurare pentru API pentru front și mobile.
- **15.05.2026**: Adăugare logging server-side pentru evenimente autentificare și erori.
- **18.05.2026**: Extindere suite teste: adăugare teste funcționale pentru login/update profil.
- **19.05.2026**: Rulat teste, investigat și corectat eșecuri (fixuri mici de logică).
- **20.05.2026**: Generare documentație API (endpoints autentificare, profil, interese).
- **21.05.2026**: Actualizare `README.md` cu pași de instalare și rulare locală.
- **22.05.2026**: Repetiție demo: scenarii comune (înregistrare, login, edit profil).
- **25.05.2026**: Seed de utilizatori de test și date demo pentru prezentare.
- **26.05.2026**: Profilare performanță endpoint-uri critice și optimizări simple.
- **27.05.2026**: Audit securitate dependențe și actualizare pachete vulnerabile.
- **28.05.2026**: Finalizare intrări pentru caiet, commit și pregătire materialelor.

---

Dacă vrei, pot adăuga detalii pentru fiecare zi (ore lucrate, rezultate, probleme întâmpinate) sau să export fișierul sub alt format.