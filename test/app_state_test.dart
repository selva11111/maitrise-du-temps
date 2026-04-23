import 'package:chronometrage_arrivee/src/application/app_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('sauvegarde et recharge une modification locale de bareme', () async {
    SharedPreferences.setMockInitialValues({});
    final state = ChronometrageState();
    await state.initialiser();

    final section = state.sections.firstWhere(
      (section) =>
          section.activites.any((activite) => activite.regles.isNotEmpty),
    );
    final activite = section.activites.firstWhere(
      (activite) => activite.regles.isNotEmpty,
    );
    final regle = activite.regles.first;
    final nouvelleNote = regle.note == 20 ? 19 : 20;

    await state.mettreAJourRegleBareme(
      sectionId: section.id,
      activiteId: activite.id,
      regleIndex: 0,
      regle: regle.copie(note: nouvelleNote),
    );

    final reloaded = ChronometrageState();
    await reloaded.initialiser();
    final sectionRechargee =
        reloaded.sections.firstWhere((candidate) => candidate.id == section.id);
    final activiteRechargee = sectionRechargee.activites
        .firstWhere((candidate) => candidate.id == activite.id);

    expect(activiteRechargee.regles.first.note, nouvelleNote);
  });

  test('stocke et recharge localement le mot de passe admin', () async {
    SharedPreferences.setMockInitialValues({});
    final state = ChronometrageState();
    await state.initialiser();

    expect(
      state.verifierMotDePasseAdmin('Castelnaudary2026+'),
      isTrue,
    );

    final erreur = await state.changerMotDePasseAdmin(
      motDePasseActuel: 'Castelnaudary2026+',
      nouveauMotDePasse: 'ChronoAdmin2026!',
      confirmation: 'ChronoAdmin2026!',
    );

    expect(erreur, isNull);
    expect(state.verifierMotDePasseAdmin('ChronoAdmin2026!'), isTrue);
    expect(state.verifierMotDePasseAdmin('Castelnaudary2026+'), isFalse);

    final reloaded = ChronometrageState();
    await reloaded.initialiser();

    expect(reloaded.verifierMotDePasseAdmin('ChronoAdmin2026!'), isTrue);
    expect(reloaded.verifierMotDePasseAdmin('Castelnaudary2026+'), isFalse);
  });
}
