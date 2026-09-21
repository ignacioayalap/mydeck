import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/deck.dart';
import 'formatters.dart';

class DeckExporter {
  /// Generate Moxfield text format (e.g., '1 Sol Ring (CMM) 401 *F*')
  static String toMoxfieldText(Deck deck) {
    final buffer = StringBuffer();
    buffer.writeln('// Deck: ${deck.name} (${deck.format})');
    buffer.writeln('// Exported from MyDeck App');
    buffer.writeln();

    // Group cards by category
    final Map<String, List> categorized = {};
    for (final card in deck.cards) {
      categorized.putIfAbsent(card.category, () => []).add(card);
    }

    categorized.forEach((cat, cards) {
      buffer.writeln('// $cat (${cards.length})');
      for (final card in cards) {
        final foilTag = card.isFoil ? ' *F*' : '';
        final setInfo = card.setCode.isNotEmpty ? ' (${card.setCode.toLowerCase()})' : '';
        final collectorInfo = card.collectorNumber.isNotEmpty ? ' ${card.collectorNumber}' : '';
        buffer.writeln('${card.quantity} ${card.name}$setInfo$collectorInfo$foilTag');
      }
      buffer.writeln();
    });

    return buffer.toString().trim();
  }

  /// Generate Moxfield compatible CSV
  static String toMoxfieldCsv(Deck deck) {
    final List<List<dynamic>> rows = [
      [
        'Count',
        'Tradelist Count',
        'Name',
        'Edition',
        'Condition',
        'Language',
        'Foil',
        'Tags',
        'Last Modified',
        'Collector Number',
        'Alter',
        'Proxy',
        'Purchase Price'
      ]
    ];

    for (final card in deck.cards) {
      rows.add([
        card.quantity,
        0,
        card.name,
        card.setCode.toLowerCase(),
        'Near Mint',
        'English',
        card.isFoil ? 'foil' : '',
        card.category,
        DateTime.now().toIso8601String(),
        card.collectorNumber,
        'FALSE',
        'FALSE',
        card.currentPriceUsd > 0 ? card.currentPriceUsd.toStringAsFixed(2) : ''
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }

  /// Generate Excel / General CSV format
  static String toExcelCsv(Deck deck) {
    final List<List<dynamic>> rows = [
      [
        'Cantidad',
        'Nombre',
        'Coste de Maná',
        'CMC',
        'Tipo',
        'Categoría',
        'Edición',
        'Número',
        'Rareza',
        'Foil',
        'Precio Unitario USD',
        'Precio Total USD'
      ]
    ];

    for (final card in deck.cards) {
      rows.add([
        card.quantity,
        card.name,
        card.manaCost,
        card.cmc,
        card.typeLine,
        card.category,
        card.setName.isNotEmpty ? card.setName : card.setCode,
        card.collectorNumber,
        card.rarity,
        card.isFoil ? 'SÍ' : 'NO',
        card.currentPriceUsd.toStringAsFixed(2),
        card.totalPriceUsd.toStringAsFixed(2),
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }

  /// Generate and preview/print PDF
  static Future<void> exportPdf(Deck deck) async {
    final doc = pw.Document();

    final fontBold = await PdfGoogleFonts.robotoBold();
    final fontRegular = await PdfGoogleFonts.robotoRegular();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      deck.name,
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 22,
                        color: PdfColors.deepPurple900,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Formato: ${deck.format} • ${deck.totalCards} cartas',
                      style: pw.TextStyle(font: fontRegular, fontSize: 12, color: PdfColors.grey700),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      Formatters.formatUsd(deck.totalPriceUsd),
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 18,
                        color: PdfColors.green800,
                      ),
                    ),
                    pw.Text(
                      'Valor Total Estimado',
                      style: pw.TextStyle(font: fontRegular, fontSize: 10, color: PdfColors.grey600),
                    ),
                  ],
                ),
              ],
            ),
            pw.Divider(thickness: 1.5, color: PdfColors.deepPurple200),
            pw.SizedBox(height: 10),

            // Summary table of categories
            pw.Text(
              'Desglose por Tipos de Carta',
              style: pw.TextStyle(font: fontBold, fontSize: 14),
            ),
            pw.SizedBox(height: 6),
            pw.Wrap(
              spacing: 12,
              runSpacing: 6,
              children: deck.categoryCounts.entries
                  .where((e) => e.value > 0)
                  .map(
                    (e) => pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey200,
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text(
                        '${e.key}: ${e.value}',
                        style: pw.TextStyle(font: fontRegular, fontSize: 10),
                      ),
                    ),
                  )
                  .toList(),
            ),
            pw.SizedBox(height: 16),

            // Cards Table
            pw.Text(
              'Lista Completa de Cartas',
              style: pw.TextStyle(font: fontBold, fontSize: 14),
            ),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headers: ['Cant.', 'Nombre', 'Tipo', 'Edición', 'Foil', 'P. Unit', 'Total'],
              headerStyle: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.deepPurple800),
              cellStyle: pw.TextStyle(font: fontRegular, fontSize: 8),
              cellAlignment: pw.Alignment.centerLeft,
              data: deck.cards.map((c) {
                return [
                  '${c.quantity}x',
                  c.name,
                  c.typeLine,
                  c.setCode.toUpperCase(),
                  c.isFoil ? '★ Foil' : '-',
                  Formatters.formatUsd(c.currentPriceUsd),
                  Formatters.formatUsd(c.totalPriceUsd),
                ];
              }).toList(),
            ),

            pw.SizedBox(height: 20),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'Generado con MyDeck App • ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                style: pw.TextStyle(font: fontRegular, fontSize: 8, color: PdfColors.grey500),
              ),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: '${deck.name.replaceAll(' ', '_')}_deck.pdf',
    );
  }

  /// Generate a shareable URL / Code for other app users
  static String generateSharePayload(Deck deck) {
    final payload = {
      'app': 'mydeck',
      'version': '1.0',
      'deck': deck.toJson(),
    };
    final jsonStr = jsonEncode(payload);
    final base64Code = base64Encode(utf8.encode(jsonStr));
    return 'mydeck://import?data=$base64Code';
  }

  /// Decode a shared deck payload
  static Deck? importFromSharePayload(String codeOrUrl) {
    try {
      String cleanCode = codeOrUrl.trim();
      if (cleanCode.startsWith('mydeck://import?data=')) {
        cleanCode = cleanCode.replaceFirst('mydeck://import?data=', '');
      }
      final decodedJson = utf8.decode(base64Decode(cleanCode));
      final Map<String, dynamic> data = jsonDecode(decodedJson);
      if (data['deck'] != null) {
        return Deck.fromJson(data['deck']);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Native OS share
  static Future<void> shareDeckAsText(Deck deck) async {
    final text = '''
🎴 Mazo de Magic: The Gathering
Nombre: ${deck.name}
Formato: ${deck.format}
Total Cartas: ${deck.totalCards}
Valor Estimado: ${Formatters.formatUsd(deck.totalPriceUsd)}

Enlace para importar en MyDeck:
${generateSharePayload(deck)}
''';
    await Share.share(text, subject: 'Mazo MTG: ${deck.name}');
  }
}
