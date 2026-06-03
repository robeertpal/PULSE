import 'package:flutter/material.dart';

import '../widgets/auth_shell.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  static const _termsText =
      'Ultima actualizare: 21 Mai 2026\n\n'
      'Prin accesarea, instalarea sau utilizarea aplicației PULSE, utilizatorul confirmă faptul că a citit, înțeles și acceptat integral prezentul document privind Termenii și Condițiile de Utilizare, precum și prevederile referitoare la prelucrarea datelor cu caracter personal.\n\n'
      'PULSE reprezintă o aplicație software cu caracter educațional și demonstrativ, dezvoltată în cadrul unui proiect academic universitar, având ca scop centralizarea, organizarea și personalizarea conținutului profesional medical, inclusiv articole, știri, publicații, cursuri și evenimente, prin utilizarea tehnologiilor moderne software și a funcționalităților bazate pe inteligență artificială.\n\n'
      'Întregul proiect PULSE, inclusiv conceptul aplicației, structura funcțională, arhitectura software, modelele de baze de date, documentația tehnică, interfața utilizator, identitatea vizuală, denumirea „PULSE”, elementele grafice originale și orice alte componente dezvoltate în cadrul proiectului reprezintă proprietatea intelectuală a autorilor Pal Robert-Attila, Păun Antonio-Ștefan și Vișan Miruna-Alexandra și beneficiază de protecția conferită de legislația aplicabilă în materia drepturilor de autor și a proprietății intelectuale.\n\n'
      'În procesul de analiză, proiectare, dezvoltare și documentare a aplicației au fost utilizate instrumente software bazate pe inteligență artificială și alte tehnologii asistive. Utilizarea acestor instrumente nu afectează drepturile autorilor asupra contribuțiilor originale realizate în cadrul proiectului. Autorii nu revendică drepturi exclusive asupra materialelor sau rezultatelor generate automat de sisteme terțe în măsura în care legislația aplicabilă nu permite acest lucru. Cu toate acestea, drepturile asupra versiunii finale a aplicației, asupra contribuțiilor originale realizate de autori și asupra modului de selecție, organizare, adaptare și integrare a tuturor componentelor proiectului aparțin autorilor, în limitele prevăzute de lege.\n\n'
      'Aplicația este destinată exclusiv utilizării educaționale, academice și demonstrative. PULSE nu reprezintă un dispozitiv medical, nu furnizează servicii medicale autorizate și nu poate fi considerată o sursă oficială de diagnostic, tratament sau recomandare medicală. Informațiile disponibile în cadrul aplicației au caracter exclusiv informativ și educațional și nu înlocuiesc consultul, opinia sau recomandările formulate de personal medical autorizat.\n\n'
      'În cadrul aplicației pot fi utilizate imagini, videoclipuri, articole, publicații, logo-uri, materiale grafice sau alte elemente multimedia provenite din surse externe disponibile public. Aceste materiale sunt utilizate exclusiv în scop educațional și demonstrativ, fără intenția obținerii unui beneficiu comercial și fără revendicarea drepturilor de proprietate intelectuală asupra acestora. Drepturile aferente acestor materiale aparțin titularilor lor de drept. La solicitarea legitimă a deținătorilor drepturilor de autor, respectivele materiale pot fi eliminate din cadrul aplicației.\n\n'
      'Pentru accesarea anumitor funcționalități ale aplicației, utilizatorul poate crea un cont prin furnizarea informațiilor solicitate. Utilizatorul este responsabil pentru exactitatea și actualizarea informațiilor furnizate, pentru păstrarea confidențialității datelor de autentificare și pentru toate activitățile desfășurate prin intermediul contului său. Autorii proiectului își rezervă dreptul de a suspenda, restricționa sau elimina accesul utilizatorilor care utilizează aplicația într-un mod contrar prezentelor condiții, dispozițiilor legale sau intereselor legitime ale proiectului.\n\n'
      'În vederea funcționării aplicației și furnizării funcționalităților sale, pot fi colectate și prelucrate date cu caracter personal, inclusiv adresa de e-mail, date de autentificare, informații profesionale introduse de utilizator, interese profesionale, activități desfășurate în aplicație, preferințe de conținut și alte informații necesare personalizării experienței utilizatorului. Pot fi prelucrate și informații privind activitatea utilizatorului în cadrul aplicației, inclusiv conținutul vizualizat, articolele salvate, recomandările generate, istoricul activităților și interacțiunile cu funcționalitățile bazate pe inteligență artificială.\n\n'
      'Prelucrarea datelor cu caracter personal se realizează în conformitate cu Regulamentul (UE) 2016/679 privind protecția persoanelor fizice în ceea ce privește prelucrarea datelor cu caracter personal și libera circulație a acestor date („GDPR”), precum și cu legislația națională aplicabilă. Datele colectate sunt utilizate exclusiv în scopul furnizării funcționalităților aplicației, personalizării experienței utilizatorului, asigurării securității platformei, îmbunătățirii serviciilor oferite și realizării obiectivelor educaționale și academice ale proiectului.\n\n'
      'Datele pot fi stocate pe infrastructuri cloud, servere de dezvoltare, servere de testare sau alte medii tehnice necesare funcționării și dezvoltării proiectului. Autorii proiectului depun toate eforturile rezonabile pentru implementarea măsurilor tehnice și organizatorice necesare protejării datelor și prevenirii accesului neautorizat, însă niciun sistem informatic nu poate garanta un nivel absolut de securitate.\n\n'
      'Utilizatorul beneficiază de toate drepturile prevăzute de legislația aplicabilă în materia protecției datelor cu caracter personal, inclusiv dreptul de acces la date, dreptul la rectificare, dreptul la ștergere, dreptul la restricționarea prelucrării, dreptul la opoziție, dreptul la portabilitatea datelor și dreptul de retragere a consimțământului, în condițiile și limitele prevăzute de lege.\n\n'
      'PULSE poate integra funcționalități bazate pe inteligență artificială, inclusiv sisteme de recomandare personalizată, generare de rezumate și furnizare de răspunsuri automate referitoare la conținutul disponibil în aplicație. Informațiile generate de aceste sisteme pot conține erori, omisiuni sau interpretări inexacte și nu trebuie considerate sfaturi medicale, recomandări clinice sau surse oficiale de diagnostic ori tratament. Utilizatorul este singurul responsabil pentru verificarea și validarea informațiilor obținute prin intermediul aplicației.\n\n'
      'Este interzisă copierea, reproducerea, distribuirea, publicarea, modificarea, comercializarea, decompilarea, extragerea, reutilizarea sau exploatarea neautorizată a aplicației, a codului sursă, a documentației, a elementelor grafice, a bazelor de date sau a oricăror alte componente aparținând proiectului PULSE. Orice utilizare neautorizată poate atrage răspunderea civilă, contravențională sau penală, după caz, conform legislației aplicabile.\n\n'
      'Autorii proiectului nu pot fi trași la răspundere pentru eventuale erori tehnice, întreruperi temporare sau permanente ale serviciului, indisponibilitatea aplicației, pierderea accidentală a datelor, funcționarea defectuoasă a serviciilor furnizate de terți, interpretarea informațiilor prezentate sau utilizarea necorespunzătoare a conținutului disponibil în aplicație. Utilizarea aplicației se realizează exclusiv pe propria răspundere a utilizatorului.\n\n'
      'Aplicația poate utiliza servicii externe, infrastructuri cloud, biblioteci software open-source, framework-uri software, API-uri și servicii bazate pe inteligență artificială furnizate de terți. Aceste servicii pot avea propriii termeni și propriile politici de confidențialitate, pentru care autorii proiectului nu își asumă responsabilitatea.\n\n'
      'Autorii proiectului își rezervă dreptul de a modifica, actualiza, suspenda, limita sau întrerupe funcționarea aplicației ori de a modifica prezentul document în orice moment, fără notificare prealabilă. Continuarea utilizării aplicației după publicarea modificărilor constituie acceptarea automată a noilor dispoziții.\n\n'
      'Prezentul document este guvernat și interpretat în conformitate cu legislația română și cu legislația Uniunii Europene aplicabilă în materia protecției datelor, drepturilor de autor și proprietății intelectuale. Eventualele litigii apărute în legătură cu utilizarea aplicației vor fi soluționate de instanțele competente din România, în condițiile prevăzute de lege.\n\n'
      'Prin utilizarea aplicației PULSE, utilizatorul declară că a citit, înțeles și acceptat integral prezentul document privind Termenii și Condițiile de Utilizare și Politica de Confidențialitate GDPR.';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthShell.background(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton.filledTonal(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.14),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Termeni și Condiții',
                          style: TextStyle(
                            foreground: Paint()
                              ..shader = AuthShell.pulseGradient.createShader(
                                const Rect.fromLTWH(0, 0, 520, 72),
                              ),
                            fontSize: 38,
                            height: 1.22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 22),
                        FrostedAuthCard(
                          padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
                          child: const Text(
                            _termsText,
                            style: TextStyle(
                              color: AuthShell.textPrimary,
                              fontSize: 15.5,
                              height: 1.58,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        AuthSecondaryButton(
                          label: 'Înapoi',
                          light: true,
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
