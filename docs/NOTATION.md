# Logique de notation

## Source de verite

Les fichiers texte du dossier projet sont lus au demarrage:

- `FG1.txt`
- `FGE.txt`
- `FS1-OO.txt`
- `FTS .txt`

Chaque fichier devient une section. Les titres sans deux-points deviennent des activites. Les lignes au format `note : condition` deviennent des regles.

## Correspondance actuelle des sections

- `FG1.txt` -> `FG1`
- `FGE.txt` -> `FGE`
- `FTS .txt` -> `FGI`
- `FS1-OO.txt` -> `ST1-00-AGUER`

## Correspondance actuelle des activites

- `GRIMPER` -> `G.CORDE`
- `MARCHE COMMANDO` -> `8KMTAP`
- `PARCOURS D'OBSTACLE(S)` -> `PO`
- `PARCOURS NAUTIQUE` -> `PIST`
- `NATATION` -> `NATATION`
- `NATATION T.COMB` -> `NATATION T.COMB 2400M`

Ces correspondances sont documentees comme hypotheses et peuvent etre ajustees apres validation metier.

## Regles de temps

Le temps du participant est converti en secondes. Exemple:

```text
19 : 3'20" < t <= 3'25"
```

devient:

```text
200 s < t <= 205 s
```

Pour l'activite `GRIMPER`, les notations du type `6'50"` sont interpretees comme `6,50 s`, car une valeur de 6 minutes serait incoherente pour une corde.

## Regles de distance et hauteur

Les lignes utilisant `h`, `l`, `m` ou `corde` sont conservees comme regles de hauteur/distance. Le MVP les parse mais l'ecran principal calcule d'abord les notes depuis un temps. Une prochaine etape doit ajouter un mode de saisie de valeur pour ces activites mixtes.

## Ambiguites detectees

- Dans `FG1.txt` et `FGE.txt`, les notes 12 et 11 de `GRIMPER` ont la meme condition `11" < t <= 12"`.
- Certaines activites melangent notation au temps et notation par distance/hauteur apres une note minimale.
- `FTS .txt` est mappe a `FGI` par hypothese, faute d'un fichier nomme `FGI.txt`.
