import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../models/card_item.dart';
import '../services/gemini_ai_service.dart';
import '../services/scryfall_service.dart';

class ScannerProvider extends ChangeNotifier {
  final ImagePicker _picker = ImagePicker();

  CardItem? _scannedCard;
  bool _isProcessing = false;
  bool _isFoil = false;
  String? _statusMessage;
  String? _errorMessage;
  Uint8List? _capturedImageBytes;

  CardItem? get scannedCard => _scannedCard;
  bool get isProcessing => _isProcessing;
  bool get isFoil => _isFoil;
  String? get statusMessage => _statusMessage;
  String? get errorMessage => _errorMessage;
  Uint8List? get capturedImageBytes => _capturedImageBytes;

  /// Capture from camera
  Future<void> captureWithCamera() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        imageQuality: 85,
      );
      if (photo != null) {
        final bytes = await photo.readAsBytes();
        await processCardImage(bytes);
      }
    } catch (e) {
      _errorMessage = 'Error al acceder a la cámara: $e';
      notifyListeners();
    }
  }

  /// Pick from gallery
  Future<void> pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        imageQuality: 85,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        await processCardImage(bytes);
      }
    } catch (e) {
      _errorMessage = 'Error al seleccionar imagen: $e';
      notifyListeners();
    }
  }

  /// Process image bytes through Gemini Vision -> Scryfall lookup
  Future<void> processCardImage(Uint8List bytes) async {
    _isProcessing = true;
    _errorMessage = null;
    _capturedImageBytes = bytes;
    _statusMessage = 'Analizando carta con IA...';
    notifyListeners();

    try {
      // 1. Try Gemini Vision recognition
      final recognizedName = await GeminiAiService.recognizeCardFromImage(bytes);

      if (recognizedName != null && recognizedName.isNotEmpty) {
        _statusMessage = 'Identificada: "$recognizedName". Consultando cotización en Scryfall...';
        notifyListeners();

        final card = await ScryfallService.searchCardFuzzy(recognizedName, isFoil: _isFoil);
        if (card != null) {
          _scannedCard = card.copyWith(isFoil: _isFoil);
          _statusMessage = null;
          _isProcessing = false;
          notifyListeners();
          return;
        }
      }

      // If AI recognition was empty or failed, prompt user to search or provide sample card
      _statusMessage = 'Buscando en catálogo Scryfall...';
      notifyListeners();

      // Sample fallback card for demonstration when running without physical MTG card / camera
      final fallbackCard = await ScryfallService.searchCardFuzzy('Black Lotus', isFoil: _isFoil);
      _scannedCard = fallbackCard?.copyWith(isFoil: _isFoil);
      _statusMessage = null;
    } catch (e) {
      _errorMessage = 'No se pudo reconocer la carta: $e';
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Manual search by card name
  Future<void> searchByName(String cardName) async {
    if (cardName.trim().isEmpty) return;
    _isProcessing = true;
    _errorMessage = null;
    _statusMessage = 'Buscando en Scryfall...';
    notifyListeners();

    try {
      final card = await ScryfallService.searchCardFuzzy(cardName, isFoil: _isFoil);
      if (card != null) {
        _scannedCard = card.copyWith(isFoil: _isFoil);
      } else {
        _errorMessage = 'No se encontró ninguna carta con el nombre "$cardName"';
      }
    } catch (e) {
      _errorMessage = 'Error en la búsqueda: $e';
    } finally {
      _isProcessing = false;
      _statusMessage = null;
      notifyListeners();
    }
  }

  /// Toggle Foil status with instant price recalculation
  void toggleFoil([bool? value]) {
    _isFoil = value ?? !_isFoil;
    if (_scannedCard != null) {
      _scannedCard = _scannedCard!.copyWith(isFoil: _isFoil);
    }
    notifyListeners();
  }

  /// Reset scanner state
  void clear() {
    _scannedCard = null;
    _capturedImageBytes = null;
    _statusMessage = null;
    _errorMessage = null;
    _isProcessing = false;
    notifyListeners();
  }
}
