// lib/screens/mobile/web_contact_selection_screen.dart
import 'package:flutter/material.dart';
import '../../models/contact.dart';
import '../../models/user.dart';
import '../../services/supabase_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
// MyAppBar is defined locally in this file
import 'web_date_selection_screen.dart';
import 'mobile_login_screen.dart';

class ContactSelectionScreen extends StatefulWidget {
  const ContactSelectionScreen({super.key});

  @override
  State<ContactSelectionScreen> createState() => _ContactSelectionScreenState();
}

class _ContactSelectionScreenState extends State<ContactSelectionScreen> {
  final _searchController = TextEditingController();
  List<Contact> _contacts = [];
  List<Contact> _filteredContacts = [];
  bool _isLoading = true;
  AppUser? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserAndContacts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserAndContacts() async {
    try {
      _currentUser = await SupabaseService.getCurrentUser();

      if (_currentUser == null) {
        _navigateToLogin();
        return;
      }

      await _loadContacts();
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(
          context,
          'فشل في تحميل بيانات المستخدم',
          isError: true,
        );
      }
    }
  }

  Future<void> _loadContacts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<Contact> contacts;

      if (_currentUser!.isAdmin) {
        contacts = await SupabaseService.getContacts();
      } else {
        contacts = await SupabaseService.getUserContacts(
          salesman: _currentUser!.salesman,
          area: _currentUser!.area,
        );
      }

      if (mounted) {
        setState(() {
          _contacts = contacts;
          _filteredContacts = contacts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        Helpers.showSnackBar(
          context,
          'فشل في تحميل قائمة العملاء',
          isError: true,
        );
      }
    }
  }

  void _filterContacts(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredContacts = _contacts;
      } else {
        _filteredContacts = _contacts.where((contact) {
          final nameMatch =
          contact.nameAr.toLowerCase().contains(query.toLowerCase());
          final codeMatch =
          contact.code.toLowerCase().contains(query.toLowerCase());
          return nameMatch || codeMatch;
        }).toList();
      }
    });
  }

  void _selectContact(Contact contact) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DateRangeScreen(contact: contact),
      ),
    );
  }

  Future<void> _logout() async {
    try {
      await SupabaseService.signOut();
      await Helpers.setLoggedIn(false);
      await Helpers.clearUserData();
      if (mounted) {
        _navigateToLogin();
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(
          context,
          'فشل في تسجيل الخروج',
          isError: true,
        );
      }
    }
  }

  void _navigateToLogin() {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _currentUser != null
          ? _MyHomeAppBar(
        currentUser: _currentUser!,
        onLogout: _logout,
        onRefresh: _loadContacts,
      )
          : AppBar(
        title: const Text('اختيار العميل'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              // Search Field
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  onChanged: _filterContacts,
                  decoration: const InputDecoration(
                    labelText: 'البحث عن عميل',
                    hintText: 'ادخل اسم العميل أو رقمه',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),

              // Contacts List
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredContacts.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _contacts.isEmpty
                            ? 'لا توجد عملاء'
                            : 'لا توجد نتائج للبحث',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (_contacts.isEmpty) ...[
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _loadContacts,
                          child: const Text('إعادة التحميل'),
                        ),
                      ],
                    ],
                  ),
                )
                    : ListView.builder(
                  itemCount: _filteredContacts.length,
                  itemBuilder: (context, index) {
                    final contact = _filteredContacts[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                          const Color(AppConstants.primaryColor),
                          child: Text(
                            contact.nameAr.isNotEmpty
                                ? contact.nameAr[0]
                                : 'ع',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          contact.nameAr,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('رقم العميل: ${contact.code}'),
                            if (contact.areaName?.isNotEmpty == true)
                              Text('المنطقة: ${contact.areaName}'),
                            if (contact.phone?.isNotEmpty == true)
                              Text('الهاتف: ${contact.phone}'),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () => _selectContact(contact),
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
}

class _MyHomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final AppUser currentUser;
  final VoidCallback onLogout;
  final VoidCallback onRefresh;

  const _MyHomeAppBar({
    required this.currentUser,
    required this.onLogout,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 8,
      backgroundColor: const Color(AppConstants.primaryColor),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "${getGreetingMessage()}${currentUser.username}",
            style: Theme.of(context).textTheme.titleSmall!.apply(
              color: const Color(0xFFFFFFFF),
            ),
          ),
          Text(
            'مندوب: ${currentUser.salesman}${currentUser.area != null ? ' - منطقة: ${currentUser.area}' : ''}',
            style: Theme.of(context).textTheme.titleMedium!.apply(
              color: const Color(0xFFFFFFFF),
            ),
          ),
        ],
      ),
      actions: [
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'logout') {
              onLogout();
            } else if (value == 'refresh') {
              onRefresh();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'refresh',
              child: Row(
                children: [
                  Icon(Icons.refresh),
                  SizedBox(width: 8),
                  Text('تحديث'),
                ],
              ),
            ),
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
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

String getGreetingMessage() {
  final hour = DateTime.now().hour;

  if (hour >= 5 && hour < 12) {
    return 'صباح الخير ☀️';
  } else if (hour >= 12 && hour < 17) {
    return 'مساء الخير 🌤️';
  } else {
    return 'مساء الخير 🌙';
  }
}