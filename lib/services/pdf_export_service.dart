import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/medication.dart';

class PdfExportService {
  /// Generates an inventory PDF and returns the file path. [medications] can be filtered (e.g. stock > 0).
  /// [memberNameById] optional map to display member names (id -> name).
  static Future<String> generateInventoryPdf(
    List<Medication> medications, {
    Map<int, String>? memberNameById,
    bool onlyInStock = true,
  }) async {
    final list = onlyInStock ? medications.where((m) => m.quantite > 0).toList() : medications;
    final pdf = pw.Document();
    final dateStr = DateFormat.yMMMd('fr').format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Inventaire MediStock', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text('Export du $dateStr', style: const pw.TextStyle(fontSize: 10)),
                pw.SizedBox(height: 16),
              ],
            ),
          ),
          pw.Table(
    border: pw.TableBorder.all(width: 0.5),
    columnWidths: {
      0: const pw.FlexColumnWidth(3),
      1: const pw.FlexColumnWidth(1),
      2: const pw.FlexColumnWidth(1),
      3: const pw.FlexColumnWidth(1.5),
      4: const pw.FlexColumnWidth(1.5),
    },
    children: [
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey300),
        children: [
          pw.Padding(child: pw.Text('Médicament', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)), padding: const pw.EdgeInsets.all(4)),
          pw.Padding(child: pw.Text('Qté', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)), padding: const pw.EdgeInsets.all(4)),
          pw.Padding(child: pw.Text('Unité', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)), padding: const pw.EdgeInsets.all(4)),
          pw.Padding(child: pw.Text('Péremption', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)), padding: const pw.EdgeInsets.all(4)),
          pw.Padding(child: pw.Text('Lieu / Personne', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)), padding: const pw.EdgeInsets.all(4)),
        ],
      ),
      ...list.map((m) {
        final peremption = m.datePeremption != null ? DateFormat.yMMMd('fr').format(m.datePeremption!) : '–';
        final lieuPersonne = [
          if (m.lieu != null && m.lieu!.isNotEmpty) m.lieu,
          if (m.memberId != null && (memberNameById != null)) memberNameById[m.memberId],
        ].whereType<String>().join(' • ');
        return pw.TableRow(
          children: [
            pw.Padding(child: pw.Text(m.nom, maxLines: 2), padding: const pw.EdgeInsets.all(4)),
            pw.Padding(child: pw.Text('${m.quantite}'), padding: const pw.EdgeInsets.all(4)),
            pw.Padding(child: pw.Text(m.unite), padding: const pw.EdgeInsets.all(4)),
            pw.Padding(child: pw.Text(peremption), padding: const pw.EdgeInsets.all(4)),
            pw.Padding(child: pw.Text(lieuPersonne.isEmpty ? '–' : lieuPersonne, maxLines: 1), padding: const pw.EdgeInsets.all(4)),
          ],
        );
      }),
    ],
          ),
        ],
      ),
    );

    final dir = await getTemporaryDirectory();
    final name = 'medistock_inventaire_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }
}
