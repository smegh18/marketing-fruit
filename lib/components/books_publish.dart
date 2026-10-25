// lib/components/books_publish.dart
import 'package:flutter/material.dart';
import 'package:Marketing_Fruit/screens/dashboard/book_creation_controller.dart';
import 'package:provider/provider.dart';
// import 'package:Marketing_Fruit/components/book_creation_controller.dart';

class BooksOverviewSection extends StatelessWidget {
  const BooksOverviewSection({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<BookCreationController>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              spreadRadius: 2,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Books Overview', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),

            // Summary (bound to controller)
            _readonlyField('Book Name', ctrl.bookName),
            const SizedBox(height: 12),
            _readonlyField('Book Description', ctrl.bookDescription, maxLines: 3),
            const SizedBox(height: 12),
            _readonlyField('Author Name', ctrl.authorName),
            const SizedBox(height: 12),
            _readonlyField('Author Description', ctrl.authorDescription, maxLines: 2),
            const SizedBox(height: 12),
            _readonlyField('Tags', ctrl.tags),
            const SizedBox(height: 12),
            _readonlyField('Amazon Link', ctrl.amazonLink),
            const SizedBox(height: 16),

            // Cover
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Cover Image'),
                const SizedBox(height: 8),
                Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                    image: (ctrl.coverUrl.isNotEmpty)
                        ? DecorationImage(image: NetworkImage(ctrl.coverUrl), fit: BoxFit.cover)
                        : null,
                  ),
                  child: (ctrl.coverUrl.isEmpty)
                      ? const Center(child: Icon(Icons.image, size: 50, color: Colors.grey))
                      : null,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Book File URL status
            _readonlyField('PDF URL', ctrl.pdfUrl.isNotEmpty ? 'Uploaded ✓' : 'Not uploaded'),

            const SizedBox(height: 24),

            // Publish Button
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: (ctrl.bookName.isEmpty || ctrl.authorName.isEmpty || ctrl.pdfUrl.isEmpty)
                    ? null
                    : () async {
                        await ctrl.publish();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Book published successfully!')),
                          );
                        }
                      },
                icon: const Icon(Icons.publish),
                label: const Text('Publish Book'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Draft ID: ${ctrl.draftId} | Status: ${ctrl.status}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _readonlyField(String label, String value, {int maxLines = 1}) {
    final controller = TextEditingController(text: value);
    return TextFormField(
      controller: controller,
      readOnly: true,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
