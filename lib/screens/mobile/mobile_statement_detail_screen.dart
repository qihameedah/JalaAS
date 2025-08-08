// lib/screens/mobile/mobile_statement_detail_screen.dart
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

// lib/screens/mobile/statement_detail_screen.dart - Updated build method
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppConstants.backgroundColor),
      appBar: AppBar(
        title: Text(ArabicTextHelper.cleanText(widget.contact.nameAr)),
        backgroundColor: const Color(AppConstants.primaryColor),
        foregroundColor: Colors.white,
        actions: [
          if (_details.isNotEmpty)
            IconButton(
              icon: _isGeneratingPdf
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.picture_as_pdf, color: Colors.white),
              onPressed: _isGeneratingPdf ? null : _generatePdf,
              tooltip: 'إنشاء PDF',
            ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadDetails,
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                    Color(AppConstants.primaryColor)),
              ),
            )
          : _details.isEmpty
              ? Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.description_outlined,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'لا توجد تفاصيل لهذا المستند',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
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

// Updated _buildPaymentDetails method with new colors and compact design
  Widget _buildPaymentDetails() {
    if (_details.isEmpty) return const SizedBox();

    final detail = _details.first;
    final screenWidth = MediaQuery.of(context).size.width;
    final fixedColumnWidth = screenWidth * 0.4;
    final scrollableColumnContentWidth =
        screenWidth > 520 ? screenWidth * 0.6 : 320.0;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Container(
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: const BoxDecoration(
                  color: Color(AppConstants.primaryColor),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.payment, color: Colors.white, size: 14),
                    const SizedBox(width: 6),
                    const Text(
                      'تفاصيل القبض',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
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
                        color: const Color(AppConstants.lightPrimary),
                        border: Border(
                          left: BorderSide(
                              color: const Color(AppConstants.primaryColor),
                              width: 2),
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
                                  color: Colors.white,
                                ),
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
                                  color: Colors.white,
                                ),
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
                          decoration: const BoxDecoration(
                            color: Color(AppConstants.lightPrimary),
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
                                      color: Colors.white,
                                    ),
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
                                      color: Colors.white,
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
                          left: BorderSide(
                              color: const Color(AppConstants.primaryColor),
                              width: 2),
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
                                          ? 11
                                          : 12,
                                  fontWeight: FontWeight.w600,
                                ),
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
                                          ? 11
                                          : 12,
                                ),
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
                                              ? 11
                                              : 12,
                                    ),
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
                                              ? 12
                                              : 13,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(
                                          AppConstants.primaryColor),
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

// Updated _buildInvoiceDetails method with new colors and compact design
  Widget _buildInvoiceDetails() {
    final items = _details.where((d) => d.item.isNotEmpty).toList();
    if (items.isEmpty) return const SizedBox();

    final screenWidth = MediaQuery.of(context).size.width;
    final fixedColumnWidth = screenWidth * 0.45;
    final scrollableColumnContentWidth =
        screenWidth > 520 ? screenWidth * 0.55 : 320.0;

    // Calculate totals
    double totalAmount = 0;
    double tax = 0;
    double discount = 0;

    for (final item in items) {
      totalAmount += Helpers.parseNumber(item.amount);
    }

    if (items.isNotEmpty) {
      for (final item in items) {
        if (item.tax.isNotEmpty) {
          tax = Helpers.parseNumber(item.tax);
        }
        if (item.docDiscount.isNotEmpty) {
          discount = Helpers.parseNumber(item.docDiscount);
        }
      }
    }

    final afterDiscount = _roundToNearest(totalAmount);
    final netAmount = afterDiscount;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Container(
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: const BoxDecoration(
                  color: Color(AppConstants.primaryColor),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.inventory, color: Colors.white, size: 14),
                    const SizedBox(width: 6),
                    const Text(
                      'الأصناف',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${items.length} صنف',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
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
                        color: const Color(AppConstants.lightPrimary),
                        border: Border(
                          left: BorderSide(
                              color: const Color(AppConstants.primaryColor),
                              width: 2),
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
                                  color: Colors.white,
                                ),
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
                                  color: Colors.white,
                                ),
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
                          decoration: const BoxDecoration(
                            color: Color(AppConstants.lightPrimary),
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
                                      color: Colors.white,
                                    ),
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
                                      color: Colors.white,
                                    ),
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
                                      color: Colors.white,
                                    ),
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
                                      color: Colors.white,
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
              // Scrollable Data Rows Container
              SizedBox(
                height: 240, // Reduced height for better space utilization
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
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(AppConstants.surfaceColor),
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(8)),
                  border: Border(top: BorderSide(color: Colors.grey.shade300)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildTotalRow('المجموع', totalAmount),
                    if (tax > 0) _buildTotalRow('ضريبة ال 16%', tax),
                    if (discount != 0) _buildTotalRow('الخصم', discount),
                    _buildTotalRow('بعد الخصم', afterDiscount),
                    const Divider(height: 8),
                    _buildTotalRow('الصافي', netAmount, isNet: true),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

// Updated _buildInvoiceFixedRowPart method with compact design
  Widget _buildInvoiceFixedRowPart(
      models.AccountStatementDetail item, int index) {
    final screenWidth = MediaQuery.of(context).size.width;
    final itemCodeFontSize = screenWidth < 600 ? 10.0 : 11.0;
    final itemNameFontSize = screenWidth < 600 ? 10.0 : 11.0;

    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: index % 2 == 0
            ? Colors.white
            : const Color(AppConstants.surfaceColor),
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 0.5),
          left: BorderSide(
              color: const Color(AppConstants.primaryColor), width: 2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4),
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
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Center(
                child: Text(
                  ArabicTextHelper.cleanText(item.name),
                  style: TextStyle(
                    fontSize: itemNameFontSize,
                    fontWeight: FontWeight.bold,
                  ),
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

// Updated _buildInvoiceScrollableRowPart method with compact design
  Widget _buildInvoiceScrollableRowPart(
      models.AccountStatementDetail item, int index) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dataFontSize = screenWidth < 600 ? 10.0 : 11.0;
    final unitFontSize = screenWidth < 600 ? 9.0 : 10.0;

    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: index % 2 == 0
            ? Colors.white
            : const Color(AppConstants.surfaceColor),
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
                  fontSize: dataFontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                item.unit,
                style: TextStyle(
                  fontSize: unitFontSize,
                  color: Colors.black,
                ),
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
                  color: const Color(AppConstants.primaryColor),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

// Updated _buildTotalRow method with new colors
  Widget _buildTotalRow(String label, double amount, {bool isNet = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            Helpers.formatNumber(amount.toString()),
            style: TextStyle(
              fontSize: isNet ? 14 : 12,
              fontWeight: isNet ? FontWeight.bold : FontWeight.w600,
              color: isNet
                  ? const Color(AppConstants.primaryColor)
                  : Colors.black87,
            ),
          ),
          Text(
            '$label:',
            style: TextStyle(
              fontSize: isNet ? 14 : 12,
              fontWeight: isNet ? FontWeight.bold : FontWeight.w600,
              color: isNet
                  ? const Color(AppConstants.primaryColor)
                  : Colors.black87,
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
