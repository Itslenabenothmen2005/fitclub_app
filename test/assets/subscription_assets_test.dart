import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('all subscription and welcome image assets are bundled', () async {
    const assets = [
      'assets/Bienvenue.png',
      'assets/pilates.png',
      'assets/musculation.png',
      'assets/tennis.png',
      'assets/enfant.png',
      'assets/yoga.png',
      'assets/full accés.png',
      'assets/boxe.jpg',
    ];

    for (final asset in assets) {
      final image = await rootBundle.load(asset);
      expect(image.lengthInBytes, greaterThan(0), reason: asset);
    }
  });
}
