// lib/components/book_upload.dart
import 'dart:io' show File;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:Marketing_Fruit/screens/dashboard/book_creation_controller.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
// import 'package:Marketing_Fruit/components/book_creation_controller.dart';

class BookUploadSection extends StatefulWidget {
  const BookUploadSection({super.key});

  @override
  State<BookUploadSection> createState() => _BookUploadSectionState();
}

class _BookUploadSectionState extends State<BookUploadSection> {
  bool _uploadingCover = false;
  bool _uploadingPdf = false;
  String? _coverName;
  String? _pdfName;

  Future<void> _pickAndUploadCover(BuildContext context) async {
    final ctrl = context.read<BookCreationController>();
    try {
      setState(() => _uploadingCover = true);
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true, // needed for web
      );
      if (result == null) return;

      final file = result.files.single;
      _coverName = file.name;

      if (kIsWeb) {
        final bytes = file.bytes;
        if (bytes == null) throw Exception('No bytes found for web upload.');
        final ext = '.${(file.extension ?? 'jpg')}';
        await ctrl.uploadCover(bytes: bytes, fileExt: ext);
      } else {
        if (file.path == null) throw Exception('No path for selected file.');
        await ctrl.uploadCover(file: File(file.path!));
      }
      if (mounted) setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cover upload failed: $e')));
    } finally {
      if (mounted) setState(() => _uploadingCover = false);
    }
  }

  Future<void> _pickAndUploadPdf(BuildContext context) async {
    final ctrl = context.read<BookCreationController>();
    try {
      setState(() => _uploadingPdf = true);
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
        withData: true, // needed for web
      );
      if (result == null) return;

      final file = result.files.single;
      _pdfName = file.name;

      if (kIsWeb) {
        final bytes = file.bytes;
        if (bytes == null) throw Exception('No bytes found for web upload.');
        await ctrl.uploadPdf(bytes: bytes);
      } else {
        if (file.path == null) throw Exception('No path for selected file.');
        await ctrl.uploadPdf(file: File(file.path!));
      }
      if (mounted) setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF upload failed: $e')));
    } finally {
      if (mounted) setState(() => _uploadingPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<BookCreationController>();
    final screenWidth = MediaQuery.of(context).size.width;
    final containerWidth = screenWidth * 0.90;

    return SingleChildScrollView(
      child: Container(
        width: containerWidth,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Book Upload Section', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),

            /// Upload Cover Image
            const Text('Upload Cover Image (jpg, png format)', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: _uploadingCover
                    ? const CircularProgressIndicator()
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton(
                            onPressed: () => _pickAndUploadCover(context),
                            child: const Text('Select & Upload Cover'),
                          ),
                          const SizedBox(height: 8),
                          if (_coverName != null) Text('Selected: $_coverName', style: const TextStyle(color: Colors.grey)),
                          if (ctrl.coverUrl.isNotEmpty) Text('Uploaded ✓', style: const TextStyle(color: Colors.green)),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 24),

            /// Upload PDF
            const Text('Upload PDF', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: _uploadingPdf
                    ? const CircularProgressIndicator()
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton(
                            onPressed: () => _pickAndUploadPdf(context),
                            child: const Text('Select & Upload PDF'),
                          ),
                          const SizedBox(height: 8),
                          if (_pdfName != null) Text('Selected: $_pdfName', style: const TextStyle(color: Colors.grey)),
                          if (ctrl.pdfUrl.isNotEmpty) Text('Uploaded ✓', style: const TextStyle(color: Colors.green)),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 16),
            if (ctrl.coverUrl.isNotEmpty)
              Text('Cover URL: ${ctrl.coverUrl}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            if (ctrl.pdfUrl.isNotEmpty)
              Text('PDF URL: ${ctrl.pdfUrl}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
