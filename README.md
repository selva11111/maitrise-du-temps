# Maitrise du Temps

Application Flutter en francais pour mesurer les temps d'arrivee, importer des participants, administrer les baremes et exporter les resultats.

## Dossier de travail

Le dossier a utiliser pour continuer le developpement est:

```text
C:\Users\cyberselva\Desktop\chrono_app
```

Le dossier original avec caracteres accentues existe encore, mais la copie `chrono_app` est la version de travail, car elle evite les problemes Java/Gradle avec le chemin contenant `Ł`.

## Etat actuel

Fonctions implementees:

- chronometre principal,
- enregistrement du temps d'un participant sans arreter le chronometre,
- affichage mobile optimise: stoper + filtre + noms visibles,
- participants tries par nom,
- filtre par nom, prenom, numero et groupe,
- correction manuelle des temps au format `HH:MM:SS.mmm`,
- correction aussi depuis l'onglet `Resultats`,
- statuts: Termine, DNF, DNS, Disqualifie, Non valide,
- calcul automatique des notes selon les baremes,
- classement provisoire,
- import CSV par collage,
- import XLSX depuis un fichier,
- telechargement d'un modele XLSX pour remplir les participants,
- export XLSX des resultats,
- export CSV par copie,
- sauvegarde locale automatique avec `shared_preferences`,
- bouton pour vider tous les participants et resultats,
- menu domaine/activite replie sur mobile,
- confirmation avant changement de domaine/activite pendant le chronometre,
- meteo Castelnaudary 11400 via Open-Meteo,
- administration locale des baremes par domaine/activite avec mot de passe,
- modification des notes, temps minimum/maximum et inclusions de seuils,
- restauration des baremes d'origine,
- logo `4re.png`,
- icone Android generee z obrazu `maitrise_du_temps1.png`,
- menu `Politique et contact` avec mention de creation par `_STAN_` pour le 4RE,
- bouton e-mail vers `instructeur.selva@gmail.com`,
- theme vert/rouge Legion etrangere.

Mot de passe administrateur actuel:

```text
admin123
```

## APK actuel

APK debug genere:

```text
C:\Users\cyberselva\Desktop\chrono_app\build\app\outputs\flutter-apk\app-debug.apk
```

Derniere generation connue: 22/04/2026 22:50:15.

Ce fichier est une version debug pour tests Android. Le telephone peut demander d'autoriser l'installation depuis une source inconnue.

## Web local

Serveur web local utilise pendant le developpement:

```text
http://127.0.0.1:5237
```

Logs:

```text
C:\Users\cyberselva\Desktop\chrono_app\flutter-web-current.out.log
C:\Users\cyberselva\Desktop\chrono_app\flutter-web-current.err.log
```

## Environnement installe

Flutter:

```text
C:\Users\cyberselva\tools\flutter
```

Git MinGit:

```text
C:\Users\cyberselva\tools\mingit
```

Android SDK:

```text
C:\Users\cyberselva\tools\android-sdk
```

JDK:

```text
C:\Users\cyberselva\Desktop\codex app\tools\jdk-21
```

Variables d'environnement a definir dans PowerShell avant commandes Flutter:

```powershell
$project='C:\Users\cyberselva\Desktop\chrono_app'
$sdk='C:\Users\cyberselva\tools\android-sdk'
$env:Path="C:\Users\cyberselva\tools\flutter\bin;C:\Users\cyberselva\tools\mingit\cmd;C:\Users\cyberselva\Desktop\codex app\tools\jdk-21\bin;$sdk\platform-tools;$sdk\cmdline-tools\latest\bin;$env:Path"
$env:JAVA_HOME="C:\Users\cyberselva\Desktop\codex app\tools\jdk-21"
$env:ANDROID_HOME=$sdk
$env:ANDROID_SDK_ROOT=$sdk
Set-Location -LiteralPath $project
```

## Commandes utiles

Verifier le code:

```powershell
dart format lib test
flutter analyze
flutter test
```

Lancer web:

```powershell
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 5237
```

Construire APK debug:

```powershell
flutter build apk --debug
```

## Structure principale

```text
lib/main.dart
lib/src/application/app_state.dart
lib/src/data/bareme_parser.dart
lib/src/data/demo_data.dart
lib/src/domain/models.dart
lib/src/presentation/chronometrage_app.dart
test/bareme_parser_test.dart
test/widget_test.dart
```

## Assets et donnees

Baremes charges comme assets:

```text
FG1.txt
FGE.txt
FS1-OO.txt
FTS .txt
```

Logo:

```text
4re.png
```

Exemple CSV:

```text
data/participants_exemple.csv
```

## Formats de donnees

CSV participants:

```csv
prenom;nom;numero;groupe;categorie
Jean;Dupont;101;Groupe 1;Senior
```

XLSX participants:

Colonnes reconnues:

```text
Prenom / Imie
Nom / Nazwisko
Numero / Nr / Dossard
Groupe / Grupa
Categorie / Kategoria
```

Temps:

```text
HH:MM:SS.mmm
00:01:23.456
```

Ancien format encore accepte pour correction:

```text
MM:SS.mmm
02:03.400
```

## Limites connues

- L'APK est debug, pas encore signe en release.
- La meteo Open-Meteo demande internet sur l'appareil.
- Le stockage local est propre a l'appareil/navigateur.
- Les baremes modifies sont sauvegardes localement sur l'appareil/navigateur.
- L'export XLSX sur Android peut dependre des permissions/gestionnaires de fichiers du telephone.
- Il faudra tester l'ergonomie mobile directement sur telephone pendant une vraie activite.
