import 'package:flutter_test/flutter_test.dart';
import 'package:mydeck/core/utils/deck_exporter.dart';
import 'package:mydeck/models/card_item.dart';
import 'package:mydeck/models/deck.dart';

void main() {
  group('CardItem & Pricing Tests', () {
    test('Calculates non-foil and foil pricing correctly', () {
      final cardNonFoil = CardItem(
        id: '1',
        scryfallId: 's1',
        name: 'Sol Ring',
        priceUsd: 1.50,
        priceUsdFoil: 4.00,
        isFoil: false,
        quantity: 2,
      );

      expect(cardNonFoil.currentPriceUsd, 1.50);
      expect(cardNonFoil.totalPriceUsd, 3.00);

      final cardFoil = cardNonFoil.copyWith(isFoil: true);
      expect(cardFoil.currentPriceUsd, 4.00);
      expect(cardFoil.totalPriceUsd, 8.00);
    });

    test('Correctly identifies card categories', () {
      final creature = CardItem(
        id: '1',
        scryfallId: 's1',
        name: 'Atraxa',
        typeLine: 'Legendary Creature — Phyrexian Angel',
      );
      expect(creature.category, 'Criaturas');

      final land = CardItem(
        id: '2',
        scryfallId: 's2',
        name: 'Watery Grave',
        typeLine: 'Land — Island Swamp',
      );
      expect(land.category, 'Tierras');
    });
  });

  group('Deck Metrics & Exporter Tests', () {
    final testDeck = Deck(
      id: 'd1',
      name: 'Test Commander Deck',
      format: 'Commander',
      cards: [
        CardItem(
          id: 'c1',
          scryfallId: 'sc1',
          name: 'Sol Ring',
          typeLine: 'Artifact',
          cmc: 1,
          setCode: 'CMM',
          collectorNumber: '401',
          priceUsd: 2.00,
          priceUsdFoil: 5.00,
          isFoil: false,
          quantity: 1,
        ),
        CardItem(
          id: 'c2',
          scryfallId: 'sc2',
          name: 'Lightning Bolt',
          typeLine: 'Instant',
          cmc: 1,
          setCode: 'J22',
          collectorNumber: '561',
          priceUsd: 1.00,
          priceUsdFoil: 3.00,
          isFoil: true,
          quantity: 2,
        ),
      ],
    );

    test('Deck totals are accurate', () {
      expect(testDeck.totalCards, 3);
      // Sol ring non-foil ($2) + 2x Lightning Bolt foil ($3 * 2 = $6) = $8.00
      expect(testDeck.totalPriceUsd, 8.00);
    });

    test('Moxfield export generates valid formatted lines', () {
      final moxfield = DeckExporter.toMoxfieldText(testDeck);
      expect(moxfield, contains('1 Sol Ring (cmm) 401'));
      expect(moxfield, contains('2 Lightning Bolt (j22) 561 *F*'));
    });

    test('Share payload generates and imports back correctly', () {
      final payload = DeckExporter.generateSharePayload(testDeck);
      expect(payload, startsWith('mydeck://import?data='));

      final imported = DeckExporter.importFromSharePayload(payload);
      expect(imported, isNotNull);
      expect(imported!.name, testDeck.name);
      expect(imported.cards.length, testDeck.cards.length);
      expect(imported.totalCards, testDeck.totalCards);
    });
  });
}
