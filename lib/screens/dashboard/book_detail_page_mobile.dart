import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:Marketing_Fruit/components/categories_section_mobile.dart';
import 'dart:convert';



class BookDetailPageMobile extends StatefulWidget {
  final Map<String, dynamic> book;
  final bool hasStartedReading;
  final VoidCallback? onCloseTab;

  const BookDetailPageMobile({
    super.key,
    required this.book,
    this.hasStartedReading = false,
    this.onCloseTab,
  });

  @override
  State<BookDetailPageMobile> createState() => _BookDetailPageMobileState();
}

class _BookDetailPageMobileState extends State<BookDetailPageMobile> {
  int userRating = 0;

  Future<List<Map<String, dynamic>>> fetchOtherEditions(String title) async {
    final query = Uri.encodeComponent('intitle:$title');
    final url = 'https://www.googleapis.com/books/v1/volumes?q=$query&maxResults=10';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final items = data['items'] as List?;
      return items != null ? items.cast<Map<String, dynamic>>() : [];
    } else {
      print('Failed to fetch editions: ${response.body}');
      return [];
    }
  }

  final List<CategoryItem> demoCategories = [
    CategoryItem(name: "Category 1", imagePath: "assets/Assets/bandar.png"),
    CategoryItem(name: "Category 2", imagePath: "assets/Assets/music.png"),
    CategoryItem(name: "Category 3", imagePath: "assets/Assets/paint.png"),
    CategoryItem(name: "Category 4", imagePath: "assets/Assets/taklu.png"),
    CategoryItem(name: "Category 5", imagePath: "assets/Assets/choti.png"),
  ];

  @override
  Widget build(BuildContext context) {
    final volume = widget.book['volumeInfo'] ?? {};
    final title = volume['title'] ?? 'Untitled';
    final authors = (volume['authors'] as List?)?.join(', ') ?? 'Unknown';
    final desc = volume['description'] ?? 'No description available.';
    final publishedDate = volume['publishedDate'] ?? 'Unknown';
    final categories = (volume['categories'] as List?)?.join(', ') ?? 'General';
    final ratingsCount = volume['ratingsCount']?.toString() ?? '0';
    final avgRating = volume['averageRating']?.toDouble() ?? 0.0;
    final rawUrl = volume['imageLinks']?['thumbnail'];
    final imageUrl = rawUrl != null
        ? 'https://images.weserv.nl/?url=${Uri.encodeComponent(rawUrl.replaceFirst('http:', 'https:'))}'
        : 'https://via.placeholder.com/150x200.png?text=No+Cover';
    final isbnList = volume['industryIdentifiers'] ?? [];
    final isbn = isbnList.isNotEmpty ? isbnList.first['identifier'] : 'N/A';
    final language = volume['language'] ?? 'Unknown';
    final pageCount = volume['pageCount']?.toString() ?? 'N/A';
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.cardColor,
        elevation: 0,
        title: Text('Book Detail', style: TextStyle(color: theme.hintColor, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.hintColor),
          onPressed: widget.onCloseTab ?? () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Book Cover & Main Info
              Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(18),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        imageUrl,
                        width: 140,
                        height: 190,
                        fit: BoxFit.cover,
                      ),
                    ),
                    SizedBox(height: 18),
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      authors,
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.star, color: Colors.orange, size: 22),
                        SizedBox(width: 6),
                        Text('$avgRating', style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(width: 8),
                        Text('$ratingsCount Ratings'),
                      ],
                    ),
                    SizedBox(height: 18),
                    Text(
                      desc,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            shape: StadiumBorder(),
                            backgroundColor: theme.primaryColorLight,
                            minimumSize: Size(120, 38),
                          ),
                          child: Text(widget.hasStartedReading ? "Continue Reading" : "Start Reading"),
                        ),
                        OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            shape: StadiumBorder(),
                            side: BorderSide(color: theme.primaryColorLight),
                            minimumSize: Size(120, 38),
                          ),
                          child: Text("Order Physical"),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (i) {
                        return IconButton(
                          icon: Icon(i < userRating ? Icons.star : Icons.star_border, color: Colors.amber, size: 26),
                          onPressed: () => setState(() => userRating = i + 1),
                          padding: EdgeInsets.zero,
                        );
                      }),
                    ),
                    SizedBox(height: 12),
                    // Divider(),
                    // SizedBox(height: 6),
                    // Wrap(
                    //   spacing: 6,
                    //   children: categories.split(',').map((cat) => Chip(label: Text(cat.trim()))).toList(),
                    // ),
                  ],
                ),
              ),

              // Book Meta
              SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12, blurRadius: 3, offset: Offset(0, 1),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    _metaRow("Publication Date", publishedDate),
                    _metaRow("Pages", pageCount),
                    _metaRow("ISBN", isbn),
                    _metaRow("Language", language),
                  ],
                ),
              ),

              // More Edition Section
              SizedBox(height: 18),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: fetchOtherEditions(title),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Padding(
                      padding: EdgeInsets.only(top: 32),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) return SizedBox();

                  final editions = snapshot.data!;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("More Editions", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      SizedBox(height: 10),
                      SizedBox(
                        height: 180,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: editions.length,
                          separatorBuilder: (_, __) => SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            final edition = editions[index];
                            final info = edition['volumeInfo'] ?? {};
                            final thumb = info['imageLinks']?['thumbnail'];
                            final imageUrl = thumb != null
                                ? 'https://images.weserv.nl/?url=${Uri.encodeComponent(thumb.replaceFirst('http:', 'https:'))}'
                                : 'https://via.placeholder.com/150x220.png?text=No+Cover';
                            final format = info['printType'] ?? 'Format';
                            final editionTitle = info['title'] ?? 'Edition Name';
                            final year = info['publishedDate']?.split('-').first ?? 'Year';

                            return GestureDetector(
                              onTap: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (_) => BookDetailPageMobile(book: edition)),
                                );
                              },
                              child: SizedBox(
                                width: 120,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(imageUrl, width: 120, height: 120, fit: BoxFit.cover),
                                    ),
                                    SizedBox(height: 5),
                                    Text(format, style: theme.textTheme.bodySmall, maxLines: 1),
                                    Text(editionTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall),
                                    Text(year, style: theme.textTheme.labelSmall),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 6),
                      // GestureDetector(
                      //   onTap: () {},
                      //   child: Padding(
                      //     padding: EdgeInsets.symmetric(vertical: 4),
                      //     child: Text(
                      //       "Show all Editions",
                      //       style: TextStyle(
                      //         decoration: TextDecoration.underline,
                      //         color: Colors.blueAccent,
                      //       ),
                      //     ),
                      //   ),
                      // ),
                    ],
                  );
                },
              ),

              // About Author Section
              SizedBox(height: 18),
              Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4, offset: Offset(0, 1)),
                  ],
                ),
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('About the Author', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    SizedBox(height: 15),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 34,
                          backgroundImage: NetworkImage('https://api.dicebear.com/7.x/adventurer-neutral/png?seed=${Uri.encodeComponent(authors)}'),
                        ),
                        SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(authors, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                              SizedBox(height: 6),
                              Text('No.of Books    No.of Followers', style: theme.textTheme.bodySmall),
                              SizedBox(height: 8),
                              Text(desc, style: theme.textTheme.bodyMedium, maxLines: 5, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Categories Section
              SizedBox(height: 18),
              // Text("Categories", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              // SizedBox(height: 12),
              CategoriesSectionMobile(categories: demoCategories),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metaRow(String label, String value) => Padding(
    padding: EdgeInsets.symmetric(vertical: 2),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
      ],
    ),
  );
}
