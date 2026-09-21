import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/deck.dart';
import '../../providers/auth_provider.dart';
import '../../providers/deck_provider.dart';
import '../scanner/card_scanner_screen.dart';
import '../settings/settings_screen.dart';
import 'deck_detail_screen.dart';
import 'deck_export_dialog.dart';

class DeckListScreen extends StatelessWidget {
  const DeckListScreen({super.key});

  void _showCreateDeckDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    String selectedFormat = 'Commander';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Crear Nuevo Mazo'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del Mazo',
                        hintText: 'ej. Urza Lord High Artificer',
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: selectedFormat,
                      decoration: const InputDecoration(labelText: 'Formato'),
                      dropdownColor: AppColors.surface,
                      items: const [
                        DropdownMenuItem(value: 'Commander', child: Text('Commander / EDH (100)')),
                        DropdownMenuItem(value: 'Modern', child: Text('Modern (60)')),
                        DropdownMenuItem(value: 'Standard', child: Text('Standard (60)')),
                        DropdownMenuItem(value: 'Pioneer', child: Text('Pioneer (60)')),
                        DropdownMenuItem(value: 'Legacy', child: Text('Legacy (60)')),
                        DropdownMenuItem(value: 'Casual', child: Text('Casual')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedFormat = val);
                      },
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: descController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Descripción / Estrategia (opcional)',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) return;
                    final deckProvider = context.read<DeckProvider>();
                    final newDeck = await deckProvider.createDeck(
                      name: nameController.text,
                      description: descController.text,
                      format: selectedFormat,
                    );
                    if (context.mounted) {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DeckDetailScreen(deckId: newDeck.id),
                        ),
                      );
                    }
                  },
                  child: const Text('Crear Mazo'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showImportSharedDeckDialog(BuildContext context) {
    final codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Importar Mazo Compartido'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Pega la dirección o código del mazo que compartió otro usuario de la aplicación:',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: codeController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'mydeck://import?data=... o código de mazo',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final deckProvider = context.read<DeckProvider>();
                final imported = await deckProvider.importDeckFromCode(codeController.text);
                if (context.mounted) {
                  Navigator.pop(context);
                  if (imported != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('¡Mazo "${imported.name}" importado con éxito!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DeckDetailScreen(deckId: imported.id),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No se pudo decodificar el mazo. Verifica el código.'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
              child: const Text('Importar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final deckProvider = context.watch<DeckProvider>();
    final auth = context.watch<AuthProvider>();
    final decks = deckProvider.decks;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.foilGold],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.auto_awesome_motion, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Text('Mi Colección de Mazos'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined),
            tooltip: 'Importar Mazo Compartido',
            onPressed: () => _showImportSharedDeckDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Ajustes y Perfil',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: deckProvider.isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : decks.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.style_outlined, size: 64, color: AppColors.textMuted),
                          const SizedBox(height: 16),
                          const Text(
                            'Tu colección de mazos está vacía',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Crea tu primer mazo o escanea cartas para empezar a construir.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => _showCreateDeckDialog(context),
                            icon: const Icon(Icons.add),
                            label: const Text('Crear Primer Mazo'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: decks.length,
                    itemBuilder: (context, index) {
                      final deck = decks[index];
                      return _buildDeckCard(context, deck, deckProvider);
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.camera_alt, color: Colors.white),
        label: const Text('Escanear Carta', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CardScannerScreen()),
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${decks.length} mazos • Planeswalker: ${auth.currentUser?.username ?? 'Invitado'}',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            ElevatedButton.icon(
              onPressed: () => _showCreateDeckDialog(context),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Nuevo Mazo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.surfaceLight,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeckCard(BuildContext context, Deck deck, DeckProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DeckDetailScreen(deckId: deck.id),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Deck Cover Art Banner
            SizedBox(
              height: 120,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (deck.effectiveCoverImage.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: deck.effectiveCoverImage,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: AppColors.surfaceLight),
                      errorWidget: (_, __, ___) => Container(color: AppColors.surfaceLight),
                    )
                  else
                    Container(
                      color: AppColors.surfaceLight,
                      child: const Center(
                        child: Icon(Icons.style, size: 40, color: AppColors.textMuted),
                      ),
                    ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.8),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        deck.format,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryLight,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    left: 12,
                    right: 12,
                    child: Text(
                      deck.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Informative Deck Summary Section (User Story #5)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Total Updated Price (USD & EUR)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PRECIO ACTUALIZADO',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMuted,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            Formatters.formatUsd(deck.totalPriceUsd),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppColors.success,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            Formatters.formatEur(deck.totalPriceEur),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Cards Count & Quick Menu
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          '${deck.totalCards} cartas',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 6),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 20, color: AppColors.textSecondary),
                        color: AppColors.surface,
                        onSelected: (action) {
                          if (action == 'export') {
                            DeckExportDialog.show(context, deck);
                          } else if (action == 'duplicate') {
                            provider.duplicateDeck(deck);
                          } else if (action == 'delete') {
                            provider.deleteDeck(deck.id);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'export',
                            child: Row(
                              children: [
                                Icon(Icons.share_outlined, size: 18),
                                SizedBox(width: 8),
                                Text('Exportar / Compartir'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'duplicate',
                            child: Row(
                              children: [
                                Icon(Icons.copy, size: 18),
                                SizedBox(width: 8),
                                Text('Duplicar Mazo'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                                SizedBox(width: 8),
                                Text('Eliminar Mazo', style: TextStyle(color: AppColors.error)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
