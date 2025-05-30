  import 'dart:io';

  import 'package:flutter/material.dart';
  import 'package:supabase_flutter/supabase_flutter.dart';

  class UserService {
    final supabase = Supabase.instance.client;
    
    // Cache to store user details
    final Map<String, Map<String, dynamic>> _userCache = {};

    /// Inserts or updates user profile fields in the 'userdata' table.
    Future<void> saveDetails(String uid, Map<String, dynamic> data) async {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('No signed‑in user');

      await supabase.from('userdata').upsert({
        'id': uid,
        'email': user.email,
        ...data,
      });
      
      // Update cache when user details are saved
      if (_userCache.containsKey(uid)) {
        _userCache[uid]?.addAll(data);
      }
    }

    /// Updates only the banner_choice column for an existing user row.
    Future<void> updateBannerChoice(String uid, String? choice) async {
      // Supabase column banner_choice is NOT NULL; use 'none' for no banner
      final value = choice ?? 'none';
      await supabase
        .from('userdata')
        .update({'banner_choice': value})
        .eq('id', uid);
        
      // Update cache when banner choice is updated
      if (_userCache.containsKey(uid)) {
        _userCache[uid]?['banner_choice'] = value;
      }
    }

    /// Streams the current user's row from 'userdata'.
    Stream<List<Map<String, dynamic>>> detailsStream(String uid) {
      return supabase
          .from('userdata')
          .stream(primaryKey: ['id'])
          .eq('id', uid)
          .map((data) {
            // Update cache when new data comes from the stream
            if (data.isNotEmpty) {
              _userCache[uid] = Map<String, dynamic>.from(data.first);
            }
            return data;
          });
    }
    
    /// Gets user details from cache or fetches if not available
    Future<Map<String, dynamic>?> getUserDetails(String uid) async {
      // Return from cache if available
      if (_userCache.containsKey(uid)) {
        return _userCache[uid];
      }
      
      // Otherwise fetch from database
      try {
        final response = await supabase
            .from('userdata')
            .select()
            .eq('id', uid)
            .single();
        
        // Store in cache
        _userCache[uid] = Map<String, dynamic>.from(response);
        return _userCache[uid];
      } catch (e) {
        debugPrint('Error fetching user details: $e');
        return null;
      }
    }

    /// Clears the user cache
    void clearCache() {
      _userCache.clear();
    }

    /// Uploads avatar to storage and returns public URL.
    Future<String?> uploadAvatar(String uid, File file) async {
      final ext = file.path.split('.').last.toLowerCase();
      final bytes = await file.readAsBytes();
      final imagePath = '$uid/profile.$ext';

      try {
        await supabase.storage.from('avatar').uploadBinary(
          imagePath, bytes,
          fileOptions: FileOptions(upsert: true, contentType: 'image/$ext'),
        );
        var url = supabase.storage.from('avatar').getPublicUrl(imagePath);
        
        // Update avatar URL in cache if user exists in cache
        if (_userCache.containsKey(uid)) {
          _userCache[uid]?['avatar_url'] = url;
        }
        
        return Uri.parse(url)
          .replace(queryParameters: {'t': DateTime.now().millisecondsSinceEpoch.toString()})
          .toString();
      } on StorageException catch (e) {
        debugPrint('Storage error [${e.statusCode}]: ${e.message}');
        return null;
      }
    }
  }