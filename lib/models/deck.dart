import 'card_item.dart';

class Deck {
  final String id;
  final String name;
  final String description;
  final String format; // Commander, Modern, Standard, Pioneer, Legacy, Casual
  final String coverImageUrl;
  final List<CardItem> cards;
  final DateTime createdAt;
  final DateTime updatedAt;

  Deck({
    required this.id,
    required this.name,
    this.description = '',
    this.format = 'Commander',
    this.coverImageUrl = '',
    this.cards = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Total count of cards (sum of all quantities)
  int get totalCards {
    return cards.fold<int>(0, (sum, card) => sum + card.quantity);
  }

  /// Total updated deck price in USD
  double get totalPriceUsd {
    return cards.fold<double>(0.0, (sum, card) => sum + card.totalPriceUsd);
  }

  /// Total updated deck price in EUR
  double get totalPriceEur {
    return cards.fold<double>(0.0, (sum, card) => sum + card.totalPriceEur);
  }

  /// Distinct colors present in the deck
  List<String> get colors {
    final Set<String> colorSet = {};
    for (final card in cards) {
      colorSet.addAll(card.colorIdentity);
    }
    return colorSet.toList();
  }

  /// Breakdown of cards by primary category
  Map<String, int> get categoryCounts {
    final Map<String, int> counts = {
      'Criaturas': 0,
      'Tierras': 0,
      'Instantáneos': 0,
      'Conjuros': 0,
      'Artefactos': 0,
      'Encantamientos': 0,
      'Planeswalkers': 0,
      'Otros': 0,
    };
    for (final card in cards) {
      final cat = card.category;
      counts[cat] = (counts[cat] ?? 0) + card.quantity;
    }
    return counts;
  }

  /// Mana curve distribution (CMC 0 to 7+)
  Map<int, int> get manaCurve {
    final Map<int, int> curve = {0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0};
    for (final card in cards) {
      // Exclude lands from mana curve
      if (card.category == 'Tierras') continue;
      final int cmcBucket = card.cmc >= 7 ? 7 : card.cmc.floor();
      curve[cmcBucket] = (curve[cmcBucket] ?? 0) + card.quantity;
    }
    return curve;
  }

  /// Effective cover image (uses coverImageUrl or the first high-res art)
  String get effectiveCoverImage {
    if (coverImageUrl.isNotEmpty) return coverImageUrl;
    for (final card in cards) {
      if (card.artCropUrl.isNotEmpty) return card.artCropUrl;
      if (card.imageUrl.isNotEmpty) return card.imageUrl;
    }
    return '';
  }

  Deck copyWith({
    String? id,
    String? name,
    String? description,
    String? format,
    String? coverImageUrl,
    List<CardItem>? cards,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Deck(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      format: format ?? this.format,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      cards: cards ?? this.cards,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'format': format,
      'coverImageUrl': coverImageUrl,
      'cards': cards.map((c) => c.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Deck.fromJson(Map<String, dynamic> json) {
    return Deck(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Mazo Sin Nombre',
      description: json['description'] ?? '',
      format: json['format'] ?? 'Commander',
      coverImageUrl: json['coverImageUrl'] ?? '',
      cards: (json['cards'] as List<dynamic>?)
              ?.map((e) => CardItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
