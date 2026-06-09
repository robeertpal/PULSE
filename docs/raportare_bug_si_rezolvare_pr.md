# Raportare bug și rezolvare prin Pull Request

## 1. Context

În dezvoltarea proiectului PULSE a fost utilizat un flux de lucru colaborativ bazat pe GitHub. Problemele identificate în timpul implementării și testării au fost raportate ca issue-uri, analizate în mod structurat, rezolvate pe branch-uri dedicate și integrate ulterior în proiect prin Pull Request.

Acest mod de lucru oferă trasabilitate, claritate și control asupra modificărilor. Fiecare bug poate fi urmărit de la momentul raportării până la rezolvare, iar fiecare intervenție tehnică rămâne documentată în istoricul proiectului.

## 2. Raportarea bug-ului

Un bug relevant a fost identificat în pagina de înregistrare din aplicația Flutter Web. Problema apărea în momentul în care utilizatorul încerca să finalizeze procesul de creare a contului.

La apăsarea butonului „Finalizează înregistrarea”, aplicația afișa următorul mesaj de eroare:

```text
Nu mă pot conecta la backend pentru înregistrarea contului. Verifică dacă serverul API rulează pe https://pulse-backend-5f9b.onrender.com și dacă pagina Flutter este deschisă cu un URL permis de CORS.
```

Bug-ul a fost raportat ca issue pe GitHub, pentru ca problema să poată fi urmărită clar în cadrul procesului de dezvoltare. Raportarea într-un issue a permis delimitarea problemei, documentarea contextului și asocierea ulterioară cu soluția implementată.

## 3. Investigarea problemei

Problema a fost analizată prin verificarea flow-ului de register, a conexiunii dintre frontend-ul Flutter Web și backend-ul FastAPI, precum și a configurării URL-ului API și a politicilor CORS.

Investigația a urmărit identificarea cauzei care bloca înregistrarea utilizatorului. În mod special, analiza s-a concentrat pe punctul de comunicare dintre aplicația web și serverul backend, deoarece mesajul de eroare indica o problemă de conectivitate sau de configurare între cele două componente.

Acest proces a permis separarea cauzei reale de simptomele vizibile în interfață și a oferit baza necesară pentru o rezolvare punctuală.

## 4. Rezolvarea bug-ului

Rezolvarea bug-ului a fost realizată pe un branch dedicat, separat de `main`, pentru a păstra un flux de lucru curat și ușor de verificat.

Branch-ul utilizat a fost:

```text
fix-register-flow-backend-connection
```

Pe acest branch au fost ajustate componentele necesare pentru ca flow-ul de register să comunice corect cu backend-ul. Intervenția a fost concentrată asupra funcționării conexiunii și a procesului de înregistrare, fără modificarea inutilă a designului paginii.

Această abordare a păstrat separarea dintre corecția funcțională și aspectul vizual al aplicației, reducând riscul introducerii unor schimbări neintenționate.

## 5. Pull Request

Modificările au fost propuse prin Pull Request-ul:

```text
Fix register flow backend connection #17
```

Pull Request-ul a fost legat de issue-ul raportat, astfel încât rezolvarea bug-ului să fie documentată și verificabilă în istoricul GitHub. Prin această asociere, traseul complet al problemei rămâne vizibil: raportare, investigare, implementare, verificare și integrare.

Utilizarea Pull Request-ului a permis revizuirea modificărilor înainte de integrarea lor în ramura principală a proiectului și a oferit un punct clar de control asupra calității soluției.

## 6. Validare și testare

După implementarea fix-ului, au fost rulate verificări pentru a confirma că flow-ul de register funcționează corect. Validarea a urmărit atât comportamentul funcțional al aplicației, cât și menținerea experienței vizuale existente.

Testarea a urmărit:

- conectarea corectă a frontend-ului la backend;
- eliminarea erorii de register;
- păstrarea comportamentului vizual al paginii;
- stabilitatea aplicației după modificare.

Prin aceste verificări, s-a confirmat că utilizatorul poate continua procesul de înregistrare fără eroarea de conectivitate raportată inițial.

## 7. Concluzie

Proiectul PULSE respectă cerința:

```text
raportare bug și rezolvare cu pull request
```

Există un exemplu concret de bug raportat, investigat, rezolvat pe un branch dedicat și integrat prin Pull Request.

Prin raportarea bug-ului în GitHub Issues, rezolvarea acestuia pe un branch dedicat și integrarea modificărilor prin Pull Request, proiectul PULSE demonstrează utilizarea unui flux profesionist de lucru pentru managementul problemelor și al modificărilor software.
