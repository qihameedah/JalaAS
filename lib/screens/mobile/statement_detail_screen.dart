// lib/screens/mobile/statement_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../models/contact.dart';
import '../../models/account_statement.dart';
import '../../models/account_statement.dart' as models;
import '../../services/api_service.dart';
import '../../services/pdf_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../utils/arabic_text_helper.dart';

class StatementDetailScreen extends StatefulWidget {
  final Contact contact;
  final AccountStatement statement;
  final String fromDate;
  final String toDate;

  const StatementDetailScreen({
    super.key,
    required this.contact,
    required this.statement,
    required this.fromDate,
    required this.toDate,
  });

  @override
  State<StatementDetailScreen> createState() => _StatementDetailScreenState();
}

class _StatementDetailScreenState extends State<StatementDetailScreen> {
  List<models.AccountStatementDetail> _details = [];
  bool _isLoading = true;
  bool _isGeneratingPdf = false;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final details = await ApiService.getAccountStatementDetails(
        contactCode: widget.contact.code,
        fromDate: widget.fromDate,
        toDate: widget.toDate,
      );

      // Filter details for this specific statement
      final filteredDetails = details.where((detail) {
        return ArabicTextHelper.cleanText(detail.shownParent) ==
            ArabicTextHelper.cleanText(widget.statement.shownParent);
      }).toList();

      setState(() {
        _details = filteredDetails;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      Helpers.showSnackBar(
        context,
        'فشل في تحميل تفاصيل المستند: ${e.toString()}',
        isError: true,
      );
    }
  }

  Future<void> _generatePdf() async {
    setState(() {
      _isGeneratingPdf = true;
    });

    try {
      final pdfBytes = await PdfService.generateInvoiceDetailPdf(
        contact: widget.contact,
        details: _details,
        documentTitle: ArabicTextHelper.cleanText(widget.statement.displayName),
      );

      await Printing.layoutPdf(
        onLayout: (format) async => pdfBytes,
        name:
            '${widget.statement.documentType}_${widget.contact.code}_${widget.statement.documentNumber}.pdf',
      );
    } catch (e) {
      Helpers.showSnackBar(
        context,
        'فشل في إنشاء ملف PDF: ${e.toString()}',
        isError: true,
      );
    } finally {
      setState(() {
        _isGeneratingPdf = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(ArabicTextHelper.cleanText(widget.contact.nameAr)),
        actions: [
          if (_details.isNotEmpty)
            IconButton(
              icon: _isGeneratingPdf
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.picture_as_pdf),
              onPressed: _isGeneratingPdf ? null : _generatePdf,
              tooltip: 'إنشاء PDF',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDetails,
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _details.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'لا توجد تفاصيل لهذا المستند',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final documentType = widget.statement.documentType;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Document Title
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ArabicTextHelper.cleanText(widget.statement.displayName),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_details.isNotEmpty &&
                      _details.first.docComment.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ملاحظة:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            ArabicTextHelper.cleanText(
                                _details.first.docComment),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Content based on document type
          if (documentType == 'payment')
            _buildPaymentDetails()
          else
            _buildInvoiceDetails(),
        ],
      ),
    );
  }

  Widget _buildPaymentDetails() {
    if (_details.isEmpty) return const SizedBox();

    final detail = _details.first;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'تفاصيل القبض',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Table(
              border: TableBorder.all(color: Colors.grey[300]!),
              columnWidths: const {
                0: FixedColumnWidth(40),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(1),
                3: FlexColumnWidth(1),
                4: FlexColumnWidth(1),
              },
              children: [
                // Header
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey[200]),
                  children: [
                    _buildTableCell('#', isHeader: true),
                    _buildTableCell('طريقة الدفع', isHeader: true),
                    _buildTableCell('رقم', isHeader: true),
                    _buildTableCell('التاريخ', isHeader: true),
                    _buildTableCell('القيمة', isHeader: true),
                  ],
                ),
                // Data
                TableRow(
                  children: [
                    _buildTableCell('1'),
                    _buildTableCell(detail.check.isEmpty ? 'كاش' : 'شيكات'),
                    _buildTableCell(
                        detail.check.isEmpty ? '-' : detail.checkNumber),
                    _buildTableCell(
                        detail.check.isEmpty ? '-' : detail.checkDueDate),
                    _buildTableCell(Helpers.formatNumber(detail.credit)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceDetails() {
    final items = _details.where((d) => d.item.isNotEmpty).toList();

    if (items.isEmpty) return const SizedBox();

    // Calculate totals
    double totalAmount = 0;
    double tax = 0;
    double discount = 0;

    for (final item in items) {
      totalAmount += Helpers.parseNumber(item.amount);
    }

    if (items.isNotEmpty) {
      tax = Helpers.parseNumber(items.last.tax);
      discount = Helpers.parseNumber(items.last.docDiscount);
    }

    final afterDiscount = _roundToNearest(totalAmount);
    final netAmount = afterDiscount;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'الأصناف',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 16),

            // Items Table
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 20,
                headingRowColor: WidgetStateProperty.all(Colors.grey[200]),
                columns: const [
                  DataColumn(label: Text('#')),
                  DataColumn(label: Text('رقم الصنف')),
                  DataColumn(label: Text('اسم الصنف')),
                  DataColumn(label: Text('الكمية')),
                  DataColumn(label: Text('السعر')),
                  DataColumn(label: Text('المبلغ')),
                ],
                rows: items.asMap().entries.map((entry) {
                  final index = entry.key + 1;
                  final item = entry.value;

                  return DataRow(
                    cells: [
                      DataCell(Text(index.toString())),
                      DataCell(Text(item.item)),
                      DataCell(
                        SizedBox(
                          width: 200,
                          child: Text(
                            ArabicTextHelper.cleanText(item.name),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(Text(
                          '${Helpers.formatNumber(item.quantity)} ${item.unit}')),
                      DataCell(Text(Helpers.formatNumber(item.price))),
                      DataCell(Text(Helpers.formatNumber(item.amount))),
                    ],
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 20),

            // Totals
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildTotalRow('المجموع', totalAmount),
                  if (tax > 0) _buildTotalRow('ضريبة ال 16%', tax),
                  if (discount != 0) _buildTotalRow('الخصم', discount),
                  _buildTotalRow('بعد الخصم', afterDiscount),
                  const Divider(),
                  _buildTotalRow('الصافي', netAmount, isNet: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableCell(String text, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          fontSize: isHeader ? 14 : 12,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount, {bool isNet = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            Helpers.formatNumber(amount.toString()),
            style: TextStyle(
              fontSize: isNet ? 16 : 14,
              fontWeight: isNet ? FontWeight.bold : FontWeight.normal,
              color: isNet ? const Color(AppConstants.primaryColor) : null,
            ),
          ),
          Text(
            '$label:',
            style: TextStyle(
              fontSize: isNet ? 16 : 14,
              fontWeight: isNet ? FontWeight.bold : FontWeight.normal,
              color: isNet ? const Color(AppConstants.primaryColor) : null,
            ),
          ),
        ],
      ),
    );
  }

  double _roundToNearest(double amount) {
    final decimal = amount - amount.floor();
    if (decimal >= 0.5) {
      return amount.ceil().toDouble();
    } else {
      return amount.floor().toDouble();
    }
  }
}
