import 'dart:typed_data';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ImageDB {
  static Database? _db;

  static Future<void> init() async {
    if (kIsWeb || _db != null) return;

    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'images.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE images (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            image BLOB
          )
        ''');
      },
    );
  }

  static Future<int> insertImage(Uint8List imageBytes) async {
    // if (kIsWeb) {
    //   // Optionally: throw or return null-equivalent
    //   return -1;
    // }
    await init();
    return await _db!.insert('images', {'image': imageBytes});
  }

  static Future<Uint8List?> getImage(int id) async {
    if (kIsWeb) {
      // On web, we can't use SQLite, so return null
      return null;
    }

    await init();
    final result = await _db!.query(
      'images',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return result.first['image'] as Uint8List;
    }

    return null;
  }

  // Helper method to get image bytes from either SQLite (mobile) or Firestore (web)
  static Future<Uint8List?> getImageFromData(
      dynamic imageId, dynamic imageBytes) async {
    if (kIsWeb) {
      // On web, use imageBytes from Firestore
      if (imageBytes != null) {
        Uint8List? finalImageBytes;
        if (imageBytes is Uint8List) {
          finalImageBytes = imageBytes;
        } else if (imageBytes is List) {
          finalImageBytes = Uint8List.fromList(imageBytes.cast<int>());
        }

        if (finalImageBytes != null) {
          return finalImageBytes;
        }
      }
      return null;
    } else {
      // On mobile, use imageId to get from SQLite
      if (imageId != null && imageId is int) {
        return await getImage(imageId);
      }
      return null;
    }
  }
}
