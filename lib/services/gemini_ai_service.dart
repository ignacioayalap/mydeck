import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/ai_recommendation.dart';
import '../models/deck.dart';
import 'storage_service.dart';

class GeminiAiService {
  /// Recognize card from image bytes (Base64) using Gemini Vision API
  static Future<String?> recognizeCardFromImage(Uint8List imageBytes) async {
    final apiKey = await StorageService.getGeminiApiKey();
    if (apiKey.isEmpty) {
      // Return null to trigger fallback fuzzy title match
      return null;
    }

    try {
      final base64Image = base64Encode(imageBytes);
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey',
      );

      final payload = {
        'contents': [
          {
            'parts': [
              {
                'text':
                    'Identify the exact name of this Magic: The Gathering card in English. Return ONLY the card title, nothing else.',
              },
              {
                'inline_data': {
                  'mime_type': 'image/jpeg',
                  'data': base64Image,
                }
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.1,
          'maxOutputTokens': 50,
        }
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final text = json['candidates']?[0]?['content']?['parts']?[0]?['text'];
        if (text != null) {
          return text.toString().trim().replaceAll('"', '').replaceAll("'", '');
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Analyze deck and return Infinite Combos
  static Future<List<ComboRecommendation>> analyzeCombos(Deck deck) async {
    final apiKey = await StorageService.getGeminiApiKey();
    final cardNames = deck.cards.map((c) => c.name).join(', ');

    if (apiKey.isNotEmpty) {
      try {
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey',
        );

        final prompt = '''
Eres un experto de Magic: The Gathering (EDH / Commander).
Analiza la siguiente lista de cartas de un mazo de MTG ($cardNames).
Identifica o recomienda combos infinitos posibles (maná infinito, daño infinito, turnos infinitos, tokens infinitos) que integren las cartas actuales o que requieran 1 o 2 cartas adicionales faltantes.
Devuelve ÚNICAMENTE un array JSON válido con el siguiente formato, sin formato Markdown extra:
[
  {
    "title": "Nombre del Combo",
    "cardsInDeck": ["Carta 1", "Carta 2"],
    "cardsMissing": ["Carta Requerida Faltante"],
    "result": "Maná infinito de todos los colores",
    "instructions": "1. Activa la habilidad X... 2. Resuelve el disparador Y..."
  }
]
''';

        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'parts': [{'text': prompt}]
              }
            ],
            'generationConfig': {'temperature': 0.3}
          }),
        );

        if (response.statusCode == 200) {
          final json = jsonDecode(response.body);
          String rawText = json['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
          rawText = rawText.replaceAll('```json', '').replaceAll('```', '').trim();
          final List<dynamic> list = jsonDecode(rawText);
          return list.map((e) => ComboRecommendation.fromJson(e)).toList();
        }
      } catch (_) {
        // Fall back to rule engine
      }
    }

    // High-intelligence heuristic MTG combo database fallback
    return _generateSmartComboFallbacks(deck);
  }

  /// Analyze land base & recommend enhancements
  static Future<List<LandRecommendation>> analyzeLands(Deck deck) async {
    final apiKey = await StorageService.getGeminiApiKey();
    final cardNames = deck.cards.map((c) => c.name).join(', ');
    final colors = deck.colors.join('/');

    if (apiKey.isNotEmpty) {
      try {
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey',
        );

        final prompt = '''
Eres un analista de bases de maná de Magic: The Gathering.
Para este mazo con colores ($colors) y cartas ($cardNames):
Recomienda entre 3 y 5 tierras para potenciar el mazo (Shocklands, Fetchlands, Triomas o Tierras de utilidad como Boseiju, Cabal Coffers, Urza's Saga).
Devuelve ÚNICAMENTE un array JSON válido:
[
  {
    "landName": "Nombre de la Tierra",
    "type": "Shockland / Fetchland / Utilidad",
    "reason": "Por qué potencia este mazo específico",
    "replaceSuggestion": "Tierra básica o tapland a retirar",
    "estimatedPriceUsd": 15.5
  }
]
''';

        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'parts': [{'text': prompt}]
              }
            ],
            'generationConfig': {'temperature': 0.3}
          }),
        );

        if (response.statusCode == 200) {
          final json = jsonDecode(response.body);
          String rawText = json['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
          rawText = rawText.replaceAll('```json', '').replaceAll('```', '').trim();
          final List<dynamic> list = jsonDecode(rawText);
          return list.map((e) => LandRecommendation.fromJson(e)).toList();
        }
      } catch (_) {
        // fallback
      }
    }

    return _generateSmartLandFallbacks(deck);
  }

  /// Analyze recommended card upgrades & cuts
  static Future<List<CardUpgradeRecommendation>> analyzeUpgrades(Deck deck) async {
    final apiKey = await StorageService.getGeminiApiKey();
    final cardNames = deck.cards.map((c) => c.name).join(', ');

    if (apiKey.isNotEmpty) {
      try {
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey',
        );

        final prompt = '''
Eres un entrenador competitivo de MTG.
Mazo: ${deck.name} (Formato: ${deck.format}).
Cartas: $cardNames.
Recomienda 3 a 5 mejoras concretas (qué carta agregar, cuál quitar de la lista, categoría y justificación).
Devuelve ÚNICAMENTE un array JSON válido:
[
  {
    "addCardName": "Carta Sugerida",
    "cutCardName": "Carta a Quitar",
    "category": "Sinergia / Rampa / Robo / Remoción / Finisher",
    "reason": "Justificación táctica",
    "tier": "Económico / Competitivo / High-End"
  }
]
''';

        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'parts': [{'text': prompt}]
              }
            ],
            'generationConfig': {'temperature': 0.3}
          }),
        );

        if (response.statusCode == 200) {
          final json = jsonDecode(response.body);
          String rawText = json['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
          rawText = rawText.replaceAll('```json', '').replaceAll('```', '').trim();
          final List<dynamic> list = jsonDecode(rawText);
          return list.map((e) => CardUpgradeRecommendation.fromJson(e)).toList();
        }
      } catch (_) {
        // fallback
      }
    }

    return _generateSmartUpgradeFallbacks(deck);
  }

  /// In-deck interactive AI Chat assistant
  static Future<String> chatWithDeckAssistant({
    required Deck deck,
    required List<ChatMessage> history,
    required String userMessage,
  }) async {
    final apiKey = await StorageService.getGeminiApiKey();
    final deckSummary = '''
Mazo: "${deck.name}"
Formato: ${deck.format}
Total cartas: ${deck.totalCards}
Valor aproximado: \$${deck.totalPriceUsd.toStringAsFixed(2)} USD
Identidad de Color: ${deck.colors.join(', ')}
Cartas clave: ${deck.cards.take(25).map((c) => c.name).join(', ')}
''';

    if (apiKey.isNotEmpty) {
      try {
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey',
        );

        final systemInstruction = '''
Eres el Asistente Táctico y Copiloto de Inteligencia Artificial para este mazo de Magic: The Gathering.
Conoces al detalle cada carta, la curva de maná, las sinergias y debilidades de este mazo:
$deckSummary
Responde en español de forma entusiasta, estratégica, concisa y experta. Da consejos prácticos sobre jugadas, reemplazos, sinergias y condiciones de victoria.
''';

        final contents = [
          {
            'role': 'user',
            'parts': [{'text': systemInstruction}]
          },
          {
            'role': 'model',
            'parts': [{'text': '¡Entendido! Soy tu copiloto para "${deck.name}". ¿Qué jugada o mejora analizamos hoy?'}]
          },
          ...history.take(8).map((m) => {
                'role': m.isUser ? 'user' : 'model',
                'parts': [{'text': m.text}]
              }),
          {
            'role': 'user',
            'parts': [{'text': userMessage}]
          }
        ];

        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': contents,
            'generationConfig': {'temperature': 0.7, 'maxOutputTokens': 500}
          }),
        );

        if (response.statusCode == 200) {
          final json = jsonDecode(response.body);
          final answer = json['candidates']?[0]?['content']?['parts']?[0]?['text'];
          if (answer != null) return answer.toString().trim();
        }
      } catch (_) {
        // fallback
      }
    }

    // Heuristic assistant fallback for instant answers without API key
    return _generateHeuristicChatAnswer(deck, userMessage);
  }

  // --- HEURISTIC INTELLIGENCE ENGINE (NO API KEY REQUIRED) ---
  static List<ComboRecommendation> _generateSmartComboFallbacks(Deck deck) {
    final names = deck.cards.map((c) => c.name.toLowerCase()).toSet();
    final List<ComboRecommendation> results = [];

    // Atraxa / Doubling Season synergy
    if (names.any((n) => n.contains('doubling season') || n.contains('atraxa'))) {
      results.add(
        ComboRecommendation(
          title: 'Planeswalkers con Ultímate Inmediato',
          cardsInDeck: [
            if (names.any((n) => n.contains('doubling season'))) 'Doubling Season',
            if (names.any((n) => n.contains('atraxa'))) 'Atraxa, Praetors\' Voice',
          ],
          cardsMissing: ['Tamiyo, Field Researcher', 'Jace, Unraveler of Secrets'],
          result: 'Emblemas de omnisciencia o contrahechizos infinitos el turno que entran.',
          instructions:
              '1. Con Doubling Season en mesa, cualquier Planeswalker entra con el doble de lealtad.\n2. Lanzas a Tamiyo o Jace con suficientes contadores para activar su -8 inmediatamente.\n3. Obtienes el emblema que te permite lanzar hechizos gratis o contrarrestar el primer hechizo oponente cada turno.',
        ),
      );
    }

    // Infinite Mana: Dramatic Scepter or Basalt Monolith
    if (names.any((n) => n.contains('sol ring'))) {
      results.add(
        ComboRecommendation(
          title: 'Isochron Scepter + Dramatic Reversal',
          cardsInDeck: ['Sol Ring'],
          cardsMissing: ['Isochron Scepter', 'Dramatic Reversal'],
          result: 'Maná incoloro y maná de manarocas infinito + tormenta infinita.',
          instructions:
              '1. Lanza Isochron Scepter con Imprint exiliando Dramatic Reversal.\n2. Tapa Sol Ring y otra manaroca para generar al menos {3}.\n3. Paga {2} y gira Isochron Scepter para lanzar una copia de Dramatic Reversal.\n4. Se enderezan todos tus artefactos. Repite para maná infinito.',
        ),
      );
    }

    // Heliod + Walking Ballista
    results.add(
      ComboRecommendation(
        title: 'Heliod, Sun-Crowned + Walking Ballista',
        cardsInDeck: names.contains('walking ballista') ? ['Walking Ballista'] : [],
        cardsMissing: names.contains('walking ballista')
            ? ['Heliod, Sun-Crowned']
            : ['Heliod, Sun-Crowned', 'Walking Ballista'],
        result: 'Daño directo infinito a todos los oponentes y vida infinita.',
        instructions:
            '1. Da vínculo vital (Lifelink) a Walking Ballista con la habilidad de Heliod ({1}{W}).\n2. Remueve un contador +1/+1 de Ballista para hacer 1 daño a un oponente.\n3. El daño dispara la habilidad de Heliod, poniendo un nuevo contador +1/+1 sobre Ballista.\n4. Repite el bucle indefinidamente hasta ganar la partida.',
      ),
    );

    // Kiki-Jiki
    results.add(
      ComboRecommendation(
        title: 'Kiki-Jiki, Mirror Breaker + Restoration Angel',
        cardsInDeck: [],
        cardsMissing: ['Kiki-Jiki, Mirror Breaker', 'Restoration Angel'],
        result: 'Copias infinitas con prisa de Restoration Angel y ataque letal.',
        instructions:
            '1. Con Kiki-Jiki en mesa, juega Restoration Angel.\n2. El disparador de entrada del Ángel pestañea (blinks) a Kiki-Jiki.\n3. Kiki-Jiki entra enderezado; gíralo para copiar a Restoration Angel.\n4. La nueva copia pestañea a Kiki-Jiki. Repite y ataca con infinitos ángeles.',
      ),
    );

    return results;
  }

  static List<LandRecommendation> _generateSmartLandFallbacks(Deck deck) {
    final colors = deck.colors.toSet();
    final List<LandRecommendation> lands = [];

    if (colors.contains('U') && colors.contains('B')) {
      lands.add(
        LandRecommendation(
          landName: 'Underground Sea',
          type: 'Dual Land Original',
          reason: 'Entra enderezada sin coste de vida y tiene tipos Isla y Pantano para ser buscada.',
          replaceSuggestion: 'Dimir Guildgate o Isla básica',
          estimatedPriceUsd: 750.0,
        ),
      );
      lands.add(
        LandRecommendation(
          landName: 'Polluted Delta',
          type: 'Fetchland',
          reason: 'Adelgaza la biblioteca y fija el maná en el momento óptimo a velocidad instantánea.',
          replaceSuggestion: 'Tierra básica',
          estimatedPriceUsd: 14.5,
        ),
      );
    }

    if (colors.contains('G')) {
      lands.add(
        LandRecommendation(
          landName: 'Boseiju, Who Endures',
          type: 'Tierra de Utilidad',
          reason: 'Indiscutible versatilidad: entra enderezada o destruye artefactos, encantamientos o tierras rivales sin ser contrarrestable.',
          replaceSuggestion: 'Bosque básico',
          estimatedPriceUsd: 38.0,
        ),
      );
    }

    lands.add(
      LandRecommendation(
        landName: 'Urza\'s Saga',
        type: 'Tierra de Utilidad / Artefacto',
        reason: 'Produce fichas de constructo gigantes y busca Sol Ring directamente a la mesa en el capítulo III.',
        replaceSuggestion: 'Tierra incolora genérica',
        estimatedPriceUsd: 45.0,
      ),
    );

    if (colors.length >= 3) {
      lands.add(
        LandRecommendation(
          landName: 'Zagoth Triome / Raffine\'s Tower',
          type: 'Trioma',
          reason: 'Cubre 3 colores del mazo, tiene 3 tipos de tierra básica y puede ciclarse si te sobran tierras.',
          replaceSuggestion: 'Tierra triple que entra girada sin tipos',
          estimatedPriceUsd: 13.0,
        ),
      );
    }

    return lands;
  }

  static List<CardUpgradeRecommendation> _generateSmartUpgradeFallbacks(Deck deck) {
    return [
      CardUpgradeRecommendation(
        addCardName: 'Rhystic Study',
        cutCardName: 'Robo de cartas de alto coste',
        category: 'Robo',
        reason: 'El mejor motor pasivo de robo en el formato multijugador. Penaliza a los oponentes por jugar o te llena la mano constantemente.',
        tier: 'High-End',
      ),
      CardUpgradeRecommendation(
        addCardName: 'Demonic Tutor',
        cutCardName: 'Buscador condicional lento',
        category: 'Sinergia / Tutor',
        reason: 'Por solo 2 manás pone cualquier respuesta o pieza de combo directamente en tu mano sin revelar.',
        tier: 'Competitivo',
      ),
      CardUpgradeRecommendation(
        addCardName: 'Swords to Plowshares',
        cutCardName: 'Remoción de coste 3 o superior',
        category: 'Remoción',
        reason: 'La remoción de criaturas más eficiente de Magic: velocidad instantánea, exilio incondicional por {W}.',
        tier: 'Económico',
      ),
      CardUpgradeRecommendation(
        addCardName: 'The One Ring',
        cutCardName: 'Artefacto de soporte menor',
        category: 'Robo / Protección',
        reason: 'Otorga protección contra todo por un turno y se convierte en un motor imparable de ventaja de cartas.',
        tier: 'High-End',
      ),
    ];
  }

  static String _generateHeuristicChatAnswer(Deck deck, String query) {
    final lower = query.toLowerCase();
    if (lower.contains('gana') || lower.contains('victoria') || lower.contains('estrategia') || lower.contains('wincon')) {
      return 'Para el mazo "${deck.name}", tu condición de victoria primordial radica en establecer una ventaja acumulativa de valor en mesa. Con cartas de alta sinergia y un comandante que amplifica el plan, debes asegurar aceleración en turnos 1-3, proteger tus piezas clave con interacción a velocidad instantánea y culminar con un combo infinito o daño evasivo abrumador.';
    }
    if (lower.contains('sacar') || lower.contains('quitar') || lower.contains('cut') || lower.contains('reemplazar')) {
      return 'Al analizar la curva de maná de "${deck.name}", te sugiero recortar cartas de coste convertido mayor a 4 que no tengan un impacto inmediato en el campo de batalla al entrar. También puedes revisar si tienes más de 37 tierras si juegas suficiente aceleración (rocas de maná de coste 2).';
    }
    if (lower.contains('tierra') || lower.contains('mana') || lower.contains('base')) {
      return 'La base de maná de "${deck.name}" cuenta actualmente con ${deck.categoryCounts['Tierras'] ?? 0} tierras. Te recomiendo priorizar tierras dobles no condicionadas (Shocklands y Fetchlands) y tierras de utilidad como Boseiju o Urza\'s Saga para maximizar la consistencia.';
    }
    if (lower.contains('combo')) {
      return '¡Este mazo tiene un gran potencial de combos! Revisa la pestaña de "Combos Infinitos" dentro del menú de herramientas donde detallamos la inclusión de piezas como Isochron Scepter o Walking Ballista para cerrar partidas al instante.';
    }
    return 'Analizando "${deck.name}" (${deck.totalCards} cartas, valor actual: \$${deck.totalPriceUsd.toStringAsFixed(2)}): Es un mazo muy sólido con un gran balance de colores. Te sugiero enfocarte en acelerar los primeros turnos y afinar las respuestas contra amenazas voladoras y daño de área.';
  }
}
