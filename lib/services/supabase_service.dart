// lib/services/supabase_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart';
import '../models/contact.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: 'https://ykwnsmyvkwjctidhoqib.supabase.co',
      anonKey:
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inlrd25zbXl2a3dqY3RpZGhvcWliIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTExOTkzMzYsImV4cCI6MjA2Njc3NTMzNn0.W6WYYc-s24kX2H_-9bvWe1nG31lDlFCSVnDSqIKD5xk',
    );
  }

  // Auth methods
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String username,
    required String salesman,
    String? area,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'username': username,
          'salesman': salesman,
          'area': area,
        },
      );

      if (response.user != null) {
        // Wait a bit for the trigger to create the user profile
        await Future.delayed(const Duration(milliseconds: 500));

        // Try to update the user profile if it was created by trigger
        try {
          await _client.from('users').update({
            'username': username,
            'area': area,
            'salesman': salesman,
            'email': email,
            'user_type': 'user',
            'is_active': false,
          }).eq('id', response.user!.id);
        } catch (e) {
          // If update fails, try to insert
          try {
            await _client.from('users').insert({
              'id': response.user!.id,
              'username': username,
              'area': area,
              'salesman': salesman,
              'email': email,
              'user_type': 'user',
              'is_active': false,
            });
          } catch (insertError) {
            print('Failed to create user profile: $insertError');
          }
        }
      }

      return response;
    } catch (e) {
      print('SignUp error: $e');
      rethrow;
    }
  }

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('SignIn error: $e');
      rethrow;
    }
  }

  static Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      print('SignOut error: $e');
      rethrow;
    }
  }

  static Future<AppUser?> getCurrentUser() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return null;

      final response =
      await _client.from('users').select().eq('id', user.id).single();

      return AppUser.fromJson(response);
    } catch (e) {
      print('getCurrentUser error: $e');
      return null;
    }
  }

  static User? get currentAuthUser => _client.auth.currentUser;

  // Users management
  static Future<List<AppUser>> getUsers() async {
    try {
      final response = await _client
          .from('users')
          .select()
          .order('created_at', ascending: false);

      return response.map<AppUser>((json) => AppUser.fromJson(json)).toList();
    } catch (e) {
      print('getUsers error: $e');
      rethrow;
    }
  }

  static Future<void> createUser({
    required String username,
    required String email,
    required String password,
    required String salesman,
    String? area,
  }) async {
    try {
      // Use regular signup instead of admin.createUser
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'username': username,
          'salesman': salesman,
          'area': area,
        },
      );

      if (response.user != null) {
        // Wait for trigger to create user profile
        await Future.delayed(const Duration(milliseconds: 500));

        // Insert/update user profile
        await _client.from('users').upsert({
          'id': response.user!.id,
          'username': username,
          'area': area,
          'salesman': salesman,
          'email': email,
          'user_type': 'user',
          'is_active': false, // Admin needs to activate
        });

        // Sign out the newly created user so they don't auto-login
        await _client.auth.signOut();
      }
    } catch (e) {
      print('createUser error: $e');
      rethrow;
    }
  }

  static Future<void> updateUser({
    required String userId,
    String? username,
    String? area,
    String? salesman,
    String? email,
    bool? isActive,
  }) async {
    try {
      final Map<String, dynamic> updates = {};

      if (username != null) updates['username'] = username;
      if (area != null) updates['area'] = area;
      if (salesman != null) updates['salesman'] = salesman;
      if (email != null) updates['email'] = email;
      if (isActive != null) updates['is_active'] = isActive;

      if (updates.isNotEmpty) {
        await _client.from('users').update(updates).eq('id', userId);
      }
    } catch (e) {
      print('updateUser error: $e');
      rethrow;
    }
  }

  static Future<void> deleteUser(String userId) async {
    try {
      await _client.from('users').delete().eq('id', userId);
      await _client.auth.admin.deleteUser(userId);
    } catch (e) {
      print('deleteUser error: $e');
      rethrow;
    }
  }

  // Contacts management
  static Future<List<Contact>> getContacts({String? search}) async {
    try {
      var query = _client.from('contacts').select();

      if (search != null && search.isNotEmpty) {
        query = query.or('name_ar.ilike.%$search%,code.ilike.%$search%');
      }

      final response = await query.order('name_ar', ascending: true);
      return response.map<Contact>((json) => Contact.fromJson(json)).toList();
    } catch (e) {
      print('getContacts error: $e');
      rethrow;
    }
  }

  static Future<List<Contact>> getUserContacts({
    required String salesman,
    String? area,
    String? search,
  }) async {
    try {
      var query = _client.from('contacts').select().eq('salesman', salesman);

      if (area != null) {
        query = query.eq('area', area);
      }

      if (search != null && search.isNotEmpty) {
        query = query.or('name_ar.ilike.%$search%,code.ilike.%$search%');
      }

      final response = await query.order('name_ar', ascending: true);
      return response.map<Contact>((json) => Contact.fromJson(json)).toList();
    } catch (e) {
      print('getUserContacts error: $e');
      rethrow;
    }
  }

  static Future<void> syncContacts(List<Contact> contacts) async {
    try {
      // Delete all existing contacts
      await _client.from('contacts').delete().neq('id', 0);

      // Insert new contacts in batches
      const batchSize = 100;
      for (int i = 0; i < contacts.length; i += batchSize) {
        final batch = contacts.skip(i).take(batchSize).map((contact) {
          final json = contact.toJson();
          json.remove('id'); // Remove id to let database auto-generate

          // Ensure all required fields have values
          json['code'] = json['code'] ?? '';
          json['name_ar'] = json['name_ar'] ?? '';

          return json;
        }).toList();

        await _client.from('contacts').insert(batch);
      }
    } catch (e) {
      print('syncContacts error: $e');
      rethrow;
    }
  }

  static Future<Contact?> getContactByCode(String code) async {
    try {
      final response = await _client
          .from('contacts')
          .select()
          .eq('code', code)
          .maybeSingle();

      return response != null ? Contact.fromJson(response) : null;
    } catch (e) {
      print('getContactByCode error: $e');
      return null;
    }
  }
}
