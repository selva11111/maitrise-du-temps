# Architecture

## Choix technique

Le projet est structure comme une application Flutter simple mais extensible:

- `domain`: modeles purs de l'application.
- `data`: lecture et interpretation des fichiers de baremes.
- `application`: etat applicatif, chronometre, resultats, import/export.
- `presentation`: interface Flutter en francais.

Le MVP utilise `ChangeNotifier` pour eviter d'ajouter trop tot une dependance de gestion d'etat. Cette solution reste suffisante pour valider le produit terrain. Plus tard, le projet pourra migrer vers Riverpod, Bloc ou une architecture plus stricte sans changer les modeles metier.

## Stockage

Le MVP garde les donnees en memoire. Pour une version terrain, ajouter une couche `repository` avec SQLite ou Hive:

- sessions de chronometrage,
- participants importes,
- resultats,
- historique des corrections,
- baremes normalises.

## Evolutions prevues

L'architecture laisse de la place pour:

- QR code,
- NFC,
- authentification,
- synchronisation en ligne,
- multi-appareils,
- export PDF complet,
- gestion de plusieurs sessions.
