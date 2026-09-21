import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/ai_recommendation.dart';
import '../../../models/deck.dart';
import '../../../providers/deck_provider.dart';
import '../../../services/gemini_ai_service.dart';
import '../../../services/scryfall_service.dart';

class DeckUpgradesScreen extends StatefulWidget {
  final Deck deck;

  const DeckUpgradesScreen({super.key, required this.deck});

  @override
  State<DeckUpgradesScreen> createState() => _DeckUpgradesScreenState();
}

class _DeckUpgradesScreenState extends State<DeckUpgradesScreen> {
  List<CardUpgradeRecommendation> _upgrades = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUpgrades();
  }

  Future<void> _loadUpgrades() async {
    setState(() => _isLoading = true);
    final results = await GeminiAiService.analyzeUpgrades(widget.deck);
    if (mounted) {
      setState(() {
        _upgrades = results;
        _isLoading = false;
      });
    }
  }

  Future<void> _addCard(String cardName) async {
    final deckProvider = context.read<DeckProvider>();
    final card = await ScryfallService.searchCardFuzzy(cardName);
    if (card != null && mounted) {
      await deckProvider.addCardToDeck(deckId: widget.deck.id, card: card);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡"$cardName" añadida a tu mazo!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mejoras de Cartas (IA)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadUpgrades,
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
                  Text('Analizando sinergias y cartas subóptimas...', style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _upgrades.length,
              itemBuilder: (context, index) {
                final item = _upgrades[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
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
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              item.category,
                              style: const TextStyle(
                                color: AppColors.primaryLight,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: item.tier == 'High-End'
                                  ? AppColors.foilGold.withOpacity(0.15)
                                  : AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: item.tier == 'High-End' ? AppColors.foilGold : AppColors.border,
                              ),
                            ),
                            child: Text(
                              item.tier,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: item.tier == 'High-End' ? AppColors.foilGold : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // In/Out comparison
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.success.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.success.withOpacity(0.3)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.add_circle, color: AppColors.success, size: 14),
                                      SizedBox(width: 4),
                                      Text('AGREGAR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.success)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.addCardName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.error.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.error.withOpacity(0.3)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.remove_circle, color: AppColors.error, size: 14),
                                      SizedBox(width: 4),
                                      Text('QUITAR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.error)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.cutCardName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Rationale
                      Text(
                        item.reason,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                      ),
                      const SizedBox(height: 12),

                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: () => _addCard(item.addCardName),
                          icon: const Icon(Icons.add, size: 16),
                          label: Text('Agregar "${item.addCardName}"'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
