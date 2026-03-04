import 'package:flutter_test/flutter_test.dart';
import 'package:medistock/models/medication.dart';

void main() {
  group('Medication alert logic', () {
    test('estPerime when date in past', () {
      final m = Medication(
        codeScanned: '1',
        nom: 'Test',
        quantite: 1,
        datePeremption: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(m.estPerime, isTrue);
      expect(m.estBientotPerime, isFalse);
    });

    test('estBientotPerime when within 30 days', () {
      final m = Medication(
        codeScanned: '1',
        nom: 'Test',
        quantite: 1,
        datePeremption: DateTime.now().add(const Duration(days: 15)),
      );
      expect(m.estPerime, isFalse);
      expect(m.estBientotPerime, isTrue);
    });

    test('stockFaible when quantite <= seuilAlerte', () {
      final m = Medication(
        codeScanned: '1',
        nom: 'Test',
        quantite: 2,
        seuilAlerte: 3,
      );
      expect(m.stockFaible, isTrue);
    });

    test('stockFaible false when quantite > seuilAlerte', () {
      final m = Medication(
        codeScanned: '1',
        nom: 'Test',
        quantite: 5,
        seuilAlerte: 3,
      );
      expect(m.stockFaible, isFalse);
    });
  });
}
