import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../application/app_state.dart';
import '../domain/models.dart';

class ChronometrageApp extends StatelessWidget {
  const ChronometrageApp({super.key, required this.state});

  final ChronometrageState state;

  @override
  Widget build(BuildContext context) {
    const vertLegion = Color(0xff0f5a35);
    const rougeLegion = Color(0xffb32024);
    const vertFond = Color(0xffedf5ee);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Maîtrise du Temps',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: vertLegion,
          primary: vertLegion,
          secondary: rougeLegion,
          tertiary: const Color(0xffd9b45f),
          surface: vertFond,
          surfaceContainerHighest: const Color(0xccdcefe1),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xdd0f5a35),
          foregroundColor: Colors.white,
          surfaceTintColor: vertLegion,
        ),
        scaffoldBackgroundColor: vertFond,
        hoverColor: rougeLegion.withValues(alpha: 0.14),
        highlightColor: rougeLegion.withValues(alpha: 0.18),
        popupMenuTheme: PopupMenuThemeData(
          color: const Color(0xf2edf5ee),
          surfaceTintColor: vertLegion,
          textStyle: const TextStyle(color: Color(0xff143c2a)),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.focused)) {
              return const TextStyle(
                color: rougeLegion,
                fontWeight: FontWeight.w700,
              );
            }
            return const TextStyle(color: Color(0xff143c2a));
          }),
        ),
        iconButtonTheme: IconButtonThemeData(
          style: ButtonStyle(
            overlayColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.hovered) ||
                  states.contains(WidgetState.pressed)) {
                return rougeLegion.withValues(alpha: 0.22);
              }
              return null;
            }),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: rougeLegion,
            overlayColor: Colors.white.withValues(alpha: 0.16),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: ButtonStyle(
            foregroundColor: const WidgetStatePropertyAll(vertLegion),
            overlayColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.hovered) ||
                  states.contains(WidgetState.pressed)) {
                return rougeLegion.withValues(alpha: 0.14);
              }
              return null;
            }),
          ),
        ),
        useMaterial3: true,
        visualDensity: VisualDensity.standard,
      ),
      home: _AccueilChronometrage(state: state),
    );
  }
}

class _AccueilChronometrage extends StatelessWidget {
  const _AccueilChronometrage({required this.state});

  final ChronometrageState state;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          leadingWidth: 66,
          leading: const Padding(
            padding: EdgeInsets.all(6),
            child: _LogoApp(taille: 46),
          ),
          title: const Text(
            'Maîtrise du Temps',
            overflow: TextOverflow.ellipsis,
          ),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'Chronomètre'),
              Tab(text: 'Résultats'),
              Tab(text: 'Journal'),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Ajouter un participant',
              onPressed: () => _ouvrirAjoutParticipantSecurise(context),
              icon: const Icon(Icons.person_add_alt_1),
            ),
            PopupMenuButton<String>(
              tooltip: 'Fichiers et participants',
              onSelected: (action) async {
                await Future<void>.delayed(const Duration(milliseconds: 80));
                if (!context.mounted) return;
                if (action == 'xlsx-template') _telechargerModeleXlsx(context);
                if (action == 'xlsx-import') _importerXlsx(context);
                if (action == 'xlsx-export') _exporterXlsx(context);
                if (action == 'weather') _ouvrirMeteo(context);
                if (action == 'admin-settings') {
                  _ouvrirParametresAdminSecurises(context);
                }
                if (action == 'about') _ouvrirAPropos(context);
                if (action == 'clear-participants') {
                  _confirmerViderParticipants(context);
                }
                if (action == 'csv-import') _ouvrirImportCsv(context);
                if (action == 'csv-export') _ouvrirExportCsv(context);
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'xlsx-template',
                  child: Text('Télécharger modèle XLSX'),
                ),
                PopupMenuItem(
                  value: 'xlsx-import',
                  child: Text('Importer XLSX'),
                ),
                PopupMenuItem(
                  value: 'xlsx-export',
                  child: Text('Exporter XLSX'),
                ),
                PopupMenuItem(
                  value: 'weather',
                  child: Text('Météo Castelnaudary'),
                ),
                PopupMenuItem(
                  value: 'admin-settings',
                  child: Text('Paramètres administrateur'),
                ),
                PopupMenuItem(
                  value: 'about',
                  child: Text('Politique et contact'),
                ),
                PopupMenuDivider(),
                PopupMenuItem(
                  value: 'clear-participants',
                  child: Text('Vider les participants'),
                ),
                PopupMenuDivider(),
                PopupMenuItem(
                  value: 'csv-import',
                  child: Text('Importer CSV'),
                ),
                PopupMenuItem(
                  value: 'csv-export',
                  child: Text('Exporter CSV'),
                ),
              ],
            ),
          ],
        ),
        body: AnimatedBuilder(
          animation: state,
          builder: (context, _) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final mobile = constraints.maxWidth < 720;
                return Column(
                  children: [
                    if (mobile)
                      _PanneauContexteRepliable(state: state)
                    else
                      _BarreContexte(state: state),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _EcranChronometre(state: state),
                          _EcranResultats(state: state),
                          _EcranJournal(state: state),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _telechargerModeleXlsx(BuildContext context) async {
    try {
      final chemin = await state.telechargerModeleParticipantsXlsx();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Modèle XLSX enregistré: $chemin')),
      );
    } catch (erreur) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Téléchargement du modèle impossible: $erreur')),
      );
    }
  }

  Future<void> _ouvrirMeteo(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Météo Castelnaudary 11400'),
          content: SizedBox(
            width: 360,
            child: FutureBuilder<_MeteoCastelnaudary>(
              future: _MeteoCastelnaudary.charger(),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return Text('Météo indisponible: ${snapshot.error}');
                }
                final meteo = snapshot.requireData;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${meteo.temperature.toStringAsFixed(1)} °C',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text('Vent: ${meteo.vent.toStringAsFixed(1)} km/h'),
                    Text('Humidité: ${meteo.humidite}%'),
                    Text('Précipitations: ${meteo.precipitation} mm'),
                    Text('Conditions: ${meteo.description}'),
                    const SizedBox(height: 8),
                    Text('Mise à jour: ${meteo.dateLocale}'),
                  ],
                );
              },
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _importerXlsx(BuildContext context) async {
    final fichier = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['xlsx'],
      withData: true,
    );
    final bytes = fichier?.files.single.bytes;
    if (bytes == null) return;

    try {
      final nombre = state.importerXlsx(bytes);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$nombre participants importés depuis XLSX.')),
      );
    } catch (erreur) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import XLSX impossible: $erreur')),
      );
    }
  }

  Future<void> _confirmerViderParticipants(BuildContext context) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Vider les participants'),
          content: const Text(
            'Tous les noms, participants et résultats seront supprimés de la session sauvegardée.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Vider'),
            ),
          ],
        );
      },
    );
    if (confirme != true) return;
    state.viderParticipants();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Liste des participants vidée.')),
      );
    }
  }

  // ignore: unused_element
  Future<void> _ouvrirAjoutParticipant(BuildContext context) async {
    final prenom = TextEditingController();
    final nom = TextEditingController();
    final numero = TextEditingController();
    final groupe = TextEditingController();
    final categorie = TextEditingController();

    final donnees = await showDialog<
        ({
          String prenom,
          String nom,
          String numero,
          String groupe,
          String categorie
        })>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ajouter un participant'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: prenom,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                      labelText: 'Prénom', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: nom,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                      labelText: 'Nom', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: numero,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                      labelText: 'Numéro', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: groupe,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                      labelText: 'Groupe', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: categorie,
                  decoration: const InputDecoration(
                      labelText: 'Catégorie', border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler')),
            FilledButton(
              onPressed: () => Navigator.pop(
                context,
                (
                  prenom: prenom.text,
                  nom: nom.text,
                  numero: numero.text,
                  groupe: groupe.text,
                  categorie: categorie.text,
                ),
              ),
              child: const Text('Ajouter'),
            ),
          ],
        );
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      prenom.dispose();
      nom.dispose();
      numero.dispose();
      groupe.dispose();
      categorie.dispose();
    });

    if (donnees == null) return;
    final erreur = state.ajouterParticipant(
      prenom: donnees.prenom,
      nom: donnees.nom,
      numero: donnees.numero,
      groupe: donnees.groupe,
      categorie: donnees.categorie,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(erreur ?? 'Participant ajouté et session sauvegardée.')),
      );
    }
  }

  Future<void> _ouvrirImportCsv(BuildContext context) async {
    final controller = TextEditingController(
      text: 'prenom;nom;numero;groupe;categorie\n'
          'Nadia;Durand;301;Peloton 3;Senior\n'
          'Hugo;Leroy;302;Peloton 3;Senior',
    );
    final contenu = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Importer des participants'),
          content: SizedBox(
            width: 560,
            child: TextField(
              controller: controller,
              minLines: 8,
              maxLines: 14,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'CSV séparé par des points-virgules',
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Importer'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (contenu != null) state.importerCsv(contenu);
  }

  Future<void> _exporterXlsx(BuildContext context) async {
    try {
      final chemin = await state.exporterXlsx();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fichier XLSX enregistré: $chemin')),
      );
    } catch (erreur) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export XLSX impossible: $erreur')),
      );
    }
  }

  Future<void> _ouvrirExportCsv(BuildContext context) async {
    final csv = state.exporterCsv();
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Export CSV'),
          content: SizedBox(
            width: 680,
            child: SelectableText(csv),
          ),
          actions: [
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: csv));
                Navigator.pop(context);
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copier'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  // ignore: unused_element
  Future<void> _ouvrirAdministrationBaremesLegacy(BuildContext context) async {
    final motDePasse = TextEditingController();
    final autorise = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Administration barèmes'),
          content: SizedBox(
            width: 360,
            child: TextField(
              controller: motDePasse,
              autofocus: true,
              obscureText: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Mot de passe administrateur',
              ),
              onSubmitted: (_) => Navigator.pop(
                context,
                state.verifierMotDePasseAdmin(motDePasse.text),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                context,
                state.verifierMotDePasseAdmin(motDePasse.text),
              ),
              child: const Text('Ouvrir'),
            ),
          ],
        );
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      motDePasse.dispose();
    });
    if (!context.mounted || autorise == null) return;
    if (!autorise) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mot de passe incorrect.')),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) => _DialogueAdministrationBaremes(state: state),
    );
  }

  Future<void> _ouvrirAPropos(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Politique et contact'),
          content: const SingleChildScrollView(
            child: SizedBox(
              width: 380,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: _LogoApp(taille: 108)),
                  SizedBox(height: 16),
                  Text(
                    'Maîtrise du Temps',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text('Application créée par _STAN_ pour le 4RE.'),
                  SizedBox(height: 8),
                  Text(
                    'Les participants, temps, résultats et barèmes modifiés sont conservés localement sur cet appareil.',
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Aucune liste de participants n’est envoyée par l’application. La météo utilise uniquement le service Open-Meteo pour Castelnaudary.',
                  ),
                  SizedBox(height: 8),
                  Text(
                    'En cas de problème, de question ou de besoin d’assistance, veuillez me contacter.',
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () => _envoyerMessageContact(context),
              icon: const Icon(Icons.mail_outline),
              label: const Text('Envoyer un message'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _envoyerMessageContact(BuildContext context) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final uri = Uri(
      scheme: 'mailto',
      path: 'instructeur.selva@gmail.com',
      queryParameters: {
        'subject': 'Maîtrise du Temps - assistance',
      },
    );
    final ouvert = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (ouvert) return;

    await Clipboard.setData(
      const ClipboardData(text: 'instructeur.selva@gmail.com'),
    );
    messenger?.showSnackBar(
      const SnackBar(
        content: Text('Adresse e-mail copiée: instructeur.selva@gmail.com'),
      ),
    );
  }

  Future<void> _ouvrirAjoutParticipantSecurise(BuildContext context) async {
    final donnees = await showDialog<
        ({
          String prenom,
          String nom,
          String numero,
          String groupe,
          String categorie
        })>(
      context: context,
      builder: (_) => const _DialogueAjoutParticipant(),
    );
    if (donnees == null || !context.mounted) return;

    final erreur = state.ajouterParticipant(
      prenom: donnees.prenom,
      nom: donnees.nom,
      numero: donnees.numero,
      groupe: donnees.groupe,
      categorie: donnees.categorie,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(erreur ?? 'Participant ajouté et session sauvegardée.'),
      ),
    );
  }

  Future<void> _ouvrirParametresAdminSecurises(BuildContext context) async {
    final autorise = await showDialog<bool>(
      context: context,
      builder: (_) => _DialogueMotDePasseAdmin(state: state),
    );
    if (!context.mounted || autorise == null) return;
    if (!autorise) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mot de passe incorrect.')),
      );
      return;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _EcranParametresAdmin(state: state),
      ),
    );
  }

  // ignore: unused_element
  Future<void> _ouvrirAdministrationBaremes(
    BuildContext context,
  ) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _EcranAdministrationBaremes(state: state),
      ),
    );
  }
}

class _EcranParametresAdmin extends StatelessWidget {
  const _EcranParametresAdmin({required this.state});

  final ChronometrageState state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres administrateur')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Espace réservé aux fonctions sensibles: accès aux barèmes, sécurité administrateur et opérations système.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            _CarteActionAdmin(
              icone: Icons.rule_folder_outlined,
              titre: 'Administration barèmes',
              description:
                  'Modifier les règles de notation, les seuils et les bornes de chaque activité.',
              onTap: () => _ouvrirAdministrationBaremes(context),
            ),
            const SizedBox(height: 12),
            _CarteActionAdmin(
              icone: Icons.lock_reset,
              titre: 'Changer le mot de passe admin',
              description:
                  'Mettre à jour le mot de passe administrateur enregistré localement sous forme d’empreinte.',
              onTap: () => _ouvrirChangementMotDePasse(context),
            ),
            const SizedBox(height: 12),
            _CarteActionAdmin(
              icone: Icons.verified_user_outlined,
              titre: 'Sécurité locale',
              description:
                  'Le mot de passe administrateur est stocké localement sous forme de hash SHA-256. Les barèmes restent enregistrés sur cet appareil.',
              onTap: null,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _ouvrirAdministrationBaremes(BuildContext context) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _EcranAdministrationBaremes(state: state),
      ),
    );
  }

  Future<void> _ouvrirChangementMotDePasse(BuildContext context) async {
    final changeEffectue = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _EcranChangementMotDePasseAdmin(state: state),
      ),
    );
    if (changeEffectue != true || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mot de passe administrateur mis à jour.'),
      ),
    );
  }
}

class _CarteActionAdmin extends StatelessWidget {
  const _CarteActionAdmin({
    required this.icone,
    required this.titre,
    required this.description,
    required this.onTap,
  });

  final IconData icone;
  final String titre;
  final String description;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icone, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titre,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(description),
                  ],
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EcranAdministrationBaremes extends StatefulWidget {
  const _EcranAdministrationBaremes({required this.state});

  final ChronometrageState state;

  @override
  State<_EcranAdministrationBaremes> createState() =>
      _EcranAdministrationBaremesState();
}

class _EcranAdministrationBaremesState
    extends State<_EcranAdministrationBaremes> {
  late String? _sectionId =
      widget.state.sectionCourante?.id ?? _premiereSection()?.id;
  late String? _activiteId = _premiereActivite(_sectionSelectionnee)?.id;

  BaremeSection? _premiereSection() {
    return widget.state.sections.isEmpty ? null : widget.state.sections.first;
  }

  BaremeActivite? _premiereActivite(BaremeSection? section) {
    if (section == null || section.activites.isEmpty) return null;
    return section.activites.first;
  }

  BaremeSection? get _sectionSelectionnee {
    for (final section in widget.state.sections) {
      if (section.id == _sectionId) return section;
    }
    return _premiereSection();
  }

  BaremeActivite? get _activiteSelectionnee {
    final section = _sectionSelectionnee;
    if (section == null) return null;
    for (final activite in section.activites) {
      if (activite.id == _activiteId) return activite;
    }
    return _premiereActivite(section);
  }

  @override
  Widget build(BuildContext context) {
    final section = _sectionSelectionnee;
    final activite = _activiteSelectionnee;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administration barèmes'),
        actions: [
          IconButton(
            tooltip: 'Rafraîchir les barèmes',
            onPressed: _rafraichirBaremes,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Restaurer les barèmes',
            onPressed: _restaurerBaremes,
            icon: const Icon(Icons.restore),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: 260,
                    child: DropdownButtonFormField<String>(
                      initialValue: _sectionId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Domaine',
                      ),
                      items: widget.state.sections
                          .map((item) => DropdownMenuItem(
                                value: item.id,
                                child: Text(
                                  item.nom,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _sectionId = value;
                          _activiteId =
                              _premiereActivite(_sectionSelectionnee)?.id;
                        });
                      },
                    ),
                  ),
                  SizedBox(
                    width: 360,
                    child: DropdownButtonFormField<String>(
                      initialValue: activite?.id,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Activité',
                      ),
                      items: (section?.activites ?? [])
                          .map((item) => DropdownMenuItem(
                                value: item.id,
                                child: Text(
                                  item.nom,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ))
                          .toList(),
                      onChanged: (value) => setState(() => _activiteId = value),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _rafraichirBaremes,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Rafraîchir les barèmes'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _restaurerBaremes,
                    icon: const Icon(Icons.restore),
                    label: const Text('Restaurer les barèmes'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Les modifications sont sauvegardées localement et recalculent immédiatement les notes déjà saisies.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: activite == null
                    ? const Center(child: Text('Aucune activité disponible.'))
                    : ListView.separated(
                        itemCount: activite.regles.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final regle = activite.regles[index];
                          return ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              child: Text(regle.note.toString()),
                            ),
                            title: Text(
                              '${_libelleTypeMesure(regle.type)}  ${_formatValeurBareme(regle, regle.minimum)} - ${_formatValeurBareme(regle, regle.maximum)}',
                            ),
                            subtitle: Text(
                              'Min ${regle.minimumInclus ? 'inclus' : 'exclu'} - Max ${regle.maximumInclus ? 'inclus' : 'exclu'}',
                            ),
                            trailing: IconButton(
                              tooltip: 'Modifier la règle',
                              icon: const Icon(Icons.edit),
                              onPressed: () => _modifierRegle(index, regle),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _modifierRegle(int index, RegleBareme regle) async {
    final activite = _activiteSelectionnee;
    final section = _sectionSelectionnee;
    if (activite == null || section == null) return;
    final regleModifiee = await Navigator.of(context).push<RegleBareme>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _EcranEditionRegleBareme(
          regle: regle,
          typeParDefaut: activite.typePrincipal,
        ),
      ),
    );
    if (regleModifiee == null || !mounted) return;

    await widget.state.mettreAJourRegleBareme(
      sectionId: section.id,
      activiteId: activite.id,
      regleIndex: index,
      regle: regleModifiee,
    );
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Barème modifié et sauvegardé.')),
    );
  }

  Future<void> _restaurerBaremes() async {
    final confirmer = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restaurer les barèmes'),
        content: const Text(
          'Toutes les modifications locales des barèmes seront supprimées.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restaurer'),
          ),
        ],
      ),
    );
    if (confirmer != true) return;
    await widget.state.reinitialiserBaremes();
    if (!mounted) return;
    setState(() {
      _sectionId = widget.state.sectionCourante?.id;
      _activiteId = widget.state.activiteCourante?.id;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Barèmes restaurés.')),
    );
  }

  Future<void> _rafraichirBaremes() async {
    await widget.state.rechargerBaremesEnregistres();
    if (!mounted) return;
    setState(() {
      _sectionId = widget.state.sectionCourante?.id;
      _activiteId = widget.state.activiteCourante?.id;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Barèmes rechargés depuis le stockage local.'),
      ),
    );
  }
}

class _EcranEditionRegleBareme extends StatefulWidget {
  const _EcranEditionRegleBareme({
    required this.regle,
    required this.typeParDefaut,
  });

  final RegleBareme regle;
  final TypeMesure typeParDefaut;

  @override
  State<_EcranEditionRegleBareme> createState() =>
      _EcranEditionRegleBaremeState();
}

class _EcranEditionRegleBaremeState extends State<_EcranEditionRegleBareme> {
  late final TextEditingController _note = TextEditingController(
    text: widget.regle.note.toString(),
  );
  late final TextEditingController _minimum = TextEditingController(
    text: _formatValeurBareme(widget.regle, widget.regle.minimum),
  );
  late final TextEditingController _maximum = TextEditingController(
    text: _formatValeurBareme(widget.regle, widget.regle.maximum),
  );
  late TypeMesure _type = widget.regle.type == TypeMesure.inconnue
      ? widget.typeParDefaut
      : widget.regle.type;
  late bool _minimumInclus = widget.regle.minimumInclus;
  late bool _maximumInclus = widget.regle.maximumInclus;
  String? _erreur;

  @override
  void dispose() {
    _note.dispose();
    _minimum.dispose();
    _maximum.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Modifier une règle')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _note,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Note',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<TypeMesure>(
                    initialValue: _type,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Type de mesure',
                    ),
                    items: TypeMesure.values
                        .where((type) => type != TypeMesure.inconnue)
                        .map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(_libelleTypeMesure(type)),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _type = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _minimum,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: 'Minimum',
                      hintText:
                          _type == TypeMesure.temps ? 'HH:MM:SS.mmm' : '0',
                    ),
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Minimum inclus'),
                    value: _minimumInclus,
                    onChanged: (value) {
                      setState(() => _minimumInclus = value ?? false);
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _maximum,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _valider(),
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: 'Maximum',
                      hintText:
                          _type == TypeMesure.temps ? 'HH:MM:SS.mmm' : '0',
                    ),
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Maximum inclus'),
                    value: _maximumInclus,
                    onChanged: (value) {
                      setState(() => _maximumInclus = value ?? false);
                    },
                  ),
                  if (_erreur != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _erreur!,
                      style:
                          TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Annuler'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _valider,
                          child: const Text('Sauvegarder'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _valider() {
    final note = int.tryParse(_note.text.trim());
    final minimum = _parseValeurBareme(_type, _minimum.text);
    final maximum = _parseValeurBareme(_type, _maximum.text);
    if (note == null || note < 0 || note > 20) {
      setState(() => _erreur = 'La note doit être comprise entre 0 et 20.');
      return;
    }
    if (_minimum.text.trim().isNotEmpty && minimum == null) {
      setState(() => _erreur = 'Minimum invalide.');
      return;
    }
    if (_maximum.text.trim().isNotEmpty && maximum == null) {
      setState(() => _erreur = 'Maximum invalide.');
      return;
    }
    if (minimum != null && maximum != null && minimum > maximum) {
      setState(() => _erreur = 'Le minimum ne peut pas dépasser le maximum.');
      return;
    }

    Navigator.pop(
      context,
      widget.regle.copie(
        note: note,
        type: _type,
        minimum: minimum,
        maximum: maximum,
        minimumInclus: _minimumInclus,
        maximumInclus: _maximumInclus,
      ),
    );
  }
}

class _EcranChangementMotDePasseAdmin extends StatefulWidget {
  const _EcranChangementMotDePasseAdmin({required this.state});

  final ChronometrageState state;

  @override
  State<_EcranChangementMotDePasseAdmin> createState() =>
      _EcranChangementMotDePasseAdminState();
}

class _EcranChangementMotDePasseAdminState
    extends State<_EcranChangementMotDePasseAdmin> {
  final _actuel = TextEditingController();
  final _nouveau = TextEditingController();
  final _confirmation = TextEditingController();
  String? _erreur;
  bool _enCours = false;
  bool _afficherActuel = false;
  bool _afficherNouveau = false;
  bool _afficherConfirmation = false;

  @override
  void dispose() {
    _actuel.dispose();
    _nouveau.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Changer mot de passe admin')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Le mot de passe administrateur est stocké localement sous forme d’empreinte de sécurité.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Exigences: 12 caractères minimum, avec majuscule, minuscule, chiffre et caractère spécial.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _actuel,
                    obscureText: !_afficherActuel,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: 'Mot de passe actuel',
                      suffixIcon: IconButton(
                        onPressed: () =>
                            setState(() => _afficherActuel = !_afficherActuel),
                        icon: Icon(
                          _afficherActuel
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nouveau,
                    obscureText: !_afficherNouveau,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: 'Nouveau mot de passe',
                      suffixIcon: IconButton(
                        onPressed: () => setState(
                          () => _afficherNouveau = !_afficherNouveau,
                        ),
                        icon: Icon(
                          _afficherNouveau
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _confirmation,
                    obscureText: !_afficherConfirmation,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _valider(),
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: 'Confirmer le nouveau mot de passe',
                      suffixIcon: IconButton(
                        onPressed: () => setState(
                          () => _afficherConfirmation = !_afficherConfirmation,
                        ),
                        icon: Icon(
                          _afficherConfirmation
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                      ),
                    ),
                  ),
                  if (_erreur != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _erreur!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _enCours
                              ? null
                              : () => Navigator.of(context).pop(false),
                          child: const Text('Annuler'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _enCours ? null : _valider,
                          child: Text(
                            _enCours ? 'Mise à jour...' : 'Mettre à jour',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _valider() async {
    setState(() {
      _erreur = null;
      _enCours = true;
    });
    final erreur = await widget.state.changerMotDePasseAdmin(
      motDePasseActuel: _actuel.text,
      nouveauMotDePasse: _nouveau.text,
      confirmation: _confirmation.text,
    );
    if (!mounted) return;
    if (erreur != null) {
      setState(() {
        _erreur = erreur;
        _enCours = false;
      });
      return;
    }
    Navigator.of(context).pop(true);
  }
}

class _DialogueAjoutParticipant extends StatefulWidget {
  const _DialogueAjoutParticipant();

  @override
  State<_DialogueAjoutParticipant> createState() =>
      _DialogueAjoutParticipantState();
}

class _DialogueAjoutParticipantState extends State<_DialogueAjoutParticipant> {
  final _prenom = TextEditingController();
  final _nom = TextEditingController();
  final _numero = TextEditingController();
  final _groupe = TextEditingController();
  final _categorie = TextEditingController();

  @override
  void dispose() {
    _prenom.dispose();
    _nom.dispose();
    _numero.dispose();
    _groupe.dispose();
    _categorie.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter un participant'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _prenom,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Prénom',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _nom,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Nom',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _numero,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Numéro',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _groupe,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Groupe',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _categorie,
              decoration: const InputDecoration(
                labelText: 'Catégorie',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop((
            prenom: _prenom.text,
            nom: _nom.text,
            numero: _numero.text,
            groupe: _groupe.text,
            categorie: _categorie.text,
          )),
          child: const Text('Ajouter'),
        ),
      ],
    );
  }
}

class _DialogueMotDePasseAdmin extends StatefulWidget {
  const _DialogueMotDePasseAdmin({required this.state});

  final ChronometrageState state;

  @override
  State<_DialogueMotDePasseAdmin> createState() =>
      _DialogueMotDePasseAdminState();
}

class _DialogueMotDePasseAdminState extends State<_DialogueMotDePasseAdmin> {
  final _motDePasse = TextEditingController();

  @override
  void dispose() {
    _motDePasse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Administration barèmes'),
      content: SizedBox(
        width: 360,
        child: TextField(
          controller: _motDePasse,
          autofocus: true,
          obscureText: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Mot de passe administrateur',
          ),
          onSubmitted: (_) => _valider(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _valider,
          child: const Text('Ouvrir'),
        ),
      ],
    );
  }

  void _valider() {
    Navigator.of(context).pop(
      widget.state.verifierMotDePasseAdmin(_motDePasse.text),
    );
  }
}

class _PanneauContexteRepliable extends StatelessWidget {
  const _PanneauContexteRepliable({required this.state});

  final ChronometrageState state;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
      child: ExpansionTile(
        initiallyExpanded: false,
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        childrenPadding: EdgeInsets.zero,
        collapsedBackgroundColor: const Color(0xccdcefe1),
        backgroundColor: const Color(0xccdcefe1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        collapsedShape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        leading: const Icon(Icons.tune),
        title: Text(
          '${state.sectionCourante?.id ?? '-'} / ${state.activiteCourante?.nom ?? '-'}',
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: const Text('Menu domaine et activité'),
        children: [
          _BarreContexte(state: state, compact: true),
        ],
      ),
    );
  }
}

class _RechercheParticipants extends StatelessWidget {
  const _RechercheParticipants({required this.state});

  final ChronometrageState state;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: state.definirRecherche,
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.search),
        labelText: 'Filtrer par nom ou numéro',
        border: OutlineInputBorder(),
        isDense: true,
      ),
    );
  }
}

class _BarreContexte extends StatelessWidget {
  const _BarreContexte({required this.state, this.compact = false});

  final ChronometrageState state;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final section = state.sectionCourante;
    final activites = section?.activites ?? [];
    final couleurs = Theme.of(context).colorScheme;
    return Container(
      margin:
          compact ? EdgeInsets.zero : const EdgeInsets.fromLTRB(12, 12, 12, 4),
      decoration: BoxDecoration(
        color: const Color(0xccdcefe1),
        border: Border.all(color: couleurs.primary.withValues(alpha: 0.22)),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: couleurs.primary.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: compact ? const EdgeInsets.all(10) : const EdgeInsets.all(12),
        child: Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: compact ? 300 : 190,
              child: DropdownButtonFormField<String>(
                initialValue: state.sectionSelectionnee,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Section',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: state.sections
                    .map((section) => DropdownMenuItem(
                          value: section.id,
                          child: Text(section.nom,
                              overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    _changerSection(context, value);
                  }
                },
              ),
            ),
            SizedBox(
              width: compact ? 300 : 280,
              child: DropdownButtonFormField<String>(
                initialValue: state.activiteCourante?.id,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Activité',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: activites
                    .map((activite) => DropdownMenuItem(
                          value: activite.id,
                          child: Text(activite.nom,
                              overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    _changerActivite(context, value);
                  }
                },
              ),
            ),
            Chip(
              avatar: const Icon(Icons.rule, size: 18),
              label: Text(
                  '${state.activiteCourante?.regles.length ?? 0} règles chargées'),
            ),
            if (state.alertesBaremes.isNotEmpty)
              Chip(
                avatar: const Icon(Icons.warning_amber, size: 18),
                label: Text('${state.alertesBaremes.length} lignes à vérifier'),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _changerSection(BuildContext context, String id) async {
    if (id == state.sectionSelectionnee) return;
    if (!await _confirmerChangementPendantChrono(context)) return;
    state.choisirSection(id);
  }

  Future<void> _changerActivite(BuildContext context, String id) async {
    if (id == state.activiteSelectionnee) return;
    if (!await _confirmerChangementPendantChrono(context)) return;
    state.choisirActivite(id);
  }

  Future<bool> _confirmerChangementPendantChrono(BuildContext context) async {
    if (!state.estEnCours) return true;
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Chronomètre en cours'),
          content: const Text(
            'Changer de domaine ou d’activité pendant une mesure peut recalculer les notes des résultats déjà saisis. Continuer ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirmer'),
            ),
          ],
        );
      },
    );
    return confirme == true;
  }
}

class _DialogueAdministrationBaremes extends StatefulWidget {
  const _DialogueAdministrationBaremes({required this.state});

  final ChronometrageState state;

  @override
  State<_DialogueAdministrationBaremes> createState() =>
      _DialogueAdministrationBaremesState();
}

class _DialogueAdministrationBaremesState
    extends State<_DialogueAdministrationBaremes> {
  late String? _sectionId =
      widget.state.sectionCourante?.id ?? _premiereSection()?.id;
  late String? _activiteId = _premiereActivite(_sectionSelectionnee)?.id;

  BaremeSection? _premiereSection() {
    return widget.state.sections.isEmpty ? null : widget.state.sections.first;
  }

  BaremeActivite? _premiereActivite(BaremeSection? section) {
    if (section == null || section.activites.isEmpty) return null;
    return section.activites.first;
  }

  BaremeSection? get _sectionSelectionnee {
    for (final section in widget.state.sections) {
      if (section.id == _sectionId) return section;
    }
    return _premiereSection();
  }

  BaremeActivite? get _activiteSelectionnee {
    final section = _sectionSelectionnee;
    if (section == null) return null;
    for (final activite in section.activites) {
      if (activite.id == _activiteId) return activite;
    }
    return _premiereActivite(section);
  }

  @override
  Widget build(BuildContext context) {
    final section = _sectionSelectionnee;
    final activite = _activiteSelectionnee;
    return AlertDialog(
      title: const Text('Administration barèmes'),
      content: SizedBox(
        width: 820,
        height: 620,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: [
                SizedBox(
                  width: 240,
                  child: DropdownButtonFormField<String>(
                    initialValue: _sectionId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Domaine',
                    ),
                    items: widget.state.sections
                        .map((section) => DropdownMenuItem(
                              value: section.id,
                              child: Text(
                                section.nom,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _sectionId = value;
                        _activiteId =
                            _premiereActivite(_sectionSelectionnee)?.id;
                      });
                    },
                  ),
                ),
                SizedBox(
                  width: 320,
                  child: DropdownButtonFormField<String>(
                    initialValue: activite?.id,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Activité',
                    ),
                    items: (section?.activites ?? [])
                        .map((activite) => DropdownMenuItem(
                              value: activite.id,
                              child: Text(
                                activite.nom,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() => _activiteId = value),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _rafraichirBaremes,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Rafraîchir les barèmes'),
                ),
                OutlinedButton.icon(
                  onPressed: _restaurerBaremes,
                  icon: const Icon(Icons.restore),
                  label: const Text('Restaurer les barèmes'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Les modifications sont sauvegardées localement et recalculent les notes déjà saisies.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: activite == null
                  ? const Center(child: Text('Aucune activité disponible.'))
                  : ListView.separated(
                      itemCount: activite.regles.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final regle = activite.regles[index];
                        return ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            child: Text(regle.note.toString()),
                          ),
                          title: Text(
                            '${_libelleTypeMesure(regle.type)}  ${_formatValeurBareme(regle, regle.minimum)} - ${_formatValeurBareme(regle, regle.maximum)}',
                          ),
                          subtitle: Text(
                            'Min ${regle.minimumInclus ? 'inclus' : 'exclu'} - Max ${regle.maximumInclus ? 'inclus' : 'exclu'}',
                          ),
                          trailing: IconButton(
                            tooltip: 'Modifier la règle',
                            icon: const Icon(Icons.edit),
                            onPressed: () => _modifierRegle(index, regle),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fermer'),
        ),
      ],
    );
  }

  Future<void> _modifierRegle(int index, RegleBareme regle) async {
    final activite = _activiteSelectionnee;
    final section = _sectionSelectionnee;
    if (activite == null || section == null) return;
    final messenger = ScaffoldMessenger.maybeOf(context);

    final regleModifiee = await showDialog<RegleBareme>(
      context: context,
      builder: (context) => _DialogueEditionRegleBareme(
        regle: regle,
        typeParDefaut: activite.typePrincipal,
      ),
    );
    if (regleModifiee == null) return;
    if (!mounted) return;

    await widget.state.mettreAJourRegleBareme(
      sectionId: section.id,
      activiteId: activite.id,
      regleIndex: index,
      regle: regleModifiee,
    );
    if (!mounted) return;
    setState(() {});
    messenger?.showSnackBar(
      const SnackBar(content: Text('Barème modifié et sauvegardé.')),
    );
  }

  Future<void> _restaurerBaremes() async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final confirmer = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restaurer les barèmes'),
        content: const Text(
          'Toutes les modifications locales des barèmes seront supprimées.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restaurer'),
          ),
        ],
      ),
    );
    if (confirmer != true) return;
    await widget.state.reinitialiserBaremes();
    if (!mounted) return;
    setState(() {
      _sectionId = widget.state.sectionCourante?.id;
      _activiteId = widget.state.activiteCourante?.id;
    });
    messenger?.showSnackBar(
      const SnackBar(content: Text('Barèmes restaurés.')),
    );
  }

  Future<void> _rafraichirBaremes() async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    await widget.state.rechargerBaremesEnregistres();
    if (!mounted) return;
    setState(() {
      _sectionId = widget.state.sectionCourante?.id;
      _activiteId = widget.state.activiteCourante?.id;
    });
    messenger?.showSnackBar(
      const SnackBar(
        content: Text('Barèmes rechargés depuis le stockage local.'),
      ),
    );
  }
}

class _DialogueEditionRegleBareme extends StatefulWidget {
  const _DialogueEditionRegleBareme({
    required this.regle,
    required this.typeParDefaut,
  });

  final RegleBareme regle;
  final TypeMesure typeParDefaut;

  @override
  State<_DialogueEditionRegleBareme> createState() =>
      _DialogueEditionRegleBaremeState();
}

class _DialogueEditionRegleBaremeState
    extends State<_DialogueEditionRegleBareme> {
  late final TextEditingController _note = TextEditingController(
    text: widget.regle.note.toString(),
  );
  late final TextEditingController _minimum = TextEditingController(
    text: _formatValeurBareme(widget.regle, widget.regle.minimum),
  );
  late final TextEditingController _maximum = TextEditingController(
    text: _formatValeurBareme(widget.regle, widget.regle.maximum),
  );
  late TypeMesure _type = widget.regle.type == TypeMesure.inconnue
      ? widget.typeParDefaut
      : widget.regle.type;
  late bool _minimumInclus = widget.regle.minimumInclus;
  late bool _maximumInclus = widget.regle.maximumInclus;
  String? _erreur;

  @override
  void dispose() {
    _note.dispose();
    _minimum.dispose();
    _maximum.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: const Text('Modifier une règle'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _note,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Note',
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<TypeMesure>(
                initialValue: _type,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Type de mesure',
                ),
                items: TypeMesure.values
                    .where((type) => type != TypeMesure.inconnue)
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(_libelleTypeMesure(type)),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _type = value);
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _minimum,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: 'Minimum',
                  hintText: _type == TypeMesure.temps ? 'HH:MM:SS.mmm' : '0',
                ),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Minimum inclus'),
                value: _minimumInclus,
                onChanged: (value) {
                  setState(() => _minimumInclus = value ?? false);
                },
              ),
              TextField(
                controller: _maximum,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _valider(),
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: 'Maximum',
                  hintText: _type == TypeMesure.temps ? 'HH:MM:SS.mmm' : '0',
                ),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Maximum inclus'),
                value: _maximumInclus,
                onChanged: (value) {
                  setState(() => _maximumInclus = value ?? false);
                },
              ),
              if (_erreur != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _erreur!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _valider,
          child: const Text('Sauvegarder'),
        ),
      ],
    );
  }

  void _valider() {
    final note = int.tryParse(_note.text.trim());
    final minimum = _parseValeurBareme(_type, _minimum.text);
    final maximum = _parseValeurBareme(_type, _maximum.text);
    if (note == null || note < 0 || note > 20) {
      setState(() => _erreur = 'La note doit être comprise entre 0 et 20.');
      return;
    }
    if (_minimum.text.trim().isNotEmpty && minimum == null) {
      setState(() => _erreur = 'Minimum invalide.');
      return;
    }
    if (_maximum.text.trim().isNotEmpty && maximum == null) {
      setState(() => _erreur = 'Maximum invalide.');
      return;
    }
    if (minimum != null && maximum != null && minimum > maximum) {
      setState(() => _erreur = 'Le minimum ne peut pas dépasser le maximum.');
      return;
    }

    Navigator.pop(
      context,
      widget.regle.copie(
        note: note,
        type: _type,
        minimum: minimum,
        maximum: maximum,
        minimumInclus: _minimumInclus,
        maximumInclus: _maximumInclus,
        effacerMinimum: minimum == null,
        effacerMaximum: maximum == null,
      ),
    );
  }
}

String _libelleTypeMesure(TypeMesure type) {
  return switch (type) {
    TypeMesure.temps => 'Temps',
    TypeMesure.distance => 'Distance',
    TypeMesure.hauteur => 'Hauteur',
    TypeMesure.validation => 'Validation',
    TypeMesure.inconnue => 'Inconnue',
  };
}

String _formatValeurBareme(RegleBareme regle, double? valeur) {
  if (valeur == null) return '';
  if (regle.type == TypeMesure.temps) {
    return formatDuration(Duration(milliseconds: (valeur * 1000).round()));
  }
  final entier = valeur.truncateToDouble() == valeur;
  return entier ? valeur.toInt().toString() : valeur.toStringAsFixed(2);
}

double? _parseValeurBareme(TypeMesure type, String valeur) {
  final texte = valeur.trim();
  if (texte.isEmpty) return null;
  if (type == TypeMesure.temps) {
    final temps = parseTemps(texte);
    return temps == null ? null : temps.inMilliseconds / 1000;
  }
  return double.tryParse(texte.replaceAll(',', '.'));
}

class _LogoApp extends StatelessWidget {
  const _LogoApp({required this.taille});

  final double taille;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      '4re.png',
      width: taille,
      height: taille,
      fit: BoxFit.contain,
    );
  }
}

class _EcranChronometre extends StatelessWidget {
  const _EcranChronometre({required this.state});

  final ChronometrageState state;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final large = constraints.maxWidth >= 860;
        if (large) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: 360, child: _PanneauChronometre(state: state)),
              Expanded(child: _ListeParticipants(state: state)),
            ],
          );
        }
        return Column(
          children: [
            _PanneauChronometre(state: state, compact: true),
            Expanded(child: _ListeParticipants(state: state)),
          ],
        );
      },
    );
  }
}

class _PanneauChronometre extends StatelessWidget {
  const _PanneauChronometre({required this.state, this.compact = false});

  final ChronometrageState state;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final couleur = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xccf5faf6),
        border: Border(
            right: BorderSide(color: couleur.primary.withValues(alpha: 0.18))),
      ),
      child: SingleChildScrollView(
        padding: compact
            ? const EdgeInsets.fromLTRB(10, 8, 10, 6)
            : const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (compact)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _RechercheParticipants(state: state),
              ),
            Text(
              formatDuration(state.tempsEcoule),
              textAlign: TextAlign.center,
              style: (compact
                      ? Theme.of(context).textTheme.headlineMedium
                      : Theme.of(context).textTheme.displayLarge)
                  ?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: compact ? 8 : 18),
            Wrap(
              spacing: compact ? 6 : 10,
              runSpacing: compact ? 6 : 10,
              alignment: WrapAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: state.estEnCours ? null : state.demarrer,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('START'),
                ),
                FilledButton.tonalIcon(
                  onPressed: state.estEnCours ? state.arreter : null,
                  icon: const Icon(Icons.stop),
                  label: const Text('STOP'),
                ),
                OutlinedButton.icon(
                  onPressed: state.reinitialiser,
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('RESET'),
                ),
              ],
            ),
            if (!compact) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: state.annulerDernierEnregistrement,
                icon: const Icon(Icons.undo),
                label: const Text('Annuler le dernier enregistrement'),
              ),
              const SizedBox(height: 16),
              _RechercheParticipants(state: state),
              const SizedBox(height: 16),
              Text(
                'Cliquez sur un participant pour enregistrer son temps courant. Le chronomètre principal continue après chaque clic.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ListeParticipants extends StatelessWidget {
  const _ListeParticipants({required this.state});

  final ChronometrageState state;

  @override
  Widget build(BuildContext context) {
    final participants = state.participantsFiltres;
    return ListView.separated(
      padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 720 ? 8 : 12),
      itemCount: participants.length,
      separatorBuilder: (_, __) =>
          SizedBox(height: MediaQuery.sizeOf(context).width < 720 ? 5 : 8),
      itemBuilder: (context, index) {
        final participant = participants[index];
        final resultat = state.resultats[participant.id];
        return _CarteParticipant(
          state: state,
          participant: participant,
          resultat: resultat,
        );
      },
    );
  }
}

class _CarteParticipant extends StatelessWidget {
  const _CarteParticipant({
    required this.state,
    required this.participant,
    required this.resultat,
  });

  final ChronometrageState state;
  final Participant participant;
  final ResultatParticipant? resultat;

  @override
  Widget build(BuildContext context) {
    final note = resultat?.note;
    final mobile = MediaQuery.sizeOf(context).width < 720;
    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white.withValues(alpha: 0.92),
      child: InkWell(
        onTap: state.estEnCours
            ? () => state.enregistrerArrivee(participant)
            : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.all(mobile ? 7 : 12),
          child: mobile
              ? _CarteParticipantMobile(
                  state: state,
                  participant: participant,
                  resultat: resultat,
                  note: note,
                )
              : _CarteParticipantLarge(
                  state: state,
                  participant: participant,
                  resultat: resultat,
                  note: note,
                ),
        ),
      ),
    );
  }
}

class _CarteParticipantMobile extends StatelessWidget {
  const _CarteParticipantMobile({
    required this.state,
    required this.participant,
    required this.resultat,
    required this.note,
  });

  final ChronometrageState state;
  final Participant participant;
  final ResultatParticipant? resultat;
  final int? note;

  @override
  Widget build(BuildContext context) {
    final couleurs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: couleurs.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            participant.numero,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: couleurs.primary,
                ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                participant.nom.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
              ),
              Text(
                participant.prenom,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 2),
              Wrap(
                spacing: 4,
                runSpacing: 2,
                children: [
                  if (resultat?.temps != null)
                    Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text(formatDuration(resultat!.temps!)),
                    ),
                  if (note != null)
                    Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text('Note $note'),
                    ),
                  Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text(resultat?.statut.label ?? 'En attente'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton(
              onPressed: state.estEnCours
                  ? () => state.enregistrerArrivee(participant)
                  : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size(66, 34),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                textStyle: Theme.of(context).textTheme.labelMedium,
              ),
              child: const Text('STOP'),
            ),
            IconButton(
              tooltip: 'Corriger le temps',
              visualDensity: VisualDensity.compact,
              onPressed: () => _ouvrirCorrectionTempsSecurise(
                context: context,
                state: state,
                participant: participant,
                resultat: resultat,
              ),
              icon: const Icon(Icons.edit),
            ),
          ],
        ),
      ],
    );
  }
}

class _CarteParticipantLarge extends StatelessWidget {
  const _CarteParticipantLarge({
    required this.state,
    required this.participant,
    required this.resultat,
    required this.note,
  });

  final ChronometrageState state;
  final Participant participant;
  final ResultatParticipant? resultat;
  final int? note;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 64,
          child: Text(
            participant.numero,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(participant.nomComplet,
                  style: Theme.of(context).textTheme.titleMedium),
              Text(participant.groupe),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  Chip(label: Text(resultat?.statut.label ?? 'En attente')),
                  if (resultat?.temps != null)
                    Chip(label: Text(formatDuration(resultat!.temps!))),
                  if (note != null) Chip(label: Text('Note $note/20')),
                ],
              ),
            ],
          ),
        ),
        Wrap(
          spacing: 6,
          children: [
            FilledButton(
              onPressed: state.estEnCours
                  ? () => state.enregistrerArrivee(participant)
                  : null,
              child: const Text('Arrivée'),
            ),
            IconButton(
              tooltip: 'Corriger le temps',
              onPressed: () => _ouvrirCorrectionTempsSecurise(
                context: context,
                state: state,
                participant: participant,
                resultat: resultat,
              ),
              icon: const Icon(Icons.edit),
            ),
            PopupMenuButton<StatutResultat>(
              tooltip: 'Changer le statut',
              onSelected: (statut) => state.modifierStatut(participant, statut),
              itemBuilder: (context) => StatutResultat.values
                  .where((statut) => statut != StatutResultat.enAttente)
                  .map((statut) =>
                      PopupMenuItem(value: statut, child: Text(statut.label)))
                  .toList(),
            ),
            IconButton(
              tooltip: 'Supprimer le resultat',
              onPressed: () => state.supprimerResultat(participant),
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ],
    );
  }
}

class _EcranResultats extends StatelessWidget {
  const _EcranResultats({required this.state});

  final ChronometrageState state;

  @override
  Widget build(BuildContext context) {
    final lignes = state.resultatsClasses;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStatePropertyAll(
          Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
        ),
        columns: const [
          DataColumn(label: Text('Rang')),
          DataColumn(label: Text('Numéro')),
          DataColumn(label: Text('Prenom')),
          DataColumn(label: Text('Nom')),
          DataColumn(label: Text('Groupe')),
          DataColumn(label: Text('Temps')),
          DataColumn(label: Text('Note')),
          DataColumn(label: Text('Statut')),
          DataColumn(label: Text('Action')),
        ],
        rows: lignes.map((ligne) {
          final participant = ligne.$1;
          final resultat = ligne.$2;
          return DataRow(
            cells: [
              DataCell(Text(resultat.rang?.toString() ?? '-')),
              DataCell(Text(participant.numero)),
              DataCell(Text(participant.prenom)),
              DataCell(Text(participant.nom)),
              DataCell(Text(participant.groupe)),
              DataCell(Text(resultat.temps == null
                  ? '-'
                  : formatDuration(resultat.temps!))),
              DataCell(Text(resultat.note?.toString() ?? '-')),
              DataCell(Text(resultat.statut.label)),
              DataCell(
                IconButton(
                  tooltip: 'Modifier ce résultat',
                  icon: const Icon(Icons.edit),
                  onPressed: () => _ouvrirCorrectionTempsSecurise(
                    context: context,
                    state: state,
                    participant: participant,
                    resultat: resultat,
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

Future<void> _ouvrirCorrectionTempsSecurise({
  required BuildContext context,
  required ChronometrageState state,
  required Participant participant,
  required ResultatParticipant? resultat,
}) async {
  final temps = await showDialog<Duration>(
    context: context,
    builder: (_) => _DialogueCorrectionTemps(
      participant: participant,
      resultat: resultat,
    ),
  );
  if (temps == null) return;
  state.modifierTemps(participant, temps);
}

class _DialogueCorrectionTemps extends StatefulWidget {
  const _DialogueCorrectionTemps({
    required this.participant,
    required this.resultat,
  });

  final Participant participant;
  final ResultatParticipant? resultat;

  @override
  State<_DialogueCorrectionTemps> createState() =>
      _DialogueCorrectionTempsState();
}

class _DialogueCorrectionTempsState extends State<_DialogueCorrectionTemps> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.resultat?.temps == null
        ? '00:00:00.000'
        : formatDuration(widget.resultat!.temps!),
  );
  String? _erreur;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Corriger ${widget.participant.nomComplet}'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Temps au format HH:MM:SS.mmm',
              ),
              onSubmitted: (_) => _valider(),
            ),
            if (_erreur != null) ...[
              const SizedBox(height: 10),
              Text(
                _erreur!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _valider,
          child: const Text('Valider'),
        ),
      ],
    );
  }

  void _valider() {
    final temps = parseTemps(_controller.text);
    if (temps == null) {
      setState(() {
        _erreur = 'Format invalide. Utilisez HH:MM:SS.mmm.';
      });
      return;
    }
    Navigator.of(context).pop(temps);
  }
}

// ignore: unused_element
Future<void> _ouvrirCorrectionTemps({
  required BuildContext context,
  required ChronometrageState state,
  required Participant participant,
  required ResultatParticipant? resultat,
}) async {
  final controller = TextEditingController(
    text: resultat?.temps == null
        ? '00:00:00.000'
        : formatDuration(resultat!.temps!),
  );
  final valeur = await showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Corriger ${participant.nomComplet}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Temps au format HH:MM:SS.mmm',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Valider'),
          ),
        ],
      );
    },
  );
  controller.dispose();
  if (valeur == null) return;

  final temps = parseTemps(valeur);
  if (temps == null) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Format invalide. Utilisez HH:MM:SS.mmm.')),
    );
    return;
  }
  state.modifierTemps(participant, temps);
}

class _MeteoCastelnaudary {
  const _MeteoCastelnaudary({
    required this.temperature,
    required this.vent,
    required this.humidite,
    required this.precipitation,
    required this.code,
    required this.dateLocale,
  });

  final double temperature;
  final double vent;
  final int humidite;
  final double precipitation;
  final int code;
  final String dateLocale;

  String get description {
    if (code == 0) return 'Ciel clair';
    if ([1, 2, 3].contains(code)) return 'Partiellement nuageux';
    if ([45, 48].contains(code)) return 'Brouillard';
    if ([51, 53, 55, 56, 57].contains(code)) return 'Bruine';
    if ([61, 63, 65, 66, 67, 80, 81, 82].contains(code)) return 'Pluie';
    if ([71, 73, 75, 77, 85, 86].contains(code)) return 'Neige';
    if ([95, 96, 99].contains(code)) return 'Orage';
    return 'Code météo $code';
  }

  static Future<_MeteoCastelnaudary> charger() async {
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': '43.318',
      'longitude': '1.954',
      'current':
          'temperature_2m,relative_humidity_2m,precipitation,weather_code,wind_speed_10m',
      'timezone': 'Europe/Paris',
    });
    final response = await http.get(uri).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }
    final donnees = jsonDecode(response.body) as Map<String, dynamic>;
    final current = donnees['current'] as Map<String, dynamic>;
    return _MeteoCastelnaudary(
      temperature: (current['temperature_2m'] as num).toDouble(),
      vent: (current['wind_speed_10m'] as num).toDouble(),
      humidite: (current['relative_humidity_2m'] as num).toInt(),
      precipitation: (current['precipitation'] as num).toDouble(),
      code: (current['weather_code'] as num).toInt(),
      dateLocale: current['time'] as String? ?? '-',
    );
  }
}

class _EcranJournal extends StatelessWidget {
  const _EcranJournal({required this.state});

  final ChronometrageState state;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (state.alertesBaremes.isNotEmpty) ...[
          Text('Lignes de barèmes à vérifier',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final alerte in state.alertesBaremes)
            ListTile(
                leading: const Icon(Icons.warning_amber), title: Text(alerte)),
          const Divider(),
        ],
        Text('Historique des modifications',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final entree in state.historique)
          ListTile(
            leading: const Icon(Icons.history),
            title: Text(entree.message),
            subtitle: Text(
                '${entree.date.hour.toString().padLeft(2, '0')}:${entree.date.minute.toString().padLeft(2, '0')}'),
          ),
      ],
    );
  }
}
