import 'package:flutter_test/flutter_test.dart';
import 'package:medistock/services/medication_api_service.dart';

void main() {
  group('MedicationApiService.parsePresentationLibelle', () {
    test('plaquette de 16 comprimés', () {
      final r = MedicationApiService.parsePresentationLibelle('Plaquette(s) de 16 comprimé(s)', null);
      expect(r.$1, 'Plaquette');
      expect(r.$2, 16);
    });

    test('boîte de 30 comprimés', () {
      final r = MedicationApiService.parsePresentationLibelle('Boîte de 30 comprimé(s)', null);
      expect(r.$1, 'Boîte');
      expect(r.$2, 30);
    });

    test('30 comprimés sans préfixe', () {
      final r = MedicationApiService.parsePresentationLibelle('30 comprimés', null);
      expect(r.$1, 'Comprimé');
      expect(r.$2, 30);
    });

    test('sachets', () {
      final r = MedicationApiService.parsePresentationLibelle('10 sachet(s)', null);
      expect(r.$1, 'Sachet');
      expect(r.$2, 10);
    });

    test('ml / flacon', () {
      final r = MedicationApiService.parsePresentationLibelle('Flacon de 125 ml', null);
      expect(r.$1, 'Flacon');
      expect(r.$2, 125);
    });

    test('empty returns null', () {
      final r = MedicationApiService.parsePresentationLibelle('', null);
      expect(r.$1, isNull);
      expect(r.$2, isNull);
    });
  });
}
