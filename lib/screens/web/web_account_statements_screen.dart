// lib/screens/web/web_account_statements_screen.dart
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../models/user.dart';
import '../../models/contact.dart';
import '../../models/account_statement.dart';
import '../../services/api_service.dart';
import '../../services/pdf_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../utils/arabic_text_helper.dart';
import 'web_statement_detail_screen.dart';

class WebAccountStatementsScreen extends StatefulWidget {
  final AppUser user;
  final Contact contact;
  final DateTime fromDate;
  final DateTime toDate;

  const WebAccountStatementsScreen({
    super.key,
    required this.user,
    required this.contact,
    required this.fromDate,
    required this.toDate,
  });

  @override
  State<WebAccountStatementsScreen> createState() =>
      _WebAccountStatementsScreenState();
}

class _WebAccountStatementsScreenState
    extends State<WebAccountStatementsScreen> {
  List<AccountStatement> _statements = [];
  bool _isLoading = true;
  bool _isGeneratingPdf = false;

  // Controllers for horizontal scrolling (header and data)
  final ScrollController _horizontalHeaderController = ScrollController();
  final ScrollController _horizontalDataController = ScrollController();
  // Controller for vertical scrolling of the ENTIRE screen content
  // Note: This _verticalController will now control the main screen body,
  // not internal table parts.
  final ScrollController _screenVerticalController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadStatements();

    // Attach listeners to synchronize horizontal scrolling between header and data
    _horizontalHeaderController.addListener(() {
      if (_horizontalHeaderController.offset !=
          _horizontalDataController.offset) {
        _horizontalDataController.jumpTo(_horizontalHeaderController.offset);
      }
    });

    _horizontalDataController.addListener(() {
      if (_horizontalDataController.offset !=
          _horizontalHeaderController.offset) {
        _horizontalHeaderController.jumpTo(_horizontalDataController.offset);
      }
    });
  }

  @override
  void dispose() {
    // Dispose all scroll controllers to prevent memory leaks
    _horizontalHeaderController.dispose();
    _horizontalDataController.dispose();
    _screenVerticalController
        .dispose(); // Dispose the screen's vertical controller
    super.dispose();
  }

  Future<void> _loadStatements() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final statements = await ApiService.getAccountStatements(
        contactCode: widget.contact.code,
        fromDate: Helpers.formatDate(widget.fromDate),
        toDate: Helpers.formatDate(widget.toDate),
      );

      setState(() {
        _statements = statements;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        Helpers.showSnackBar(
          context,
          'فشل في تحميل كشف الحساب: ${e.toString()}',
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
      final pdfBytes = await PdfService.generateAccountStatementPdf(
        contact: widget.contact,
        statements: _statements,
        fromDate: Helpers.formatDate(widget.fromDate),
        toDate: Helpers.formatDate(widget.toDate),
      );

      await Printing.layoutPdf(
        onLayout: (format) async => pdfBytes,
        name:
            'كشف_حساب_${widget.contact.code}_${Helpers.formatDate(widget.fromDate)}_${Helpers.formatDate(widget.toDate)}.pdf',
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

  void _viewStatementDetail(AccountStatement statement) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WebStatementDetailScreen(
          user: widget.user,
          contact: widget.contact,
          statement: statement,
          fromDate: widget.fromDate,
          toDate: widget.toDate,
        ),
      ),
    );
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
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    widget.contact.nameAr.isNotEmpty
                        ? widget.contact.nameAr[0]
                        : '؟',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        ArabicTextHelper.cleanText(widget.contact.nameAr),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${widget.contact.code} - ${_statements.length} حركة',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            if (_statements.isNotEmpty)
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
              onPressed: _loadStatements,
              tooltip: 'تحديث',
            ),
            const SizedBox(width: 8),
          ],
        ),
        // --- Change: Structure for fixed header ---
        body: Column(
          children: [
            _buildCompactDateHeader(),
            _isLoading
                ? const Expanded(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  )
                : _statements.isEmpty
                    ? Expanded(child: _buildEmptyState())
                    : Expanded(
                        child: Center(
                          child: _buildStatementsTable(),
                        ),
                      ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactDateHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      child: Text(
        'الفترة: ${Helpers.formatDisplayDate(widget.fromDate)} - ${Helpers.formatDisplayDate(widget.toDate)}',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade600,
        ),
        textAlign: TextAlign.center,
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
              Icons.receipt_long_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد حركات في هذه الفترة',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadStatements,
              child: const Text('إعادة التحميل'),
            ),
          ],
        ),
      ),
    );
  }

// Replace the _buildStatementsTable() method with this:
  Widget _buildStatementsTable() {
    final screenWidth = MediaQuery.of(context).size.width;
    final fixedColumnWidth = MediaQuery.of(context).size.width * 0.5;
    final scrollableColumnContentWidth =
        screenWidth > 520 ? MediaQuery.of(context).size.width * 0.5 : 240.0;

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
              // --- Fixed Header Row (Always visible at the top) ---
              SizedBox(
                height: 40,
                child: Row(
                  children: [
                    // Fixed header columns (Date, Document)
                    Container(
                      width: fixedColumnWidth,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800,
                        border: Border(
                            // Separator border
                            top: BorderSide(
                                color: Colors.grey.shade200, width: 1),
                            left: BorderSide(
                                color: Colors.grey.shade400, width: 2)),
                      ),
                      child: const Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Center(
                              child: Text(
                                'التاريخ',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: Center(
                              child: Text(
                                'المستند',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Scrollable header columns (Debit, Credit, Balance)
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        controller: _horizontalHeaderController,
                        child: Container(
                          width: scrollableColumnContentWidth,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade800,
                            border: Border(
                              top: BorderSide(
                                  color: Colors.grey.shade200, width: 1),
                              right: BorderSide(
                                  color: Colors.grey.shade200, width: 1),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Expanded(
                                child: Center(
                                  child: Text(
                                    'مدين',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: Text(
                                    'دائن',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: Text(
                                    'الرصيد',
                                    style: TextStyle(
                                        fontSize: 12,
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
              // --- Scrollable Data Rows Container ---
              Expanded(
                child: SingleChildScrollView(
                  controller: _screenVerticalController,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Fixed Column Data
                      SizedBox(
                        width: fixedColumnWidth,
                        child: Column(
                          children: [
                            for (int index = 0;
                                index < _statements.length;
                                index++)
                              _buildFixedRowPart(_statements[index], index),
                          ],
                        ),
                      ),
                      // Right Scrollable Columns Data
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          controller: _horizontalDataController,
                          child: SizedBox(
                            width: scrollableColumnContentWidth,
                            child: Column(
                              children: [
                                for (int index = 0;
                                    index < _statements.length;
                                    index++)
                                  _buildScrollableRowPart(
                                      _statements[index], index),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Widget for the fixed part of a data row (Date, Document) ---
  Widget _buildFixedRowPart(AccountStatement statement, int index) {
    return InkWell(
        onTap: statement.documentType == 'other'
            ? null // Not tappable if document type is 'other'
            : () => _viewStatementDetail(statement),
        child: Container(
          height: 52, // Fixed height for each data row
          decoration: BoxDecoration(
            color: index % 2 == 0
                ? Colors.white
                : Colors.grey.shade50, // Alternating row colors
            border: Border(
              bottom: BorderSide(
                  color: Colors.grey.shade200,
                  width: 0.5), // Separator between rows
              left: BorderSide(
                  color: Colors.grey.shade400,
                  width: 2), // Visual separator for fixed columns
            ),
          ),
          child: Row(
            children: [
// Replace the التاريخ (Date) column section with this:
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Center(
                    child: Text(
                      statement.docDate,
                      style: TextStyle(
                        fontSize:
                            MediaQuery.of(context).size.width < 400 ? 8.8 : 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              // المستند (Document) column
              Expanded(
                flex: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getDocumentTypeColor(statement
                                  .documentType), // Color based on type
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              Helpers.getDocumentTypeInArabic(statement
                                  .documentType), // Arabic document type
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          if (statement.documentType != 'other')
                            const Icon(Icons.arrow_forward_ios,
                                size: 10, color: Colors.grey),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ArabicTextHelper.cleanText(
                            statement.displayName), // Cleaned display name
                        style: const TextStyle(fontSize: 10),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis, // Truncate long text
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ));
  }

  // --- Widget for the scrollable part of a data row (Debit, Credit, Balance) ---
  Widget _buildScrollableRowPart(AccountStatement statement, int index) {
    final debitColor =
        statement.debit.isNotEmpty ? Colors.red.shade600 : Colors.grey.shade400;
    final creditColor = statement.credit.isNotEmpty
        ? Colors.green.shade600
        : Colors.grey.shade400;
    final balanceColor = Colors.blue.shade700;

    return InkWell(
      onTap: statement.documentType == 'other'
          ? null // Not tappable if document type is 'other'
          : () => _viewStatementDetail(statement), // Tap to view details
      child: Container(
        height: 52, // Fixed height for each data row
        decoration: BoxDecoration(
          color: index % 2 == 0
              ? Colors.white
              : Colors.grey.shade50, // Alternating row colors
          border: Border(
            bottom: BorderSide(
                color: Colors.grey.shade200,
                width: 0.5), // Separator between rows
          ),
        ),
        child: Row(
          children: [
            // مدين (Debit) column
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'مدين', // Label for Debit
                      style: TextStyle(
                          fontSize: 8,
                          color: debitColor,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      Helpers.formatNumber(
                          statement.debit), // Formatted debit amount
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: debitColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            // دائن (Credit) column
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'دائن', // Label for Credit
                      style: TextStyle(
                          fontSize: 8,
                          color: creditColor,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      Helpers.formatNumber(
                          statement.credit), // Formatted credit amount
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: creditColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            // الرصيد (Balance) column
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'الرصيد', // Label for Balance
                      style: TextStyle(
                          fontSize: 8,
                          color: balanceColor,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      Helpers.formatNumber(statement
                          .runningBalance), // Formatted running balance
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: balanceColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
