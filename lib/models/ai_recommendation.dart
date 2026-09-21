class ComboRecommendation {
  final String title;
  final List<String> cardsInDeck;
  final List<String> cardsMissing;
  final String result;
  final String instructions;

  ComboRecommendation({
    required this.title,
    required this.cardsInDeck,
    required this.cardsMissing,
    required this.result,
    required this.instructions,
  });

  factory ComboRecommendation.fromJson(Map<String, dynamic> json) {
    return ComboRecommendation(
      title: json['title'] ?? 'Combo Infinito',
      cardsInDeck: (json['cardsInDeck'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      cardsMissing: (json['cardsMissing'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      result: json['result'] ?? '',
      instructions: json['instructions'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'cardsInDeck': cardsInDeck,
      'cardsMissing': cardsMissing,
      'result': result,
      'instructions': instructions,
    };
  }
}

class LandRecommendation {
  final String landName;
  final String type; // Shockland, Fetchland, Dual, Trioma, Utilidad
  final String reason;
  final String replaceSuggestion;
  final double estimatedPriceUsd;

  LandRecommendation({
    required this.landName,
    required this.type,
    required this.reason,
    required this.replaceSuggestion,
    this.estimatedPriceUsd = 0.0,
  });

  factory LandRecommendation.fromJson(Map<String, dynamic> json) {
    return LandRecommendation(
      landName: json['landName'] ?? '',
      type: json['type'] ?? 'Tierra de Utilidad',
      reason: json['reason'] ?? '',
      replaceSuggestion: json['replaceSuggestion'] ?? 'Tierra básica sobrante',
      estimatedPriceUsd: (json['estimatedPriceUsd'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'landName': landName,
      'type': type,
      'reason': reason,
      'replaceSuggestion': replaceSuggestion,
      'estimatedPriceUsd': estimatedPriceUsd,
    };
  }
}

class CardUpgradeRecommendation {
  final String addCardName;
  final String cutCardName;
  final String category; // Rampa, Robo, Sinergia, Remoción, Finisher
  final String reason;
  final String tier; // Económico, Competitivo, High-End

  CardUpgradeRecommendation({
    required this.addCardName,
    required this.cutCardName,
    required this.category,
    required this.reason,
    this.tier = 'Competitivo',
  });

  factory CardUpgradeRecommendation.fromJson(Map<String, dynamic> json) {
    return CardUpgradeRecommendation(
      addCardName: json['addCardName'] ?? '',
      cutCardName: json['cutCardName'] ?? '',
      category: json['category'] ?? 'Sinergia',
      reason: json['reason'] ?? '',
      tier: json['tier'] ?? 'Competitivo',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'addCardName': addCardName,
      'cutCardName': cutCardName,
      'category': category,
      'reason': reason,
      'tier': tier,
    };
  }
}

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? '',
      text: json['text'] ?? '',
      isUser: json['isUser'] ?? false,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
