// lib/screens/mobile/date_range_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/contact.dart';
import '../../utils/constants.dart';
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
      locale: const Locale('ar'),
    );

    if (picked != null) {
      setState(() {
        _fromDate = picked;
        // Ensure toDate is not before fromDate
        if (_toDate != null && _toDate!.isBefore(picked)) {
          _toDate = picked;
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
      locale: const Locale('ar'),
    );

    if (picked != null) {
      setState(() {
        _toDate = picked;
      });
    }
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
        from = now;
        break;
      case 'week':
        from = now.subtract(const Duration(days: 7));
        break;
      case 'month':
        from = DateTime(now.year, now.month, 1);
        break;
      case 'quarter':
        final quarter = ((now.month - 1) ~/ 3) + 1;
        from = DateTime(now.year, (quarter - 1) * 3 + 1, 1);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اختيار الفترة'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Contact Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'العميل المحدد:',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.contact.nameAr,
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
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Quick Date Selection
            Text(
              'اختيار سريع:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _QuickDateChip(
                  label: 'اليوم',
                  onTap: () => _setQuickDate('today'),
                ),
                _QuickDateChip(
                  label: 'آخر أسبوع',
                  onTap: () => _setQuickDate('week'),
                ),
                _QuickDateChip(
                  label: 'هذا الشهر',
                  onTap: () => _setQuickDate('month'),
                ),
                _QuickDateChip(
                  label: 'هذا الربع',
                  onTap: () => _setQuickDate('quarter'),
                ),
                _QuickDateChip(
                  label: 'هذا العام',
                  onTap: () => _setQuickDate('year'),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Custom Date Selection
            Text(
              'اختيار مخصص:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 16),

            // From Date
            InkWell(
              onTap: _selectFromDate,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today),
                    const SizedBox(width: 12),
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
                        const SizedBox(height: 4),
                        Text(
                          _fromDate != null
                              ? _displayDateFormat.format(_fromDate!)
                              : 'اختر التاريخ',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // To Date
            InkWell(
              onTap: _selectToDate,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today),
                    const SizedBox(width: 12),
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
                        const SizedBox(height: 4),
                        Text(
                          _toDate != null
                              ? _displayDateFormat.format(_toDate!)
                              : 'اختر التاريخ',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // Proceed Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    (_fromDate != null && _toDate != null) ? _proceed : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('عرض كشف الحساب'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(AppConstants.primaryColor).withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(AppConstants.primaryColor).withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(AppConstants.primaryColor),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
