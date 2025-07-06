// lib/screens/web/contact_selection_screen.dart
import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../models/contact.dart';
import '../../services/supabase_service.dart';
import '../../utils/helpers.dart';
import '../../utils/arabic_text_helper.dart';
import 'date_selection_screen.dart';
import 'web_login_screen.dart';

class ContactSelectionScreen extends StatefulWidget {
  final AppUser user;

  const ContactSelectionScreen({
    super.key,
    required this.user,
  });

  @override
  State<ContactSelectionScreen> createState() => _ContactSelectionScreenState();
}

class _ContactSelectionScreenState extends State<ContactSelectionScreen> {
  final _searchController = TextEditingController();
  List<Contact> _allContacts = [];
  List<Contact> _filteredContacts = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadContacts();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _filterContacts();
    });
  }

  void _filterContacts() {
    if (_searchQuery.isEmpty) {
      _filteredContacts = _allContacts;
    } else {
      _filteredContacts = _allContacts.where((contact) {
        final nameMatch =
            contact.nameAr.toLowerCase().contains(_searchQuery.toLowerCase());
        final codeMatch =
            contact.code.toLowerCase().contains(_searchQuery.toLowerCase());
        return nameMatch || codeMatch;
      }).toList();
    }
  }

  Future<void> _loadContacts() async {
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
        _allContacts = contacts;
        _filteredContacts = contacts;
        _isLoading = false;
      });

      if (contacts.isNotEmpty) {
        Helpers.showSnackBar(
          context,
          'تم تحميل ${contacts.length} عميل بنجاح',
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      Helpers.showSnackBar(
        context,
        'فشل في تحميل قائمة العملاء: ${e.toString()}',
        isError: true,
      );
    }
  }

  void _selectContact(Contact contact) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DateSelectionScreen(
          user: widget.user,
          contact: contact,
        ),
      ),
    );
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

  int _getCrossAxisCount(double screenWidth) {
    if (screenWidth < 600) return 1; // Mobile
    if (screenWidth < 900) return 2; // Tablet
    if (screenWidth < 1200) return 3; // Small desktop
    return 4; // Large desktop
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('اختيار العميل'),
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
              } else if (value == 'refresh') {
                _loadContacts();
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
      ),
      body: Column(
        children: [
          // Search Header
          Container(
            padding: EdgeInsets.all(isDesktop ? 24 : 16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.people, color: Colors.blue.shade600),
                    const SizedBox(width: 8),
                    Text(
                      'العملاء',
                      style: TextStyle(
                        fontSize: isDesktop ? 24 : 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    const Spacer(),
                    if (_isLoading)
                      const CircularProgressIndicator()
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'العدد: ${_filteredContacts.length}',
                          style: TextStyle(
                            color: Colors.blue.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                // Search Bar
                Container(
                  constraints: BoxConstraints(
                    maxWidth: isDesktop ? 600 : double.infinity,
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'ابحث عن عميل بالاسم أو الرقم...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredContacts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'لا توجد عملاء'
                                  : 'لا توجد نتائج للبحث "${_searchQuery}"',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : Padding(
                        padding: EdgeInsets.all(isDesktop ? 24 : 16),
                        child: GridView.builder(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: _getCrossAxisCount(screenWidth),
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: isDesktop ? 3.5 : 4,
                          ),
                          itemCount: _filteredContacts.length,
                          itemBuilder: (context, index) {
                            final contact = _filteredContacts[index];
                            return _ContactCard(
                              contact: contact,
                              onTap: () => _selectContact(contact),
                              isDesktop: isDesktop,
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatefulWidget {
  final Contact contact;
  final VoidCallback onTap;
  final bool isDesktop;

  const _ContactCard({
    required this.contact,
    required this.onTap,
    required this.isDesktop,
  });

  @override
  State<_ContactCard> createState() => _ContactCardState();
}

class _ContactCardState extends State<_ContactCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.all(widget.isDesktop ? 16 : 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isHovered ? Colors.blue.shade300 : Colors.grey.shade200,
                width: _isHovered ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(_isHovered ? 0.1 : 0.05),
                  blurRadius: _isHovered ? 8 : 4,
                  spreadRadius: _isHovered ? 2 : 0,
                ),
              ],
            ),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: widget.isDesktop ? 24 : 20,
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    widget.contact.nameAr.isNotEmpty
                        ? widget.contact.nameAr[0]
                        : '؟',
                    style: TextStyle(
                      fontSize: widget.isDesktop ? 16 : 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
                SizedBox(width: widget.isDesktop ? 16 : 12),

                // Contact Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        ArabicTextHelper.cleanText(widget.contact.nameAr),
                        style: TextStyle(
                          fontSize: widget.isDesktop ? 16 : 14,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'رقم العميل: ${widget.contact.code}',
                        style: TextStyle(
                          fontSize: widget.isDesktop ? 12 : 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (widget.contact.area != null && widget.isDesktop) ...[
                        const SizedBox(height: 2),
                        Text(
                          'المنطقة: ${widget.contact.area}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Arrow
                Icon(
                  Icons.arrow_forward_ios,
                  size: widget.isDesktop ? 16 : 14,
                  color:
                      _isHovered ? Colors.blue.shade600 : Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
