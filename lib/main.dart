import 'package:flutter/material.dart';

import 'src/application/app_state.dart';
import 'src/presentation/chronometrage_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _DemarrageApp());
}

class _DemarrageApp extends StatefulWidget {
  const _DemarrageApp();

  @override
  State<_DemarrageApp> createState() => _DemarrageAppState();
}

class _DemarrageAppState extends State<_DemarrageApp> {
  late final Future<ChronometrageState> _chargement = _charger();

  Future<ChronometrageState> _charger() async {
    final state = ChronometrageState();
    await state.initialiser();
    return state;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ChronometrageState>(
      future: _chargement,
      builder: (context, snapshot) {
        final state = snapshot.data;
        if (state != null) {
          return ChronometrageApp(state: state);
        }
        return const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: _EcranDemarrage(),
        );
      },
    );
  }
}

class _EcranDemarrage extends StatelessWidget {
  const _EcranDemarrage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xff0f5a35),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image(
              image: AssetImage('4re.png'),
              width: 176,
              height: 176,
            ),
            SizedBox(height: 18),
            Text(
              'Maîtrise du Temps',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 20),
            SizedBox(
              width: 180,
              child: LinearProgressIndicator(
                backgroundColor: Colors.white24,
                color: Color(0xffb32024),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
