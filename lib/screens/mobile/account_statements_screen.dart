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
      Helpers.showSnackBar(
        context,
        'فشل في تحميل كشف الحساب: ${e.toString()}',
        isError: true,
      );
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
        fromDate: widget.fromDate,
        toDate: widget.toDate,
      );

      await Printing.layoutPdf(
        onLayout: (format) async => pdfBytes,
        name:
            'كشف_حساب_${widget.contact.code}_${widget.fromDate}_${widget.toDate}.pdf',
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
      body: Column(
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
            onTap: statement.documentType == 'other' ? null : () => _viewStatementDetail(statement),
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 20,
        columns: const [
          DataColumn(label: Text('التاريخ')),
          DataColumn(label: Text('المستند')),
          DataColumn(label: Text('مدين')),
          DataColumn(label: Text('دائن')),
          DataColumn(label: Text('الرصيد')),
        ],
        rows: _statements.map((statement) {
          return DataRow(
            onSelectChanged: (_) => _viewStatementDetail(statement),
            cells: [
              DataCell(Text(statement.docDate)),
              DataCell(
                SizedBox(
                  width: 150,
                  child: Text(
                    ArabicTextHelper.cleanText(statement.displayName),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              DataCell(
                Text(
                  Helpers.formatNumber(statement.debit),
                  style: TextStyle(
                    color: statement.debit.isNotEmpty
                        ? Colors.red[600]
                        : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              DataCell(
                Text(
                  Helpers.formatNumber(statement.credit),
                  style: TextStyle(
                    color: statement.credit.isNotEmpty
                        ? Colors.green[600]
                        : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              DataCell(
                Text(
                  Helpers.formatNumber(statement.runningBalance),
                  style: const TextStyle(
                    color: Color(AppConstants.primaryColor),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        }).toList(),
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
}
