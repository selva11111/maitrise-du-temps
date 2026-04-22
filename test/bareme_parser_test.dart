import 'package:chronometrage_arrivee/src/application/app_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronometrage_arrivee/src/data/bareme_parser.dart';
import 'package:chronometrage_arrivee/src/domain/models.dart';

void main() {
  test('parse un bareme de temps simple', () {
    final section = BaremeParser().analyser(
      chemin: 'FG1.txt',
      contenu: '''
BAREMES
MARCHE COMMANDO
20 : t <= 40"
19 : 40" < t <= 41"
0  : 59" < t
''',
    );

    expect(section.id, 'FG1');
    expect(section.activites, hasLength(1));
    final activite = section.activites.first;
    expect(activite.id, '8KMTAP');
    expect(activite.notePourTemps(const Duration(seconds: 40)), 20);
    expect(activite.notePourTemps(const Duration(milliseconds: 40500)), 19);
    expect(activite.notePourTemps(const Duration(seconds: 60)), 0);
  });

  test('parse les valeurs de hauteur', () {
    final section = BaremeParser().analyser(
      chemin: 'FG1.txt',
      contenu: '''
GRIMPER
5 : 5 m
4 : 5m >= h >= 4m
0 : 1m > h
''',
    );

    final activite = section.activites.first;
    expect(activite.notePourValeur(5, TypeMesure.hauteur), 5);
    expect(activite.notePourValeur(4.5, TypeMesure.hauteur), 4);
    expect(activite.notePourValeur(0.9, TypeMesure.hauteur), 0);
  });

  test('formatte et parse les temps avec millisecondes', () {
    const temps = Duration(hours: 1, minutes: 2, seconds: 3, milliseconds: 45);
    expect(formatDuration(temps), '01:02:03.045');
    expect(parseTemps('01:02:03.045'), temps);
    expect(parseTemps('02:03.4'),
        const Duration(minutes: 2, seconds: 3, milliseconds: 400));
  });
}
