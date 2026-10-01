# AutoDealer Pro pentru iPhone — proiect de dezvoltare 0.1

Acesta este codul sursă al unei aplicații native SwiftUI, nu o aplicație .ipa gata de instalat. Proiectul nu a fost compilat sau rulat în Xcode: mediul în care a fost pregătit nu are macOS, Xcode sau simulator iOS.

## Ce este implementat în cod

- Ecrane native în germană, pentru iPhone și iPad, cu adaptare la dimensiunea textului și culorile sistemului.
- Mașini: adăugare, editare, căutare, filtrare și ștergere cu confirmare.
- Etape: Angekauft, Aufbereitung, Inseriert, Reserviert, Verkauft.
- Clienți și asocierea cumpărătorului cu mașina; vânzarea necesită cumpărător și dată.
- Calcul în cenți întregi pentru prețuri, costuri și marjă înainte de taxe.
- Galerie prin selectorul iOS și fotografiere cu camera. Fotografiile sunt redimensionate și salvate local.
- Texte de anunțuri editabile, copiere și partajare prin iOS.
- Generare nativă de PDF-uri cu mai multe pagini: factură/contract marcate ENTWURF; previzualizare PDFKit și partajare.
- Datele firmei, salvare locală atomică, export și restaurare a unei copii JSON cu fotografii.
- Ștergerea datelor locale din aplicație.

## Limitarea esențială

Această etapă este o aplicație locală. NU sincronizează date cu site-ul AutoDealer Pro. NU are conturi SaaS, echipă sau abonamente active. Site-ul existent rămâne privat și separat. Aplicația afișează clar aceste limitări.

Nu introduceți un token de acces global al site-ului în aplicație. O aplicație distribuită nu poate păstra un astfel de secret.

## Dacă ai doar iPhone

Am adăugat `codemagic.yaml` pentru verificare pe un Mac în cloud. Nu ai nevoie de Mac personal. Deschide **CLOUD_SETUP_RO.md** pentru pașii de conectare GitHub/Codemagic și activarea ulterioară TestFlight. Configurația nu a fost încă rulată în cloud.

## Deschidere și verificare pe Mac

1. Instalați o versiune de Xcode care îndeplinește cerințele Apple curente. La verificarea din 30.09.2026, pragul publicat pentru upload era Xcode 26 cu SDK iOS 26 sau ulterior. Proiectul are deployment target iOS 17.
2. Deschideți `AutoDealerPro.xcodeproj`.
3. Alegeți schema AutoDealerPro și un simulator iPhone instalat.
4. Apăsați Run sau rulați `./scripts/verify-on-mac.sh` pentru compilare și teste.
5. Pentru un iPhone fizic: în Signing & Capabilities, selectați contul/Team-ul propriu și înlocuiți identificatorul `com.example.autodealerpro` cu unul unic. Nu există certificate sau conturi inserate în proiect.
6. Un cont Apple personal poate permite testare limitată pe propriul dispozitiv; pentru TestFlight și App Store este necesar Apple Developer Program.

## Înainte de App Store

Vezi `APP_STORE_RO.md`. Nu trimiteți acest proiect drept un SaaS finalizat. Sunt necesare autentificarea și serviciul public securizat, sincronizarea între utilizatori, abonamentele alese, datele reale ale operatorului, declarațiile de confidențialitate, testarea dispozitivelor și semnarea.

## Date și documente

Fișierele aplicației folosesc protecția datelor iOS și sunt salvate în Application Support. Nu există analytics sau publicitate. Copiile exportate conțin date personale și fotografii; utilizatorul decide unde le salvează. Exportul este o copie locală, nu un mecanism de sincronizare. Importul acceptă numai backupul acestei aplicații, doar într-un spațiu local gol, maximum 100 MB. Backupurile mai mari trebuie gestionate într-o etapă ulterioară; nu presupuneți că vor putea fi restaurate.

Documentele PDF sunt schițe. Codul nu implementează fiscalitate, facturi electronice conforme, numerotare fiscală secvențială sau clauze juridice complete. Câmpurile fiscale și contractuale sunt introduse manual.

## Validare efectuată în mediul de construire

- Fișierele plist și JSON și referințele proiectului Xcode au fost verificate structural.
- Au fost incluse teste XCTest pentru sume exacte, marjă, validarea vânzărilor și serializarea datelor.
- Testele XCTest NU au fost rulate. Compilarea SwiftUI și testarea pe simulator/dispozitiv sunt încă necesare.

Surse Apple consultate:
- https://developer.apple.com/news/upcoming-requirements/
- https://developer.apple.com/app-store/review/guidelines/
- https://developer.apple.com/documentation/photosui/photospicker
- https://developer.apple.com/documentation/swiftui/sharelink
- https://developer.apple.com/documentation/uikit/uigraphicspdfrenderer
