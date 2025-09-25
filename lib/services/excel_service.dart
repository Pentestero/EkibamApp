import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:file_saver/file_saver.dart';
import 'package:intl/intl.dart';
import 'package:provisions/models/purchase.dart';

class ExcelService {
  static Future<void> shareExcelReport(List<Purchase> purchases) async {
    final excel = Excel.createExcel();
    final sheet = excel['Rapport d\'Achats'];
    excel.delete('Sheet1'); // Remove default sheet

    // Define headers
    const headers = [
      'ID Achat',
      'Date',
      'Propriétaire',
      'Type de Projet',
      'Produit',
      'Fournisseur',
      'Quantité',
      'Prix Unitaire (FCFA)',
      'Sous-Total (FCFA)',
      'Mode de Paiement',
      'Commentaires',
    ];
    sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());

    // Style header row
    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#D2B48C'),
      );
    }

    // Flatten the data and add rows
    double grandTotal = 0.0;
    for (final purchase in purchases) {
      for (final item in purchase.items) {
        final row = [
          TextCellValue(purchase.id.toString()),
          TextCellValue(DateFormat('dd/MM/yyyy').format(purchase.date)),
          TextCellValue(purchase.owner),
          TextCellValue(purchase.projectType),
          TextCellValue(item.productName ?? 'N/A'),
          TextCellValue(item.supplierName ?? 'N/A'),
          DoubleCellValue(item.quantity),
          DoubleCellValue(item.unitPrice),
          DoubleCellValue(item.total),
          TextCellValue(purchase.paymentMethod),
          TextCellValue(purchase.comments),
        ];
        sheet.appendRow(row);
        grandTotal += item.total;
      }
    }

    // Add summary row
    final summaryRowIndex = sheet.maxRows;
    sheet.appendRow([
      TextCellValue(''), TextCellValue(''), TextCellValue(''),
      TextCellValue(''), TextCellValue(''), TextCellValue(''),
      TextCellValue(''),
      TextCellValue('TOTAL GÉNÉRAL'),
      DoubleCellValue(grandTotal),
    ]);

    // Style summary row
    final totalLabelCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: summaryRowIndex));
    totalLabelCell.cellStyle = CellStyle(bold: true, horizontalAlign: HorizontalAlign.Right);
    final totalValueCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: summaryRowIndex));
    totalValueCell.cellStyle = CellStyle(bold: true, backgroundColorHex: ExcelColor.fromHexString('#FFEB3B'));

    // Auto-fit columns
    for (int i = 0; i < headers.length; i++) {
      sheet.setColumnAutoFit(i);
    }

    // Save the file
    final bytes = excel.encode();
    if (bytes != null) {
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      await FileSaver.instance.saveFile(
        name: 'Rapport_Achats_$timestamp.xlsx',
        bytes: Uint8List.fromList(bytes),
        mimeType: MimeType.microsoftExcel,
      );
    }
  }
}