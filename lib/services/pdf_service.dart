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
  // Cache fonts to avoid loading them multiple times
  static pw.Font? _arabicFont;
  static pw.Font? _arabicBoldFont;
  static pw.Font? _englishFont;
  static pw.Font? _englishBoldFont;

  static Future<void> _loadFonts() async {
    if (_arabicFont == null) {
      _arabicFont = await PdfGoogleFonts.notoSansArabicRegular();
      _arabicBoldFont = await PdfGoogleFonts.notoSansArabicBold();
      _englishFont = await PdfGoogleFonts.robotoRegular();
      _englishBoldFont = await PdfGoogleFonts.robotoBold();
    }
  }

  static pw.TextStyle _getTextStyle({
    required String text,
    bool isBold = false,
    double fontSize = 12,
  }) {
    // Check if text contains Arabic characters
    final hasArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(text);

    return pw.TextStyle(
      font: hasArabic
          ? (isBold ? _arabicBoldFont! : _arabicFont!)
          : (isBold ? _englishBoldFont! : _englishFont!),
      fontSize: fontSize,
      fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
      fontFallback: [
        _arabicFont!,
        _englishFont!,
        _arabicBoldFont!,
        _englishBoldFont!,
      ],
    );
  }

  static Future<Uint8List> generateAccountStatementPdf({
    required Contact contact,
    required List<AccountStatement> statements,
    required String fromDate,
    required String toDate,
  }) async {
    await _loadFonts();

    final pdf = pw.Document();

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
                padding: const pw.EdgeInsets.all(5),
                decoration: const pw.BoxDecoration(
                  color: PdfColors.grey200,
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      'كشف الحساب - ${ArabicTextHelper.cleanText(contact.nameAr)}',
                      style: _getTextStyle(
                        text: 'كشف الحساب - ${ArabicTextHelper.cleanText(contact.nameAr)}',
                        isBold: true,
                        fontSize: 18,
                      ),
                    ),

                    pw.SizedBox(height: 5),

                    pw.Text(
                      'التاريخ: ${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
                      style: _getTextStyle(
                        text: 'التاريخ: ${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
                        fontSize: 12,
                      ),
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
                      style: _getTextStyle(
                        text: 'رقم العميل: ${contact.code}',
                        fontSize: 12,
                      ),
                    ),
                    if (contact.streetAddress?.isNotEmpty == true)
                      pw.Text(
                        'العنوان: ${ArabicTextHelper.cleanText(contact.streetAddress!)}',
                        style: _getTextStyle(
                          text: 'العنوان: ${ArabicTextHelper.cleanText(contact.streetAddress!)}',
                          fontSize: 12,
                        ),
                      ),
                    if (contact.taxId?.isNotEmpty == true)
                      pw.Text(
                        'الرقم الضريبي: ${contact.taxId}',
                        style: _getTextStyle(
                          text: 'الرقم الضريبي: ${contact.taxId}',
                          fontSize: 12,
                        ),
                      ),
                    if (contact.phone?.isNotEmpty == true)
                      pw.Text(
                        'الهاتف: ${_formatPhoneNumber(contact.phone!)}',
                        style: _getTextStyle(
                          text: 'الهاتف: ${_formatPhoneNumber(contact.phone!)}',
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Table with LTR column order
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400),
                columnWidths: {

                  0: const pw.FlexColumnWidth(1),      // الرصيد الجاري
                  1: const pw.FlexColumnWidth(1),      // دائن
                  2: const pw.FlexColumnWidth(1),      // مدين
                  3: const pw.FlexColumnWidth(1),      // المستند
                  4: const pw.FlexColumnWidth(1),      // التاريخ
                  5: const pw.FixedColumnWidth(30),    // #

                },
                children: [

                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [

                      _buildTableCell('الرصيد الجاري', isHeader: true),
                      _buildTableCell('دائن', isHeader: true),
                      _buildTableCell('مدين', isHeader: true),
                      _buildTableCell('المستند', isHeader: true),
                      _buildTableCell('التاريخ', isHeader: true),
                      _buildTableCell('#', isHeader: true),

                    ],
                  ),

                  // Data rows
                  ...statements.asMap().entries.map((entry) {
                    final index = entry.key + 1;
                    final statement = entry.value;

                    return pw.TableRow(
                      children: [

                        _buildTableCell(_formatNumber(statement.runningBalance)),
                        _buildTableCell(_formatNumber(statement.credit)),
                        _buildTableCell(_formatNumber(statement.debit)),
                        _buildTableCell(ArabicTextHelper.cleanText(statement.displayName)),
                        _buildTableCell(statement.docDate),
                        _buildTableCell(index.toString()),

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
    await _loadFonts();

    final pdf = pw.Document();

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
                      style: _getTextStyle(
                        text: ArabicTextHelper.cleanText(documentTitle),
                        isBold: true,
                        fontSize: 18,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      ArabicTextHelper.cleanText(contact.nameAr),
                      style: _getTextStyle(
                        text: ArabicTextHelper.cleanText(contact.nameAr),
                        fontSize: 14,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      'التاريخ: ${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
                      style: _getTextStyle(
                        text: 'التاريخ: ${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
                        fontSize: 12,
                      ),
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
                      style: _getTextStyle(
                        text: 'رقم العميل: ${contact.code}',
                        fontSize: 12,
                      ),
                    ),
                    if (contact.streetAddress?.isNotEmpty == true)
                      pw.Text(
                        'العنوان: ${ArabicTextHelper.cleanText(contact.streetAddress!)}',
                        style: _getTextStyle(
                          text: 'العنوان: ${ArabicTextHelper.cleanText(contact.streetAddress!)}',
                          fontSize: 12,
                        ),
                      ),
                    if (contact.taxId?.isNotEmpty == true)
                      pw.Text(
                        'الرقم الضريبي: ${contact.taxId}',
                        style: _getTextStyle(
                          text: 'الرقم الضريبي: ${contact.taxId}',
                          fontSize: 12,
                        ),
                      ),
                    if (contact.phone?.isNotEmpty == true)
                      pw.Text(
                        'الهاتف: ${_formatPhoneNumber(contact.phone!)}',
                        style: _getTextStyle(
                          text: 'الهاتف: ${_formatPhoneNumber(contact.phone!)}',
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Items table with LTR column order
              if (items.isNotEmpty) ...[
                pw.Table(
                  defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
                  border: pw.TableBorder.all(color: PdfColors.grey400),
                  columnWidths: {

                    5: const pw.FixedColumnWidth(30),    // #
                    4: const pw.FlexColumnWidth(1.5),      // رقم الصنف
                    3: const pw.FlexColumnWidth(3),      // اسم الصنف
                    2: const pw.FlexColumnWidth(1),      // الكمية
                    1: const pw.FlexColumnWidth(1),      // السعر
                    0: const pw.FlexColumnWidth(1),
                    // المبلغ
                  },
                  children: [
                    // Header - arranged left to right
                    pw.TableRow(

                      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                      children: [

                        _buildTableCell('المجموع', isHeader: true),

                        _buildTableCell('السعر', isHeader: true),

                        _buildTableCell('الكمية', isHeader: true),

                        _buildTableCell('اسم الصنف', isHeader: true),

                        _buildTableCell('رقم الصنف', isHeader: true),

                        _buildTableCell('#', isHeader: true),

                      ],
                    ),

                    // Items
                    ...items.asMap().entries.map((entry) {
                      final index = entry.key + 1;
                      final item = entry.value;

                      return pw.TableRow(
                        children: [

                          _buildTableCell(_formatNumber(item.amount)),

                          _buildTableCell(_formatNumber(item.price)),

                          _buildTableCell('${_formatNumber(item.quantity)} ${item.unit}'),

                          _buildTableCell(ArabicTextHelper.cleanText(item.name)),

                          _buildTableCell(item.item),

                          _buildTableCell(index.toString()),

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
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'المجموع: ${_formatNumber(totalAmount.toString())}',
                        style: _getTextStyle(
                          text: 'المجموع: ${_formatNumber(totalAmount.toString())}',
                          isBold: true,
                          fontSize: 12,
                        ),
                        textDirection: pw.TextDirection.rtl,
                      ),
                      if (tax > 0)
                        pw.Text(
                          'ضريبة ال 16%: ${_formatNumber(tax.toString())}',
                          style: _getTextStyle(
                            text: 'ضريبة ال 16%: ${_formatNumber(tax.toString())}',
                            fontSize: 12,
                          ),
                          textDirection: pw.TextDirection.rtl,
                        ),
                      if (discount != 0)
                        pw.Text(
                          'الخصم: ${_formatNumber(discount.toString())}',
                          style: _getTextStyle(
                            text: 'الخصم: ${_formatNumber(discount.toString())}',
                            fontSize: 12,
                          ),
                          textDirection: pw.TextDirection.rtl,
                        ),
                      pw.Text(
                        'بعد الخصم: ${_formatNumber(afterDiscount.toString())}',
                        style: _getTextStyle(
                          text: 'بعد الخصم: ${_formatNumber(afterDiscount.toString())}',
                          fontSize: 12,
                        ),
                        textDirection: pw.TextDirection.rtl,
                      ),
                      pw.Text(
                        'الصافي: ${_formatNumber(netAmount.toString())}',
                        style: _getTextStyle(
                          text: 'الصافي: ${_formatNumber(netAmount.toString())}',
                          isBold: true,
                          fontSize: 14,
                        ),
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
                        style: _getTextStyle(
                          text: 'ملاحظة:',
                          isBold: true,
                          fontSize: 12,
                        ),
                        textDirection: pw.TextDirection.rtl,
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        ArabicTextHelper.cleanText(details.first.docComment),
                        style: _getTextStyle(
                          text: ArabicTextHelper.cleanText(details.first.docComment),
                          fontSize: 10,
                        ),
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
      String text, {
        bool isHeader = false,
      }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: _getTextStyle(
          text: text,
          isBold: isHeader,
          fontSize: isHeader ? 12 : 10,
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

  // New method to format phone numbers properly for RTL display
  static String _formatPhoneNumber(String phone) {
    if (phone.isEmpty) return '';

    // Remove any existing formatting
    String cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');

    // Format based on common patterns
    if (cleanPhone.startsWith('+')) {
      // International format
      return cleanPhone;
    } else if (cleanPhone.length >= 10) {
      // Local format - add parentheses and dashes for better readability
      if (cleanPhone.length == 10) {
        return '(${cleanPhone.substring(0, 3)}) ${cleanPhone.substring(3, 6)}-${cleanPhone.substring(6)}';
      } else if (cleanPhone.length == 11) {
        return '(${cleanPhone.substring(0, 3)}) ${cleanPhone.substring(3, 7)}-${cleanPhone.substring(7)}';
      }
    }

    return cleanPhone;
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