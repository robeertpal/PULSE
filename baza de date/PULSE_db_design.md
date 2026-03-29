# Arhitectura Bazei de Date - Platformă Medicală (V3 - Final Polish)

Acest document descrie baza de date la nivel conceptual și logic, conform principiilor de normalizare solicitate, integrând capabilitățile de „Recent Activity”, recomandări asistate, gestiune corectă a punctelor EMC și un ORM foarte robust implementat.

---

## A. Varianta conceptuală

### 1. Domeniul USER
* **`users`**: Entitatea unică pentru autentificare. Aici stă doar `email` și `password_hash`.
* **`user_profiles`**: Identitatea demografică și profesională (1:1 cu users). A fost extins cu `total_emc_points` (cache util pentru frontend).
* **Interese (`interests` & `user_profile_interests`)**: Din punct de vedere semantic, tabelul M:N este legat direct de `user_profiles` (prin `user_profile_id`), reprezentând preferințele utilizatorului în profilul său medical, nu preferințe de autentificare generice.
* **Nomenclatoare Geografice**: Pentru a proteja datele de accidente de tip "Delete Cascade", județele (`counties`) controlează orașele (`cities`) și interzic ștergerea lor accidentală folosind protecție strictă prin `ON DELETE RESTRICT`. La fel pentru celelalte nomenclatoare de sistem statice (`occupations`, `specializations`).

### 2. Domeniul CONTENT
* **`content_items`**: Master table polimorfic central (`article`, `news`, etc). Joacă și rolul de unificator SEO (Tabelul ține clauza de unicitate pentru `slug`).
* **Entitățile Satelit (`events`, `courses`, `publications`)**: Extensii verticale (1:1) pentru date specifice. Tabelul temporar de `publications` nu are un `slug` propriu redundant, ci folosește direct `slug`-ul primit prin relația sa 1:1 de unicitate cu `content_item`-ul părinte de tip 'publicație'.
* **`publication_issues`**: Edițiile concrete ale publicațiilor, asigurate împotriva erorilor de duplicare prim constrângere compusă.

### 3. Domeniul ACTIVITY, ENGAGEMENT & LOGGING
* **`user_activity_logs`**: Jurnalizează acțiunile (ex. `article_opened`, `summary_generated`). Numele coloanei logice JSON este "metadata", dar pentru interacțiunea sigură și neambiguă la nivel de cod Python SQLAlchemy a fost redenumită la nivel de alias sub umbrela `metadata_info`.
* **`recommendations`**: Recomandările de conținut.
* **`user_emc_point_logs`**: Tabelul de jurnalizare strictă a obținerii/primirii de puncte EMC de pe platformă, cu pointere și motive clare de tip audit.

---

## B. Varianta logică (Corecții de Constrângere și Triggere)

1. **Unicitate Multi-Coloană (Evitarea Duplicatelor)**
   * `publication_issues`: Constrângere logică [(publication_id, year, issue_number)](file:///C:/Users/Lenovo/.gemini/antigravity/brain/f26868af-7898-44cf-8c28-b2ac4e9afeda/medical_models.py#81-95).
   * `user_courses` & `user_event_registrations`: Constrângere ferma M:N per utilizator/item [(user_id, event_id)](file:///C:/Users/Lenovo/.gemini/antigravity/brain/f26868af-7898-44cf-8c28-b2ac4e9afeda/medical_models.py#81-95) evită re-înscrierea automată neplanificată.

2. **Trigger pentru `updated_at` (Postgres Native)**
   * Actualizările manuale în terminal pe baza de date vor schimba oricum absolut corect timestampul, mulțumită trigger-ului `update_updated_at_column()` declanșat automat prin clauza ENGINE-ului (BEFORE UPDATE).

3. **Livrabil SQLAlchemy Complet**
   * Scriptul ORM Python ([models.py](file:///C:/Users/Lenovo/.gemini/antigravity/brain/f26868af-7898-44cf-8c28-b2ac4e9afeda/medical_models.py)) include acum explicit relațiile inverse pe toate entitățile intermediare (ex. [UserEventRegistration](file:///C:/Users/Lenovo/.gemini/antigravity/brain/f26868af-7898-44cf-8c28-b2ac4e9afeda/medical_models.py#296-306) mapped -> [Event](file:///C:/Users/Lenovo/.gemini/antigravity/brain/f26868af-7898-44cf-8c28-b2ac4e9afeda/medical_models.py#163-182), [User](file:///C:/Users/Lenovo/.gemini/antigravity/brain/f26868af-7898-44cf-8c28-b2ac4e9afeda/medical_models.py#81-95)), pentru confort maxim în backend framework-u FastAPI prin rutine de "eager loading".
