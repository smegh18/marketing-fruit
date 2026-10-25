import 'package:flutter/material.dart';

class CategoriesSectionWidget extends StatefulWidget {
  final List<CategoryItem> categories;

  const CategoriesSectionWidget({super.key, required this.categories});

  @override
  State<CategoriesSectionWidget> createState() => _CategoriesSectionWidgetState();
}

class _CategoriesSectionWidgetState extends State<CategoriesSectionWidget> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double screenWidth = MediaQuery.of(context).size.width;
    final double scaleFactor = MediaQuery.of(context).devicePixelRatio;
    final double cardImageSize = screenWidth * 0.1;
    final double cardTextSize = screenWidth * 0.015;

    return Container(
      width: screenWidth * 0.74,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Categories',
                style: TextStyle(
                  fontSize: 22 ,
                  fontWeight: FontWeight.bold,
                  color: theme.hintColor,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  'Show all',
                  style: TextStyle(
                    color: theme.hintColor,
                    fontSize: 22,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Scrollable Category Cards with Scrollbar
          SizedBox(
            height: cardImageSize + 60,
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              trackVisibility: true,
              thickness: 6,
              radius: const Radius.circular(4),
              scrollbarOrientation: ScrollbarOrientation.bottom,
              child: ListView.separated(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                itemCount: widget.categories.length,
                separatorBuilder: (context, index) => SizedBox(width: cardImageSize * 0.42),
                itemBuilder: (context, index) {
                  final item = widget.categories[index];
                  final bool isFeatured = index == 1;

                  return Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: cardImageSize,
                            height: cardImageSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                image: AssetImage(item.imagePath),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          // Optional featured overlay
                          // if (isFeatured)
                          //   Positioned(
                          //     bottom: 0,
                          //     right: 0,
                          //     child: Container(
                          //       decoration: BoxDecoration(
                          //         color: Colors.greenAccent[400],
                          //         shape: BoxShape.circle,
                          //       ),
                          //       padding: EdgeInsets.all(6),
                          //       child: Icon(
                          //         Icons.play_arrow,
                          //         color: Colors.black,
                          //         size: 16,
                          //       ),
                          //     ),
                          //   ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: cardImageSize + 10,
                        child: Text(
                          item.name,
                          style: TextStyle(
                            color: theme.hintColor,
                            fontWeight: FontWeight.w600,
                            fontSize: cardTextSize,
                          ),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryItem {
  final String name;
  final String imagePath;

  CategoryItem({required this.name, required this.imagePath});
}
