// lib/screens/web/sync_data_screen.dart
import 'package:flutter/material.dart';
import '../../models/contact.dart';
import '../../services/api_service.dart';
import '../../services/supabase_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

class SyncDataScreen extends StatefulWidget {
  const SyncDataScreen({super.key});

  @override
  State<SyncDataScreen> createState() => _SyncDataScreenState();
}

class _SyncDataScreenState extends State<SyncDataScreen> {
  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  int _totalContacts = 0;
  String _syncStatus = '';

  @override
  void initState() {
    super.initState();
    _loadContactsCount();
  }

  Future<void> _loadContactsCount() async {
    try {
      final contacts = await SupabaseService.getContacts();
      setState(() {
        _totalContacts = contacts.length;
      });
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _syncContacts() async {
    setState(() {
      _isSyncing = true;
      _syncStatus = 'جاري تحميل البيانات من Bisan API...';
    });

    try {
      // Step 1: Fetch contacts from Bisan API
      setState(() {
        _syncStatus = 'جاري تحميل البيانات من Bisan API...';
      });

      final bisanContacts = await ApiService.getContacts();

      if (bisanContacts.isEmpty) {
        setState(() {
          _syncStatus = 'لم يتم العثور على بيانات في Bisan API';
          _isSyncing = false;
        });
        Helpers.showSnackBar(
          context,
          'لم يتم العثور على بيانات في Bisan API',
          isError: true,
        );
        return;
      }

      // Step 2: Sync to Supabase
      setState(() {
        _syncStatus =
            'جاري حفظ ${bisanContacts.length} جهة اتصال في قاعدة البيانات...';
      });

      await SupabaseService.syncContacts(bisanContacts);

      setState(() {
        _lastSyncTime = DateTime.now();
        _totalContacts = bisanContacts.length;
        _syncStatus =
            'تمت المزامنة بنجاح! تم حفظ ${bisanContacts.length} جهة اتصال.';
        _isSyncing = false;
      });

      Helpers.showSnackBar(
        context,
        'تمت مزامنة البيانات بنجاح! تم حفظ ${bisanContacts.length} جهة اتصال.',
      );
    } catch (e) {
      setState(() {
        _syncStatus = 'فشل في المزامنة: ${e.toString()}';
        _isSyncing = false;
      });

      Helpers.showSnackBar(
        context,
        'فشل في مزامنة البيانات: ${e.toString()}',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'مزامنة البيانات',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 8),

            Text(
              'مزامنة بيانات العملاء من Bisan API',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),

            const SizedBox(height: 32),

            // Statistics Cards
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.people,
                                color: const Color(AppConstants.primaryColor),
                                size: 32,
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'إجمالي العملاء',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    _totalContacts.toString(),
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                color: Colors.green[600],
                                size: 32,
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'آخر مزامنة',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    _lastSyncTime != null
                                        ? Helpers.formatDisplayDate(
                                            _lastSyncTime!)
                                        : 'لم تتم المزامنة بعد',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Sync Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.sync,
                          color: const Color(AppConstants.primaryColor),
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'مزامنة البيانات',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'اضغط على الزر أدناه لمزامنة بيانات العملاء من Bisan API. سيتم حذف جميع البيانات الحالية واستبدالها بالبيانات الجديدة.',
                      style: TextStyle(
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_isSyncing) ...[
                      Row(
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _syncStatus,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          const Color(AppConstants.primaryColor),
                        ),
                      ),
                    ] else ...[
                      if (_syncStatus.isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _syncStatus.contains('فشل')
                                ? Colors.red[50]
                                : Colors.green[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _syncStatus.contains('فشل')
                                  ? Colors.red[200]!
                                  : Colors.green[200]!,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _syncStatus.contains('فشل')
                                    ? Icons.error
                                    : Icons.check_circle,
                                color: _syncStatus.contains('فشل')
                                    ? Colors.red[600]
                                    : Colors.green[600],
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _syncStatus,
                                  style: TextStyle(
                                    color: _syncStatus.contains('فشل')
                                        ? Colors.red[700]
                                        : Colors.green[700],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      ElevatedButton.icon(
                        onPressed: _syncContacts,
                        icon: const Icon(Icons.sync),
                        label: const Text('بدء المزامنة'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Warning Card
            Card(
              color: Colors.orange[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning,
                      color: Colors.orange[600],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'تحذير',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[700],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ستؤدي عملية المزامنة إلى حذف جميع بيانات العملاء الحالية واستبدالها بالبيانات الجديدة من Bisan API.',
                            style: TextStyle(
                              color: Colors.orange[700],
                            ),
                          ),
                        ],
                      ),
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
