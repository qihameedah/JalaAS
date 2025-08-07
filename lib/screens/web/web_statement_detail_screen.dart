// lib/screens/web/web_statement_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../models/user.dart';
import '../../models/contact.dart';
import '../../models/account_statement.dart';
import '../../models/account_statement.dart' as models;
import '../../services/api_service.dart';
import '../../services/pdf_service.dart';
import '../../utils/constants.dart';
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

  // Controllers for invoice table scrolling
  final ScrollController _invoiceHorizontalHeaderController =
      ScrollController();
  final ScrollController _invoiceHorizontalDataController = ScrollController();
  final ScrollController _invoiceVerticalController = ScrollController();

  // Controllers for payment table scrolling
  final ScrollController _paymentHorizontalHeaderController =
      ScrollController();
  final ScrollController _paymentHorizontalDataController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadDetails();
    _setupScrollControllers();
  }

  void _setupScrollControllers() {
    // Synchronize invoice table horizontal scrolling
    _invoiceHorizontalHeaderController.addListener(() {
      if (_invoiceHorizontalHeaderController.offset !=
          _invoiceHorizontalDataController.offset) {
        _invoiceHorizontalDataController
            .jumpTo(_invoiceHorizontalHeaderController.offset);
      }
    });

    _invoiceHorizontalDataController.addListener(() {
      if (_invoiceHorizontalDataController.offset !=
          _invoiceHorizontalHeaderController.offset) {
        _invoiceHorizontalHeaderController
            .jumpTo(_invoiceHorizontalDataController.offset);
      }
    });

    // Synchronize payment table horizontal scrolling
    _paymentHorizontalHeaderController.addListener(() {
      if (_paymentHorizontalHeaderController.offset !=
          _paymentHorizontalDataController.offset) {
        _paymentHorizontalDataController
            .jumpTo(_paymentHorizontalHeaderController.offset);
      }
    });

    _paymentHorizontalDataController.addListener(() {
      if (_paymentHorizontalDataController.offset !=
          _paymentHorizontalHeaderController.offset) {
        _paymentHorizontalHeaderController
            .jumpTo(_paymentHorizontalDataController.offset);
      }
    });
  }

  @override
  void dispose() {
    // Dispose all scroll controllers
    _invoiceHorizontalHeaderController.dispose();
    _invoiceHorizontalDataController.dispose();
    _invoiceVerticalController.dispose();
    _paymentHorizontalHeaderController.dispose();
    _paymentHorizontalDataController.dispose();
    super.dispose();
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
    final isDesktop = screenWidth > 1024;
    final isTablet = screenWidth > 600 && screenWidth <= 1024;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 1,
          iconTheme: const IconThemeData(color: Colors.black87),
          title: Directionality(
            textDirection: TextDirection.rtl,
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getDocumentTypeColor(widget.statement.documentType),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    Helpers.getDocumentTypeInArabic(
                        widget.statement.documentType),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ArabicTextHelper.cleanText(widget.contact.nameAr),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            if (_details.isNotEmpty)
              IconButton(
                icon: _isGeneratingPdf
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.picture_as_pdf, size: 20),
                onPressed: _isGeneratingPdf ? null : _generatePdf,
                tooltip: 'تصدير PDF',
              ),
            IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: _loadDetails,
              tooltip: 'تحديث',
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _details.isEmpty
                ? _buildEmptyState()
                : Column(
                    children: [
                      _buildCompactHeader(),
                      Expanded(
                        child: widget.statement.documentType == 'payment'
                            ? _buildPaymentDetails()
                            : _buildInvoiceDetails(),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد تفاصيل لهذا المستند',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadDetails,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  ArabicTextHelper.cleanText(widget.statement.displayName),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                widget.statement.docDate,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                'العميل: ${widget.contact.code}',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                ),
              ),
              if (_details.isNotEmpty &&
                  _details.first.docComment.isNotEmpty) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'ملاحظة: ${ArabicTextHelper.cleanText(_details.first.docComment)}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.orange.shade700,
                      fontStyle: FontStyle.italic,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentDetails() {
    if (_details.isEmpty) return const SizedBox();

    final detail = _details.first;
    final screenWidth = MediaQuery.of(context).size.width;
    final fixedColumnWidth = screenWidth * 0.4;
    final scrollableColumnContentWidth =
        screenWidth > 520 ? screenWidth * 0.6 : 320.0;

    return Center(
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Column(
            children: [
              // Header section
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade600,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(8)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.payment, color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    const Text(
                      'تفاصيل القبض',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ],
                ),
              ),
              // Table Header
              SizedBox(
                height: 32,
                child: Row(
                  children: [
                    // Fixed header columns
                    Container(
                      width: fixedColumnWidth,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade700,
                        border: Border(
                          left:
                              BorderSide(color: Colors.grey.shade500, width: 1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Center(
                              child: Text(
                                'طريقة الدفع',
                                style: TextStyle(
                                    fontSize:
                                        MediaQuery.of(context).size.width < 600
                                            ? 10
                                            : 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: Text(
                                'رقم الشيك',
                                style: TextStyle(
                                    fontSize:
                                        MediaQuery.of(context).size.width < 600
                                            ? 10
                                            : 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Scrollable header columns
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        controller: _paymentHorizontalHeaderController,
                        child: Container(
                          width: scrollableColumnContentWidth,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade700,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Center(
                                  child: Text(
                                    'تاريخ الاستحقاق',
                                    style: TextStyle(
                                        fontSize:
                                            MediaQuery.of(context).size.width <
                                                    600
                                                ? 10
                                                : 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: Text(
                                    'القيمة',
                                    style: TextStyle(
                                        fontSize:
                                            MediaQuery.of(context).size.width <
                                                    600
                                                ? 10
                                                : 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Data Row
              SizedBox(
                height: 36,
                child: Row(
                  children: [
                    // Fixed data columns
                    Container(
                      width: fixedColumnWidth,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          left:
                              BorderSide(color: Colors.grey.shade500, width: 1),
                          bottom: BorderSide(
                              color: Colors.grey.shade300, width: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Center(
                              child: Text(
                                detail.check.isEmpty ? 'كاش' : 'شيك',
                                style: TextStyle(
                                    fontSize:
                                        MediaQuery.of(context).size.width < 600
                                            ? 10
                                            : 11),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: Text(
                                detail.check.isEmpty ? '-' : detail.checkNumber,
                                style: TextStyle(
                                    fontSize:
                                        MediaQuery.of(context).size.width < 600
                                            ? 10
                                            : 11),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Scrollable data columns
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        controller: _paymentHorizontalDataController,
                        child: Container(
                          width: scrollableColumnContentWidth,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border(
                              bottom: BorderSide(
                                  color: Colors.grey.shade300, width: 0.5),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Center(
                                  child: Text(
                                    detail.check.isEmpty
                                        ? '-'
                                        : detail.checkDueDate,
                                    style: TextStyle(
                                        fontSize:
                                            MediaQuery.of(context).size.width <
                                                    600
                                                ? 10
                                                : 11),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: Text(
                                    Helpers.formatNumber(detail.credit),
                                    style: TextStyle(
                                      fontSize:
                                          MediaQuery.of(context).size.width <
                                                  600
                                              ? 11
                                              : 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceDetails() {
    final items = _details.where((d) => d.item.isNotEmpty).toList();
    if (items.isEmpty) return const SizedBox();

    final screenWidth = MediaQuery.of(context).size.width;
    final fixedColumnWidth = screenWidth * 0.45;
    final scrollableColumnContentWidth =
        screenWidth > 520 ? screenWidth * 0.55 : 320.0;

    return Center(
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Column(
            children: [
              // Header section
              _buildInvoiceHeader(items.length),
              // Table Header
              SizedBox(
                height: 32,
                child: Row(
                  children: [
                    // Fixed header columns
                    Container(
                      width: fixedColumnWidth,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade700,
                        border: Border(
                          left:
                              BorderSide(color: Colors.grey.shade500, width: 1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Center(
                              child: Text(
                                'رقم الصنف',
                                style: TextStyle(
                                    fontSize:
                                        MediaQuery.of(context).size.width < 600
                                            ? 10
                                            : 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: Center(
                              child: Text(
                                'اسم الصنف',
                                style: TextStyle(
                                    fontSize:
                                        MediaQuery.of(context).size.width < 600
                                            ? 10
                                            : 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Scrollable header columns
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        controller: _invoiceHorizontalHeaderController,
                        child: Container(
                          width: scrollableColumnContentWidth,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade700,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Center(
                                  child: Text(
                                    'الكمية',
                                    style: TextStyle(
                                        fontSize:
                                            MediaQuery.of(context).size.width <
                                                    600
                                                ? 10
                                                : 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: Text(
                                    'الوحدة',
                                    style: TextStyle(
                                        fontSize:
                                            MediaQuery.of(context).size.width <
                                                    600
                                                ? 10
                                                : 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: Text(
                                    'السعر',
                                    style: TextStyle(
                                        fontSize:
                                            MediaQuery.of(context).size.width <
                                                    600
                                                ? 10
                                                : 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: Text(
                                    'المبلغ',
                                    style: TextStyle(
                                        fontSize:
                                            MediaQuery.of(context).size.width <
                                                    600
                                                ? 10
                                                : 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Scrollable Data Rows Container
              Expanded(
                child: SingleChildScrollView(
                  controller: _invoiceVerticalController,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Fixed Column Data
                      SizedBox(
                        width: fixedColumnWidth,
                        child: Column(
                          children: [
                            for (int index = 0; index < items.length; index++)
                              _buildInvoiceFixedRowPart(items[index], index),
                          ],
                        ),
                      ),
                      // Right Scrollable Columns Data
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          controller: _invoiceHorizontalDataController,
                          child: SizedBox(
                            width: scrollableColumnContentWidth,
                            child: Column(
                              children: [
                                for (int index = 0;
                                    index < items.length;
                                    index++)
                                  _buildInvoiceScrollableRowPart(
                                      items[index], index),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Totals Summary
              _buildTotalsSummary(items),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceHeader(int itemCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade600,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: Row(
        children: [
          Icon(Icons.inventory, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          const Text(
            'الأصناف',
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$itemCount صنف',
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceFixedRowPart(
      models.AccountStatementDetail item, int index) {
    final screenWidth = MediaQuery.of(context).size.width;
    final itemCodeFontSize = screenWidth < 600
        ? 10.0
        : screenWidth < 1200
            ? 11.0
            : 12.0;
    final itemNameFontSize = screenWidth < 600
        ? 10.0
        : screenWidth < 1200
            ? 11.0
            : 12.0;

    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: index % 2 == 0 ? Colors.white : Colors.grey.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 0.5),
          left: BorderSide(color: Colors.grey.shade500, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Center(
                child: Text(
                  item.item,
                  style: TextStyle(
                    fontSize: itemCodeFontSize,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Center(
                child: Text(
                  ArabicTextHelper.cleanText(item.name),
                  style: TextStyle(
                      fontSize: itemNameFontSize, fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceScrollableRowPart(
      models.AccountStatementDetail item, int index) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dataFontSize = screenWidth < 600
        ? 10.0
        : screenWidth < 1200
            ? 11.0
            : 12.0;
    final unitFontSize = screenWidth < 600
        ? 9.0
        : screenWidth < 1200
            ? 10.0
            : 11.0;

    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: index % 2 == 0 ? Colors.white : Colors.grey.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Center(
              child: Text(
                Helpers.formatNumber(item.quantity),
                style: TextStyle(
                    fontSize: dataFontSize, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                item.unit,
                style: TextStyle(fontSize: unitFontSize, color: Colors.black),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                Helpers.formatNumber(item.price),
                style: TextStyle(fontSize: dataFontSize),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                Helpers.formatNumber(item.amount),
                style: TextStyle(
                  fontSize: dataFontSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalsSummary(List<models.AccountStatementDetail> items) {
    double totalAmount = 0;
    double tax = 0;
    double discount = 0;

    for (final item in items) {
      totalAmount += Helpers.parseNumber(item.amount);
    }

    if (items.isNotEmpty) {
      // Get tax and discount from the last item or first item that has these values
      for (final item in items) {
        if (item.tax.isNotEmpty) {
          tax = Helpers.parseNumber(item.tax);
        }
        if (item.docDiscount.isNotEmpty) {
          discount = Helpers.parseNumber(item.docDiscount);
        }
      }
    }

    // Calculate rounded values based on nearest whole number
    final roundedTotal = totalAmount.round().toDouble();
    final calculatedDiscount = totalAmount - roundedTotal;
    final afterDiscount = roundedTotal;
    final netAmount = afterDiscount;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        children: [
          _buildTotalRow('المجموع', totalAmount),
          // Always show discount if there's a difference from rounded value
          if (calculatedDiscount != 0) ...[
            _buildTotalRow('الخصم', calculatedDiscount, isDiscount: true),
            _buildTotalRow('بعد الخصم', afterDiscount, isAfterDiscount: true),
          ],
          if (tax > 0) _buildTotalRow('ضريبة 16%', tax),
          const Divider(height: 6),
          _buildTotalRow('الصافي', netAmount, isNet: true),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount,
      {bool isNet = false,
      bool isDiscount = false,
      bool isAfterDiscount = false}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final fontSize = screenWidth < 600
        ? 11.0
        : screenWidth < 1200
            ? 12.0
            : 13.0;
    final netFontSize = screenWidth < 600
        ? 12.0
        : screenWidth < 1200
            ? 13.0
            : 14.0;

    Color textColor = Colors.grey.shade700;
    if (isNet) {
      textColor = Colors.black87;
    } else if (isDiscount) {
      textColor = Colors.grey.shade600;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: TextStyle(
              fontSize: isNet ? netFontSize : fontSize,
              fontWeight: isNet ? FontWeight.bold : FontWeight.w600,
              color: textColor,
            ),
          ),
          Text(
            Helpers.formatNumber(amount.toString()),
            style: TextStyle(
              fontSize: isNet ? netFontSize : fontSize,
              fontWeight: isNet ? FontWeight.bold : FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
