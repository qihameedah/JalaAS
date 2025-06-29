// lib/screens/web/web_statements_screen.dart
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../models/user.dart';
import '../../models/contact.dart';
import '../../models/account_statement.dart';
import '../../services/supabase_service.dart';
import '../../services/api_service.dart';
import '../../services/pdf_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../utils/arabic_text_helper.dart';
import 'web_login_screen.dart';

class WebStatementsScreen extends StatefulWidget {
  final AppUser user;

  const WebStatementsScreen({
    super.key,
    required this.user,
  });

  @override
  State<WebStatementsScreen> createState() => _WebStatementsScreenState();
}

class _WebStatementsScreenState extends State<WebStatementsScreen> {
  final _contactController = TextEditingController();
  final _fromDateController = TextEditingController();
  final _toDateController = TextEditingController();

  List<Contact> _contacts = [];
  List<Contact> _filteredContacts = [];
  Contact? _selectedContact;
  DateTime? _fromDate;
  DateTime? _toDate;

  List<AccountStatement> _statements = [];
  bool _isLoadingContacts = false;
  bool _isLoadingStatements = false;
  bool _isGeneratingPdf = false;
  bool _showContactDropdown = false;

  @override
  void initState() {
    super.initState();
    _loadContacts();
    _setDefaultDates();
  }

  @override
  void dispose() {
    _contactController.dispose();
    _fromDateController.dispose();
    _toDateController.dispose();
    super.dispose();
  }

  void _setDefaultDates() {
    final now = DateTime.now();
    _fromDate = DateTime(now.year, now.month, 1);
    _toDate = now;
    _fromDateController.text = Helpers.formatDate(_fromDate!);
    _toDateController.text = Helpers.formatDate(_toDate!);
  }

  Future<void> _loadContacts() async {
    setState(() {
      _isLoadingContacts = true;
    });

    try {
      List<Contact> contacts;

      if (widget.user.isAdmin) {
        contacts = await SupabaseService.getContacts();
      } else {
        contacts = await SupabaseService.getUserContacts(
          salesman: widget.user.salesman,
          area: widget.user.area,
        );
      }

      setState(() {
        _contacts = contacts;
        _filteredContacts = contacts;
        _isLoadingContacts = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingContacts = false;
      });
      Helpers.showSnackBar(
        context,
        'فشل في تحميل قائمة العملاء',
        isError: true,
      );
    }
  }

  void _filterContacts(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredContacts = _contacts;
        _showContactDropdown = false;
      } else {
        _filteredContacts = _contacts.where((contact) {
          final nameMatch =
              contact.nameAr.toLowerCase().contains(query.toLowerCase());
          final codeMatch =
              contact.code.toLowerCase().contains(query.toLowerCase());
          return nameMatch || codeMatch;
        }).toList();
        _showContactDropdown = true;
      }
    });
  }

  void _selectContact(Contact contact) {
    setState(() {
      _selectedContact = contact;
      _contactController.text = '${contact.nameAr} (${contact.code})';
      _showContactDropdown = false;
    });
  }

  Future<void> _selectDate(bool isFromDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFromDate ? _fromDate : _toDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _fromDate = picked;
          _fromDateController.text = Helpers.formatDate(picked);
          if (_toDate != null && _toDate!.isBefore(picked)) {
            _toDate = picked;
            _toDateController.text = Helpers.formatDate(picked);
          }
        } else {
          _toDate = picked;
          _toDateController.text = Helpers.formatDate(picked);
        }
      });
    }
  }

  Future<void> _loadStatements() async {
    if (_selectedContact == null || _fromDate == null || _toDate == null) {
      Helpers.showSnackBar(
        context,
        'يرجى اختيار العميل والتواريخ',
        isError: true,
      );
      return;
    }

    setState(() {
      _isLoadingStatements = true;
      _statements = [];
    });

    try {
      final statements = await ApiService.getAccountStatements(
        contactCode: _selectedContact!.code,
        fromDate: Helpers.formatDate(_fromDate!),
        toDate: Helpers.formatDate(_toDate!),
      );

      setState(() {
        _statements = statements;
        _isLoadingStatements = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingStatements = false;
      });
      Helpers.showSnackBar(
        context,
        'فشل في تحميل كشف الحساب: ${e.toString()}',
        isError: true,
      );
    }
  }

  Future<void> _generatePdf() async {
    if (_selectedContact == null || _statements.isEmpty) return;

    setState(() {
      _isGeneratingPdf = true;
    });

    try {
      final pdfBytes = await PdfService.generateAccountStatementPdf(
        contact: _selectedContact!,
        statements: _statements,
        fromDate: Helpers.formatDate(_fromDate!),
        toDate: Helpers.formatDate(_toDate!),
      );

      await Printing.layoutPdf(
        onLayout: (format) async => pdfBytes,
        name:
            'كشف_حساب_${_selectedContact!.code}_${Helpers.formatDate(_fromDate!)}_${Helpers.formatDate(_toDate!)}.pdf',
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

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل تريد تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await SupabaseService.signOut();
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const WebLoginScreen(),
            ),
          );
        }
      } catch (e) {
        Helpers.showSnackBar(
          context,
          'فشل في تسجيل الخروج',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 1200;

    return Scaffold(
      appBar: AppBar(
        title: const Text('كشوف الحسابات'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                'مرحباً، ${widget.user.username}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('تسجيل الخروج'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Panel
            SizedBox(
              width: isWideScreen ? 400 : 350,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'البحث عن كشف حساب',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),

                      const SizedBox(height: 24),

                      // Contact Selection
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'العميل',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Stack(
                            children: [
                              TextFormField(
                                controller: _contactController,
                                onChanged: _filterContacts,
                                decoration: const InputDecoration(
                                  hintText: 'ابحث عن عميل بالاسم أو الرقم',
                                  prefixIcon: Icon(Icons.search),
                                ),
                              ),
                              if (_showContactDropdown &&
                                  _filteredContacts.isNotEmpty)
                                Positioned(
                                  top: 60,
                                  left: 0,
                                  right: 0,
                                  child: Card(
                                    elevation: 8,
                                    child: Container(
                                      constraints:
                                          const BoxConstraints(maxHeight: 200),
                                      child: ListView.builder(
                                        shrinkWrap: true,
                                        itemCount:
                                            _filteredContacts.take(5).length,
                                        itemBuilder: (context, index) {
                                          final contact =
                                              _filteredContacts[index];
                                          return ListTile(
                                            dense: true,
                                            title: Text(contact.nameAr),
                                            subtitle: Text(
                                                'رقم العميل: ${contact.code}'),
                                            onTap: () =>
                                                _selectContact(contact),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Date Range
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'من تاريخ',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _fromDateController,
                                  readOnly: true,
                                  onTap: () => _selectDate(true),
                                  decoration: const InputDecoration(
                                    suffixIcon: Icon(Icons.calendar_today),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'إلى تاريخ',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _toDateController,
                                  readOnly: true,
                                  onTap: () => _selectDate(false),
                                  decoration: const InputDecoration(
                                    suffixIcon: Icon(Icons.calendar_today),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Search Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: (_selectedContact != null &&
                                  !_isLoadingStatements)
                              ? _loadStatements
                              : null,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isLoadingStatements
                              ? const CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                )
                              : const Text('عرض كشف الحساب'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(width: 24),

            // Results Panel
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'كشف الحساب',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const Spacer(),
                          if (_statements.isNotEmpty) ...[
                            ElevatedButton.icon(
                              onPressed: _isGeneratingPdf ? null : _generatePdf,
                              icon: _isGeneratingPdf
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Icon(Icons.picture_as_pdf),
                              label: const Text('تصدير PDF'),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 24),
                      if (_selectedContact != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ArabicTextHelper.cleanText(
                                    _selectedContact!.nameAr),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'رقم العميل: ${_selectedContact!.code}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              if (_fromDate != null && _toDate != null)
                                Text(
                                  'الفترة: ${Helpers.formatDisplayDate(_fromDate!)} - ${Helpers.formatDisplayDate(_toDate!)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      Expanded(
                        child: _isLoadingStatements
                            ? const Center(child: CircularProgressIndicator())
                            : _statements.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.receipt_long_outlined,
                                          size: 64,
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          _selectedContact == null
                                              ? 'اختر عميلاً لعرض كشف الحساب'
                                              : 'لا توجد حركات في هذه الفترة',
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : SingleChildScrollView(
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
                                          cells: [
                                            DataCell(Text(statement.docDate)),
                                            DataCell(
                                              SizedBox(
                                                width: 200,
                                                child: Text(
                                                  ArabicTextHelper.cleanText(
                                                      statement.displayName),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Text(
                                                Helpers.formatNumber(
                                                    statement.debit),
                                                style: TextStyle(
                                                  color:
                                                      statement.debit.isNotEmpty
                                                          ? Colors.red[600]
                                                          : Colors.grey,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Text(
                                                Helpers.formatNumber(
                                                    statement.credit),
                                                style: TextStyle(
                                                  color: statement
                                                          .credit.isNotEmpty
                                                      ? Colors.green[600]
                                                      : Colors.grey,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Text(
                                                Helpers.formatNumber(
                                                    statement.runningBalance),
                                                style: const TextStyle(
                                                  color: Color(AppConstants
                                                      .primaryColor),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      }).toList(),
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
    );
  }
}
