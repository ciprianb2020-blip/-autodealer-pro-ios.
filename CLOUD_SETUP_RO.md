# AutoDealer Pro — continuare fără Mac personal

Proiectul este pregătit pentru Codemagic. Configurația a fost validată local, dar NU a fost executată o compilare în cloud. Încă nu există o aplicație IPA instalabilă.

## Primul pas: verificarea codului, fără cont Apple plătit

1. Conectează GitHub în ChatGPT, pentru a putea transfera proiectul într-un repository privat. Dacă nu ai cont, creează unul pe https://github.com/signup.
2. Creează un cont pe https://codemagic.io și conectează acel repository. Serviciul poate avea limite/costuri proprii; verifică planul înainte de a porni rulări.
3. În repository, `codemagic.yaml` și `AutoDealerPro.xcodeproj` trebuie să fie la rădăcină. Nu încărca doar ZIP-ul ca fișier: trebuie încărcat conținutul dezarhivat al folderului AutoDealerPro-iOS.
4. Selectează proiect de tip iOS nativ / configurație YAML și fluxul **AutoDealer Pro - Build and tests** (`ios-verify`).
5. Pornește o rulare manuală. Nu există declanșatoare automate în configurație.
6. Codemagic va verifica fișierele, va compila aplicația și va executa testele XCTest pe un simulator iPhone. Dacă apare o eroare, trimite jurnalul de compilare pentru corectare.

Rezultatele așteptate după o rulare REUȘITĂ: un jurnal, rezultatele XCTest și un ZIP cu aplicația de simulator. **Aplicația de simulator nu se poate instala pe iPhone.** Această etapă ne arată dacă sursele compilează înainte de a configura semnarea Apple.

## A doua etapă: instalare prin TestFlight

Necesită Apple Developer Program activ și o fișă a aplicației în App Store Connect.

- Înregistrează un Bundle ID unic la Apple și folosește același ID în proiect și în profilul de semnare.
- În Codemagic, configurează integrarea App Store Connect și certificatul/profilul de distribuție potrivit. Cheia privată Apple se introduce numai în câmpul securizat al serviciului; nu o trimite în chat și nu o adăuga în repository.
- După ce există identitatea reală, se rulează `scripts/configure-testflight.py --bundle-id ID_REAL --integration NUME_INTEGRARE`. Scriptul poate fi rulat de asistent înainte de transferul următoarei versiuni; nu ai nevoie să-l rulezi pe iPhone.
- Scriptul activează fluxul **AutoDealer Pro - Internal TestFlight** (`ios-testflight`). Momentan fluxul semnat este doar un șablon separat, pentru ca prima verificare să nu ceară credențiale Apple inexistente.
- Fluxul semnat execută din nou testele, stabilește un număr unic de build și încarcă o versiune destinată EXCLUSIV testării interne în App Store Connect. O eroare de test blochează semnarea și uploadul.
- După procesarea Apple, adaugi contul tău ca tester intern în App Store Connect, rezolvi eventualele declarații de conformitate cerute și instalezi versiunea prin TestFlight.

`submit_to_testflight: false` înseamnă că fluxul nu cere automat verificarea beta externă; uploadul este pentru testare internă. `submit_to_app_store: false` păstrează publicarea în App Store ca etapă separată. Nu trebuie schimbate pentru primul test pe telefonul tău.

Numerele de build folosesc secvența întregului proiect Codemagic. Dacă muți aplicația într-un proiect nou sau există deja versiuni încărcate din altă sursă, ajustează BUILD_NUMBER_OFFSET astfel încât noul număr să depășească ultimul număr folosit. Nu rula simultan mai multe fluxuri semnate pentru prima încărcare.

## A treia etapă: SaaS și App Store

Prima versiune iPhone rămâne locală. Autentificarea clienților externi, sincronizarea cu site-ul, echipa, abonamentele și documentele complete ale operatorului rămân de implementat. Un build intern reușit nu înseamnă că acestea sunt gata sau că Apple a aprobat aplicația.

Vezi APP_STORE_RO.md pentru condițiile de lansare și README_RO.md pentru funcțiile implementate.

Documentație folosită (30.09.2026):
https://docs.codemagic.io/yaml-quick-start/building-a-native-ios-app/
https://docs.codemagic.io/yaml-code-signing/signing-ios/
https://docs.codemagic.io/yaml-publishing/app-store-connect/
https://docs.codemagic.io/knowledge-codemagic/build-versioning/
