# Etapele rămase pentru lansarea AutoDealer Pro SaaS

Stare: surse iOS 0.1, fără compilare/semnare Apple. Nu există o înregistrare App Store Connect creată și nu s-a făcut nicio trimitere către Apple.

## 1. Contul și identitatea editorului

- Înscriere în Apple Developer Program cu Apple ID-ul utilizatorului.
- Alegerea tipului de înscriere potrivit situației juridice. Einzelunternehmen se înscrie, de regulă, ca persoană fizică și apare cu numele legal al titularului. Pentru o organizație eligibilă este necesară verificarea entității, de regulă cu D-U-N-S.
- Identificator unic al aplicației și Team ID în proiect.
- Crearea fișei App Store Connect de către titular sau o persoană invitată cu drepturi potrivite.

## 2. Conectarea SaaS — trebuie implementată înaintea distribuției ca SaaS

Site-ul existent este privat și folosește autentificarea platformei ChatGPT. Nu există încă o autentificare mobilă publică validată. Un simplu WebView sau un token de serviciu inclus în aplicație nu rezolvă această problemă.

Decizie necesară: un serviciu public de autentificare potrivit aplicației mobile și serverului, cu conturi individuale, membership verificat pe server, tenant_id derivat din sesiune, sesiuni revocabile și tokenuri stocate în Keychain. Nu activați accesul public al site-ului fără verificarea rutelor și a politicii de acces.

Contractul API trebuie definit și testat pentru vehicule, clienți, costuri, fotografii, firmă și membri. Adăugați versionare/revizii, rezolvarea conflictelor, reîncercări sigure și izolarea între firme. Datele locale nu trebuie urcate sau înlocuite automat fără ca utilizatorul să aleagă firma destinație și migrarea.

Trebuie implementate înregistrarea, autentificarea, deconectarea, recuperarea accesului și ștergerea contului conform serviciului ales. Ștergerea datelor locale deja implementată NU echivalează cu ștergerea unui cont SaaS.

## 3. Abonamente

Basic/Pro/Premium sunt încă neimplementate. Prețurile nu au fost stabilite. Modelul de vânzare (contracte cu organizații, vânzări individuale, cumpărare în aplicație) determină regulile Apple aplicabile. Nu presupuneți că orice SaaS B2B este automat exceptat de la plățile în aplicație. Verificați regula 3.1 și implementați fluxul potrivit înainte de trimitere.

## 4. Documentele editorului

- Denumire juridică, adresă și date de contact reale.
- Pagină publică de suport și politică de confidențialitate care descrie serviciul final.
- Declarațiile App Privacy corelate cu toate SDK-urile și datele efectiv prelucrate.
- Condiții de utilizare, retenție și ștergere, inclusiv tratamentul documentelor care trebuie păstrate legal.
- Clasificare de vârstă și răspunsuri corecte despre criptare și distribuție.

Acestea nu pot fi finalizate prin inventarea datelor firmei sau a unui serviciu de plată.

## 5. TestFlight și App Review

- Compilare și teste pe macOS, apoi verificare pe iPhone fizic: cameră, permisiune refuzată, fotografii, PDF multipagină, partajare, backup/restaurare, date invalide, Dynamic Type, VoiceOver și modul întunecat.
- Pentru SaaS: izolare între două firme, membri revocați, conexiune absentă și expirarea autentificării.
- TestFlight intern, apoi testare cu utilizatori reali.
- Capturi REALE din versiunea finală pe dimensiunile cerute de App Store Connect, descriere germană și contacte de suport.
- Cont demonstrativ funcțional pentru review dacă aplicația necesită autentificare.
- Archive în Xcode, Validate App, Upload și trimitere la verificarea Apple. Aprobarea nu este garantată.

Referințe:
https://developer.apple.com/programs/enroll/
https://developer.apple.com/app-store/review/guidelines/
https://developer.apple.com/news/upcoming-requirements/
