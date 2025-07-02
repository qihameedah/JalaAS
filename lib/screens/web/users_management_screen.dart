// lib/screens/web/users_management_screen.dart
import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/supabase_service.dart';
import '../../utils/helpers.dart';

class UsersManagementScreen extends StatefulWidget {
  const UsersManagementScreen({super.key});

  @override
  State<UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends State<UsersManagementScreen> {
  List<AppUser> _users = [];
  bool _isLoading = true;
  final bool _isCreatingUser = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final users = await SupabaseService.getUsers();
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      Helpers.showSnackBar(
        context,
        'فشل في تحميل قائمة المستخدمين',
        isError: true,
      );
    }
  }

  Future<void> _showCreateUserDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const _CreateUserDialog(),
    );

    if (result == true) {
      _loadUsers();
    }
  }

  Future<void> _showEditUserDialog(AppUser user) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _EditUserDialog(user: user),
    );

    if (result == true) {
      _loadUsers();
    }
  }

  Future<void> _deleteUser(AppUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المستخدم'),
        content: Text('هل تريد حذف المستخدم "${user.username}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await SupabaseService.deleteUser(user.id);
        Helpers.showSnackBar(context, 'تم حذف المستخدم بنجاح');
        _loadUsers();
      } catch (e) {
        Helpers.showSnackBar(
          context,
          'فشل في حذف المستخدم',
          isError: true,
        );
      }
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
            Row(
              children: [
                Text(
                  'إدارة المستخدمين',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _showCreateUserDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة مستخدم'),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _loadUsers,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'تحديث',
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _users.isEmpty
                      ? const Center(
                          child: Text(
                            'لا يوجد مستخدمون',
                            style: TextStyle(fontSize: 18),
                          ),
                        )
                      : Card(
                          child: SingleChildScrollView(
                            child: DataTable(
                              columnSpacing: 20,
                              columns: const [
                                DataColumn(label: Text('اسم المستخدم')),
                                DataColumn(label: Text('البريد الإلكتروني')),
                                DataColumn(label: Text('المندوب')),
                                DataColumn(label: Text('المنطقة')),
                                DataColumn(label: Text('نوع المستخدم')),
                                DataColumn(label: Text('الحالة')),
                                DataColumn(label: Text('الإجراءات')),
                              ],
                              rows: _users.map((user) {
                                return DataRow(
                                  cells: [
                                    DataCell(Text(user.username)),
                                    DataCell(Text(user.email)),
                                    DataCell(Text(user.salesman)),
                                    DataCell(Text(user.area ?? '-')),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: user.isAdmin
                                              ? Colors.red[100]
                                              : Colors.blue[100],
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          user.isAdmin ? 'مدير' : 'مستخدم',
                                          style: TextStyle(
                                            color: user.isAdmin
                                                ? Colors.red[700]
                                                : Colors.blue[700],
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: user.isActive
                                              ? Colors.green[100]
                                              : Colors.grey[100],
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          user.isActive ? 'مفعل' : 'غير مفعل',
                                          style: TextStyle(
                                            color: user.isActive
                                                ? Colors.green[700]
                                                : Colors.grey[700],
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            onPressed: () =>
                                                _showEditUserDialog(user),
                                            icon: const Icon(Icons.edit),
                                            tooltip: 'تعديل',
                                          ),
                                          if (!user.isAdmin)
                                            IconButton(
                                              onPressed: () =>
                                                  _deleteUser(user),
                                              icon: const Icon(Icons.delete),
                                              color: Colors.red,
                                              tooltip: 'حذف',
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
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

class _CreateUserDialog extends StatefulWidget {
  const _CreateUserDialog();

  @override
  State<_CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends State<_CreateUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _salesmanController = TextEditingController();
  final _areaController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _salesmanController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await SupabaseService.createUser(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        salesman: _salesmanController.text.trim(),
        area: _areaController.text.trim().isEmpty
            ? null
            : _areaController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        Helpers.showSnackBar(context, 'تم إنشاء المستخدم بنجاح');
      }
    } catch (e) {
      Helpers.showSnackBar(
        context,
        'فشل في إنشاء المستخدم',
        isError: true,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('إضافة مستخدم جديد'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'اسم المستخدم',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال اسم المستخدم';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'البريد الإلكتروني',
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال البريد الإلكتروني';
                  }
                  if (!Helpers.isValidEmail(value)) {
                    return 'البريد الإلكتروني غير صحيح';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'كلمة المرور',
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال كلمة المرور';
                  }
                  if (value.length < 6) {
                    return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _salesmanController,
                decoration: const InputDecoration(
                  labelText: 'المندوب',
                  prefixIcon: Icon(Icons.badge),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال رقم المندوب';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _areaController,
                decoration: const InputDecoration(
                  labelText: 'المنطقة (اختياري)',
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createUser,
          child: _isLoading
              ? const CircularProgressIndicator()
              : const Text('إنشاء'),
        ),
      ],
    );
  }
}

class _EditUserDialog extends StatefulWidget {
  final AppUser user;

  const _EditUserDialog({required this.user});

  @override
  State<_EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<_EditUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _salesmanController = TextEditingController();
  final _areaController = TextEditingController();
  bool _isActive = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _usernameController.text = widget.user.username;
    _emailController.text = widget.user.email;
    _salesmanController.text = widget.user.salesman;
    _areaController.text = widget.user.area ?? '';
    _isActive = widget.user.isActive;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _salesmanController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  Future<void> _updateUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await SupabaseService.updateUser(
        userId: widget.user.id,
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        salesman: _salesmanController.text.trim(),
        area: _areaController.text.trim().isEmpty
            ? null
            : _areaController.text.trim(),
        isActive: _isActive,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        Helpers.showSnackBar(context, 'تم تحديث المستخدم بنجاح');
      }
    } catch (e) {
      Helpers.showSnackBar(
        context,
        'فشل في تحديث المستخدم',
        isError: true,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('تعديل المستخدم'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'اسم المستخدم',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال اسم المستخدم';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'البريد الإلكتروني',
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال البريد الإلكتروني';
                  }
                  if (!Helpers.isValidEmail(value)) {
                    return 'البريد الإلكتروني غير صحيح';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _salesmanController,
                decoration: const InputDecoration(
                  labelText: 'المندوب',
                  prefixIcon: Icon(Icons.badge),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال رقم المندوب';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _areaController,
                decoration: const InputDecoration(
                  labelText: 'المنطقة (اختياري)',
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: _isActive,
                    onChanged: (value) {
                      setState(() {
                        _isActive = value ?? false;
                      });
                    },
                  ),
                  const Text('المستخدم مفعل'),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _updateUser,
          child: _isLoading
              ? const CircularProgressIndicator()
              : const Text('تحديث'),
        ),
      ],
    );
  }
}
