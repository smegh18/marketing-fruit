// lib/components/book_creation_controller.dart
import 'dart:io' show File;
import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';

class BookCreationController extends ChangeNotifier {
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  late final String draftId;
  late final DatabaseReference _ref;

  // Fields
  String bookName = '';
  String bookDescription = '';
  String authorName = '';
  String authorDescription = '';
  String tags = '';
  String amazonLink = '';
  String coverUrl = '';
  String pdfUrl = '';
  String status = 'draft'; // 'draft' | 'published'

  BookCreationController() {
    draftId = _db.ref('books').push().key!;
    _ref = _db.ref('books/$draftId');
    // Initialize the draft node (so you can see it immediately in DB)
    _saveDraft(initial: true);
  }

  Future<void> _saveDraft({bool initial = false}) async {
    final now = DateTime.now().toIso8601String();
    await _ref.update({
      'bookName': bookName,
      'bookDescription': bookDescription,
      'authorName': authorName,
      'authorDescription': authorDescription,
      'tags': tags,
      'amazonLink': amazonLink,
      'coverUrl': coverUrl,
      'pdfUrl': pdfUrl,
      'status': status,
      if (initial) 'createdAt': now,
      'updatedAt': now,
    });
  }

  // Setters that persist immediately
  void setBookName(String v) { bookName = v; _saveDraft(); notifyListeners(); }
  void setBookDescription(String v) { bookDescription = v; _saveDraft(); notifyListeners(); }
  void setAuthorName(String v) { authorName = v; _saveDraft(); notifyListeners(); }
  void setAuthorDescription(String v) { authorDescription = v; _saveDraft(); notifyListeners(); }
  void setTags(String v) { tags = v; _saveDraft(); notifyListeners(); }
  void setAmazonLink(String v) { amazonLink = v; _saveDraft(); notifyListeners(); }

  // Upload cover image (web: bytes | mobile/desktop: File)
  Future<void> uploadCover({Uint8List? bytes, File? file, String? fileExt}) async {
    if (bytes == null && file == null) throw Exception('No file provided for cover upload.');
    final ext = (fileExt ?? (kIsWeb ? '.jpg' : (file?.path.split('.').last ?? 'jpg'))).toString();
    final ref = _storage.ref().child('books/$draftId/cover.${ext.replaceAll(".", "")}');

    UploadTask task;
    if (kIsWeb) {
      if (bytes == null) throw Exception('Web upload requires bytes.');
      task = ref.putData(bytes, SettableMetadata(contentType: 'image/${ext.replaceAll(".", "")}'));
    } else {
      task = ref.putFile(file!);
    }
    final snap = await task.whenComplete(() {});
    coverUrl = await snap.ref.getDownloadURL();
    await _saveDraft();
    notifyListeners();
  }

  // Upload PDF
  Future<void> uploadPdf({Uint8List? bytes, File? file}) async {
    final ref = _storage.ref().child('books/$draftId/book.pdf');

    UploadTask task;
    if (kIsWeb) {
      if (bytes == null) throw Exception('Web upload requires bytes.');
      task = ref.putData(bytes, SettableMetadata(contentType: 'application/pdf'));
    } else {
      task = ref.putFile(file!);
    }
    final snap = await task.whenComplete(() {});
    pdfUrl = await snap.ref.getDownloadURL();
    await _saveDraft();
    notifyListeners();
  }

  Future<void> publish() async {
    status = 'published';
    await _ref.update({
      'status': status,
      'publishedAt': DateTime.now().toIso8601String(),
    });
    notifyListeners();
  }
}
