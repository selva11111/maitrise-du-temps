import 'package:chronometrage_arrivee/src/application/app_state.dart';
import 'package:chronometrage_arrivee/src/presentation/chronometrage_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('affiche l ecran principal de chronometrage', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final state = ChronometrageState();
    addTearDown(state.dispose);
    await state.initialiser();

    await tester.pumpWidget(ChronometrageApp(state: state));
    await tester.pump();

    expect(find.text('Maîtrise du Temps'), findsOneWidget);
    expect(find.text('START'), findsOneWidget);
    expect(find.text('STOP'), findsOneWidget);
    expect(find.text('RESET'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('ouvre le dialogue ajout participant sans erreur',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final state = ChronometrageState();
    addTearDown(state.dispose);
    await state.initialiser();

    await tester.pumpWidget(ChronometrageApp(state: state));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Ajouter un participant'));
    await tester.pumpAndSettle();

    expect(find.text('Ajouter un participant'), findsOneWidget);
    final champs = find.byType(TextField);
    await tester.enterText(champs.at(champs.evaluate().length - 5), 'Jean');
    await tester.enterText(champs.at(champs.evaluate().length - 4), 'Test');
    await tester.enterText(champs.at(champs.evaluate().length - 3), '999');
    await tester.tap(find.text('Ajouter').last);
    await tester.pump(const Duration(milliseconds: 600));

    expect(state.participants.any((participant) => participant.numero == '999'),
        isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('ouvre administration baremes depuis le menu sans erreur',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final state = ChronometrageState();
    addTearDown(state.dispose);
    await state.initialiser();

    await tester.pumpWidget(ChronometrageApp(state: state));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Fichiers et participants'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Administration barèmes'));
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pumpAndSettle();

    expect(find.text('Mot de passe administrateur'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'admin123');
    await tester.tap(find.widgetWithText(FilledButton, 'Ouvrir'));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Domaine'), findsOneWidget);
    await tester.tap(find.text('Fermer').last);
    await tester.pump(const Duration(milliseconds: 600));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('modifie une regle bareme depuis administration', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final state = ChronometrageState();
    addTearDown(state.dispose);
    await state.initialiser();
    final section = state.sections.firstWhere(
      (section) =>
          section.activites.any((activite) => activite.regles.isNotEmpty),
    );
    final activite = section.activites.firstWhere(
      (activite) => activite.regles.isNotEmpty,
    );
    state.choisirSection(section.id);
    state.choisirActivite(activite.id);
    final nouvelleNote = activite.regles.first.note == 20 ? 19 : 20;

    await tester.pumpWidget(ChronometrageApp(state: state));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Fichiers et participants'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Administration barèmes'));
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'admin123');
    await tester.tap(find.widgetWithText(FilledButton, 'Ouvrir'));
    await tester.pump(const Duration(milliseconds: 600));

    await tester.tap(find.byTooltip('Modifier la règle').first);
    await tester.pumpAndSettle();
    final champsEdition = find.byType(TextField);
    await tester.enterText(
      champsEdition.at(champsEdition.evaluate().length - 3),
      '$nouvelleNote',
    );
    await tester.tap(find.text('Sauvegarder'));
    await tester.pump(const Duration(milliseconds: 800));

    final sectionModifiee =
        state.sections.firstWhere((candidate) => candidate.id == section.id);
    final activiteModifiee = sectionModifiee.activites
        .firstWhere((candidate) => candidate.id == activite.id);
    expect(activiteModifiee.regles.first.note, nouvelleNote);

    await tester.tap(find.text('Fermer').last);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('corrige un resultat par le crayon sans erreur', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final state = ChronometrageState();
    addTearDown(state.dispose);
    await state.initialiser();
    final participant = state.participantsFiltres.first;
    state.modifierTemps(participant, const Duration(seconds: 10));

    await tester.pumpWidget(ChronometrageApp(state: state));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Corriger le temps').first);
    await tester.pumpAndSettle();
    expect(find.text('Corriger ${participant.nomComplet}'), findsOneWidget);

    final champs = find.byType(TextField);
    await tester.enterText(champs.last, '00:00:12.345');
    await tester.tap(find.widgetWithText(FilledButton, 'Valider').last);
    await tester.pump(const Duration(milliseconds: 800));

    expect(state.resultats[participant.id]?.temps,
        const Duration(seconds: 12, milliseconds: 345));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
