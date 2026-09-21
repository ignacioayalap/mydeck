import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/deck.dart';
import '../../providers/deck_provider.dart';
import '../../widgets/card_preview_widget.dart';
import '../../widgets/mana_curve_chart.dart';
import '../scanner/card_scanner_screen.dart';
import 'deck_export_dialog.dart';
import 'tools/deck_chat_screen.dart';
import 'tools/deck_combos_screen.dart';
import 'tools/deck_lands_screen.dart';
import 'tools/deck_upgrades_screen.dart';

class DeckDetailScreen extends StatefulWidget {
  final String deckId;

  const DeckDetailScreen({super.key, required this.deckId});

  @override
  State<DeckDetailScreen> createState() => _DeckDetailScreenState();
}

class _DeckDetailScreenState extends State<DeckDetailScreen> with SingleTickerProviderStateMixin {
  String _selectedCategory = 'Todos';

  void _showAiToolsMenu(Deck deck) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                      child: const Icon(Icons.psychology, color: AppColors.primaryLight, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Herramientas de IA para el Mazo',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        Text(
                          'Análisis estratégico inteligente y optimización',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: AppColors.border),

                // Tool 1: Infinite Combos
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.surfaceLight,
                    child: Icon(Icons.all_inclusive, color: AppColors.foilGold),
                  ),
                  title: const Text('Combos Infinitos', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Detecta combos en el mazo y sugiere cartas faltantes'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => DeckCombosScreen(deck: deck)),
                    );
                  },
                ),

                // Tool 2: Lands Optimizer
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.surfaceLight,
                    child: Icon(Icons.landscape_outlined, color: AppColors.success),
                  ),
                  title: const Text('Tierras para Potenciar', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Shocklands, Fetchlands, Triomas y tierras de utilidad'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => DeckLandsScreen(deck: deck)),
                    );
                  },
                ),

                // Tool 3: Card Upgrades & Cuts
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.surfaceLight,
                    child: Icon(Icons.upgrade, color: AppColors.primaryLight),
                  ),
                  title: const Text('Mejoras de Cartas Recomendadas', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Sinergias, aceleración y cartas débiles a recortar'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => DeckUpgradesScreen(deck: deck)),
                    );
                  },
                ),

                // Tool 4: In-deck AI Chat Assistant
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.surfaceLight,
                    child: Icon(Icons.chat_bubble_outline, color: AppColors.info),
                  ),
                  title: const Text('Asistente Personal (Copiloto Chat)', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Pregunta cualquier duda táctica o reemplazo en vivo'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => DeckChatScreen(deck: deck)),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final deckProvider = context.watch<DeckProvider>();
    final decks = deckProvider.decks.where((d) => d.id == widget.deckId);

    if (decks.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Mazo no encontrado')),
      );
    }

    final deck = decks.first;
    final filteredCards = _selectedCategory == 'Todos'
        ? deck.cards
        : deck.cards.where((c) => c.category == _selectedCategory).toList();

    final categories = ['Todos', ...deck.categoryCounts.keys.where((k) => (deck.categoryCounts[k] ?? 0) > 0)];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero Cover Art App Bar
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                deck.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black, blurRadius: 10)],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (deck.effectiveCoverImage.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: deck.effectiveCoverImage,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: AppColors.surface),
                      errorWidget: (_, __, ___) => Container(color: AppColors.surface),
                    )
                  else
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primaryDark, AppColors.surface],
                        ),
                      ),
                    ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppColors.background.withOpacity(0.6),
                          AppColors.background,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined),
                tooltip: 'Exportar / Compartir',
                onPressed: () => DeckExportDialog.show(context, deck),
              ),
            ],
          ),

          // Informative Deck Stats Section (User Story #5)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Deck Info Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('VALOR TOTAL ACTUALIZADO',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                                const SizedBox(height: 2),
                                Text(
                                  Formatters.formatUsd(deck.totalPriceUsd),
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.success,
                                  ),
                                ),
                                Text(
                                  Formatters.formatEur(deck.totalPriceEur),
                                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    deck.format,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: AppColors.primaryLight,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${deck.totalCards} cartas en total',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (deck.description.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          const Divider(height: 1, color: AppColors.border),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              deck.description,
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Quick Action Buttons (Herramientas IA, Escanear, Exportar)
                  Row(
                    children: [
                      // AI Tools Button
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showAiToolsMenu(deck),
                          icon: const Icon(Icons.auto_awesome, size: 18),
                          label: const Text('Herramientas IA'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Scan & Add card button
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CardScannerScreen(targetDeckId: deck.id),
                            ),
                          );
                        },
                        icon: const Icon(Icons.camera_alt_outlined, size: 18),
                        label: const Text('Escanear'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.surfaceLight,
                          foregroundColor: AppColors.textPrimary,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Mana Curve Chart
                  ManaCurveChart(manaCurve: deck.manaCurve),
                  const SizedBox(height: 14),

                  // Category Filter Chips
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final cat = categories[index];
                        final isSelected = cat == _selectedCategory;
                        final count = cat == 'Todos' ? deck.totalCards : (deck.categoryCounts[cat] ?? 0);
                        return ChoiceChip(
                          label: Text('$cat ($count)'),
                          selected: isSelected,
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.surface,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                          ),
                          onSelected: (val) {
                            if (val) setState(() => _selectedCategory = cat);
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // Cards Grid
          if (filteredCards.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.style_outlined, size: 48, color: AppColors.textMuted),
                      SizedBox(height: 12),
                      Text(
                        'No hay cartas en esta categoría',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.58,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final card = filteredCards[index];
                    return CardPreviewWidget(
                      card: card,
                      showControls: true,
                      onToggleFoil: () => deckProvider.toggleCardFoil(deck.id, card.id),
                      onIncrement: () => deckProvider.updateCardQuantity(deck.id, card.id, card.quantity + 1),
                      onDecrement: () => deckProvider.updateCardQuantity(deck.id, card.id, card.quantity - 1),
                      onRemove: () => deckProvider.removeCardFromDeck(deck.id, card.id),
                    );
                  },
                  childCount: filteredCards.length,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}
