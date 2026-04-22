enum TypeMesure { temps, distance, hauteur, validation, inconnue }

extension TypeMesureJson on TypeMesure {
  static TypeMesure depuisNom(String? nom) {
    for (final type in TypeMesure.values) {
      if (type.name == nom) return type;
    }
    return TypeMesure.inconnue;
  }
}

enum StatutResultat { enAttente, termine, dnf, dns, disqualifie, nonValide }

extension StatutResultatLabel on StatutResultat {
  String get label {
    switch (this) {
      case StatutResultat.enAttente:
        return 'En attente';
      case StatutResultat.termine:
        return 'Terminé';
      case StatutResultat.dnf:
        return 'DNF';
      case StatutResultat.dns:
        return 'DNS';
      case StatutResultat.disqualifie:
        return 'Disqualifié';
      case StatutResultat.nonValide:
        return 'Non valide';
    }
  }

  static StatutResultat depuisNom(String? nom) {
    for (final statut in StatutResultat.values) {
      if (statut.name == nom) return statut;
    }
    return StatutResultat.enAttente;
  }
}

class Participant {
  const Participant({
    required this.id,
    required this.prenom,
    required this.nom,
    required this.numero,
    required this.groupe,
    this.categorie,
  });

  final String id;
  final String prenom;
  final String nom;
  final String numero;
  final String groupe;
  final String? categorie;

  String get nomComplet => '$prenom $nom';

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'prenom': prenom,
      'nom': nom,
      'numero': numero,
      'groupe': groupe,
      'categorie': categorie,
    };
  }

  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      id: json['id'] as String? ?? '',
      prenom: json['prenom'] as String? ?? '',
      nom: json['nom'] as String? ?? '',
      numero: json['numero'] as String? ?? '',
      groupe: json['groupe'] as String? ?? '',
      categorie: json['categorie'] as String?,
    );
  }

  static Participant depuisCsv(List<String> colonnes) {
    if (colonnes.length < 5) {
      throw const FormatException('Ligne CSV participant incomplete.');
    }
    return Participant(
      id: colonnes[2].trim().isEmpty
          ? '${colonnes[0]}-${colonnes[1]}'
          : colonnes[2].trim(),
      prenom: colonnes[0].trim(),
      nom: colonnes[1].trim(),
      numero: colonnes[2].trim(),
      groupe: colonnes[3].trim(),
      categorie: colonnes.length > 4 ? colonnes[4].trim() : null,
    );
  }
}

class ResultatParticipant {
  const ResultatParticipant({
    required this.participantId,
    required this.statut,
    this.temps,
    this.valeur,
    this.note,
    this.rang,
  });

  final String participantId;
  final StatutResultat statut;
  final Duration? temps;
  final double? valeur;
  final int? note;
  final int? rang;

  Map<String, Object?> toJson() {
    return {
      'participantId': participantId,
      'statut': statut.name,
      'tempsMs': temps?.inMilliseconds,
      'valeur': valeur,
      'note': note,
      'rang': rang,
    };
  }

  factory ResultatParticipant.fromJson(Map<String, dynamic> json) {
    final tempsMs = json['tempsMs'];
    return ResultatParticipant(
      participantId: json['participantId'] as String? ?? '',
      statut: StatutResultatLabel.depuisNom(json['statut'] as String?),
      temps: tempsMs is int ? Duration(milliseconds: tempsMs) : null,
      valeur: (json['valeur'] as num?)?.toDouble(),
      note: json['note'] as int?,
      rang: json['rang'] as int?,
    );
  }

  ResultatParticipant copie({
    StatutResultat? statut,
    Duration? temps,
    double? valeur,
    int? note,
    int? rang,
    bool effacerTemps = false,
    bool effacerValeur = false,
  }) {
    return ResultatParticipant(
      participantId: participantId,
      statut: statut ?? this.statut,
      temps: effacerTemps ? null : temps ?? this.temps,
      valeur: effacerValeur ? null : valeur ?? this.valeur,
      note: note ?? this.note,
      rang: rang ?? this.rang,
    );
  }
}

class EntreeHistorique {
  const EntreeHistorique({
    required this.date,
    required this.message,
  });

  final DateTime date;
  final String message;
}

class RegleBareme {
  const RegleBareme({
    required this.note,
    required this.type,
    required this.source,
    this.minimum,
    this.maximum,
    this.minimumInclus = false,
    this.maximumInclus = true,
  });

  final int note;
  final TypeMesure type;
  final double? minimum;
  final double? maximum;
  final bool minimumInclus;
  final bool maximumInclus;
  final String source;

  bool correspond(double valeur) {
    final min = minimum;
    final max = maximum;
    if (min != null) {
      if (minimumInclus) {
        if (valeur < min) return false;
      } else if (valeur <= min) {
        return false;
      }
    }
    if (max != null) {
      if (maximumInclus) {
        if (valeur > max) return false;
      } else if (valeur >= max) {
        return false;
      }
    }
    return true;
  }

  RegleBareme copie({
    int? note,
    TypeMesure? type,
    double? minimum,
    double? maximum,
    bool? minimumInclus,
    bool? maximumInclus,
    String? source,
    bool effacerMinimum = false,
    bool effacerMaximum = false,
  }) {
    return RegleBareme(
      note: note ?? this.note,
      type: type ?? this.type,
      minimum: effacerMinimum ? null : minimum ?? this.minimum,
      maximum: effacerMaximum ? null : maximum ?? this.maximum,
      minimumInclus: minimumInclus ?? this.minimumInclus,
      maximumInclus: maximumInclus ?? this.maximumInclus,
      source: source ?? this.source,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'note': note,
      'type': type.name,
      'minimum': minimum,
      'maximum': maximum,
      'minimumInclus': minimumInclus,
      'maximumInclus': maximumInclus,
      'source': source,
    };
  }

  factory RegleBareme.fromJson(Map<String, dynamic> json) {
    return RegleBareme(
      note: json['note'] as int? ?? 0,
      type: TypeMesureJson.depuisNom(json['type'] as String?),
      source: json['source'] as String? ?? '',
      minimum: (json['minimum'] as num?)?.toDouble(),
      maximum: (json['maximum'] as num?)?.toDouble(),
      minimumInclus: json['minimumInclus'] as bool? ?? false,
      maximumInclus: json['maximumInclus'] as bool? ?? true,
    );
  }
}

class BaremeActivite {
  const BaremeActivite({
    required this.id,
    required this.nom,
    required this.typePrincipal,
    required this.regles,
    required this.lignesNonAnalysees,
  });

  final String id;
  final String nom;
  final TypeMesure typePrincipal;
  final List<RegleBareme> regles;
  final List<String> lignesNonAnalysees;

  int? notePourTemps(Duration temps) {
    final secondes = temps.inMilliseconds / 1000;
    return notePourValeur(secondes, TypeMesure.temps);
  }

  int? notePourValeur(double valeur, TypeMesure type) {
    for (final regle in regles.where((regle) => regle.type == type)) {
      if (regle.correspond(valeur)) return regle.note;
    }
    return null;
  }

  BaremeActivite copie({
    String? id,
    String? nom,
    TypeMesure? typePrincipal,
    List<RegleBareme>? regles,
    List<String>? lignesNonAnalysees,
  }) {
    return BaremeActivite(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      typePrincipal: typePrincipal ?? this.typePrincipal,
      regles: regles ?? this.regles,
      lignesNonAnalysees: lignesNonAnalysees ?? this.lignesNonAnalysees,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'nom': nom,
      'typePrincipal': typePrincipal.name,
      'regles': regles.map((regle) => regle.toJson()).toList(),
      'lignesNonAnalysees': lignesNonAnalysees,
    };
  }

  factory BaremeActivite.fromJson(Map<String, dynamic> json) {
    return BaremeActivite(
      id: json['id'] as String? ?? '',
      nom: json['nom'] as String? ?? '',
      typePrincipal: TypeMesureJson.depuisNom(json['typePrincipal'] as String?),
      regles: (json['regles'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map(
              (regle) => RegleBareme.fromJson(Map<String, dynamic>.from(regle)))
          .toList(),
      lignesNonAnalysees: (json['lignesNonAnalysees'] as List<dynamic>? ?? [])
          .whereType<String>()
          .toList(),
    );
  }
}

class BaremeSection {
  const BaremeSection({
    required this.id,
    required this.nom,
    required this.source,
    required this.activites,
  });

  final String id;
  final String nom;
  final String source;
  final List<BaremeActivite> activites;

  BaremeSection copie({
    String? id,
    String? nom,
    String? source,
    List<BaremeActivite>? activites,
  }) {
    return BaremeSection(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      source: source ?? this.source,
      activites: activites ?? this.activites,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'nom': nom,
      'source': source,
      'activites': activites.map((activite) => activite.toJson()).toList(),
    };
  }

  factory BaremeSection.fromJson(Map<String, dynamic> json) {
    return BaremeSection(
      id: json['id'] as String? ?? '',
      nom: json['nom'] as String? ?? '',
      source: json['source'] as String? ?? '',
      activites: (json['activites'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((activite) =>
              BaremeActivite.fromJson(Map<String, dynamic>.from(activite)))
          .toList(),
    );
  }
}
