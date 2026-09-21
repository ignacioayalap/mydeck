import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/ai_recommendation.dart';
import '../../../models/deck.dart';
import '../../../providers/deck_provider.dart';
import '../../../services/gemini_ai_service.dart';
import '../../../services/scryfall_service.dart';

class DeckLandsScreen extends StatefulWidget {
  final Deck deck;

  const DeckLandsScreen({super.key, required this.deck});

  @override
  State<DeckLandsScreen> createState() => _DeckLandsScreenState();
}

class _DeckLandsScreenState extends State<DeckLandsScreen> {
  List<LandRecommendation> _lands = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLands();
  }

  Future<void> _loadLands() async {
    setState(() => _isLoading = true);
    final results = await GeminiAiService.analyzeLands(widget.deck);
    if (mounted) {
      setState(() {
        _lands = results;
        _isLoading = false;
      });
    }
  }

  Future<void> _addLandToDeck(String landName) async {
    final deckProvider = context.read<DeckProvider>();
    final card = await ScryfallService.searchCardFuzzy(landName);
    if (card != null && mounted) {
      await deckProvider.addCardToDeck(deckId: widget.deck.id, card: card);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡"$landName" añadida a la base de maná!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final landCount = widget.deck.categoryCounts['Tierras'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tierras para Potenciar (IA)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadLands,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text('Analizando curva y balance de colores...', style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Mana Base Overview Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('Total Tierras', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          const SizedBox(height: 4),
                          Text('$landCount', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Container(width: 1, height: 35, color: AppColors.border),
                      Column(
                        children: [
                          const Text('Colores del Mazo', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          const SizedBox(height: 4),
                          Text(
                            widget.deck.colors.isEmpty ? 'Incoloro' : widget.deck.colors.join(' • '),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryLight),
                          ),
                        ],
                      ),
                      Container(width: 1, height: 35, color: AppColors.border),
                      Column(
                        children: [
                          const Text('Ratio Sugerido', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          const SizedBox(height: 4),
                          Text(
                            landCount < 35 ? 'Aumentar (+2)' : (landCount > 39 ? 'Reducir (-2)' : 'Óptimo'),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: (landCount >= 35 && landCount <= 39) ? AppColors.success : AppColors.foilGold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  'Recomendaciones de Tierras por IA',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 12),

                ..._lands.map((land) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                land.landName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.primaryLight.withOpacity(0.4)),
                              ),
                              child: Text(
                                land.type,
                                style: const TextStyle(fontSize: 11, color: AppColors.primaryLight, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          land.reason,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Sugerencia de corte:', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                                Text(land.replaceSuggestion, style: const TextStyle(fontSize: 11, color: AppColors.error)),
                              ],
                            ),
                            ElevatedButton.icon(
                              onPressed: () => _addLandToDeck(land.landName),
                              icon: const Icon(Icons.add, size: 16),
                              label: Text(
                                land.estimatedPriceUsd > 0
                                    ? 'Añadir (${Formatters.formatUsd(land.estimatedPriceUsd)})'
                                    : 'Añadir al Mazo',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.surfaceLight,
                                foregroundColor: AppColors.textPrimary,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
    );
  }
}
