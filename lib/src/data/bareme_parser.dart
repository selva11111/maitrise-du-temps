import '../domain/models.dart';

class BaremeParser {
  BaremeSection analyser({
    required String chemin,
    required String contenu,
  }) {
    final section = _sectionDepuisChemin(chemin);
    final lignes = contenu
        .split(RegExp(r'\r?\n'))
        .map((ligne) => ligne.trim())
        .where((ligne) => ligne.isNotEmpty)
        .toList();

    final activites = <BaremeActivite>[];
    String? nomActivite;
    final regles = <RegleBareme>[];
    final nonAnalysees = <String>[];

    void terminerActivite() {
      if (nomActivite == null) return;
      activites.add(
        BaremeActivite(
          id: normaliserActivite(nomActivite),
          nom: nomActivite,
          typePrincipal: _typePrincipal(regles),
          regles: List.unmodifiable(regles),
          lignesNonAnalysees: List.unmodifiable(nonAnalysees),
        ),
      );
      regles.clear();
      nonAnalysees.clear();
    }

    for (final ligne in lignes) {
      if (ligne.toUpperCase().startsWith('BAREMES') ||
          ligne.toUpperCase().startsWith('BARÈMES')) {
        continue;
      }

      final regle = _regleDepuisLigne(ligne, nomActivite);
      if (regle != null) {
        regles.add(regle);
        continue;
      }

      if (!ligne.contains(':')) {
        terminerActivite();
        nomActivite = _nettoyerTitre(ligne);
        continue;
      }

      nonAnalysees.add(ligne);
    }

    terminerActivite();

    return BaremeSection(
      id: section.$1,
      nom: section.$2,
      source: chemin,
      activites: List.unmodifiable(activites),
    );
  }

  static String normaliserActivite(String nom) {
    final upper = _sansAccents(nom).toUpperCase();
    if (upper.contains('GRIMPER')) return 'G.CORDE';
    if (upper.contains('MARCHE')) return '8KMTAP';
    if (upper.contains('OBSTACLE')) return 'PO';
    if (upper.contains('NAUTIQUE')) return 'PIST';
    if (upper.contains('NATATION') || upper.contains('NAGE')) {
      if (upper.contains('T.COMB')) return 'NATATION T.COMB 2400M';
      return 'NATATION';
    }
    return upper
        .replaceAll(RegExp(r'[^A-Z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  static String _nettoyerTitre(String ligne) {
    return ligne.replaceAll(RegExp(r'^[^\wÀ-ÿ]+', unicode: true), '').trim();
  }

  (String, String) _sectionDepuisChemin(String chemin) {
    final fichier = chemin.split(RegExp(r'[\\/]')).last.toUpperCase();
    if (fichier.startsWith('FG1')) return ('FG1', 'FG1');
    if (fichier.startsWith('FGE')) return ('FGE', 'FGE');
    if (fichier.startsWith('FS1')) return ('ST1-00', 'ST1-00');
    if (fichier.startsWith('FTS')) return ('FGI', 'FGI');
    return (fichier.replaceAll('.TXT', ''), fichier.replaceAll('.TXT', ''));
  }

  RegleBareme? _regleDepuisLigne(String ligne, String? activite) {
    final match = RegExp(r'^(\d+)\s*:\s*(.+)$').firstMatch(ligne);
    if (match == null) return null;

    final note = int.parse(match.group(1)!);
    final expression = match.group(2)!.trim();
    final lower = expression.toLowerCase();

    if (lower.contains('t')) {
      return _regleTemps(note, expression, activite ?? '', ligne);
    }
    final activiteNormalisee = _sansAccents(activite ?? '').toUpperCase();
    if (lower.contains('h') ||
        lower.contains('corde') ||
        (activiteNormalisee.contains('GRIMPER') && lower.contains('m'))) {
      return _regleMetres(note, expression, TypeMesure.hauteur, ligne);
    }
    if (lower.contains('l') || lower.contains('m')) {
      return _regleMetres(note, expression, TypeMesure.distance, ligne);
    }
    return RegleBareme(
      note: note,
      type: TypeMesure.inconnue,
      source: ligne,
    );
  }

  RegleBareme _regleTemps(
    int note,
    String expression,
    String activite,
    String source,
  ) {
    final valeurs = _extraireTemps(expression, activite);
    if (valeurs.isEmpty) {
      return RegleBareme(note: note, type: TypeMesure.inconnue, source: source);
    }

    final texte = expression.replaceAll('≤', '<=').trim();
    if (texte.startsWith('t <=')) {
      return RegleBareme(
        note: note,
        type: TypeMesure.temps,
        maximum: valeurs.first,
        maximumInclus: true,
        source: source,
      );
    }
    if (texte.startsWith('t <')) {
      return RegleBareme(
        note: note,
        type: TypeMesure.temps,
        maximum: valeurs.first,
        maximumInclus: false,
        source: source,
      );
    }
    if (valeurs.length >= 2) {
      return RegleBareme(
        note: note,
        type: TypeMesure.temps,
        minimum: valeurs[0],
        maximum: valeurs[1],
        minimumInclus: false,
        maximumInclus: true,
        source: source,
      );
    }
    return RegleBareme(
      note: note,
      type: TypeMesure.temps,
      minimum: valeurs.first,
      minimumInclus: false,
      source: source,
    );
  }

  RegleBareme _regleMetres(
    int note,
    String expression,
    TypeMesure type,
    String source,
  ) {
    final valeurs = RegExp(r'(\d+(?:[,.]\d+)?)\s*m')
        .allMatches(expression)
        .map((match) => double.parse(match.group(1)!.replaceAll(',', '.')))
        .toList();

    if (valeurs.length >= 2) {
      return RegleBareme(
        note: note,
        type: type,
        minimum: valeurs[1],
        maximum: valeurs[0],
        minimumInclus: true,
        maximumInclus: true,
        source: source,
      );
    }
    if (valeurs.length == 1) {
      final texte = expression.replaceAll('>', '<');
      if (texte.contains('<')) {
        return RegleBareme(
          note: note,
          type: type,
          maximum: valeurs.first,
          maximumInclus: false,
          source: source,
        );
      }
      return RegleBareme(
        note: note,
        type: type,
        minimum: valeurs.first,
        maximum: valeurs.first,
        minimumInclus: true,
        maximumInclus: true,
        source: source,
      );
    }
    if (expression.toLowerCase().contains('corde')) {
      return RegleBareme(
        note: note,
        type: type,
        minimum: 5,
        maximum: 5,
        minimumInclus: true,
        maximumInclus: true,
        source: source,
      );
    }
    return RegleBareme(note: note, type: TypeMesure.inconnue, source: source);
  }

  List<double> _extraireTemps(String expression, String activite) {
    final grimper = _sansAccents(activite).toUpperCase().contains('GRIMPER');
    return RegExp("(\\d+)(?:'(\\d{1,2}))?\"")
        .allMatches(expression)
        .map((match) {
      final premier = double.parse(match.group(1)!);
      final second = match.group(2);
      if (second == null) return premier;
      final secondePartie = double.parse(second);
      if (grimper && premier < 20) {
        return premier + (secondePartie / 100);
      }
      return (premier * 60) + secondePartie;
    }).toList();
  }

  TypeMesure _typePrincipal(List<RegleBareme> regles) {
    final ordre = [TypeMesure.temps, TypeMesure.distance, TypeMesure.hauteur];
    for (final type in ordre) {
      if (regles.any((regle) => regle.type == type)) return type;
    }
    return TypeMesure.inconnue;
  }

  static String _sansAccents(String valeur) {
    const accents = {
      'À': 'A',
      'Â': 'A',
      'Ä': 'A',
      'Ç': 'C',
      'É': 'E',
      'È': 'E',
      'Ê': 'E',
      'Ë': 'E',
      'Î': 'I',
      'Ï': 'I',
      'Ô': 'O',
      'Ö': 'O',
      'Ù': 'U',
      'Û': 'U',
      'Ü': 'U',
      'à': 'a',
      'â': 'a',
      'ä': 'a',
      'ç': 'c',
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'ë': 'e',
      'î': 'i',
      'ï': 'i',
      'ô': 'o',
      'ö': 'o',
      'ù': 'u',
      'û': 'u',
      'ü': 'u',
    };
    var sortie = valeur;
    for (final entree in accents.entries) {
      sortie = sortie.replaceAll(entree.key, entree.value);
    }
    return sortie;
  }
}
