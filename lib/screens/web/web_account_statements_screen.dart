// lib/screens/web/web_account_statements_screen.dart
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../models/user.dart';
import '../../models/contact.dart';
import '../../models/account_statement.dart';
import '../../services/api_service.dart';
import '../../services/pdf_service.dart';
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
  bool _isCardView = true;
  bool _isGeneratingPdf = false;

  @override
  void initState() {
    super.initState();
    _loadStatements();
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;
    final isTablet = screenWidth > 600 && screenWidth <= 900;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isDesktop
              ? 'كشف حساب - ${ArabicTextHelper.cleanText(widget.contact.nameAr)}'
              : 'كشف الحساب',
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          // View Toggle
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.view_agenda,
                    color: _isCardView ? Colors.blue : Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _isCardView = true;
                    });
                  },
                  tooltip: 'عرض بطاقات',
                ),
                Container(
                  width: 1,
                  height: 20,
                  color: Colors.grey.shade300,
                ),
                IconButton(
                  icon: Icon(
                    Icons.table_rows,
                    color: !_isCardView ? Colors.blue : Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _isCardView = false;
                    });
                  },
                  tooltip: 'عرض جدولي',
                ),
              ],
            ),
          ),
          // PDF Export
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
              tooltip: 'تصدير PDF',
            ),
          // Refresh
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStatements,
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              // Contact Info Header
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(isDesktop ? 20 : 16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Center(
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: isDesktop ? 1200 : double.infinity,
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: isDesktop ? 30 : 24,
                          backgroundColor: Colors.blue.shade100,
                          child: Text(
                            widget.contact.nameAr.isNotEmpty
                                ? widget.contact.nameAr[0]
                                : '؟',
                            style: TextStyle(
                              fontSize: isDesktop ? 20 : 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                        SizedBox(width: isDesktop ? 16 : 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ArabicTextHelper.cleanText(
                                    widget.contact.nameAr),
                                style: TextStyle(
                                  fontSize: isDesktop ? 20 : 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'رقم العميل: ${widget.contact.code}',
                                style: TextStyle(
                                  fontSize: isDesktop ? 14 : 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                'الفترة: ${Helpers.formatDisplayDate(widget.fromDate)} - ${Helpers.formatDisplayDate(widget.toDate)}',
                                style: TextStyle(
                                  fontSize: isDesktop ? 14 : 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Statistics Card
                        if (isDesktop && _statements.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'إجمالي الحركات',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                Text(
                                  '${_statements.length}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
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
              ),

              // Content
              Expanded(
                child: Center(
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: isDesktop ? 1200 : double.infinity,
                    ),
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _statements.isEmpty
                            ? _buildEmptyState(isDesktop)
                            : _isCardView
                                ? _buildCardView(isDesktop, isTablet)
                                : _buildTableView(isDesktop),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isDesktop) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: isDesktop ? 80 : 64,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: isDesktop ? 24 : 16),
            Text(
              'لا توجد حركات في هذه الفترة',
              style: TextStyle(
                fontSize: isDesktop ? 20 : 18,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: isDesktop ? 16 : 8),
            ElevatedButton.icon(
              onPressed: _loadStatements,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة التحميل'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardView(bool isDesktop, bool isTablet) {
    int crossAxisCount = 1;
    if (isDesktop) {
      crossAxisCount = 2;
    } else if (isTablet) {
      crossAxisCount = 1;
    }

    if (isDesktop) {
      return GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 3.5,
        ),
        itemCount: _statements.length,
        itemBuilder: (context, index) {
          return _buildStatementCard(_statements[index], isDesktop);
        },
      );
    } else {
      return ListView.builder(
        padding: EdgeInsets.all(isTablet ? 16 : 12),
        itemCount: _statements.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildStatementCard(_statements[index], isDesktop),
          );
        },
      );
    }
  }

  Widget _buildStatementCard(AccountStatement statement, bool isDesktop) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: statement.documentType == 'other'
            ? null
            : () => _viewStatementDetail(statement),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(isDesktop ? 20 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Row
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 12 : 10,
                      vertical: isDesktop ? 6 : 5,
                    ),
                    decoration: BoxDecoration(
                      color: _getDocumentTypeColor(statement.documentType),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      Helpers.getDocumentTypeInArabic(statement.documentType),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isDesktop ? 12 : 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Flexible(
                    child: Text(
                      statement.docDate,
                      style: TextStyle(
                        fontSize: isDesktop ? 13 : 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              SizedBox(height: isDesktop ? 12 : 8),

              // Document Name
              SizedBox(
                width: double.infinity,
                child: Text(
                  ArabicTextHelper.cleanText(statement.displayName),
                  style: TextStyle(
                    fontSize: isDesktop ? 16 : 15,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              SizedBox(height: isDesktop ? 16 : 12),

              // Financial Details Row
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _buildFinancialColumn(
                        'مدين',
                        statement.debit,
                        statement.debit.isNotEmpty
                            ? Colors.red.shade600
                            : Colors.grey,
                        isDesktop,
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: _buildFinancialColumn(
                        'دائن',
                        statement.credit,
                        statement.credit.isNotEmpty
                            ? Colors.green.shade600
                            : Colors.grey,
                        isDesktop,
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: _buildFinancialColumn(
                        'الرصيد',
                        statement.runningBalance,
                        Colors.blue.shade700,
                        isDesktop,
                      ),
                    ),
                  ],
                ),
              ),

              // Comment if exists
              if (statement.docComment.isNotEmpty) ...[
                SizedBox(height: isDesktop ? 12 : 8),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(isDesktop ? 10 : 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    ArabicTextHelper.cleanText(statement.docComment),
                    style: TextStyle(
                      fontSize: isDesktop ? 12 : 11,
                      color: Colors.grey.shade700,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],

              // Action indicator
              if (statement.documentType != 'other') ...[
                SizedBox(height: isDesktop ? 12 : 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'اضغط للتفاصيل',
                      style: TextStyle(
                        fontSize: isDesktop ? 11 : 10,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: isDesktop ? 14 : 12,
                      color: Colors.grey.shade400,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFinancialColumn(
      String label, String value, Color color, bool isDesktop) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isDesktop ? 11 : 10,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            Helpers.formatNumber(value),
            style: TextStyle(
              fontSize: isDesktop ? 12 : 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTableView(bool isDesktop) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: EdgeInsets.all(isDesktop ? 20 : 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              // Table Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                        flex: 2,
                        child: Text('التاريخ',
                            style: _getHeaderStyle(isDesktop),
                            textAlign: TextAlign.center)),
                    Expanded(
                        flex: 3,
                        child: Text('المستند',
                            style: _getHeaderStyle(isDesktop),
                            textAlign: TextAlign.center)),
                    Expanded(
                        flex: 2,
                        child: Text('مدين',
                            style: _getHeaderStyle(isDesktop),
                            textAlign: TextAlign.center)),
                    Expanded(
                        flex: 2,
                        child: Text('دائن',
                            style: _getHeaderStyle(isDesktop),
                            textAlign: TextAlign.center)),
                    Expanded(
                        flex: 2,
                        child: Text('الرصيد',
                            style: _getHeaderStyle(isDesktop),
                            textAlign: TextAlign.center)),
                  ],
                ),
              ),
              // Table Rows
              Expanded(
                child: ListView.separated(
                  itemCount: _statements.length,
                  separatorBuilder: (context, index) =>
                      Divider(height: 1, color: Colors.grey.shade200),
                  itemBuilder: (context, index) {
                    final statement = _statements[index];
                    return InkWell(
                      onTap: statement.documentType == 'other'
                          ? null
                          : () => _viewStatementDetail(statement),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                statement.docDate,
                                style: _getCellStyle(isDesktop),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _getDocumentTypeColor(
                                          statement.documentType),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      Helpers.getDocumentTypeInArabic(
                                          statement.documentType),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      ArabicTextHelper.cleanText(
                                          statement.displayName),
                                      style: _getCellStyle(isDesktop),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                Helpers.formatNumber(statement.debit),
                                style: _getCellStyle(isDesktop).copyWith(
                                  color: statement.debit.isNotEmpty
                                      ? Colors.red.shade600
                                      : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                Helpers.formatNumber(statement.credit),
                                style: _getCellStyle(isDesktop).copyWith(
                                  color: statement.credit.isNotEmpty
                                      ? Colors.green.shade600
                                      : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                Helpers.formatNumber(statement.runningBalance),
                                style: _getCellStyle(isDesktop).copyWith(
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
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
}
