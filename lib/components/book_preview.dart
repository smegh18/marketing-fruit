// lib/components/book_preview.dart
import 'package:flutter/material.dart';
import 'package:Marketing_Fruit/screens/dashboard/book_creation_controller.dart';
import 'package:provider/provider.dart';
// import 'package:Marketing_Fruit/components/book_creation_controller.dart';

class BookPreviewSection extends StatelessWidget {
  const BookPreviewSection({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<BookCreationController>();
    final screenWidth = MediaQuery.of(context).size.width;
    final containerWidth = screenWidth * 0.90;

    final bookTitle = (ctrl.bookName.isNotEmpty) ? ctrl.bookName : 'Book Title';
    final author = (ctrl.authorName.isNotEmpty) ? ctrl.authorName : 'Author';
    final description = (ctrl.bookDescription.isNotEmpty)
        ? ctrl.bookDescription
        : 'Book description will appear here once added.';

    return SingleChildScrollView(
      child: Container(
        width: containerWidth,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: Store Book Card Preview
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    // Image / Placeholder
                    Container(
                      height: 220,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey.shade200,
                        image: (ctrl.coverUrl.isNotEmpty)
                            ? DecorationImage(image: NetworkImage(ctrl.coverUrl), fit: BoxFit.cover)
                            : null,
                      ),
                      child: (ctrl.coverUrl.isEmpty)
                          ? const Icon(Icons.image, size: 64, color: Colors.grey)
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      bookTitle,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      author,
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    // Row(
                    //   mainAxisAlignment: MainAxisAlignment.center,
                    //   children: const [
                    //     Icon(Icons.star, color: Colors.orange, size: 16),
                    //     SizedBox(width: 4),
                    //     Text('4.0', style: TextStyle(fontSize: 12)),
                    //     SizedBox(width: 4),
                    //     Text('(5 Ratings)', style: TextStyle(fontSize: 12)),
                    //   ],
                    // ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 32),

            // Right: Inside Book Preview
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(bookTitle, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(author, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                  const SizedBox(height: 16),
                  // const Text('⭐ 4.0    5 Ratings', style: TextStyle(fontSize: 14, color: Colors.black87)),
                  const SizedBox(height: 16),
                  Text(description, style: const TextStyle(fontSize: 14, height: 1.5)),
                  const SizedBox(height: 16),
                  if (ctrl.amazonLink.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.link, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            ctrl.amazonLink,
                            style: const TextStyle(fontSize: 13, color: Colors.blue),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  if (ctrl.pdfUrl.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.picture_as_pdf, size: 16, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'PDF uploaded ✓',
                            style: const TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
