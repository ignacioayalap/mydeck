import '../core/utils/formatters.dart';

class CardItem {
  final String id;
  final String scryfallId;
  final String name;
  final String manaCost;
  final double cmc;
  final String typeLine;
  final String oracleText;
  final String imageUrl;
  final String artCropUrl;
  final String setName;
  final String setCode;
  final String collectorNumber;
  final String rarity;
  final double priceUsd;
  final double priceUsdFoil;
  final double priceEur;
  final double priceEurFoil;
  final bool isFoil;
  final int quantity;
  final List<String> colors;
  final List<String> colorIdentity;

  CardItem({
    required this.id,
    required this.scryfallId,
    required this.name,
    this.manaCost = '',
    this.cmc = 0.0,
    this.typeLine = '',
    this.oracleText = '',
    this.imageUrl = '',
    this.artCropUrl = '',
    this.setName = '',
    this.setCode = '',
    this.collectorNumber = '',
    this.rarity = 'common',
    this.priceUsd = 0.0,
    this.priceUsdFoil = 0.0,
    this.priceEur = 0.0,
    this.priceEurFoil = 0.0,
    this.isFoil = false,
    this.quantity = 1,
    this.colors = const [],
    this.colorIdentity = const [],
  });

  /// Returns unit price in USD based on whether isFoil is selected
  double get currentPriceUsd {
    if (isFoil) {
      return priceUsdFoil > 0 ? priceUsdFoil : priceUsd;
    }
    return priceUsd > 0 ? priceUsd : priceUsdFoil;
  }

  /// Returns unit price in EUR based on whether isFoil is selected
  double get currentPriceEur {
    if (isFoil) {
      return priceEurFoil > 0 ? priceEurFoil : priceEur;
    }
    return priceEur > 0 ? priceEur : priceEurFoil;
  }

  /// Total USD price = unit price * quantity
  double get totalPriceUsd => currentPriceUsd * quantity;

  /// Total EUR price = unit price * quantity
  double get totalPriceEur => currentPriceEur * quantity;

  /// Determines primary card category
  String get category {
    final lower = typeLine.toLowerCase();
    if (lower.contains('land')) return 'Tierras';
    if (lower.contains('creature')) return 'Criaturas';
    if (lower.contains('instant')) return 'Instantáneos';
    if (lower.contains('sorcery')) return 'Conjuros';
    if (lower.contains('artifact')) return 'Artefactos';
    if (lower.contains('enchantment')) return 'Encantamientos';
    if (lower.contains('planeswalker')) return 'Planeswalkers';
    if (lower.contains('battle')) return 'Batallas';
    return 'Otros';
  }

  CardItem copyWith({
    String? id,
    String? scryfallId,
    String? name,
    String? manaCost,
    double? cmc,
    String? typeLine,
    String? oracleText,
    String? imageUrl,
    String? artCropUrl,
    String? setName,
    String? setCode,
    String? collectorNumber,
    String? rarity,
    double? priceUsd,
    double? priceUsdFoil,
    double? priceEur,
    double? priceEurFoil,
    bool? isFoil,
    int? quantity,
    List<String>? colors,
    List<String>? colorIdentity,
  }) {
    return CardItem(
      id: id ?? this.id,
      scryfallId: scryfallId ?? this.scryfallId,
      name: name ?? this.name,
      manaCost: manaCost ?? this.manaCost,
      cmc: cmc ?? this.cmc,
      typeLine: typeLine ?? this.typeLine,
      oracleText: oracleText ?? this.oracleText,
      imageUrl: imageUrl ?? this.imageUrl,
      artCropUrl: artCropUrl ?? this.artCropUrl,
      setName: setName ?? this.setName,
      setCode: setCode ?? this.setCode,
      collectorNumber: collectorNumber ?? this.collectorNumber,
      rarity: rarity ?? this.rarity,
      priceUsd: priceUsd ?? this.priceUsd,
      priceUsdFoil: priceUsdFoil ?? this.priceUsdFoil,
      priceEur: priceEur ?? this.priceEur,
      priceEurFoil: priceEurFoil ?? this.priceEurFoil,
      isFoil: isFoil ?? this.isFoil,
      quantity: quantity ?? this.quantity,
      colors: colors ?? this.colors,
      colorIdentity: colorIdentity ?? this.colorIdentity,
    );
  }

  factory CardItem.fromScryfallJson(Map<String, dynamic> json, {bool isFoil = false, int quantity = 1}) {
    // Check for double-faced cards / card_faces
    String img = '';
    String art = '';
    if (json['image_uris'] != null) {
      img = json['image_uris']['normal'] ?? json['image_uris']['large'] ?? json['image_uris']['small'] ?? '';
      art = json['image_uris']['art_crop'] ?? '';
    } else if (json['card_faces'] != null && (json['card_faces'] as List).isNotEmpty) {
      final firstFace = json['card_faces'][0];
      if (firstFace['image_uris'] != null) {
        img = firstFace['image_uris']['normal'] ?? firstFace['image_uris']['large'] ?? '';
        art = firstFace['image_uris']['art_crop'] ?? '';
      }
    }

    final prices = json['prices'] as Map<String, dynamic>? ?? {};

    return CardItem(
      id: json['id'] ?? '',
      scryfallId: json['id'] ?? '',
      name: json['name'] ?? 'Sin Nombre',
      manaCost: json['mana_cost'] ?? '',
      cmc: (json['cmc'] as num?)?.toDouble() ?? 0.0,
      typeLine: json['type_line'] ?? '',
      oracleText: json['oracle_text'] ?? '',
      imageUrl: img,
      artCropUrl: art,
      setName: json['set_name'] ?? '',
      setCode: (json['set'] ?? '').toString().toUpperCase(),
      collectorNumber: json['collector_number'] ?? '',
      rarity: json['rarity'] ?? 'common',
      priceUsd: Formatters.parsePrice(prices['usd']),
      priceUsdFoil: Formatters.parsePrice(prices['usd_foil']),
      priceEur: Formatters.parsePrice(prices['eur']),
      priceEurFoil: Formatters.parsePrice(prices['eur_foil']),
      isFoil: isFoil,
      quantity: quantity,
      colors: (json['colors'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      colorIdentity: (json['color_identity'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'scryfallId': scryfallId,
      'name': name,
      'manaCost': manaCost,
      'cmc': cmc,
      'typeLine': typeLine,
      'oracleText': oracleText,
      'imageUrl': imageUrl,
      'artCropUrl': artCropUrl,
      'setName': setName,
      'setCode': setCode,
      'collectorNumber': collectorNumber,
      'rarity': rarity,
      'priceUsd': priceUsd,
      'priceUsdFoil': priceUsdFoil,
      'priceEur': priceEur,
      'priceEurFoil': priceEurFoil,
      'isFoil': isFoil,
      'quantity': quantity,
      'colors': colors,
      'colorIdentity': colorIdentity,
    };
  }

  factory CardItem.fromJson(Map<String, dynamic> json) {
    return CardItem(
      id: json['id'] ?? '',
      scryfallId: json['scryfallId'] ?? '',
      name: json['name'] ?? '',
      manaCost: json['manaCost'] ?? '',
      cmc: (json['cmc'] as num?)?.toDouble() ?? 0.0,
      typeLine: json['typeLine'] ?? '',
      oracleText: json['oracleText'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      artCropUrl: json['artCropUrl'] ?? '',
      setName: json['setName'] ?? '',
      setCode: json['setCode'] ?? '',
      collectorNumber: json['collectorNumber'] ?? '',
      rarity: json['rarity'] ?? 'common',
      priceUsd: (json['priceUsd'] as num?)?.toDouble() ?? 0.0,
      priceUsdFoil: (json['priceUsdFoil'] as num?)?.toDouble() ?? 0.0,
      priceEur: (json['priceEur'] as num?)?.toDouble() ?? 0.0,
      priceEurFoil: (json['priceEurFoil'] as num?)?.toDouble() ?? 0.0,
      isFoil: json['isFoil'] ?? false,
      quantity: json['quantity'] ?? 1,
      colors: (json['colors'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      colorIdentity: (json['colorIdentity'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}
