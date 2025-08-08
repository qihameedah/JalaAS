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
  ];

  @override
  void initState() {
    super.initState();
    // Default to this month
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
        _selectedPeriod = ''; // Clear selected period when manually editing
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

    // Navigate to results screen
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
      // Reset loading state when returning
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
                  ),
                ),
                SizedBox(width: isDesktop ? 12 : 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        ArabicTextHelper.cleanText(widget.contact.nameAr),
                        style: TextStyle(
                          fontSize: isDesktop ? 16 : 14,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'رقم العميل: ${widget.contact.code}',
                        style: TextStyle(
                          fontSize: isDesktop ? 12 : 10,
                          color: Colors.grey.shade600,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isDesktop ? 16 : 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Text(
                    'اختر الفترة الزمنية',
                    style: TextStyle(
                      fontSize: isDesktop ? 18 : 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: isDesktop ? 16 : 12),

                  // Quick Selection Buttons
                  Text(
                    'اختيار سريع:',
                    style: TextStyle(
                      fontSize: isDesktop ? 14 : 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
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
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isDesktop ? 12 : 10,
                            vertical: isDesktop ? 8 : 6,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? period.color.shade100
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? period.color
                                  : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                period.icon,
                                size: isDesktop ? 16 : 14,
                                color: isSelected
                                    ? period.color
                                    : Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                period.title,
                                style: TextStyle(
                                  fontSize: isDesktop ? 12 : 10,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? period.color
                                      : Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  SizedBox(height: isDesktop ? 20 : 16),

                  // Date Input Fields - Always Visible
                  Text(
                    'تخصيص التواريخ:',
                    style: TextStyle(
                      fontSize: isDesktop ? 14 : 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // From and To Date Fields
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateField(
                            'من تاريخ', _fromDate, true, isDesktop),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildDateField(
                            'إلى تاريخ', _toDate, false, isDesktop),
                      ),
                    ],
                  ),

                  SizedBox(height: isDesktop ? 16 : 12),

                  // Load Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (_fromDate != null &&
                              _toDate != null &&
                              !_isLoadingStatements)
                          ? _loadStatements
                          : null,
                      style: ElevatedButton.styleFrom(
                        padding:
                            EdgeInsets.symmetric(vertical: isDesktop ? 14 : 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoadingStatements
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'جاري التحميل...',
                                  style:
                                      TextStyle(fontSize: isDesktop ? 14 : 12),
                                ),
                              ],
                            )
                          : Text(
                              'عرض كشف الحساب',
                              style: TextStyle(fontSize: isDesktop ? 14 : 12),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField(
      String label, DateTime? date, bool isFromDate, bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isDesktop ? 12 : 10,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: () => _selectCustomDate(isFromDate),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: 8,
              vertical: isDesktop ? 12 : 10,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    date != null
                        ? Helpers.formatDisplayDate(date)
                        : 'اختر التاريخ',
                    style: TextStyle(
                      fontSize: isDesktop ? 12 : 11,
                      color:
                          date != null ? Colors.black87 : Colors.grey.shade500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.calendar_today,
                  size: isDesktop ? 16 : 14,
                  color: Colors.grey.shade600,
                ),
              ],
            ),
          ),
        ),
      ],
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
