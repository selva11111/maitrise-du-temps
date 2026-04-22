import '../domain/models.dart';

const fichiersBaremes = [
  'FG1.txt',
  'FGE.txt',
  'FS1-OO.txt',
  'FTS .txt',
];

final participantsDemo = <Participant>[
  const Participant(
    id: '101',
    prenom: 'Antoine',
    nom: 'Martin',
    numero: '101',
    groupe: 'Peloton 1',
    categorie: 'Senior',
  ),
  const Participant(
    id: '102',
    prenom: 'Camille',
    nom: 'Bernard',
    numero: '102',
    groupe: 'Peloton 1',
    categorie: 'Senior',
  ),
  const Participant(
    id: '201',
    prenom: 'Lucas',
    nom: 'Petit',
    numero: '201',
    groupe: 'Peloton 2',
    categorie: 'Senior',
  ),
  const Participant(
    id: '202',
    prenom: 'Sarah',
    nom: 'Moreau',
    numero: '202',
    groupe: 'Peloton 2',
    categorie: 'Senior',
  ),
];
