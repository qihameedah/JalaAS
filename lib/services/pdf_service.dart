// lib/services/pdf_service.dart
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/contact.dart';
import '../models/account_statement.dart';
import '../utils/arabic_text_helper.dart';

class PdfService {
  static Future<Uint8List> generateAccountStatementPdf({
    required Contact contact,
    required List<AccountStatement> statements,
    required String fromDate,
    required String toDate,
  }) async {
    final pdf = pw.Document();

    // Load Arabic font
    final arabicFont = await PdfGoogleFonts.notoSansArabicRegular();
    final arabicBoldFont = await PdfGoogleFonts.notoSansArabicBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(20),
                decoration: const pw.BoxDecoration(
                  color: PdfColors.grey200,
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      'كشف الحساب - ${ArabicTextHelper.cleanText(contact.nameAr)}',
                      style: pw.TextStyle(
                        font: arabicBoldFont,
                        fontSize: 18,
                      ),
                      textDirection: pw.TextDirection.rtl,
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      'التاريخ: ${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
                      style: pw.TextStyle(
                        font: arabicFont,
                        fontSize: 12,
                      ),
                      textDirection: pw.TextDirection.rtl,
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Contact Information
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'رقم العميل: ${contact.code}',
                      style: pw.TextStyle(font: arabicFont, fontSize: 12),
                      textDirection: pw.TextDirection.rtl,
                    ),
                    if (contact.streetAddress?.isNotEmpty == true)
                      pw.Text(
                        'العنوان: ${ArabicTextHelper.cleanText(contact.streetAddress!)}',
                        style: pw.TextStyle(font: arabicFont, fontSize: 12),
                        textDirection: pw.TextDirection.rtl,
                      ),
                    if (contact.taxId?.isNotEmpty == true)
                      pw.Text(
                        'الرقم الضريبي: ${contact.taxId}',
                        style: pw.TextStyle(font: arabicFont, fontSize: 12),
                        textDirection: pw.TextDirection.rtl,
                      ),
                    if (contact.phone?.isNotEmpty == true)
                      pw.Text(
                        'الهاتف: ${contact.phone}',
                        style: pw.TextStyle(font: arabicFont, fontSize: 12),
                        textDirection: pw.TextDirection.rtl,
                      ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400),
                columnWidths: {
                  0: const pw.FixedColumnWidth(30),
                  1: const pw.FlexColumnWidth(2),
                  2: const pw.FlexColumnWidth(1),
                  3: const pw.FlexColumnWidth(1),
                  4: const pw.FlexColumnWidth(1),
                  5: const pw.FlexColumnWidth(1),
                },
                children: [
                  // Header
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      _buildTableCell('الرصيد الجاري', arabicBoldFont,
                          isHeader: true),
                      _buildTableCell('دائن', arabicBoldFont, isHeader: true),
                      _buildTableCell('مدين', arabicBoldFont, isHeader: true),
                      _buildTableCell('المستند', arabicBoldFont,
                          isHeader: true),
                      _buildTableCell('التاريخ', arabicBoldFont,
                          isHeader: true),
                      _buildTableCell('#', arabicBoldFont, isHeader: true),
                    ],
                  ),

                  // Data rows
                  ...statements.asMap().entries.map((entry) {
                    final index = entry.key + 1;
                    final statement = entry.value;

                    return pw.TableRow(
                      children: [
                        _buildTableCell(
                          _formatNumber(statement.runningBalance),
                          arabicFont,
                        ),
                        _buildTableCell(
                          _formatNumber(statement.credit),
                          arabicFont,
                        ),
                        _buildTableCell(
                          _formatNumber(statement.debit),
                          arabicFont,
                        ),
                        _buildTableCell(
                          ArabicTextHelper.cleanText(statement.displayName),
                          arabicFont,
                        ),
                        _buildTableCell(statement.docDate, arabicFont),
                        _buildTableCell(index.toString(), arabicFont),
                      ],
                    );
                  }),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static Future<Uint8List> generateInvoiceDetailPdf({
    required Contact contact,
    required List<AccountStatementDetail> details,
    required String documentTitle,
  }) async {
    final pdf = pw.Document();

    // Load Arabic font
    final arabicFont = await PdfGoogleFonts.notoSansArabicRegular();
    final arabicBoldFont = await PdfGoogleFonts.notoSansArabicBold();

    // Calculate totals
    double totalAmount = 0;
    double tax = 0;
    double discount = 0;

    final items = details.where((d) => d.item.isNotEmpty).toList();
    for (final item in items) {
      totalAmount += _parseNumber(item.amount);
    }

    if (items.isNotEmpty) {
      tax = _parseNumber(items.last.tax);
      discount = _parseNumber(items.last.docDiscount);
    }

    final afterDiscount = _roundToNearest(totalAmount);
    final netAmount = afterDiscount;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(20),
                decoration: const pw.BoxDecoration(
                  color: PdfColors.grey200,
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      ArabicTextHelper.cleanText(documentTitle),
                      style: pw.TextStyle(
                        font: arabicBoldFont,
                        fontSize: 18,
                      ),
                      textDirection: pw.TextDirection.rtl,
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      ArabicTextHelper.cleanText(contact.nameAr),
                      style: pw.TextStyle(
                        font: arabicFont,
                        fontSize: 14,
                      ),
                      textDirection: pw.TextDirection.rtl,
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      'التاريخ: ${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
                      style: pw.TextStyle(
                        font: arabicFont,
                        fontSize: 12,
                      ),
                      textDirection: pw.TextDirection.rtl,
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Contact Information
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'رقم العميل: ${contact.code}',
                      style: pw.TextStyle(font: arabicFont, fontSize: 12),
                      textDirection: pw.TextDirection.rtl,
                    ),
                    if (contact.streetAddress?.isNotEmpty == true)
                      pw.Text(
                        'العنوان: ${ArabicTextHelper.cleanText(contact.streetAddress!)}',
                        style: pw.TextStyle(font: arabicFont, fontSize: 12),
                        textDirection: pw.TextDirection.rtl,
                      ),
                    if (contact.taxId?.isNotEmpty == true)
                      pw.Text(
                        'الرقم الضريبي: ${contact.taxId}',
                        style: pw.TextStyle(font: arabicFont, fontSize: 12),
                        textDirection: pw.TextDirection.rtl,
                      ),
                    if (contact.phone?.isNotEmpty == true)
                      pw.Text(
                        'الهاتف: ${contact.phone}',
                        style: pw.TextStyle(font: arabicFont, fontSize: 12),
                        textDirection: pw.TextDirection.rtl,
                      ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Items table
              if (items.isNotEmpty) ...[
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey400),
                  columnWidths: {
                    0: const pw.FixedColumnWidth(30),
                    1: const pw.FlexColumnWidth(1),
                    2: const pw.FlexColumnWidth(3),
                    3: const pw.FlexColumnWidth(1),
                    4: const pw.FlexColumnWidth(1),
                    5: const pw.FlexColumnWidth(1),
                  },
                  children: [
                    // Header
                    pw.TableRow(
                      decoration:
                          const pw.BoxDecoration(color: PdfColors.grey200),
                      children: [
                        _buildTableCell('المبلغ', arabicBoldFont,
                            isHeader: true),
                        _buildTableCell('السعر', arabicBoldFont,
                            isHeader: true),
                        _buildTableCell('الكمية', arabicBoldFont,
                            isHeader: true),
                        _buildTableCell('اسم الصنف', arabicBoldFont,
                            isHeader: true),
                        _buildTableCell('رقم الصنف', arabicBoldFont,
                            isHeader: true),
                        _buildTableCell('#', arabicBoldFont, isHeader: true),
                      ],
                    ),

                    // Items
                    ...items.asMap().entries.map((entry) {
                      final index = entry.key + 1;
                      final item = entry.value;

                      return pw.TableRow(
                        children: [
                          _buildTableCell(
                            _formatNumber(item.amount),
                            arabicFont,
                          ),
                          _buildTableCell(
                            _formatNumber(item.price),
                            arabicFont,
                          ),
                          _buildTableCell(
                            '${_formatNumber(item.quantity)} ${item.unit}',
                            arabicFont,
                          ),
                          _buildTableCell(
                            ArabicTextHelper.cleanText(item.name),
                            arabicFont,
                          ),
                          _buildTableCell(item.item, arabicFont),
                          _buildTableCell(index.toString(), arabicFont),
                        ],
                      );
                    }),
                  ],
                ),

                pw.SizedBox(height: 20),

                // Totals
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'المجموع: ${_formatNumber(totalAmount.toString())}',
                        style: pw.TextStyle(font: arabicBoldFont, fontSize: 12),
                        textDirection: pw.TextDirection.rtl,
                      ),
                      if (tax > 0)
                        pw.Text(
                          'ضريبة ال 16%: ${_formatNumber(tax.toString())}',
                          style: pw.TextStyle(font: arabicFont, fontSize: 12),
                          textDirection: pw.TextDirection.rtl,
                        ),
                      if (discount != 0)
                        pw.Text(
                          'الخصم: ${_formatNumber(discount.toString())}',
                          style: pw.TextStyle(font: arabicFont, fontSize: 12),
                          textDirection: pw.TextDirection.rtl,
                        ),
                      pw.Text(
                        'بعد الخصم: ${_formatNumber(afterDiscount.toString())}',
                        style: pw.TextStyle(font: arabicFont, fontSize: 12),
                        textDirection: pw.TextDirection.rtl,
                      ),
                      pw.Text(
                        'الصافي: ${_formatNumber(netAmount.toString())}',
                        style: pw.TextStyle(font: arabicBoldFont, fontSize: 14),
                        textDirection: pw.TextDirection.rtl,
                      ),
                    ],
                  ),
                ),
              ],

              // Comment
              if (details.isNotEmpty &&
                  details.first.docComment.isNotEmpty) ...[
                pw.SizedBox(height: 20),
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'ملاحظة:',
                        style: pw.TextStyle(font: arabicBoldFont, fontSize: 12),
                        textDirection: pw.TextDirection.rtl,
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        ArabicTextHelper.cleanText(details.first.docComment),
                        style: pw.TextStyle(font: arabicFont, fontSize: 10),
                        textDirection: pw.TextDirection.rtl,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildTableCell(
    String text,
    pw.Font font, {
    bool isHeader = false,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontSize: isHeader ? 12 : 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: pw.TextAlign.center,
        textDirection: pw.TextDirection.rtl,
      ),
    );
  }

  static String _formatNumber(String numberStr) {
    if (numberStr.isEmpty) return '-';

    try {
      final number = double.parse(numberStr.replaceAll(',', ''));
      final formatter = NumberFormat('#,##0.00');
      return formatter.format(number);
    } catch (e) {
      return numberStr;
    }
  }

  static double _parseNumber(String numberStr) {
    if (numberStr.isEmpty) return 0;

    try {
      return double.parse(numberStr.replaceAll(',', ''));
    } catch (e) {
      return 0;
    }
  }

  static double _roundToNearest(double amount) {
    final decimal = amount - amount.floor();
    if (decimal >= 0.5) {
      return amount.ceil().toDouble();
    } else {
      return amount.floor().toDouble();
    }
  }
}
