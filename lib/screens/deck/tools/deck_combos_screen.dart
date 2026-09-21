import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/ai_recommendation.dart';
import '../../../models/deck.dart';
import '../../../providers/deck_provider.dart';
import '../../../services/gemini_ai_service.dart';
import '../../../services/scryfall_service.dart';

class DeckCombosScreen extends StatefulWidget {
  final Deck deck;

  const DeckCombosScreen({super.key, required this.deck});

  @override
  State<DeckCombosScreen> createState() => _DeckCombosScreenState();
}

class _DeckCombosScreenState extends State<DeckCombosScreen> {
  List<ComboRecommendation> _combos = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCombos();
  }

  Future<void> _loadCombos() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await GeminiAiService.analyzeCombos(widget.deck);
      if (mounted) {
        setState(() {
          _combos = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _addMissingCard(String cardName) async {
    final deckProvider = context.read<DeckProvider>();
    final card = await ScryfallService.searchCardFuzzy(cardName);
    if (card != null && mounted) {
      await deckProvider.addCardToDeck(deckId: widget.deck.id, card: card);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡"$cardName" agregada a tu mazo!'),
          backgroundColor: AppColors.success,
        ),
      );
      _loadCombos();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Combos Infinitos de IA'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadCombos,
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
                  Text(
                    'La IA está analizando los bucles y combos del mazo...',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.warning_amber, size: 48, color: AppColors.warning),
                        const SizedBox(height: 12),
                        Text(_errorMessage!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _loadCombos, child: const Text('Reintentar')),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _combos.length,
                  itemBuilder: (context, index) {
                    final combo = _combos[index];
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
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.auto_awesome, color: AppColors.primaryLight, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  combo.title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Result banner
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.success.withOpacity(0.4)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_outline, size: 16, color: AppColors.success),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    combo.result,
                                    style: const TextStyle(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Cards in deck
                          if (combo.cardsInDeck.isNotEmpty) ...[
                            const Text('Cartas ya en tu mazo:',
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: combo.cardsInDeck.map((name) {
                                return Chip(
                                  backgroundColor: AppColors.surfaceLight,
                                  label: Text(name, style: const TextStyle(fontSize: 11, color: AppColors.textPrimary)),
                                  avatar: const Icon(Icons.check, size: 14, color: AppColors.success),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 10),
                          ],

                          // Cards missing
                          if (combo.cardsMissing.isNotEmpty) ...[
                            const Text('Cartas faltantes sugeridas:',
                                style: TextStyle(fontSize: 12, color: AppColors.foilAmber, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: combo.cardsMissing.map((name) {
                                return ActionChip(
                                  backgroundColor: AppColors.foilAmber.withOpacity(0.12),
                                  side: const BorderSide(color: AppColors.foilAmber),
                                  label: Text('+ $name', style: const TextStyle(fontSize: 11, color: AppColors.foilAmber)),
                                  onPressed: () => _addMissingCard(name),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Loop instructions
                          const Text('Instrucciones del Bucle:',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Text(
                            combo.instructions,
                            style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.4),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
