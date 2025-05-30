  import 'dart:io';
  import 'package:supabase_flutter/supabase_flutter.dart';

  class PostService {
    final _supabase = Supabase.instance.client;

    Stream<List<Map<String, dynamic>>> streamPosts() {
      return _supabase
          .from('userpost')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false);
    }

    Future<void> likePost(String postId, int currentLikes) async {
      await _supabase
          .from('userpost')
          .update({'likes': currentLikes + 1})
          .eq('id', postId);
    }

    Future<void> addPost({
      required String userId,
      required String title,
      String? subtitle,
      String? content,
      required List<String>tags,
      required List<File> images,
       required String orientation,
    }) async {
      // upload each image
      final urls = <String>[];
      for (var i = 0; i < images.length; i++) {
        final ext = images[i].path.split('.').last;
        final path = '$userId/${DateTime.now().millisecondsSinceEpoch}_$i.$ext';
        final bytes = await images[i].readAsBytes();
        await _supabase.storage.from('picture').uploadBinary(
              path,
              bytes,
              fileOptions: FileOptions(upsert: true, contentType: 'image/$ext'),
            );
        final publicUrl = _supabase.storage.from('picture').getPublicUrl(path);
        urls.add(publicUrl);
      }

    Future<void> deletePost(String postId) async {
    await _supabase
      .from('userpost')
      .delete()
      .eq('id', postId);
  }

      await _supabase.from('userpost').insert({
        'user_id': userId,
        'title': title,
        'subtitle': subtitle,
        'content': content,
        'image_urls': urls,
        'orientation': orientation,
        'tags': tags,    
      });
    }

    Future<List<Map<String, dynamic>>> fetchComments(String postId) {
      return _supabase
          .from('comments')
          .select()
          .eq('post_id', postId)
          .order('created_at', ascending: true)
          .then((data) => List<Map<String, dynamic>>.from(data));
    }

    Future<void> addComment({
      required String postId,
      required String userId,
      required String comment,
    }) async {
      await _supabase.from('comments').insert({
        'post_id': postId,
        'user_id': userId,
        'comment': comment,
      });
    }

     Future<void> deletePost(String postId) async {
    await _supabase
      .from('userpost')
      .delete()
      .eq('id', postId);
  }

Future<void> updatePost({
    required String postId,
    required String title,
    String? subtitle,
    String? content,
    required List<String>tags,
    required String orientation,
    List<String>? imageUrls,
  }) async {
    final data = {
      'title': title,
      'subtitle': subtitle,
      'content': content,
      'orientation': orientation,
      'tags': tags, 
      if (imageUrls != null) 'image_urls': imageUrls,
    };
    await _supabase.from('userpost').update(data).eq('id', postId);
  }

        Future<String> uploadImage({
    required File image,
    required String userId,
    required int index,
  }) async {
    final ext = image.path.split('.').last;
    final path =
        '$userId/${DateTime.now().millisecondsSinceEpoch}_edit_$index.$ext';
    final bytes = await image.readAsBytes();

    // upload without specifying FileOptions
    await _supabase.storage.from('picture').uploadBinary(path, bytes);

    return _supabase.storage.from('picture').getPublicUrl(path);
  }

    Stream<List<Map<String, dynamic>>> streamComments(String postId) {
    return _supabase
      .from('comments')
      .stream(primaryKey: ['id'])
      .eq('post_id', postId)
      .order('created_at', ascending: true);
  }

  }
