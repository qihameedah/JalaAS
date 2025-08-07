// lib/screens/mobile/date_range_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jala_as/utils/constants.dart';
import '../../models/contact.dart';
import '../../utils/helpers.dart';
import 'account_statements_screen.dart';

class DateRangeScreen extends StatefulWidget {
  final Contact contact;

  const DateRangeScreen({
    super.key,
    required this.contact,
  });

  @override
  State<DateRangeScreen> createState() => _DateRangeScreenState();
}

class _DateRangeScreenState extends State<DateRangeScreen> {
  DateTime? _fromDate;
  DateTime? _toDate;
  final _dateFormat = DateFormat('yyyy-MM-dd');
  final _displayDateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    // Set default dates (current month)
    final now = DateTime.now();
    _fromDate = DateTime(now.year, now.month, 1);
    _toDate = now;
  }

  Future<void> _selectFromDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      // Remove hardcoded locale - let system handle it
      // locale: const Locale('ar'),
    );

    if (picked != null) {
      setState(() {
        _fromDate = picked;
        // Better logic: only adjust toDate if it's significantly before fromDate
        if (_toDate != null && _toDate!.isBefore(picked)) {
          // Show a warning to user instead of silently changing toDate
          _showDateAdjustmentWarning();
        }
      });
    }
  }

  Future<void> _selectToDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _toDate ?? DateTime.now(),
      firstDate: _fromDate ?? DateTime(2020),
      lastDate: DateTime.now(),
      // Remove hardcoded locale
      // locale: const Locale('ar'),
    );

    if (picked != null) {
      setState(() {
        _toDate = picked;
      });
    }
  }

  void _showDateAdjustmentWarning() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تأكد من أن تاريخ النهاية بعد تاريخ البداية'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _proceed() {
    if (_fromDate == null || _toDate == null) {
      Helpers.showSnackBar(
        context,
        'يرجى اختيار التواريخ',
        isError: true,
      );
      return;
    }

    if (_toDate!.isBefore(_fromDate!)) {
      Helpers.showSnackBar(
        context,
        'تاريخ النهاية يجب أن يكون بعد تاريخ البداية',
        isError: true,
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AccountStatementsScreen(
          contact: widget.contact,
          fromDate: _dateFormat.format(_fromDate!),
          toDate: _dateFormat.format(_toDate!),
        ),
      ),
    );
  }

  void _setQuickDate(String period) {
    final now = DateTime.now();
    DateTime from;

    switch (period) {
      case 'today':
        from = DateTime(now.year, now.month, now.day);
        break;
      case 'week':
        from = now.subtract(const Duration(days: 7));
        break;
      case 'month':
        from = DateTime(now.year, now.month, 1);
        break;
      case 'quarter':
        // Improved quarter calculation
        final currentQuarter = ((now.month - 1) ~/ 3) + 1;
        final quarterStartMonth = (currentQuarter - 1) * 3 + 1;
        from = DateTime(now.year, quarterStartMonth, 1);
        break;
      case 'year':
        from = DateTime(now.year, 1, 1);
        break;
      default:
        return;
    }

    setState(() {
      _fromDate = from;
      _toDate = now;
    });
  }

// lib/screens/mobile/date_range_screen.dart - Updated build method
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppConstants.backgroundColor),
      appBar: AppBar(
        title: const Text('اختيار الفترة'),
        backgroundColor: const Color(AppConstants.primaryColor),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Contact Info
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'العميل المحدد:',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.contact.nameAr,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(AppConstants.primaryColor),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'رقم العميل: ${widget.contact.code}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Quick Date Selection
                Text(
                  'اختيار سريع:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: const Color(AppConstants.primaryColor),
                      ),
                ),

                const SizedBox(height: 10),

                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _QuickDateChip(
                        label: 'اليوم', onTap: () => _setQuickDate('today')),
                    _QuickDateChip(
                        label: 'آخر أسبوع', onTap: () => _setQuickDate('week')),
                    _QuickDateChip(
                        label: 'هذا الشهر',
                        onTap: () => _setQuickDate('month')),
                    _QuickDateChip(
                        label: 'هذا الربع',
                        onTap: () => _setQuickDate('quarter')),
                    _QuickDateChip(
                        label: 'هذا العام', onTap: () => _setQuickDate('year')),
                  ],
                ),

                const SizedBox(height: 20),

                // Custom Date Selection
                Text(
                  'اختيار مخصص:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: const Color(AppConstants.primaryColor),
                      ),
                ),

                const SizedBox(height: 12),

                // From Date
                InkWell(
                  onTap: _selectFromDate,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today,
                            color: Color(AppConstants.primaryColor), size: 20),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'من تاريخ',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _fromDate != null
                                  ? _displayDateFormat.format(_fromDate!)
                                  : 'اختر التاريخ',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(AppConstants.primaryColor),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // To Date
                InkWell(
                  onTap: _selectToDate,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today,
                            color: Color(AppConstants.primaryColor), size: 20),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'إلى تاريخ',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _toDate != null
                                  ? _displayDateFormat.format(_toDate!)
                                  : 'اختر التاريخ',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(AppConstants.primaryColor),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Proceed Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_fromDate != null && _toDate != null)
                        ? _proceed
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(AppConstants.primaryColor),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      elevation: 2,
                    ),
                    child: const Text('عرض كشف الحساب',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Updated _QuickDateChip widget
class _QuickDateChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickDateChip({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(AppConstants.accentColor).withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: const Color(AppConstants.accentColor).withOpacity(0.4)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(AppConstants.accentColor),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
