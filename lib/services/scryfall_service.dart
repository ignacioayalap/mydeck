import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../models/card_item.dart';

class ScryfallService {
  /// Fuzzy search by card name (ideal for OCR / camera scanned text)
  static Future<CardItem?> searchCardFuzzy(String name, {bool isFoil = false}) async {
    if (name.trim().isEmpty) return null;
    try {
      final uri = Uri.parse(
        '${ApiConstants.scryfallNamed}?fuzzy=${Uri.encodeComponent(name.trim())}',
      );
      final response = await http.get(uri, headers: {
        'User-Agent': 'MyDeckApp/1.0',
        'Accept': 'application/json',
      });

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return CardItem.fromScryfallJson(json, isFoil: isFoil);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Exact name lookup
  static Future<CardItem?> searchCardExact(String name, {bool isFoil = false}) async {
    if (name.trim().isEmpty) return null;
    try {
      final uri = Uri.parse(
        '${ApiConstants.scryfallNamed}?exact=${Uri.encodeComponent(name.trim())}',
      );
      final response = await http.get(uri, headers: {
        'User-Agent': 'MyDeckApp/1.0',
        'Accept': 'application/json',
      });

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return CardItem.fromScryfallJson(json, isFoil: isFoil);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Autocomplete card names
  static Future<List<String>> autocomplete(String query) async {
    if (query.trim().length < 2) return [];
    try {
      final uri = Uri.parse(
        '${ApiConstants.scryfallAutocomplete}?q=${Uri.encodeComponent(query.trim())}',
      );
      final response = await http.get(uri, headers: {
        'User-Agent': 'MyDeckApp/1.0',
        'Accept': 'application/json',
      });

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List<dynamic> data = json['data'] ?? [];
        return data.map((e) => e.toString()).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Search cards by query (syntax supported)
  static Future<List<CardItem>> searchCards(String query, {int limit = 15}) async {
    if (query.trim().isEmpty) return [];
    try {
      final uri = Uri.parse(
        '${ApiConstants.scryfallSearch}?q=${Uri.encodeComponent(query.trim())}',
      );
      final response = await http.get(uri, headers: {
        'User-Agent': 'MyDeckApp/1.0',
        'Accept': 'application/json',
      });

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List<dynamic> data = json['data'] ?? [];
        return data.take(limit).map((c) => CardItem.fromScryfallJson(c)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Get random card
  static Future<CardItem?> getRandomCard() async {
    try {
      final uri = Uri.parse(ApiConstants.scryfallRandom);
      final response = await http.get(uri, headers: {
        'User-Agent': 'MyDeckApp/1.0',
        'Accept': 'application/json',
      });
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return CardItem.fromScryfallJson(json);
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
