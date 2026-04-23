# Notes de reprise - Maitrise du Temps

Date de derniere session: 23/04/2026.

## But du projet

Construire une petite application Flutter en francais pour chronometrer une arrivee, choisir un domaine/activite, enregistrer les temps des participants, calculer les notes selon baremes, administrer les baremes localement, exporter les resultats et fonctionner sur Android.

## Reprendre demain

Toujours travailler dans:

```text
C:\Users\cyberselva\Desktop\chrono_app
```

Ne pas reprendre dans le dossier original accentue sauf demande explicite:

```text
C:\Users\cyberselva\Desktop\POMYSŁ APLIKACJI - POMIAR CZASU NA MECIE
```

Raison: Gradle/Java a deja pose probleme avec les caracteres speciaux du chemin.

## Dernier etat fonctionnel

Git est initialise dans le dossier de travail.

```text
branche: main
premier commit: 9c0dcd7 Initial Maîtrise du Temps app
```

Verification reussie avant arret:

```powershell
dart format lib test
flutter analyze
flutter test
flutter build apk --debug
```

Dernier APK genere:

```text
C:\Users\cyberselva\Desktop\chrono_app\build\app\outputs\flutter-apk\app-debug.apk
```

Derniere heure connue du fichier APK: 23/04/2026 12:24:25.

Serveur web lance sur:

```text
http://127.0.0.1:5237
```

Demarrage web recommande:

```powershell
powershell -ExecutionPolicy Bypass -File C:\Users\cyberselva\Desktop\chrono_app\scripts\start-web.ps1
```

Le script prend `5237` si disponible, sinon il monte sur le prochain port libre et ecrit le port actif dans:

```text
C:\Users\cyberselva\Desktop\chrono_app\.runtime\web-server.port
```

## Ce qui a ete ajoute aujourd'hui

### Base projet

- Creation/utilisation d'une copie ASCII `chrono_app`.
- Installation/configuration Flutter, MinGit, Android SDK, JDK.
- Build APK debug fonctionnel.
- Serveur web local fonctionnel.

### Fonctionnel

- Participants importables manuellement.
- Import CSV.
- Import XLSX via `file_picker`.
- Modele XLSX telechargeable via `excel` + `file_saver`.
- Export XLSX des resultats.
- Export CSV par copie.
- Sauvegarde locale automatique avec `shared_preferences`.
- Bouton de vidage de tous les participants/resultats.
- Correction manuelle du temps.
- Correction du temps depuis liste participants et depuis tableau resultats.
- Format temps final: `HH:MM:SS.mmm`.
- Ancien format `MM:SS.mmm` reste parse.
- Confirmation avant changement de section/activite pendant chronometre actif.
- Meteo Castelnaudary via Open-Meteo et package `http`.
- Nom visible de l'application change en `Maitrise du Temps`.
- Logo interne et icone launcher Android remplaces par `maitrise_du_temps1.png`.
- Menu `Administration baremes` ajoute.
- Ecran `Paramètres administrateur` ajoute pour separer la securite et les operations sensibles de l edition des baremes.
- Menu `Politique et contact` ajoute: application creee par `_STAN_` pour le 4RE, stockage local et bouton e-mail vers `instructeur.selva@gmail.com`.
- Acces administration par mot de passe: `Castelnaudary2026+`.
- Mot de passe administrateur maintenant stocke localement sous forme d empreinte SHA-256.
- Ecran de changement du mot de passe administrateur ajoute avec validation.
- Modification locale par domaine/activite des notes, seuils minimum/maximum et bornes incluses/exclues.
- Sauvegarde locale des baremes modifies avec `shared_preferences`.
- Sauvegarde locale du hash du mot de passe administrateur avec `shared_preferences`.
- Bouton de restauration des baremes d'origine.

### UI / mobile

- Logo `4re.png` ajoute comme asset.
- Theme vert/rouge Legion etrangere.
- Ecran de demarrage avec logo.
- Sur mobile, menu section/activite replie.
- Sur mobile, affichage principal concentre sur:
  - recherche,
  - stoper,
  - liste des participants.
- Cartes participants plus compactes sur telephone pour afficher plus de noms.
- Refonte des dialogues Flutter critiques avec etat local dedie pour eviter l'erreur `_dependents.isEmpty`:
  - ajout participant,
  - mot de passe administration,
  - correction d'un resultat.
- Dialogue `Modifier une règle` rendu defilable pour eviter le `bottom overflowed by 34 pixels`.
- Bouton `Rafraîchir les barèmes` ajoute pour recharger explicitement les baremes locaux.
- Domaine `FS1` simplifie en `ST1-00`.
- Bouton e-mail laisse uniquement dans `Politique et contact`.
- Participants tries alphabetiquement par nom.
- Filtre par nom, prenom, numero, groupe.
- Nom agrandi et visible sur telephone.
- Tap sur toute la carte participant ou bouton `STOP` = enregistrement du temps.

### Stabilite

- Correction d'un probleme probable de freeze/reset: `MaterialApp` et `DefaultTabController` ne sont plus reconstruits par le timer du chronometre.
- Seul le corps utile se reconstruit via `AnimatedBuilder`.

## Fichiers importants modifies

```text
pubspec.yaml
lib/main.dart
lib/src/application/app_state.dart
lib/src/domain/models.dart
lib/src/presentation/chronometrage_app.dart
test/bareme_parser_test.dart
test/widget_test.dart
README.md
PROJECT_NOTES.md
```

## Dependances ajoutees

```yaml
excel: ^4.0.6
file_picker: ^11.0.2
file_saver: ^0.3.1
http: ^1.6.0
shared_preferences: ^2.5.5
url_launcher: ^6.3.2
```

## Points a tester demain sur telephone

1. Installer le dernier `app-debug.apk`.
2. Verifier que les noms sont lisibles en activite.
3. Verifier que le filtre par nom et numero est rapide.
4. Lancer START puis taper plusieurs participants.
5. Corriger manuellement un participant et confirmer que les autres resultats ne changent pas.
6. Changer domaine/activite pendant START et confirmer que l'avertissement apparait.
7. Importer un XLSX de participants.
8. Exporter les resultats XLSX depuis Android.
9. Tester la meteo avec internet actif.
10. Ouvrir Administration baremes avec `Castelnaudary2026+`, modifier une regle puis verifier le recalcul des notes.

## Prochaines ameliorations possibles

- Ajouter un mode plein ecran "course" sans onglets, uniquement stoper + recherche + participants.
- Ajouter un bouton "restaurer participants demo".
- Ajouter export PDF.
- Ajouter signature release Android.
- Ajouter icone launcher Android avec `4re.png`.
- Ajouter export/import des parametres administrateur si l'application doit etre dupliquee sur plusieurs appareils.
- Passer a SQLite seulement si les baremes deviennent multi-utilisateur ou si le volume de donnees depasse clairement le stockage local actuel.
- Ajouter tests widget specifiques mobile.

## Commandes PowerShell a reutiliser

```powershell
$project='C:\Users\cyberselva\Desktop\chrono_app'
$sdk='C:\Users\cyberselva\tools\android-sdk'
$env:Path="C:\Users\cyberselva\tools\flutter\bin;C:\Users\cyberselva\tools\mingit\cmd;C:\Users\cyberselva\Desktop\codex app\tools\jdk-21\bin;$sdk\platform-tools;$sdk\cmdline-tools\latest\bin;$env:Path"
$env:JAVA_HOME="C:\Users\cyberselva\Desktop\codex app\tools\jdk-21"
$env:ANDROID_HOME=$sdk
$env:ANDROID_SDK_ROOT=$sdk
Set-Location -LiteralPath $project
```

Validation:

```powershell
dart format lib test
flutter analyze
flutter test
```

Web:

```powershell
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 5237
```

APK:

```powershell
flutter build apk --debug
```

Ou:

```powershell
powershell -ExecutionPolicy Bypass -File C:\Users\cyberselva\Desktop\chrono_app\scripts\build-apk.ps1
```
