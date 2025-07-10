// lib/screens/web/web_statement_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../models/user.dart';
import '../../models/contact.dart';
import '../../models/account_statement.dart';
import '../../models/account_statement.dart' as models;
import '../../services/api_service.dart';
import '../../services/pdf_service.dart';
import '../../utils/helpers.dart';
import '../../utils/arabic_text_helper.dart';

class WebStatementDetailScreen extends StatefulWidget {
  final AppUser user;
  final Contact contact;
  final AccountStatement statement;
  final DateTime fromDate;
  final DateTime toDate;

  const WebStatementDetailScreen({
    super.key,
    required this.user,
    required this.contact,
    required this.statement,
    required this.fromDate,
    required this.toDate,
  });

  @override
  State<WebStatementDetailScreen> createState() =>
      _WebStatementDetailScreenState();
}

class _WebStatementDetailScreenState extends State<WebStatementDetailScreen> {
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
        fromDate: Helpers.formatDate(widget.fromDate),
        toDate: Helpers.formatDate(widget.toDate),
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
      if (mounted) {
        Helpers.showSnackBar(
          context,
          'فشل في تحميل تفاصيل المستند: ${e.toString()}',
          isError: true,
        );
      }
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
      if (mounted) {
        Helpers.showSnackBar(
          context,
          'فشل في إنشاء ملف PDF: ${e.toString()}',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingPdf = false;
        });
      }
    }
  }

  Color _getDocumentTypeColor(String documentType) {
    switch (documentType) {
      case 'invoice':
        return Colors.blue;
      case 'return':
        return Colors.orange;
      case 'payment':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;
    final isTablet = screenWidth > 600 && screenWidth <= 900;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isDesktop
              ? 'تفاصيل ${Helpers.getDocumentTypeInArabic(widget.statement.documentType)} - ${ArabicTextHelper.cleanText(widget.contact.nameAr)}'
              : 'تفاصيل ${Helpers.getDocumentTypeInArabic(widget.statement.documentType)}',
          overflow: TextOverflow.ellipsis,
        ),
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
              tooltip: 'تصدير PDF',
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
              ? _buildEmptyState(isDesktop)
              : _buildContent(isDesktop, isTablet),
    );
  }

  Widget _buildEmptyState(bool isDesktop) {
    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isDesktop ? 600 : double.infinity,
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: isDesktop ? 80 : 64,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: isDesktop ? 24 : 16),
            Text(
              'لا توجد تفاصيل لهذا المستند',
              style: TextStyle(
                fontSize: isDesktop ? 20 : 18,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: isDesktop ? 16 : 12),
            ElevatedButton.icon(
              onPressed: _loadDetails,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(bool isDesktop, bool isTablet) {
    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isDesktop ? 1000 : double.infinity,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isDesktop ? 24 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Document Header Card
              _buildDocumentHeader(isDesktop),

              SizedBox(height: isDesktop ? 24 : 16),

              // Content based on document type
              if (widget.statement.documentType == 'payment')
                _buildPaymentDetails(isDesktop, isTablet)
              else
                _buildInvoiceDetails(isDesktop, isTablet),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentHeader(bool isDesktop) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(isDesktop ? 24 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 16 : 12,
                    vertical: isDesktop ? 8 : 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getDocumentTypeColor(widget.statement.documentType),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Text(
                    Helpers.getDocumentTypeInArabic(
                        widget.statement.documentType),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isDesktop ? 14 : 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  widget.statement.docDate,
                  style: TextStyle(
                    fontSize: isDesktop ? 16 : 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            SizedBox(height: isDesktop ? 16 : 12),

            Text(
              ArabicTextHelper.cleanText(widget.statement.displayName),
              style: TextStyle(
                fontSize: isDesktop ? 24 : 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: isDesktop ? 16 : 12),

            // Customer Info
            Container(
              padding: EdgeInsets.all(isDesktop ? 16 : 12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: isDesktop ? 20 : 16,
                    backgroundColor: Colors.blue.shade100,
                    child: Text(
                      widget.contact.nameAr.isNotEmpty
                          ? widget.contact.nameAr[0]
                          : '؟',
                      style: TextStyle(
                        fontSize: isDesktop ? 14 : 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                  SizedBox(width: isDesktop ? 12 : 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ArabicTextHelper.cleanText(widget.contact.nameAr),
                          style: TextStyle(
                            fontSize: isDesktop ? 16 : 14,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'رقم العميل: ${widget.contact.code}',
                          style: TextStyle(
                            fontSize: isDesktop ? 12 : 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Document comment if exists
            if (_details.isNotEmpty &&
                _details.first.docComment.isNotEmpty) ...[
              SizedBox(height: isDesktop ? 16 : 12),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(isDesktop ? 16 : 12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.note_alt,
                          size: isDesktop ? 20 : 16,
                          color: Colors.amber.shade700,
                        ),
                        SizedBox(width: isDesktop ? 8 : 6),
                        Text(
                          'ملاحظة:',
                          style: TextStyle(
                            fontSize: isDesktop ? 14 : 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade700,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isDesktop ? 8 : 6),
                    Text(
                      ArabicTextHelper.cleanText(_details.first.docComment),
                      style: TextStyle(
                        fontSize: isDesktop ? 14 : 12,
                        color: Colors.amber.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentDetails(bool isDesktop, bool isTablet) {
    if (_details.isEmpty) return const SizedBox();

    final detail = _details.first;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 24 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.payment,
                  color: Colors.green.shade600,
                  size: isDesktop ? 24 : 20,
                ),
                SizedBox(width: isDesktop ? 12 : 8),
                Text(
                  'تفاصيل القبض',
                  style: TextStyle(
                    fontSize: isDesktop ? 20 : 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: isDesktop ? 20 : 16),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: EdgeInsets.all(isDesktop ? 16 : 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                            flex: 1,
                            child:
                                Text('#', style: _getHeaderStyle(isDesktop))),
                        Expanded(
                            flex: 3,
                            child: Text('طريقة الدفع',
                                style: _getHeaderStyle(isDesktop))),
                        Expanded(
                            flex: 2,
                            child:
                                Text('رقم', style: _getHeaderStyle(isDesktop))),
                        Expanded(
                            flex: 2,
                            child: Text('التاريخ',
                                style: _getHeaderStyle(isDesktop))),
                        Expanded(
                            flex: 2,
                            child: Text('القيمة',
                                style: _getHeaderStyle(isDesktop))),
                      ],
                    ),
                  ),
                  // Data Row
                  Container(
                    padding: EdgeInsets.all(isDesktop ? 16 : 12),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '1',
                              style: TextStyle(
                                fontSize: isDesktop ? 12 : 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Row(
                            children: [
                              Icon(
                                detail.check.isEmpty
                                    ? Icons.payments
                                    : Icons.receipt,
                                color: detail.check.isEmpty
                                    ? Colors.green
                                    : Colors.blue,
                                size: isDesktop ? 20 : 16,
                              ),
                              SizedBox(width: isDesktop ? 8 : 6),
                              Text(
                                detail.check.isEmpty ? 'كاش' : 'شيكات',
                                style: _getCellStyle(isDesktop),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            detail.check.isEmpty ? '-' : detail.checkNumber,
                            style: _getCellStyle(isDesktop),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            detail.check.isEmpty ? '-' : detail.checkDueDate,
                            style: _getCellStyle(isDesktop),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isDesktop ? 12 : 8,
                              vertical: isDesktop ? 8 : 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Text(
                              Helpers.formatNumber(detail.credit),
                              style: TextStyle(
                                fontSize: isDesktop ? 14 : 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceDetails(bool isDesktop, bool isTablet) {
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
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 24 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.inventory,
                  color: Colors.blue.shade600,
                  size: isDesktop ? 24 : 20,
                ),
                SizedBox(width: isDesktop ? 12 : 8),
                Text(
                  'الأصناف',
                  style: TextStyle(
                    fontSize: isDesktop ? 20 : 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 12 : 8,
                    vertical: isDesktop ? 6 : 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${items.length} صنف',
                    style: TextStyle(
                      fontSize: isDesktop ? 12 : 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: isDesktop ? 20 : 16),

            // Items Table
            Directionality(
              textDirection: TextDirection.rtl,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: EdgeInsets.all(isDesktop ? 16 : 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                              flex: 1,
                              child: Text('#',
                                  style: _getHeaderStyle(isDesktop),
                                  textAlign: TextAlign.center)),
                          Expanded(
                              flex: 2,
                              child: Text('رقم الصنف',
                                  style: _getHeaderStyle(isDesktop),
                                  textAlign: TextAlign.center)),
                          Expanded(
                              flex: 4,
                              child: Text('اسم الصنف',
                                  style: _getHeaderStyle(isDesktop),
                                  textAlign: TextAlign.center)),
                          Expanded(
                              flex: 2,
                              child: Text('الكمية',
                                  style: _getHeaderStyle(isDesktop),
                                  textAlign: TextAlign.center)),
                          Expanded(
                              flex: 2,
                              child: Text('السعر',
                                  style: _getHeaderStyle(isDesktop),
                                  textAlign: TextAlign.center)),
                          Expanded(
                              flex: 2,
                              child: Text('المبلغ',
                                  style: _getHeaderStyle(isDesktop),
                                  textAlign: TextAlign.center)),
                        ],
                      ),
                    ),
                    // Data Rows
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: items.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        color: Colors.grey.shade200,
                      ),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return Container(
                          padding: EdgeInsets.all(isDesktop ? 16 : 12),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade100,
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      fontSize: isDesktop ? 11 : 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade700,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  item.item,
                                  style: _getCellStyle(isDesktop).copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                flex: 4,
                                child: SizedBox(
                                  width: double.infinity,
                                  child: Text(
                                    ArabicTextHelper.cleanText(item.name),
                                    style: _getCellStyle(isDesktop),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Column(
                                  children: [
                                    Text(
                                      Helpers.formatNumber(item.quantity),
                                      style: _getCellStyle(isDesktop).copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    if (item.unit.isNotEmpty)
                                      Text(
                                        item.unit,
                                        style: TextStyle(
                                          fontSize: isDesktop ? 10 : 9,
                                          color: Colors.grey.shade600,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  Helpers.formatNumber(item.price),
                                  style: _getCellStyle(isDesktop),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isDesktop ? 8 : 6,
                                    vertical: isDesktop ? 6 : 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                        color: Colors.green.shade200),
                                  ),
                                  child: Text(
                                    Helpers.formatNumber(item.amount),
                                    style: TextStyle(
                                      fontSize: isDesktop ? 12 : 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade700,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: isDesktop ? 24 : 16),

            // Totals Card with RTL alignment
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(isDesktop ? 20 : 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade50, Colors.blue.shade100],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calculate,
                        color: Colors.blue.shade700,
                        size: isDesktop ? 20 : 16,
                      ),
                      SizedBox(width: isDesktop ? 8 : 6),
                      Text(
                        'ملخص المبالغ',
                        style: TextStyle(
                          fontSize: isDesktop ? 16 : 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isDesktop ? 16 : 12),
                  _buildTotalRow('المجموع', totalAmount, false, isDesktop),
                  if (tax > 0)
                    _buildTotalRow('ضريبة ال 16%', tax, false, isDesktop),
                  if (discount != 0)
                    _buildTotalRow('الخصم', discount, false, isDesktop),
                  _buildTotalRow('بعد الخصم', afterDiscount, false, isDesktop),
                  Divider(color: Colors.blue.shade300, thickness: 1),
                  _buildTotalRow('الصافي', netAmount, true, isDesktop),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalRow(
      String label, double amount, bool isNet, bool isDesktop) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isDesktop ? 6 : 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            Helpers.formatNumber(amount.toString()),
            style: TextStyle(
              fontSize: isNet ? (isDesktop ? 18 : 16) : (isDesktop ? 14 : 12),
              fontWeight: isNet ? FontWeight.bold : FontWeight.w600,
              color: isNet ? Colors.blue.shade800 : Colors.blue.shade700,
            ),
          ),
          Text(
            ':$label',
            style: TextStyle(
              fontSize: isNet ? (isDesktop ? 18 : 16) : (isDesktop ? 14 : 12),
              fontWeight: isNet ? FontWeight.bold : FontWeight.w600,
              color: isNet ? Colors.blue.shade800 : Colors.blue.shade700,
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _getHeaderStyle(bool isDesktop) {
    return TextStyle(
      fontSize: isDesktop ? 14 : 12,
      fontWeight: FontWeight.bold,
      color: Colors.grey.shade700,
    );
  }

  TextStyle _getCellStyle(bool isDesktop) {
    return TextStyle(
      fontSize: isDesktop ? 13 : 11,
      color: Colors.black87,
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
