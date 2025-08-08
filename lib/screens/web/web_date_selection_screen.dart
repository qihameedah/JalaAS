// lib/screens/web/web_date_selection_screen.dart
import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../models/contact.dart';
import '../../utils/helpers.dart';
import '../../utils/arabic_text_helper.dart';
import 'web_account_statements_screen.dart';

class DateSelectionScreen extends StatefulWidget {
  final AppUser user;
  final Contact contact;

  const DateSelectionScreen({
    super.key,
    required this.user,
    required this.contact,
  });

  @override
  State<DateSelectionScreen> createState() => _DateSelectionScreenState();
}

class _DateSelectionScreenState extends State<DateSelectionScreen> {
  DateTime? _fromDate;
  DateTime? _toDate;
  String _selectedPeriod = '';
  bool _isLoadingStatements = false;

  final List<DatePeriod> _predefinedPeriods = [
    DatePeriod(
      id: 'today',
      title: 'اليوم',
      icon: Icons.today,
      color: Colors.green,
    ),
    DatePeriod(
      id: 'this_week',
      title: 'هذا الأسبوع',
      icon: Icons.view_week,
      color: Colors.blue,
    ),
    DatePeriod(
      id: 'this_month',
      title: 'هذا الشهر',
      icon: Icons.calendar_view_month,
      color: Colors.orange,
    ),
    DatePeriod(
      id: 'this_quarter',
      title: 'هذا الربع',
      icon: Icons.calendar_view_day,
      color: Colors.purple,
    ),
    DatePeriod(
      id: 'this_year',
      title: 'هذه السنة',
      icon: Icons.calendar_today,
      color: Colors.teal,
    ),
    DatePeriod(
      id: 'last_30',
      title: 'آخر 30 يوم',
      icon: Icons.history,
      color: Colors.indigo,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectPredefinedPeriod('this_month');
  }

  void _selectPredefinedPeriod(String periodId) {
    final now = DateTime.now();
    setState(() {
      _selectedPeriod = periodId;

      switch (periodId) {
        case 'today':
          _fromDate = DateTime(now.year, now.month, now.day);
          _toDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
          break;
        case 'this_week':
          final weekday = now.weekday;
          _fromDate = now.subtract(Duration(days: weekday - 1));
          _fromDate =
              DateTime(_fromDate!.year, _fromDate!.month, _fromDate!.day);
          _toDate = now;
          break;
        case 'this_month':
          _fromDate = DateTime(now.year, now.month, 1);
          _toDate = now;
          break;
        case 'this_quarter':
          final quarterMonth = ((now.month - 1) ~/ 3) * 3 + 1;
          _fromDate = DateTime(now.year, quarterMonth, 1);
          _toDate = now;
          break;
        case 'this_year':
          _fromDate = DateTime(now.year, 1, 1);
          _toDate = now;
          break;
        case 'last_30':
          _fromDate = now.subtract(const Duration(days: 30));
          _fromDate =
              DateTime(_fromDate!.year, _fromDate!.month, _fromDate!.day);
          _toDate = now;
          break;
      }
    });
  }

  Future<void> _selectCustomDate(bool isFromDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          isFromDate ? _fromDate ?? DateTime.now() : _toDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _fromDate = picked;
          if (_toDate != null && _toDate!.isBefore(picked)) {
            _toDate = picked;
          }
        } else {
          _toDate = picked;
        }
        _selectedPeriod = '';
      });
    }
  }

  Future<void> _loadStatements() async {
    if (_fromDate == null || _toDate == null) {
      Helpers.showSnackBar(
        context,
        'يرجى اختيار التواريخ',
        isError: true,
      );
      return;
    }

    setState(() {
      _isLoadingStatements = true;
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WebAccountStatementsScreen(
          user: widget.user,
          contact: widget.contact,
          fromDate: _fromDate!,
          toDate: _toDate!,
        ),
      ),
    ).then((_) {
      if (mounted) {
        setState(() {
          _isLoadingStatements = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

<<<<<<< HEAD:lib/screens/web/date_selection_screen.dart
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 1,
          iconTheme: const IconThemeData(color: Colors.black87),
          title: Row(
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
=======
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isDesktop
              ? 'كشف حساب - ${ArabicTextHelper.cleanText(widget.contact.nameAr)}'
              : 'كشف الحساب',
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (isDesktop) {
            return _buildDesktopLayout(constraints);
          } else {
            return _buildMobileLayout(constraints);
          }
        },
      ),
    );
  }

  Widget _buildDesktopLayout(BoxConstraints constraints) {
    return Center(
      child: SizedBox(
        width: 500,
        height: constraints.maxHeight,
        child: _buildDateSelectionPanel(true, constraints.maxHeight),
      ),
    );
  }

  Widget _buildMobileLayout(BoxConstraints constraints) {
    return _buildDateSelectionPanel(false, constraints.maxHeight);
  }

  Widget _buildDateSelectionPanel(bool isDesktop, double maxHeight) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Contact Info Header - Fixed height
          Container(
            padding: EdgeInsets.all(isDesktop ? 16 : 12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: isDesktop ? 24 : 20,
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    widget.contact.nameAr.isNotEmpty
                        ? widget.contact.nameAr[0]
                        : '؟',
                    style: TextStyle(
                      fontSize: isDesktop ? 16 : 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
>>>>>>> b20a8dd912970bf0f1612c5dd009e1271fe9847f:lib/screens/web/web_date_selection_screen.dart
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
        body: SafeArea(
          child: Column(
            children: [
              _buildCompactContactInfo(),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'اختر الفترة الزمنية',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildQuickSelectionGrid(),
                      const SizedBox(height: 20),
                      _buildCustomDateSelection(),
                      const SizedBox(height: 20),
                      _buildLoadButton(),
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

  Widget _buildCompactContactInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      child: Row(
        children: [
          Icon(Icons.calendar_today, color: Colors.blue.shade600, size: 20),
          const SizedBox(width: 8),
          Text(
            'رقم العميل: ${widget.contact.code}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const Spacer(),
          if (_fromDate != null && _toDate != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${Helpers.formatDisplayDate(_fromDate!)} - ${Helpers.formatDisplayDate(_toDate!)}',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickSelectionGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'اختيار سريع:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _predefinedPeriods.map((period) {
            final isSelected = _selectedPeriod == period.id;

            return InkWell(
              onTap: () => _selectPredefinedPeriod(period.id),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? period.color.shade100 : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? period.color : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      period.icon,
                      size: 14,
                      color: isSelected ? period.color : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      period.title,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? period.color : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCustomDateSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'تخصيص التواريخ:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildCompactDateField('من تاريخ', _fromDate, true),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCompactDateField('إلى تاريخ', _toDate, false),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompactDateField(String label, DateTime? date, bool isFromDate) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: () => _selectCustomDate(isFromDate),
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    date != null
                        ? Helpers.formatDisplayDate(date)
                        : 'اختر التاريخ',
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          date != null ? Colors.black87 : Colors.grey.shade500,
                    ),
                  ),
                ),
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed:
            (_fromDate != null && _toDate != null && !_isLoadingStatements)
                ? _loadStatements
                : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade600,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
        child: _isLoadingStatements
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text('جاري التحميل...', style: TextStyle(fontSize: 14)),
                ],
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 20),
                  SizedBox(width: 8),
                  Text('عرض كشف الحساب',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
      ),
    );
  }
}

class DatePeriod {
  final String id;
  final String title;
  final IconData icon;
  final MaterialColor color;

  DatePeriod({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
  });
}
