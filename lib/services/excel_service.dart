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

    // Define headers (moved to top)
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

    // Company Name
    sheet.updateCell(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
      TextCellValue('EKIBAM Company'),
      cellStyle: CellStyle(bold: true, fontSize: 16, horizontalAlign: HorizontalAlign.Left),
    );

    // Report Title
    sheet.updateCell(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2),
      TextCellValue('RAPPORT D\'ACHATS DÉTAILLÉ'),
      cellStyle: CellStyle(bold: true, fontSize: 20, horizontalAlign: HorizontalAlign.Center, backgroundColorHex: ExcelColor.fromHexString('#ADD8E6')),
    );
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2), CellIndex.indexByColumnRow(columnIndex: headers.length - 1, rowIndex: 2));

    // Report Date
    sheet.updateCell(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 3),
      TextCellValue('Date du rapport: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}'),
      cellStyle: CellStyle(fontSize: 10, horizontalAlign: HorizontalAlign.Left),
    );
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 3), CellIndex.indexByColumnRow(columnIndex: headers.length - 1, rowIndex: 3));

    // Add headers to row 5
    sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());

    // Style header row
    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 5)); // Adjusted row index for new header
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#4CAF50'), // Green header
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'), // White text
        bottomBorder: Border(borderStyle: BorderStyle.Medium),
        topBorder: Border(borderStyle: BorderStyle.Medium),
        leftBorder: Border(borderStyle: BorderStyle.Medium),
        rightBorder: Border(borderStyle: BorderStyle.Medium),
      );
    }

    // Flatten the data and add rows
    double grandTotal = 0.0;
    int currentRow = 6; // Start data from row 6 (0-indexed)
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
          TextCellValue(item.comment ?? purchase.comments ?? ''), // Use item comment, fallback to purchase comment
        ];
        sheet.appendRow(row);
        // Apply borders to data cells
        for (int i = 0; i < row.length; i++) {
          final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: currentRow));
          cell.cellStyle = CellStyle(
            bottomBorder: Border(borderStyle: BorderStyle.Thin),
            topBorder: Border(borderStyle: BorderStyle.Thin),
            leftBorder: Border(borderStyle: BorderStyle.Thin),
            rightBorder: Border(borderStyle: BorderStyle.Thin),
          );
        }
        currentRow++;
        grandTotal += item.total;
      }
    }

    // Add summary row
    final summaryRowIndex = currentRow; // Use currentRow as the starting index for summary
    sheet.appendRow([
      TextCellValue(''), TextCellValue(''), TextCellValue(''),
      TextCellValue(''), TextCellValue(''), TextCellValue(''),
      TextCellValue(''),
      TextCellValue('TOTAL GÉNÉRAL'),
      DoubleCellValue(grandTotal),
      TextCellValue(''), // Empty cell for comments column
    ]);

    // Style summary row
    final totalLabelCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: summaryRowIndex));
    totalLabelCell.cellStyle = CellStyle(bold: true, horizontalAlign: HorizontalAlign.Right, backgroundColorHex: ExcelColor.fromHexString('#FFFACD'));
    final totalValueCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: summaryRowIndex));
    totalValueCell.cellStyle = CellStyle(bold: true, backgroundColorHex: ExcelColor.fromHexString('#FFEB3B'), bottomBorder: Border(borderStyle: BorderStyle.Medium), topBorder: Border(borderStyle: BorderStyle.Medium));

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