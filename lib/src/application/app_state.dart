import 'dart:async';
import 'dart:convert';

import 'package:excel/excel.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/bareme_parser.dart';
import '../data/demo_data.dart';
import '../domain/models.dart';

class ChronometrageState extends ChangeNotifier {
  static const _cleSession = 'chronometrage_arrivee_session_v1';
  static const _cleBaremes = 'maitrise_du_temps_baremes_v1';
  static const motDePasseAdminParDefaut = 'Castelnaudary2026+';

  final _stopwatch = Stopwatch();
  Timer? _timer;

  List<BaremeSection> sections = [];
  List<BaremeSection> _sectionsParDefaut = [];
  List<Participant> participants = List.of(participantsDemo);
  final Map<String, ResultatParticipant> resultats = {};
  final List<EntreeHistorique> historique = [];
  final List<String> alertesBaremes = [];
  final List<String> _pileAnnulation = [];

  String recherche = '';
  String? sectionSelectionnee;
  String? activiteSelectionnee;
  bool sessionChargee = false;

  Duration get tempsEcoule => _stopwatch.elapsed;
  bool get estEnCours => _stopwatch.isRunning;

  BaremeSection? get sectionCourante {
    for (final section in sections) {
      if (section.id == sectionSelectionnee) return section;
    }
    return sections.isEmpty ? null : sections.first;
  }

  BaremeActivite? get activiteCourante {
    final section = sectionCourante;
    if (section == null) return null;
    for (final activite in section.activites) {
      if (activite.id == activiteSelectionnee) return activite;
    }
    return section.activites.isEmpty ? null : section.activites.first;
  }

  List<Participant> get participantsFiltres {
    final terme = recherche.trim().toLowerCase();
    final liste = terme.isEmpty
        ? List<Participant>.of(participants)
        : participants.where((participant) {
            return participant.nomComplet.toLowerCase().contains(terme) ||
                participant.nom.toLowerCase().contains(terme) ||
                participant.prenom.toLowerCase().contains(terme) ||
                participant.numero.toLowerCase().contains(terme) ||
                participant.groupe.toLowerCase().contains(terme);
          }).toList();
    liste.sort((a, b) {
      final nom = a.nom.toLowerCase().compareTo(b.nom.toLowerCase());
      if (nom != 0) return nom;
      final prenom = a.prenom.toLowerCase().compareTo(b.prenom.toLowerCase());
      if (prenom != 0) return prenom;
      return a.numero.compareTo(b.numero);
    });
    return liste;
  }

  List<(Participant, ResultatParticipant)> get resultatsClasses {
    final lignes = participants.map((participant) {
      return (
        participant,
        resultats[participant.id] ??
            ResultatParticipant(
              participantId: participant.id,
              statut: StatutResultat.enAttente,
            ),
      );
    }).toList();

    lignes.sort((a, b) {
      final ra = a.$2;
      final rb = b.$2;
      if (ra.temps != null && rb.temps != null) {
        return ra.temps!.compareTo(rb.temps!);
      }
      if (ra.temps != null) return -1;
      if (rb.temps != null) return 1;
      final nom = a.$1.nom.toLowerCase().compareTo(b.$1.nom.toLowerCase());
      if (nom != 0) return nom;
      return a.$1.prenom.toLowerCase().compareTo(b.$1.prenom.toLowerCase());
    });

    var rang = 1;
    return lignes.map((ligne) {
      final resultat =
          ligne.$2.temps == null ? ligne.$2 : ligne.$2.copie(rang: rang++);
      return (ligne.$1, resultat);
    }).toList();
  }

  Future<void> initialiser() async {
    final parser = BaremeParser();
    final baremes = <BaremeSection>[];
    for (final chemin in fichiersBaremes) {
      final contenu = await rootBundle.loadString(chemin);
      final section = parser.analyser(chemin: chemin, contenu: contenu);
      baremes.add(section);
      for (final activite in section.activites) {
        for (final ligne in activite.lignesNonAnalysees) {
          alertesBaremes.add('${section.id} / ${activite.nom}: $ligne');
        }
      }
    }
    _sectionsParDefaut = List.unmodifiable(baremes);
    sections = List.unmodifiable(baremes);
    await _chargerBaremesModifies();
    sectionSelectionnee = sections.isEmpty ? null : sections.first.id;
    activiteSelectionnee = sections.isEmpty || sections.first.activites.isEmpty
        ? null
        : sections.first.activites.first.id;
    await _chargerSession();
    _journaliser(
      sessionChargee
          ? 'Session locale restaurée avec ${participants.length} participants.'
          : 'Application initialisée avec ${participants.length} participants de démonstration.',
    );
  }

  void choisirSection(String id) {
    sectionSelectionnee = id;
    final section = sectionCourante;
    activiteSelectionnee =
        section?.activites.isEmpty == true ? null : section?.activites.first.id;
    _recalculerNotes();
    _notifierEtSauvegarder();
  }

  void choisirActivite(String id) {
    activiteSelectionnee = id;
    _recalculerNotes();
    _notifierEtSauvegarder();
  }

  bool verifierMotDePasseAdmin(String motDePasse) {
    return motDePasse.trim() == motDePasseAdminParDefaut;
  }

  Future<void> mettreAJourRegleBareme({
    required String sectionId,
    required String activiteId,
    required int regleIndex,
    required RegleBareme regle,
  }) async {
    final nouvellesSections = [...sections];
    final sectionIndex =
        nouvellesSections.indexWhere((section) => section.id == sectionId);
    if (sectionIndex < 0) {
      throw ArgumentError('Section introuvable: $sectionId');
    }

    final section = nouvellesSections[sectionIndex];
    final nouvellesActivites = [...section.activites];
    final activiteIndex =
        nouvellesActivites.indexWhere((activite) => activite.id == activiteId);
    if (activiteIndex < 0) {
      throw ArgumentError('Activite introuvable: $activiteId');
    }

    final activite = nouvellesActivites[activiteIndex];
    if (regleIndex < 0 || regleIndex >= activite.regles.length) {
      throw RangeError.index(regleIndex, activite.regles, 'regleIndex');
    }

    final nouvellesRegles = [...activite.regles];
    nouvellesRegles[regleIndex] = regle;
    nouvellesActivites[activiteIndex] =
        activite.copie(regles: List.unmodifiable(nouvellesRegles));
    nouvellesSections[sectionIndex] =
        section.copie(activites: List.unmodifiable(nouvellesActivites));
    sections = List.unmodifiable(nouvellesSections);
    _recalculerNotes();
    await _sauvegarderBaremes();
    _journaliser(
      'Bareme modifie: ${section.id} / ${activite.nom}, note ${regle.note}.',
    );
    _notifierEtSauvegarder();
  }

  Future<void> reinitialiserBaremes() async {
    sections = List.unmodifiable(_sectionsParDefaut);
    final sectionExiste =
        sections.any((section) => section.id == sectionSelectionnee);
    if (!sectionExiste) {
      sectionSelectionnee = sections.isEmpty ? null : sections.first.id;
    }
    final section = sectionCourante;
    final activiteExiste = section?.activites
            .any((activite) => activite.id == activiteSelectionnee) ??
        false;
    if (!activiteExiste) {
      activiteSelectionnee = section?.activites.isEmpty == true
          ? null
          : section?.activites.first.id;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cleBaremes);
    _recalculerNotes();
    _journaliser('Baremes restaurees depuis les fichiers d origine.');
    _notifierEtSauvegarder();
  }

  Future<void> rechargerBaremesEnregistres() async {
    sections = List.unmodifiable(_sectionsParDefaut);
    await _chargerBaremesModifies();
    final sectionExiste =
        sections.any((section) => section.id == sectionSelectionnee);
    if (!sectionExiste) {
      sectionSelectionnee = sections.isEmpty ? null : sections.first.id;
    }
    final section = sectionCourante;
    final activiteExiste = section?.activites
            .any((activite) => activite.id == activiteSelectionnee) ??
        false;
    if (!activiteExiste) {
      activiteSelectionnee = section?.activites.isEmpty == true
          ? null
          : section?.activites.first.id;
    }
    _recalculerNotes();
    _journaliser('Baremes recharges depuis le stockage local.');
    notifyListeners();
  }

  void definirRecherche(String valeur) {
    recherche = valeur;
    notifyListeners();
  }

  void demarrer() {
    if (_stopwatch.isRunning) return;
    _stopwatch.start();
    _timer = Timer.periodic(
        const Duration(milliseconds: 100), (_) => notifyListeners());
    _journaliser('Chronomètre démarré.');
    notifyListeners();
  }

  void arreter() {
    if (!_stopwatch.isRunning) return;
    _stopwatch.stop();
    _timer?.cancel();
    _journaliser('Chronomètre arrêté à ${formatDuration(tempsEcoule)}.');
    notifyListeners();
  }

  void reinitialiser() {
    _stopwatch
      ..stop()
      ..reset();
    _timer?.cancel();
    resultats.clear();
    _pileAnnulation.clear();
    _journaliser('Chronomètre et résultats réinitialisés.');
    _notifierEtSauvegarder();
  }

  void enregistrerArrivee(Participant participant) {
    if (!_stopwatch.isRunning) return;
    final temps = _stopwatch.elapsed;
    final note = activiteCourante?.notePourTemps(temps);
    resultats[participant.id] = ResultatParticipant(
      participantId: participant.id,
      statut: StatutResultat.termine,
      temps: temps,
      note: note,
    );
    _pileAnnulation.add(participant.id);
    _journaliser(
        '${participant.nomComplet}: temps enregistré ${formatDuration(temps)}.');
    _notifierEtSauvegarder();
  }

  void modifierTemps(Participant participant, Duration temps) {
    final note = activiteCourante?.notePourTemps(temps);
    resultats[participant.id] = ResultatParticipant(
      participantId: participant.id,
      statut: StatutResultat.termine,
      temps: temps,
      note: note,
    );
    _journaliser(
        '${participant.nomComplet}: temps corrigé ${formatDuration(temps)}.');
    _notifierEtSauvegarder();
  }

  void modifierStatut(Participant participant, StatutResultat statut) {
    resultats[participant.id] = ResultatParticipant(
      participantId: participant.id,
      statut: statut,
      note: statut == StatutResultat.termine
          ? resultats[participant.id]?.note
          : null,
      temps: statut == StatutResultat.termine
          ? resultats[participant.id]?.temps
          : null,
    );
    _journaliser('${participant.nomComplet}: statut ${statut.label}.');
    _notifierEtSauvegarder();
  }

  void supprimerResultat(Participant participant) {
    resultats.remove(participant.id);
    _journaliser('${participant.nomComplet}: résultat supprimé.');
    _notifierEtSauvegarder();
  }

  void annulerDernierEnregistrement() {
    while (_pileAnnulation.isNotEmpty) {
      final id = _pileAnnulation.removeLast();
      Participant? participant;
      for (final candidat in participants) {
        if (candidat.id == id) {
          participant = candidat;
          break;
        }
      }
      if (participant != null && resultats.containsKey(id)) {
        resultats.remove(id);
        _journaliser(
            '${participant.nomComplet}: dernier enregistrement annulé.');
        _notifierEtSauvegarder();
        return;
      }
    }
  }

  String? ajouterParticipant({
    required String prenom,
    required String nom,
    required String numero,
    required String groupe,
    String? categorie,
  }) {
    final numeroNettoye = numero.trim();
    if (prenom.trim().isEmpty || nom.trim().isEmpty || numeroNettoye.isEmpty) {
      return 'Le prénom, le nom et le numéro sont obligatoires.';
    }
    if (participants
        .any((participant) => participant.numero == numeroNettoye)) {
      return 'Ce numéro est déjà utilisé.';
    }

    final participant = Participant(
      id: 'manuel-${DateTime.now().microsecondsSinceEpoch}',
      prenom: prenom.trim(),
      nom: nom.trim(),
      numero: numeroNettoye,
      groupe: groupe.trim().isEmpty ? 'Sans groupe' : groupe.trim(),
      categorie: categorie == null || categorie.trim().isEmpty
          ? null
          : categorie.trim(),
    );
    participants = [...participants, participant];
    _journaliser('${participant.nomComplet}: participant ajouté manuellement.');
    _notifierEtSauvegarder();
    return null;
  }

  void importerCsv(String contenuCsv) {
    final lignes = contenuCsv
        .split(RegExp(r'\r?\n'))
        .map((ligne) => ligne.trim())
        .where((ligne) => ligne.isNotEmpty)
        .toList();

    final nouveaux = <Participant>[];
    for (final ligne in lignes.skip(1)) {
      final colonnes = ligne.split(';');
      nouveaux.add(Participant.depuisCsv(colonnes));
    }
    if (nouveaux.isNotEmpty) {
      participants = nouveaux;
      resultats.clear();
      _pileAnnulation.clear();
      _journaliser('${nouveaux.length} participants importés depuis CSV.');
      _notifierEtSauvegarder();
    }
  }

  int importerXlsx(Uint8List bytes) {
    final excel = Excel.decodeBytes(bytes);
    if (excel.tables.isEmpty) return 0;

    final feuille = excel.tables.values.first;
    final lignes = feuille.rows;
    if (lignes.isEmpty) return 0;

    final entetes = lignes.first
        .map((cellule) => _normaliserEntete(_texteCellule(cellule?.value)))
        .toList();
    final indexPrenom = _indexEntete(entetes, const ['prenom', 'imie']);
    final indexNom = _indexEntete(entetes, const ['nom', 'nazwisko']);
    final indexNumero =
        _indexEntete(entetes, const ['numero', 'nr', 'dossard']);
    final indexGroupe = _indexEntete(entetes, const ['groupe', 'grupa']);
    final indexCategorie =
        _indexEntete(entetes, const ['categorie', 'kategoria']);

    final nouveaux = <Participant>[];
    for (var index = 1; index < lignes.length; index++) {
      final ligne = lignes[index];
      final prenom = _valeurXlsx(ligne, indexPrenom >= 0 ? indexPrenom : 0);
      final nom = _valeurXlsx(ligne, indexNom >= 0 ? indexNom : 1);
      final numero = _valeurXlsx(ligne, indexNumero >= 0 ? indexNumero : 2);
      final groupe = _valeurXlsx(ligne, indexGroupe >= 0 ? indexGroupe : 3);
      final categorie =
          _valeurXlsx(ligne, indexCategorie >= 0 ? indexCategorie : 4);
      if (prenom.isEmpty && nom.isEmpty && numero.isEmpty) continue;

      final numeroFinal =
          numero.isEmpty ? (nouveaux.length + 1).toString() : numero;
      nouveaux.add(
        Participant(
          id: 'xlsx-$numeroFinal-${DateTime.now().microsecondsSinceEpoch}-$index',
          prenom: prenom,
          nom: nom,
          numero: numeroFinal,
          groupe: groupe.isEmpty ? 'Sans groupe' : groupe,
          categorie: categorie.isEmpty ? null : categorie,
        ),
      );
    }

    if (nouveaux.isEmpty) return 0;
    participants = nouveaux;
    resultats.clear();
    _pileAnnulation.clear();
    _journaliser('${nouveaux.length} participants importés depuis XLSX.');
    _notifierEtSauvegarder();
    return nouveaux.length;
  }

  void viderParticipants() {
    participants = [];
    resultats.clear();
    _pileAnnulation.clear();
    _journaliser('Tous les participants ont été supprimés.');
    _notifierEtSauvegarder();
  }

  String exporterCsv() {
    final buffer = StringBuffer()
      ..writeln(
          'prenom;nom;numero;groupe;section;activite;temps;note;rang;statut');
    for (final ligne in resultatsClasses) {
      final participant = ligne.$1;
      final resultat = ligne.$2;
      buffer.writeln([
        participant.prenom,
        participant.nom,
        participant.numero,
        participant.groupe,
        sectionCourante?.id ?? '',
        activiteCourante?.id ?? '',
        resultat.temps == null ? '' : formatDuration(resultat.temps!),
        resultat.note?.toString() ?? '',
        resultat.rang?.toString() ?? '',
        resultat.statut.label,
      ].join(';'));
    }
    return buffer.toString();
  }

  Future<String> exporterXlsx() async {
    final excel = Excel.createExcel();
    excel.rename('Sheet1', 'Resultats');
    const feuille = 'Resultats';
    excel.appendRow(feuille, [
      TextCellValue('Prénom'),
      TextCellValue('Nom'),
      TextCellValue('Numéro'),
      TextCellValue('Groupe'),
      TextCellValue('Catégorie'),
      TextCellValue('Section'),
      TextCellValue('Activité'),
      TextCellValue('Temps'),
      TextCellValue('Note'),
      TextCellValue('Rang'),
      TextCellValue('Statut'),
    ]);

    for (final ligne in resultatsClasses) {
      final participant = ligne.$1;
      final resultat = ligne.$2;
      excel.appendRow(feuille, [
        TextCellValue(participant.prenom),
        TextCellValue(participant.nom),
        TextCellValue(participant.numero),
        TextCellValue(participant.groupe),
        TextCellValue(participant.categorie ?? ''),
        TextCellValue(sectionCourante?.id ?? ''),
        TextCellValue(activiteCourante?.id ?? ''),
        TextCellValue(
            resultat.temps == null ? '' : formatDuration(resultat.temps!)),
        resultat.note == null ? null : IntCellValue(resultat.note!),
        resultat.rang == null ? null : IntCellValue(resultat.rang!),
        TextCellValue(resultat.statut.label),
      ]);
    }

    final bytes = excel.encode();
    if (bytes == null) {
      throw StateError('Impossible de créer le fichier XLSX.');
    }
    final horodatage =
        DateTime.now().toIso8601String().replaceAll(RegExp(r'[:.]'), '-');
    return FileSaver.instance.saveFile(
      name: 'resultats_chronometrage_$horodatage',
      bytes: Uint8List.fromList(bytes),
      fileExtension: 'xlsx',
      mimeType: MimeType.microsoftExcel,
    );
  }

  Future<String> telechargerModeleParticipantsXlsx() async {
    final excel = Excel.createExcel();
    excel.rename('Sheet1', 'Participants');
    const feuille = 'Participants';
    excel.appendRow(feuille, [
      TextCellValue('Prénom'),
      TextCellValue('Nom'),
      TextCellValue('Numéro'),
      TextCellValue('Groupe'),
      TextCellValue('Catégorie'),
    ]);
    excel.appendRow(feuille, [
      TextCellValue('Jean'),
      TextCellValue('Dupont'),
      TextCellValue('101'),
      TextCellValue('Groupe 1'),
      TextCellValue('Senior'),
    ]);
    excel.appendRow(feuille, [
      TextCellValue('Marie'),
      TextCellValue('Martin'),
      TextCellValue('102'),
      TextCellValue('Groupe 1'),
      TextCellValue('Senior'),
    ]);

    final bytes = excel.encode();
    if (bytes == null) {
      throw StateError('Impossible de créer le modèle XLSX.');
    }
    return FileSaver.instance.saveFile(
      name: 'modele_participants_chronometrage',
      bytes: Uint8List.fromList(bytes),
      fileExtension: 'xlsx',
      mimeType: MimeType.microsoftExcel,
    );
  }

  void _recalculerNotes() {
    final activite = activiteCourante;
    if (activite == null) return;
    for (final entree in resultats.entries.toList()) {
      final resultat = entree.value;
      if (resultat.temps != null) {
        resultats[entree.key] =
            resultat.copie(note: activite.notePourTemps(resultat.temps!));
      }
    }
    _journaliser(
        'Notes recalculées pour ${sectionCourante?.id ?? '-'} / ${activite.id}.');
  }

  Future<void> _chargerSession() async {
    final prefs = await SharedPreferences.getInstance();
    final brut = prefs.getString(_cleSession);
    if (brut == null || brut.isEmpty) return;

    final donnees = jsonDecode(brut) as Map<String, dynamic>;
    final participantsJson = donnees['participants'] as List<dynamic>? ?? [];
    final resultatsJson = donnees['resultats'] as List<dynamic>? ?? [];

    final participantsCharges = participantsJson
        .whereType<Map>()
        .map((json) => Participant.fromJson(Map<String, dynamic>.from(json)))
        .where((participant) => participant.id.isNotEmpty)
        .toList();
    if (participantsCharges.isNotEmpty) {
      participants = participantsCharges;
    }

    resultats
      ..clear()
      ..addEntries(
        resultatsJson.whereType<Map>().map((json) {
          final resultat =
              ResultatParticipant.fromJson(Map<String, dynamic>.from(json));
          return MapEntry(resultat.participantId, resultat);
        }).where((entry) => entry.key.isNotEmpty),
      );

    final sectionSauvegardee = donnees['sectionSelectionnee'] as String?;
    if (sectionSauvegardee != null &&
        sections.any((section) => section.id == sectionSauvegardee)) {
      sectionSelectionnee = sectionSauvegardee;
    }
    final activiteSauvegardee = donnees['activiteSelectionnee'] as String?;
    final section = sectionCourante;
    if (activiteSauvegardee != null &&
        section != null &&
        section.activites
            .any((activite) => activite.id == activiteSauvegardee)) {
      activiteSelectionnee = activiteSauvegardee;
    }

    _recalculerNotes();
    sessionChargee = true;
  }

  Future<void> _chargerBaremesModifies() async {
    final prefs = await SharedPreferences.getInstance();
    final brut = prefs.getString(_cleBaremes);
    if (brut == null || brut.isEmpty) return;

    final donnees = jsonDecode(brut) as Map<String, dynamic>;
    final sectionsJson = donnees['sections'] as List<dynamic>? ?? [];
    final sectionsChargees = sectionsJson
        .whereType<Map>()
        .map((json) => BaremeSection.fromJson(Map<String, dynamic>.from(json)))
        .where((section) => section.id.isNotEmpty)
        .toList();
    if (sectionsChargees.isNotEmpty) {
      sections = List.unmodifiable(sectionsChargees);
    }
  }

  Future<void> _sauvegarderSession() async {
    final prefs = await SharedPreferences.getInstance();
    final donnees = {
      'version': 1,
      'sectionSelectionnee': sectionSelectionnee,
      'activiteSelectionnee': activiteSelectionnee,
      'participants':
          participants.map((participant) => participant.toJson()).toList(),
      'resultats':
          resultats.values.map((resultat) => resultat.toJson()).toList(),
    };
    await prefs.setString(_cleSession, jsonEncode(donnees));
  }

  Future<void> _sauvegarderBaremes() async {
    final prefs = await SharedPreferences.getInstance();
    final donnees = {
      'version': 1,
      'sections': sections.map((section) => section.toJson()).toList(),
    };
    await prefs.setString(_cleBaremes, jsonEncode(donnees));
  }

  void _notifierEtSauvegarder() {
    unawaited(_sauvegarderSession());
    notifyListeners();
  }

  static int _indexEntete(List<String> entetes, List<String> alias) {
    return entetes.indexWhere((entete) => alias.contains(entete));
  }

  static String _valeurXlsx(List<Data?> ligne, int index) {
    if (index < 0 || index >= ligne.length) return '';
    return _texteCellule(ligne[index]?.value).trim();
  }

  static String _texteCellule(CellValue? valeur) {
    return switch (valeur) {
      null => '',
      TextCellValue value => value.value.text ?? '',
      IntCellValue value => value.value.toString(),
      DoubleCellValue value => value.value.toString(),
      BoolCellValue value => value.value ? 'true' : 'false',
      FormulaCellValue value => value.formula,
      TimeCellValue value => value.toString(),
      DateCellValue value => value.toString(),
      DateTimeCellValue value => value.toString(),
    };
  }

  static String _normaliserEntete(String valeur) {
    return valeur
        .trim()
        .toLowerCase()
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('ó', 'o')
        .replaceAll('ł', 'l')
        .replaceAll('ń', 'n')
        .replaceAll('ą', 'a')
        .replaceAll('ę', 'e')
        .replaceAll('ś', 's')
        .replaceAll('ć', 'c')
        .replaceAll('ź', 'z')
        .replaceAll('ż', 'z')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '');
  }

  void _journaliser(String message) {
    historique.insert(
        0, EntreeHistorique(date: DateTime.now(), message: message));
    if (historique.length > 100) historique.removeLast();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

String formatDuration(Duration duration) {
  final heures = duration.inHours.toString().padLeft(2, '0');
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final secondes = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  final millisecondes =
      duration.inMilliseconds.remainder(1000).toString().padLeft(3, '0');
  return '$heures:$minutes:$secondes.$millisecondes';
}

Duration? parseTemps(String valeur) {
  final texte = valeur.trim().replaceAll(',', '.');
  final matchComplet =
      RegExp(r'^(\d{1,2}):(\d{2}):(\d{2})(?:\.(\d{1,3}))?$').firstMatch(texte);
  if (matchComplet != null) {
    final heures = int.parse(matchComplet.group(1)!);
    final minutes = int.parse(matchComplet.group(2)!);
    final secondes = int.parse(matchComplet.group(3)!);
    final millisecondes =
        (matchComplet.group(4) ?? '0').padRight(3, '0').substring(0, 3);
    return Duration(
      hours: heures,
      minutes: minutes,
      seconds: secondes,
      milliseconds: int.parse(millisecondes),
    );
  }

  final ancienFormat =
      RegExp(r'^(\d{1,2}):(\d{2})(?:\.(\d{1,3}))?$').firstMatch(texte);
  if (ancienFormat == null) return null;
  final minutes = int.parse(ancienFormat.group(1)!);
  final secondes = int.parse(ancienFormat.group(2)!);
  final millisecondes =
      (ancienFormat.group(3) ?? '0').padRight(3, '0').substring(0, 3);
  return Duration(
    minutes: minutes,
    seconds: secondes,
    milliseconds: int.parse(millisecondes),
  );
}
