// lib/screens/web/web_contact_selection_screen.dart
import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../models/contact.dart';
import '../../services/supabase_service.dart';
import '../../utils/helpers.dart';
import '../../utils/arabic_text_helper.dart';
import 'web_date_selection_screen.dart';
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
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
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
    if (screenWidth < 600) return 1;
    if (screenWidth < 900) return 2;
    if (screenWidth < 1200) return 3;
    return 4;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
<<<<<<< HEAD:lib/screens/web/contact_selection_screen.dart
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 1,
          iconTheme: const IconThemeData(color: Colors.black87),
          title: Row(
            children: [
              Icon(Icons.people, color: Colors.blue.shade600, size: 20),
              const SizedBox(width: 8),
              const Text(
                'اختيار العميل',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              if (!_isLoading)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_filteredContacts.length}',
                    style: TextStyle(
                      color: Colors.blue.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          actions: [
            Text(
              widget.user.username,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.black87),
=======
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
>>>>>>> b20a8dd912970bf0f1612c5dd009e1271fe9847f:lib/screens/web/web_contact_selection_screen.dart
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
<<<<<<< HEAD:lib/screens/web/contact_selection_screen.dart
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Row(
                      children: [
                        Icon(Icons.refresh, size: 16, color: Colors.black87),
                        SizedBox(width: 8),
                        Text('تحديث', style: TextStyle(color: Colors.black87)),
                      ],
                    ),
=======
                  child: Row(
                    children: [
                      Icon(Icons.refresh),
                      SizedBox(width: 8),
                      Text('تحديث'),
                    ],
>>>>>>> b20a8dd912970bf0f1612c5dd009e1271fe9847f:lib/screens/web/web_contact_selection_screen.dart
                  ),
                ),
                const PopupMenuItem(
                  value: 'logout',
<<<<<<< HEAD:lib/screens/web/contact_selection_screen.dart
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Row(
                      children: [
                        Icon(Icons.logout, size: 16, color: Colors.red),
                        SizedBox(width: 8),
                        Text('تسجيل الخروج',
                            style: TextStyle(color: Colors.red)),
                      ],
                    ),
=======
                  child: Row(
                    children: [
                      Icon(Icons.logout),
                      SizedBox(width: 8),
                      Text('تسجيل الخروج'),
                    ],
>>>>>>> b20a8dd912970bf0f1612c5dd009e1271fe9847f:lib/screens/web/web_contact_selection_screen.dart
                  ),
                ),
              ],
            ),
<<<<<<< HEAD:lib/screens/web/contact_selection_screen.dart
            const SizedBox(width: 8),
=======
>>>>>>> b20a8dd912970bf0f1612c5dd009e1271fe9847f:lib/screens/web/web_contact_selection_screen.dart
          ],
        ),
        body: Column(
          children: [
<<<<<<< HEAD:lib/screens/web/contact_selection_screen.dart
            _buildCompactSearchHeader(),
=======
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
                        SizedBox()
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
                        suffixIcon: const Icon(Icons.search),
                        prefixIcon: _searchQuery.isNotEmpty
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
>>>>>>> b20a8dd912970bf0f1612c5dd009e1271fe9847f:lib/screens/web/web_contact_selection_screen.dart
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredContacts.isEmpty
<<<<<<< HEAD:lib/screens/web/contact_selection_screen.dart
                      ? _buildEmptyState()
                      : _buildContactsList(),
=======
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
                          ? 'لا يوجد عملاء'
                          : 'لا توجد نتائج للبحث "$_searchQuery"',
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
>>>>>>> b20a8dd912970bf0f1612c5dd009e1271fe9847f:lib/screens/web/web_contact_selection_screen.dart
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactSearchHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: TextField(
          controller: _searchController,
          textDirection: TextDirection.rtl,
          decoration: InputDecoration(
            hintText: 'ابحث عن عميل بالاسم أو الرقم...',
            hintTextDirection: TextDirection.rtl,
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () => _searchController.clear(),
                  )
                : null,
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'لا توجد عملاء'
                  : 'لا توجد نتائج للبحث "$_searchQuery"',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadContacts,
              child: const Text('إعادة التحميل'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactsList() {
    return ListView.separated(
      padding: const EdgeInsets.all(8),
      itemCount: _filteredContacts.length,
      separatorBuilder: (context, index) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final contact = _filteredContacts[index];
        return _CompactContactCard(
          contact: contact,
          onTap: () => _selectContact(contact),
        );
      },
    );
  }
}

class _CompactContactCard extends StatefulWidget {
  final Contact contact;
  final VoidCallback onTap;

  const _CompactContactCard({
    required this.contact,
    required this.onTap,
  });

  @override
  State<_CompactContactCard> createState() => _CompactContactCardState();
}

class _CompactContactCardState extends State<_CompactContactCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        transform: Matrix4.identity()..scale(_isPressed ? 0.98 : 1.0),
        child: Container(
          height: 64,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    widget.contact.nameAr.isNotEmpty
                        ? widget.contact.nameAr[0]
                        : '؟',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        ArabicTextHelper.cleanText(widget.contact.nameAr),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            widget.contact.code,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (widget.contact.area != null) ...[
                            Text(
                              ' • ',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade400,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                widget.contact.area!,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
<<<<<<< HEAD:lib/screens/web/contact_selection_screen.dart
                  size: 14,
                  color: Colors.grey.shade400,
=======
                  size: widget.isDesktop ? 16 : 14,
                  color:
                  _isHovered ? Colors.blue.shade600 : Colors.grey.shade400,
>>>>>>> b20a8dd912970bf0f1612c5dd009e1271fe9847f:lib/screens/web/web_contact_selection_screen.dart
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}