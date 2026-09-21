import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/deck_exporter.dart';
import '../../models/deck.dart';

class DeckExportDialog extends StatelessWidget {
  final Deck deck;

  const DeckExportDialog({super.key, required this.deck});

  static void show(BuildContext context, Deck deck) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DeckExportDialog(deck: deck),
    );
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('¡$label copiado al portapapeles!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Exportar y Compartir Mazo',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    Text(
                      '${deck.name} • ${deck.totalCards} cartas',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 24, color: AppColors.border),

            // Option 1: Moxfield Compatible Format
            _buildExportOption(
              context: context,
              icon: Icons.code,
              iconColor: AppColors.foilGold,
              title: 'Formato Compatible con Moxfield',
              subtitle: 'Texto estándar (1x Carta [SET] *F*) y CSV compatible con Moxfield.',
              buttonLabel: 'Copiar Texto Moxfield',
              onPressed: () {
                final moxText = DeckExporter.toMoxfieldText(deck);
                _copyToClipboard(context, moxText, 'Formato Moxfield');
              },
              secondaryAction: TextButton.icon(
                icon: const Icon(Icons.file_copy_outlined, size: 14),
                label: const Text('Copiar CSV Moxfield', style: TextStyle(fontSize: 11)),
                onPressed: () {
                  final csv = DeckExporter.toMoxfieldCsv(deck);
                  _copyToClipboard(context, csv, 'CSV Moxfield');
                },
              ),
            ),
            const SizedBox(height: 12),

            // Option 2: PDF Deck Sheet
            _buildExportOption(
              context: context,
              icon: Icons.picture_as_pdf_outlined,
              iconColor: AppColors.error,
              title: 'Hoja de Mazo en PDF',
              subtitle: 'Documento PDF con arte, métricas, curva de maná y desglose de precios.',
              buttonLabel: 'Generar / Imprimir PDF',
              onPressed: () async {
                Navigator.pop(context);
                await DeckExporter.exportPdf(deck);
              },
            ),
            const SizedBox(height: 12),

            // Option 3: Excel / CSV
            _buildExportOption(
              context: context,
              icon: Icons.table_chart_outlined,
              iconColor: AppColors.success,
              title: 'Lista de Excel (CSV)',
              subtitle: 'Planilla de cálculo completa con cantidades, cotizaciones USD y estado foil.',
              buttonLabel: 'Copiar CSV para Excel',
              onPressed: () {
                final csv = DeckExporter.toExcelCsv(deck);
                _copyToClipboard(context, csv, 'Planilla CSV');
              },
            ),
            const SizedBox(height: 12),

            // Option 4: Share URL between App Users
            _buildExportOption(
              context: context,
              icon: Icons.share_outlined,
              iconColor: AppColors.primaryLight,
              title: 'Compartir entre Usuarios de MyDeck',
              subtitle: 'Genera un enlace o dirección para que otro usuario importe este mazo instantáneamente.',
              buttonLabel: 'Compartir Enlace / Código',
              onPressed: () async {
                await DeckExporter.shareDeckAsText(deck);
              },
              secondaryAction: TextButton.icon(
                icon: const Icon(Icons.link, size: 14),
                label: const Text('Copiar Enlace de Mazo', style: TextStyle(fontSize: 11)),
                onPressed: () {
                  final link = DeckExporter.generateSharePayload(deck);
                  _copyToClipboard(context, link, 'Enlace de importación');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportOption({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String buttonLabel,
    required VoidCallback onPressed,
    Widget? secondaryAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
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
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                child: Text(buttonLabel),
              ),
              if (secondaryAction != null) secondaryAction,
            ],
          ),
        ],
      ),
    );
  }
}
