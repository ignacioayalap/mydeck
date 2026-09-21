import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../core/utils/deck_exporter.dart';
import '../models/card_item.dart';
import '../models/deck.dart';
import '../services/storage_service.dart';

class DeckProvider extends ChangeNotifier {
  static const _uuid = Uuid();
  List<Deck> _decks = [];
  Deck? _selectedDeck;
  bool _isLoading = true;
  String? _errorMessage;

  List<Deck> get decks => _decks;
  Deck? get selectedDeck => _selectedDeck;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  DeckProvider() {
    loadDecks();
  }

  Future<void> loadDecks() async {
    _isLoading = true;
    notifyListeners();
    try {
      _decks = await StorageService.getDecks();
      if (_selectedDeck != null) {
        final match = _decks.where((d) => d.id == _selectedDeck!.id);
        if (match.isNotEmpty) {
          _selectedDeck = match.first;
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectDeck(Deck deck) {
    _selectedDeck = deck;
    notifyListeners();
  }

  Future<Deck> createDeck({
    required String name,
    String description = '',
    String format = 'Commander',
    String coverImageUrl = '',
  }) async {
    final newDeck = Deck(
      id: 'deck_${_uuid.v4()}',
      name: name.trim().isEmpty ? 'Nuevo Mazo' : name.trim(),
      description: description.trim(),
      format: format,
      coverImageUrl: coverImageUrl,
      cards: [],
    );

    _decks.insert(0, newDeck);
    _selectedDeck = newDeck;
    await StorageService.saveDecks(_decks);
    notifyListeners();
    return newDeck;
  }

  Future<void> updateDeck(Deck updatedDeck) async {
    final index = _decks.indexWhere((d) => d.id == updatedDeck.id);
    if (index != -1) {
      _decks[index] = updatedDeck.copyWith(updatedAt: DateTime.now());
      if (_selectedDeck?.id == updatedDeck.id) {
        _selectedDeck = _decks[index];
      }
      await StorageService.saveDecks(_decks);
      notifyListeners();
    }
  }

  Future<void> deleteDeck(String deckId) async {
    _decks.removeWhere((d) => d.id == deckId);
    if (_selectedDeck?.id == deckId) {
      _selectedDeck = _decks.isNotEmpty ? _decks.first : null;
    }
    await StorageService.saveDecks(_decks);
    notifyListeners();
  }

  Future<void> duplicateDeck(Deck deck) async {
    final copy = deck.copyWith(
      id: 'deck_${_uuid.v4()}',
      name: '${deck.name} (Copia)',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _decks.insert(0, copy);
    await StorageService.saveDecks(_decks);
    notifyListeners();
  }

  Future<void> addCardToDeck({
    required String deckId,
    required CardItem card,
  }) async {
    final deckIndex = _decks.indexWhere((d) => d.id == deckId);
    if (deckIndex == -1) return;

    final currentDeck = _decks[deckIndex];
    final updatedCards = List<CardItem>.from(currentDeck.cards);

    // Check if same card with same foil status already exists
    final existingIndex = updatedCards.indexWhere(
      (c) => (c.scryfallId == card.scryfallId || c.name.toLowerCase() == card.name.toLowerCase()) &&
             c.isFoil == card.isFoil,
    );

    if (existingIndex != -1) {
      // Increment quantity
      final existing = updatedCards[existingIndex];
      updatedCards[existingIndex] = existing.copyWith(
        quantity: existing.quantity + card.quantity,
      );
    } else {
      // Add new card copy with unique ID
      updatedCards.add(card.copyWith(id: 'c_${_uuid.v4()}'));
    }

    final updatedDeck = currentDeck.copyWith(
      cards: updatedCards,
      coverImageUrl: currentDeck.coverImageUrl.isEmpty ? card.artCropUrl : currentDeck.coverImageUrl,
      updatedAt: DateTime.now(),
    );

    _decks[deckIndex] = updatedDeck;
    if (_selectedDeck?.id == deckId) {
      _selectedDeck = updatedDeck;
    }

    await StorageService.saveDecks(_decks);
    notifyListeners();
  }

  Future<void> removeCardFromDeck(String deckId, String cardId) async {
    final deckIndex = _decks.indexWhere((d) => d.id == deckId);
    if (deckIndex == -1) return;

    final currentDeck = _decks[deckIndex];
    final updatedCards = currentDeck.cards.where((c) => c.id != cardId).toList();

    final updatedDeck = currentDeck.copyWith(
      cards: updatedCards,
      updatedAt: DateTime.now(),
    );

    _decks[deckIndex] = updatedDeck;
    if (_selectedDeck?.id == deckId) {
      _selectedDeck = updatedDeck;
    }

    await StorageService.saveDecks(_decks);
    notifyListeners();
  }

  Future<void> updateCardQuantity(String deckId, String cardId, int newQuantity) async {
    if (newQuantity <= 0) {
      await removeCardFromDeck(deckId, cardId);
      return;
    }

    final deckIndex = _decks.indexWhere((d) => d.id == deckId);
    if (deckIndex == -1) return;

    final currentDeck = _decks[deckIndex];
    final updatedCards = currentDeck.cards.map((c) {
      if (c.id == cardId) {
        return c.copyWith(quantity: newQuantity);
      }
      return c;
    }).toList();

    final updatedDeck = currentDeck.copyWith(
      cards: updatedCards,
      updatedAt: DateTime.now(),
    );

    _decks[deckIndex] = updatedDeck;
    if (_selectedDeck?.id == deckId) {
      _selectedDeck = updatedDeck;
    }

    await StorageService.saveDecks(_decks);
    notifyListeners();
  }

  Future<void> toggleCardFoil(String deckId, String cardId) async {
    final deckIndex = _decks.indexWhere((d) => d.id == deckId);
    if (deckIndex == -1) return;

    final currentDeck = _decks[deckIndex];
    final updatedCards = currentDeck.cards.map((c) {
      if (c.id == cardId) {
        return c.copyWith(isFoil: !c.isFoil);
      }
      return c;
    }).toList();

    final updatedDeck = currentDeck.copyWith(
      cards: updatedCards,
      updatedAt: DateTime.now(),
    );

    _decks[deckIndex] = updatedDeck;
    if (_selectedDeck?.id == deckId) {
      _selectedDeck = updatedDeck;
    }

    await StorageService.saveDecks(_decks);
    notifyListeners();
  }

  /// Import a shared deck from code or URL
  Future<Deck?> importDeckFromCode(String codeOrUrl) async {
    final imported = DeckExporter.importFromSharePayload(codeOrUrl);
    if (imported != null) {
      final newDeck = imported.copyWith(
        id: 'deck_${_uuid.v4()}',
        name: '${imported.name} (Importado)',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _decks.insert(0, newDeck);
      await StorageService.saveDecks(_decks);
      notifyListeners();
      return newDeck;
    }
    return null;
  }
}
