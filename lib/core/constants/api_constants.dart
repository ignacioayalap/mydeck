class ApiConstants {
  // Scryfall API Base URL
  static const String scryfallBaseUrl = 'https://api.scryfall.com';

  // Endpoints
  static const String scryfallNamed = '$scryfallBaseUrl/cards/named';
  static const String scryfallAutocomplete = '$scryfallBaseUrl/cards/autocomplete';
  static const String scryfallSearch = '$scryfallBaseUrl/cards/search';
  static const String scryfallRandom = '$scryfallBaseUrl/cards/random';

  // Gemini Generative Language API
  static const String geminiEndpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  // SharedPreferences Keys
  static const String prefUserKey = 'mydeck_current_user';
  static const String prefDecksKey = 'mydeck_saved_decks';
  static const String prefGeminiApiKey = 'mydeck_gemini_api_key';
  static const String prefIsGuestKey = 'mydeck_is_guest';
}
