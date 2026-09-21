import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/card_item.dart';
import '../../providers/deck_provider.dart';
import '../../providers/scanner_provider.dart';
import '../../services/scryfall_service.dart';
import '../../widgets/card_preview_widget.dart';

class CardScannerScreen extends StatefulWidget {
  final String? targetDeckId;

  const CardScannerScreen({super.key, this.targetDeckId});

  @override
  State<CardScannerScreen> createState() => _CardScannerScreenState();
}

class _CardScannerScreenState extends State<CardScannerScreen> {
  final _searchController = TextEditingController();
  List<String> _autocompleteSuggestions = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) async {
    if (query.trim().length < 2) {
      if (_autocompleteSuggestions.isNotEmpty) {
        setState(() => _autocompleteSuggestions = []);
      }
      return;
    }
    final suggestions = await ScryfallService.autocomplete(query);
    if (mounted) {
      setState(() {
        _autocompleteSuggestions = suggestions;
      });
    }
  }

  void _selectSuggestion(String name) {
    _searchController.text = name;
    setState(() => _autocompleteSuggestions = []);
    context.read<ScannerProvider>().searchByName(name);
  }

  void _showAddToDeckSheet(CardItem card) {
    final deckProvider = context.read<DeckProvider>();
    final decks = deckProvider.decks;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        if (decks.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.inbox, size: 48, color: AppColors.textMuted),
                const SizedBox(height: 12),
                const Text(
                  'No tienes ningún mazo en tu colección',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showCreateDeckDialog(card);
                  },
                  child: const Text('Crear Nuevo Mazo'),
                ),
              ],
            ),
          );
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Agregar carta a...',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 280),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: decks.length,
                    separatorBuilder: (_, __) => const Divider(color: AppColors.border, height: 1),
                    itemBuilder: (context, index) {
                      final d = decks[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.surfaceLight,
                          backgroundImage: d.effectiveCoverImage.isNotEmpty
                              ? NetworkImage(d.effectiveCoverImage)
                              : null,
                          child: d.effectiveCoverImage.isEmpty
                              ? const Icon(Icons.style, color: AppColors.primaryLight, size: 18)
                              : null,
                        ),
                        title: Text(d.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('${d.totalCards} cartas • ${d.format}'),
                        trailing: const Icon(Icons.add_circle, color: AppColors.primary),
                        onTap: () {
                          deckProvider.addCardToDeck(deckId: d.id, card: card);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('¡"${card.name}" agregada a "${d.name}"!'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCreateDeckDialog(CardItem card) {
    final controller = TextEditingController(text: 'Mi Mazo Commander');
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Crear Mazo'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Nombre del mazo'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final deckProvider = context.read<DeckProvider>();
                final newDeck = await deckProvider.createDeck(name: controller.text);
                await deckProvider.addCardToDeck(deckId: newDeck.id, card: card);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('¡Mazo "${newDeck.name}" creado con "${card.name}"!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
              child: const Text('Crear y Agregar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scanner = context.watch<ScannerProvider>();
    final card = scanner.scannedCard;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Escáner de Cartas con IA'),
        actions: [
          if (card != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Limpiar escáner',
              onPressed: () => scanner.clear(),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Camera & Gallery Capture Buttons
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Reconocer Carta Físicamente',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Toma una foto o sube una imagen. La IA extraerá el nombre y consultará la cotización de Scryfall.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: scanner.isProcessing
                                ? null
                                : () => scanner.captureWithCamera(),
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Cámara'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: scanner.isProcessing
                                ? null
                                : () => scanner.pickFromGallery(),
                            icon: const Icon(Icons.photo_library),
                            label: const Text('Galería'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Live Search & Autocomplete
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      onSubmitted: (query) => scanner.searchByName(query),
                      decoration: InputDecoration(
                        hintText: 'O busca por nombre (ej. Sol Ring, Atraxa...)',
                        prefixIcon: const Icon(Icons.search, color: AppColors.primaryLight),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _autocompleteSuggestions = []);
                                },
                              )
                            : null,
                      ),
                    ),
                    if (_autocompleteSuggestions.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 160),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _autocompleteSuggestions.length,
                          itemBuilder: (context, index) {
                            final name = _autocompleteSuggestions[index];
                            return ListTile(
                              dense: true,
                              title: Text(name, style: const TextStyle(fontSize: 13)),
                              leading: const Icon(Icons.style, size: 16, color: AppColors.primaryLight),
                              onTap: () => _selectSuggestion(name),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Processing / Loading Indicator
              if (scanner.isProcessing) ...[
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary),
                  ),
                  child: Column(
                    children: [
                      const CircularProgressIndicator(color: AppColors.primary),
                      const SizedBox(height: 14),
                      Text(
                        scanner.statusMessage ?? 'Procesando reconocimiento...',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Error Message
              if (scanner.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          scanner.errorMessage!,
                          style: const TextStyle(color: AppColors.error, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // RECOGNIZED CARD DETAIL & FOIL SELECTOR
              if (card != null) ...[
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: scanner.isFoil ? AppColors.foilAmber : AppColors.border,
                      width: scanner.isFoil ? 1.8 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: scanner.isFoil
                            ? AppColors.foilGold.withOpacity(0.25)
                            : Colors.black.withOpacity(0.3),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Card Preview Component
                      SizedBox(
                        height: 380,
                        child: CardPreviewWidget(
                          card: card,
                          onToggleFoil: () => scanner.toggleFoil(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // FOIL SELECTOR TOGGLE (User Story #4)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: scanner.isFoil
                              ? AppColors.foilGold.withOpacity(0.12)
                              : AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: scanner.isFoil ? AppColors.foilGold : AppColors.border,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.auto_awesome,
                                  color: scanner.isFoil ? AppColors.foilGold : AppColors.textMuted,
                                  size: 22,
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Acabado Foil (Holográfico)',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: scanner.isFoil
                                            ? AppColors.foilGold
                                            : AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      scanner.isFoil
                                          ? 'Precio Foil Scryfall: ${Formatters.formatUsd(card.priceUsdFoil)}'
                                          : 'Precio Normal Scryfall: ${Formatters.formatUsd(card.priceUsd)}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Switch.adaptive(
                              value: scanner.isFoil,
                              activeColor: AppColors.foilGold,
                              onChanged: (val) => scanner.toggleFoil(val),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Price Summary Box
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceLight,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                children: [
                                  const Text('Cotización USD',
                                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                  const SizedBox(height: 4),
                                  Text(
                                    Formatters.formatUsd(card.currentPriceUsd),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: scanner.isFoil ? AppColors.foilGold : AppColors.success,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceLight,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                children: [
                                  const Text('Cotización EUR',
                                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                  const SizedBox(height: 4),
                                  Text(
                                    Formatters.formatEur(card.currentPriceEur),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.info,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Add to Deck CTA Button
                      ElevatedButton.icon(
                        onPressed: () {
                          if (widget.targetDeckId != null) {
                            context.read<DeckProvider>().addCardToDeck(
                                  deckId: widget.targetDeckId!,
                                  card: card,
                                );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('¡"${card.name}" agregada al mazo!'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                            Navigator.pop(context);
                          } else {
                            _showAddToDeckSheet(card);
                          }
                        },
                        icon: const Icon(Icons.add_circle_outline),
                        label: Text(
                          widget.targetDeckId != null
                              ? 'Agregar al Mazo Actual'
                              : 'Agregar a mi Colección / Mazo',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
