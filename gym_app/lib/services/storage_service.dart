import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  static final _client = Supabase.instance.client;
  
  static const String avatarsBucket = 'avatars';
  static const String documentsBucket = 'documents';
  
  // Upload avatar y retorna URL pública
  static Future<String> uploadAvatar(File imageFile, String userId) async {
    try {
      final fileName = '$userId.jpg';
      
      // Eliminar avatar anterior
      try {
        await _client.storage.from(avatarsBucket).remove([fileName]);
      } catch (e) {
        print('No había avatar anterior');
      }
      
      // Subir nuevo avatar
      await _client.storage.from(avatarsBucket).upload(fileName, imageFile);
      
      // Retorna URL pública
      return _client.storage.from(avatarsBucket).getPublicUrl(fileName);
    } catch (e) {
      throw Exception('Error al subir avatar: $e');
    }
  }
  
  // Obtiene URL pública del avatar
  static String getAvatarUrl(String userId) {
    final fileName = '$userId.jpg';
    return _client.storage.from(avatarsBucket).getPublicUrl(fileName);
  }
  
  // Elimina avatar del usuario
  static Future<void> deleteAvatar(String userId) async {
    try {
      final fileName = '$userId.jpg';
      await _client.storage.from(avatarsBucket).remove([fileName]);
    } catch (e) {
      print('Error al eliminar avatar: $e');
    }
  }
  
  // Sube documento a Storage
  static Future<String> uploadDocument(
    File file,
    String userId,
    String documentType,
  ) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final fileName = '${userId}_${documentType}_$timestamp';
      
      await _client.storage.from(documentsBucket).upload(fileName, file);
      return fileName;
    } catch (e) {
      throw Exception('Error al subir documento: $e');
    }
  }
  
  // Obtiene URL pública del documento
  static String getDocumentUrl(String documentId) {
    return _client.storage.from(documentsBucket).getPublicUrl(documentId);
  }
  
  // Elimina documento
  static Future<void> deleteDocument(String documentId) async {
    try {
      await _client.storage.from(documentsBucket).remove([documentId]);
    } catch (e) {
      print('Error al eliminar documento: $e');
    }
  }
  
  // Lista avatares del usuario
  static Future<List<String>> listUserAvatars(String userId) async {
    try {
      final files = await _client.storage.from(avatarsBucket).list(path: userId);
      return files.map((f) => f.name).toList();
    } catch (e) {
      return [];
    }
  }
  
  // Lista documentos del usuario
  static Future<List<String>> listUserDocuments(String userId) async {
    try {
      final files = await _client.storage.from(documentsBucket).list();
      return files
          .where((f) => f.name.startsWith(userId))
          .map((f) => f.name)
          .toList();
    } catch (e) {
      return [];
    }
  }
  
  // Obtiene tamaño de almacenamiento
  static Future<int> getBucketSize(String bucket) async {
    try {
      final files = await _client.storage.from(bucket).list();
      return files.length; // Retorna cantidad de archivos
    } catch (e) {
      return 0;
    }
  }
}
