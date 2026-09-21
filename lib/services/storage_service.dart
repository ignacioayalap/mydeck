import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_constants.dart';
import '../models/card_item.dart';
import '../models/deck.dart';
import '../models/user_model.dart';

class StorageService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static Future<SharedPreferences> get _instance async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // --- USER AUTH STORAGE ---
  static Future<void> saveUser(UserModel user) async {
    final prefs = await _instance;
    await prefs.setString(ApiConstants.prefUserKey, jsonEncode(user.toJson()));
    await prefs.setBool(ApiConstants.prefIsGuestKey, false);
  }

  static Future<UserModel?> getUser() async {
    final prefs = await _instance;
    final userJson = prefs.getString(ApiConstants.prefUserKey);
    if (userJson == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(userJson));
    } catch (_) {
      return null;
    }
  }

  static Future<void> setGuestMode(bool isGuest) async {
    final prefs = await _instance;
    await prefs.setBool(ApiConstants.prefIsGuestKey, isGuest);
  }

  static Future<bool> isGuestMode() async {
    final prefs = await _instance;
    return prefs.getBool(ApiConstants.prefIsGuestKey) ?? false;
  }

  static Future<void> clearUser() async {
    final prefs = await _instance;
    await prefs.remove(ApiConstants.prefUserKey);
    await prefs.setBool(ApiConstants.prefIsGuestKey, false);
  }

  // --- GEMINI API KEY ---
  static Future<void> saveGeminiApiKey(String key) async {
    final prefs = await _instance;
    await prefs.setString(ApiConstants.prefGeminiApiKey, key.trim());
  }

  static Future<String> getGeminiApiKey() async {
    final prefs = await _instance;
    return prefs.getString(ApiConstants.prefGeminiApiKey) ?? '';
  }

  // --- DECKS COLLECTION STORAGE ---
  static Future<void> saveDecks(List<Deck> decks) async {
    final prefs = await _instance;
    final encoded = jsonEncode(decks.map((d) => d.toJson()).toList());
    await prefs.setString(ApiConstants.prefDecksKey, encoded);
  }

  static Future<List<Deck>> getDecks() async {
    final prefs = await _instance;
    final decksJson = prefs.getString(ApiConstants.prefDecksKey);
    if (decksJson == null) {
      // Seed with curated sample decks for an immediate rich experience
      final initialDecks = _getInitialSampleDecks();
      await saveDecks(initialDecks);
      return initialDecks;
    }
    try {
      final List<dynamic> decoded = jsonDecode(decksJson);
      return decoded.map((e) => Deck.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return _getInitialSampleDecks();
    }
  }

  static List<Deck> _getInitialSampleDecks() {
    return [
      Deck(
        id: 'deck_atraxa_01',
        name: 'Atraxa - Proliferación Sagrada',
        description: 'Mazo Commander centrado en contadores +1/+1, lealtad de planeswalkers y veneno.',
        format: 'Commander',
        coverImageUrl: 'https://cards.scryfall.io/art_crop/front/d/0/d0d070bc-ac3f-4057-9255-e42039d60874.jpg',
        cards: [
          CardItem(
            id: 'c1',
            scryfallId: 'd0d070bc-ac3f-4057-9255-e42039d60874',
            name: 'Atraxa, Praetors\' Voice',
            manaCost: '{G}{W}{U}{B}',
            cmc: 4,
            typeLine: 'Legendary Creature — Phyrexian Angel',
            oracleText: 'Flying, vigilance, deathtouch, lifelink. At the beginning of your end step, proliferate.',
            imageUrl: 'https://cards.scryfall.io/normal/front/d/0/d0d070bc-ac3f-4057-9255-e42039d60874.jpg',
            artCropUrl: 'https://cards.scryfall.io/art_crop/front/d/0/d0d070bc-ac3f-4057-9255-e42039d60874.jpg',
            setName: 'Double Masters',
            setCode: '2XM',
            collectorNumber: '190',
            rarity: 'mythic',
            priceUsd: 19.50,
            priceUsdFoil: 32.00,
            priceEur: 18.00,
            priceEurFoil: 29.50,
            isFoil: true,
            quantity: 1,
            colors: ['W', 'U', 'B', 'G'],
            colorIdentity: ['W', 'U', 'B', 'G'],
          ),
          CardItem(
            id: 'c2',
            scryfallId: '41916328-4034-453d-82d2-8b74f3e6918a',
            name: 'Sol Ring',
            manaCost: '{1}',
            cmc: 1,
            typeLine: 'Artifact',
            oracleText: '{T}: Add {C}{C}.',
            imageUrl: 'https://cards.scryfall.io/normal/front/4/1/41916328-4034-453d-82d2-8b74f3e6918a.jpg',
            artCropUrl: 'https://cards.scryfall.io/art_crop/front/4/1/41916328-4034-453d-82d2-8b74f3e6918a.jpg',
            setName: 'Commander Masters',
            setCode: 'CMM',
            collectorNumber: '401',
            rarity: 'uncommon',
            priceUsd: 1.85,
            priceUsdFoil: 3.50,
            priceEur: 1.50,
            priceEurFoil: 3.00,
            isFoil: false,
            quantity: 1,
            colors: [],
            colorIdentity: [],
          ),
          CardItem(
            id: 'c3',
            scryfallId: '8093f10e-25c3-44da-800e-61d01bb46332',
            name: 'Cyclonic Rift',
            manaCost: '{1}{U}',
            cmc: 2,
            typeLine: 'Instant',
            oracleText: 'Return target nonland permanent you don\'t control to its owner\'s hand. Overload {6}{U}',
            imageUrl: 'https://cards.scryfall.io/normal/front/8/0/8093f10e-25c3-44da-800e-61d01bb46332.jpg',
            artCropUrl: 'https://cards.scryfall.io/art_crop/front/8/0/8093f10e-25c3-44da-800e-61d01bb46332.jpg',
            setName: 'Commander Masters',
            setCode: 'CMM',
            collectorNumber: '84',
            rarity: 'rare',
            priceUsd: 38.00,
            priceUsdFoil: 54.00,
            priceEur: 35.00,
            priceEurFoil: 50.00,
            isFoil: false,
            quantity: 1,
            colors: ['U'],
            colorIdentity: ['U'],
          ),
          CardItem(
            id: 'c4',
            scryfallId: '76807f45-6677-4402-a164-8e1e7fae4465',
            name: 'Doubling Season',
            manaCost: '{4}{G}',
            cmc: 5,
            typeLine: 'Enchantment',
            oracleText: 'If an effect would create one or more tokens under your control, it creates twice that many of those tokens instead. If an effect would put one or more counters on a permanent you control, it puts twice that many of those counters on that permanent instead.',
            imageUrl: 'https://cards.scryfall.io/normal/front/7/6/76807f45-6677-4402-a164-8e1e7fae4465.jpg',
            artCropUrl: 'https://cards.scryfall.io/art_crop/front/7/6/76807f45-6677-4402-a164-8e1e7fae4465.jpg',
            setName: 'Wilds of Eldraine',
            setCode: 'WOE',
            collectorNumber: '521',
            rarity: 'mythic',
            priceUsd: 42.50,
            priceUsdFoil: 65.00,
            priceEur: 40.00,
            priceEurFoil: 60.00,
            isFoil: true,
            quantity: 1,
            colors: ['G'],
            colorIdentity: ['G'],
          ),
          CardItem(
            id: 'c5',
            scryfallId: '4b7a1362-e6e7-4007-a36c-ffdf8344ea1d',
            name: 'Watery Grave',
            manaCost: '',
            cmc: 0,
            typeLine: 'Land — Island Swamp',
            oracleText: '({T}: Add {U} or {B}.) As Watery Grave enters the battlefield, you may pay 2 life. If you don\'t, it enters the battlefield tapped.',
            imageUrl: 'https://cards.scryfall.io/normal/front/4/b/4b7a1362-e6e7-4007-a36c-ffdf8344ea1d.jpg',
            artCropUrl: 'https://cards.scryfall.io/art_crop/front/4/b/4b7a1362-e6e7-4007-a36c-ffdf8344ea1d.jpg',
            setName: 'Ravnica Remastered',
            setCode: 'RVR',
            collectorNumber: '291',
            rarity: 'rare',
            priceUsd: 14.20,
            priceUsdFoil: 22.00,
            priceEur: 13.00,
            priceEurFoil: 20.00,
            isFoil: false,
            quantity: 1,
            colors: [],
            colorIdentity: ['U', 'B'],
          ),
        ],
      ),
      Deck(
        id: 'deck_burn_02',
        name: 'Torbran - Fuego y Calcinación',
        description: 'Mazo agresivo de daño directo que aprovecha la habilidad de Torbran para amplificar cada chispa.',
        format: 'Commander',
        coverImageUrl: 'https://cards.scryfall.io/art_crop/front/7/9/79f59112-0f16-4ca7-a552-34f9a37857e9.jpg',
        cards: [
          CardItem(
            id: 'b1',
            scryfallId: '79f59112-0f16-4ca7-a552-34f9a37857e9',
            name: 'Torbran, Thane of Red Fell',
            manaCost: '{1}{R}{R}{R}',
            cmc: 4,
            typeLine: 'Legendary Creature — Dwarf Noble',
            oracleText: 'If a red source you control would deal damage to an opponent or a permanent an opponent controls, it deals that much damage plus 2 to that permanent or player instead.',
            imageUrl: 'https://cards.scryfall.io/normal/front/7/9/79f59112-0f16-4ca7-a552-34f9a37857e9.jpg',
            artCropUrl: 'https://cards.scryfall.io/art_crop/front/7/9/79f59112-0f16-4ca7-a552-34f9a37857e9.jpg',
            setName: 'Throne of Eldraine',
            setCode: 'ELD',
            collectorNumber: '147',
            rarity: 'rare',
            priceUsd: 3.15,
            priceUsdFoil: 7.80,
            priceEur: 2.90,
            priceEurFoil: 6.50,
            isFoil: false,
            quantity: 1,
            colors: ['R'],
            colorIdentity: ['R'],
          ),
          CardItem(
            id: 'b2',
            scryfallId: 'dcd20760-4416-48c0-8d59-3652614b8a1c',
            name: 'Lightning Bolt',
            manaCost: '{R}',
            cmc: 1,
            typeLine: 'Instant',
            oracleText: 'Lightning Bolt deals 3 damage to any target.',
            imageUrl: 'https://cards.scryfall.io/normal/front/d/c/dcd20760-4416-48c0-8d59-3652614b8a1c.jpg',
            artCropUrl: 'https://cards.scryfall.io/art_crop/front/d/c/dcd20760-4416-48c0-8d59-3652614b8a1c.jpg',
            setName: 'Jumpstart 2022',
            setCode: 'J22',
            collectorNumber: '561',
            rarity: 'uncommon',
            priceUsd: 1.20,
            priceUsdFoil: 4.50,
            priceEur: 1.00,
            priceEurFoil: 4.00,
            isFoil: true,
            quantity: 1,
            colors: ['R'],
            colorIdentity: ['R'],
          ),
        ],
      )
    ];
  }
}
