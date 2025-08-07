// lib/screens/mobile/account_statements_screen.dart
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../models/contact.dart';
import '../../models/account_statement.dart';
import '../../services/api_service.dart';
import '../../services/pdf_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../utils/arabic_text_helper.dart';
import 'statement_detail_screen.dart';

class AccountStatementsScreen extends StatefulWidget {
  final Contact contact;
  final String fromDate;
  final String toDate;

  const AccountStatementsScreen({
    super.key,
    required this.contact,
    required this.fromDate,
    required this.toDate,
  });

  @override
  State<AccountStatementsScreen> createState() =>
      _AccountStatementsScreenState();
}

class _AccountStatementsScreenState extends State<AccountStatementsScreen> {
  List<AccountStatement> _statements = [];
  bool _isLoading = true;
  bool _isCardView = true;
  bool _isGeneratingPdf = false;

  // Controllers for horizontal scrolling (header and data)
  final ScrollController _horizontalHeaderController = ScrollController();
  final ScrollController _horizontalDataController = ScrollController();
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
    _screenVerticalController.dispose();
    super.dispose();
  }

  // Load the account statements from the API
  Future<void> _loadStatements() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final statements = await ApiService.getAccountStatements(
        contactCode: widget.contact.code,
        fromDate: widget.fromDate,
        toDate: widget.toDate,
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
        // Check if the widget is still mounted
        Helpers.showSnackBar(
          context,
          'فشل في تحميل كشف الحساب: ${e.toString()}',
          isError: true,
        );
      }
    }
  }

  // Generate PDF of the account statements
  Future<void> _generatePdf() async {
    setState(() {
      _isGeneratingPdf = true;
    });

    try {
      final pdfBytes = await PdfService.generateAccountStatementPdf(
        contact: widget.contact,
        statements: _statements,
        fromDate: widget.fromDate,
        toDate: widget.toDate,
      );

      await Printing.layoutPdf(
        onLayout: (format) async => pdfBytes,
        name:
            'كشف_حساب_${widget.contact.code}_${widget.fromDate}_${widget.toDate}.pdf',
      );
    } catch (e) {
      if (mounted) {
        // Check if the widget is still mounted
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

  // View the details of a specific statement
  void _viewStatementDetail(AccountStatement statement) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => StatementDetailScreen(
          contact: widget.contact,
          statement: statement,
          fromDate: widget.fromDate,
          toDate: widget.toDate,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('كشف الحساب'),
        actions: [
          IconButton(
            icon: Icon(_isCardView ? Icons.table_rows : Icons.view_agenda),
            onPressed: () {
              setState(() {
                _isCardView = !_isCardView;
              });
            },
            tooltip: _isCardView ? 'عرض جدولي' : 'عرض بطاقات',
          ),
          if (_statements.isNotEmpty)
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
            onPressed: _loadStatements,
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              // Contact Info Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Colors.blue[50],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ArabicTextHelper.cleanText(widget.contact.nameAr),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'رقم العميل: ${widget.contact.code}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      'الفترة: ${Helpers.formatDisplayDate(DateTime.parse(widget.fromDate))} - ${Helpers.formatDisplayDate(DateTime.parse(widget.toDate))}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _statements.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.receipt_long_outlined,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'لا توجد حركات في هذه الفترة',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: _loadStatements,
                                  child: const Text('إعادة التحميل'),
                                ),
                              ],
                            ),
                          )
                        : _isCardView
                            ? _buildCardView()
                            : _buildTableView(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _statements.length,
      itemBuilder: (context, index) {
        final statement = _statements[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          child: InkWell(
            onTap: statement.documentType == 'other'
                ? null
                : () => _viewStatementDetail(statement),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getDocumentTypeColor(statement.documentType),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          Helpers.getDocumentTypeInArabic(
                              statement.documentType),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        statement.docDate,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ArabicTextHelper.cleanText(statement.displayName),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'مدين',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              Helpers.formatNumber(statement.debit),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: statement.debit.isNotEmpty
                                    ? Colors.red[600]
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'دائن',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              Helpers.formatNumber(statement.credit),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: statement.credit.isNotEmpty
                                    ? Colors.green[600]
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'الرصيد',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              Helpers.formatNumber(statement.runningBalance),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(AppConstants.primaryColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (statement.docComment.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        ArabicTextHelper.cleanText(statement.docComment),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (statement.documentType != 'other')
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.grey[400],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTableView() {
    final screenWidth = MediaQuery.of(context).size.width;
    final fixedColumnWidth = screenWidth * 0.5;
    final scrollableColumnContentWidth =
        screenWidth > 520 ? screenWidth * 0.5 : 240.0;

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
              // Fixed Header Row
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
                          top:
                              BorderSide(color: Colors.grey.shade200, width: 1),
                          left:
                              BorderSide(color: Colors.grey.shade400, width: 2),
                        ),
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
                                  color: Colors.white,
                                ),
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
                                  color: Colors.white,
                                ),
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
                                      color: Colors.white,
                                    ),
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
                                      color: Colors.white,
                                    ),
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

  // Widget for the fixed part of a data row (Date, Document)
  Widget _buildFixedRowPart(AccountStatement statement, int index) {
    return InkWell(
      onTap: statement.documentType == 'other'
          ? null
          : () => _viewStatementDetail(statement),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: index % 2 == 0 ? Colors.white : Colors.grey.shade50,
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
            left: BorderSide(color: Colors.grey.shade400, width: 2),
          ),
        ),
        child: Row(
          children: [
            // Date column
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
            // Document column
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
                            color:
                                _getDocumentTypeColor(statement.documentType),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            Helpers.getDocumentTypeInArabic(
                                statement.documentType),
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
                      ArabicTextHelper.cleanText(statement.displayName),
                      style: const TextStyle(fontSize: 10),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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

  // Widget for the scrollable part of a data row (Debit, Credit, Balance)
  Widget _buildScrollableRowPart(AccountStatement statement, int index) {
    final debitColor =
        statement.debit.isNotEmpty ? Colors.red.shade600 : Colors.grey.shade400;
    final creditColor = statement.credit.isNotEmpty
        ? Colors.green.shade600
        : Colors.grey.shade400;
    final balanceColor = Colors.blue.shade700;

    return InkWell(
      onTap: statement.documentType == 'other'
          ? null
          : () => _viewStatementDetail(statement),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: index % 2 == 0 ? Colors.white : Colors.grey.shade50,
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            // Debit column
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'مدين',
                      style: TextStyle(
                        fontSize: 8,
                        color: debitColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      Helpers.formatNumber(statement.debit),
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
            // Credit column
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'دائن',
                      style: TextStyle(
                        fontSize: 8,
                        color: creditColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      Helpers.formatNumber(statement.credit),
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
            // Balance column
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'الرصيد',
                      style: TextStyle(
                        fontSize: 8,
                        color: balanceColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      Helpers.formatNumber(statement.runningBalance),
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

// Updated document type color method
  Color _getDocumentTypeColor(String documentType) {
    switch (documentType) {
      case 'invoice':
        return const Color(AppConstants.primaryColor);
      case 'return':
        return const Color(AppConstants.accentColor);
      case 'payment':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
