import 'package:flutter/material.dart';

class HappyCustomersSection extends StatefulWidget {
  /// Pass the same width as the section above (for consistency)
  final double width;
  const HappyCustomersSection({super.key, required this.width});

  @override
  State<HappyCustomersSection> createState() => _HappyCustomersSectionState();
}

class _HappyCustomersSectionState extends State<HappyCustomersSection> {
  final ScrollController _scrollController = ScrollController();

  void _scrollRight() {
    _scrollController.animateTo(
      _scrollController.offset + 300,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _scrollLeft() {
    _scrollController.animateTo(
      _scrollController.offset - 300,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;

    // Scale factor logic
    double scaleFactor = 1.0;
    if (pixelRatio < 2.0 && pixelRatio > 1.0) {
      scaleFactor = 0.95;
    } else if (pixelRatio >= 2.0) {
      scaleFactor = 1.1;
    }

    return Center(
      child: Container(
        width: widget.width, // ✅ matches parent width
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              spreadRadius: 5,
              blurRadius: 7,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Title + arrows
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'OUR HAPPY CUSTOMERS',
                  style: TextStyle(
                    fontSize: 28 * scaleFactor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: _scrollLeft,
                      icon: const Icon(Icons.arrow_back_ios_new),
                    ),
                    IconButton(
                      onPressed: _scrollRight,
                      icon: const Icon(Icons.arrow_forward_ios),
                    ),
                  ],
                )
              ],
            ),

            const SizedBox(height: 20),

            // Cards row
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.18,
              child: Stack(
                children: [
                  ListView(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    children: [
                      CustomerCard(
                        name: "Sarah M.",
                        review:
                            "I'm blown away by the quality and style of the clothes...",
                        width: widget.width * 0.28,
                      ),
                      CustomerCard(
                        name: "Alex K.",
                        review:
                            "Finding clothes that align with my personal style...",
                        width: widget.width * 0.32,
                      ),
                      CustomerCard(
                        name: "James L.",
                        review:
                            "As someone who's always on the lookout for unique fashion...",
                        width: widget.width * 0.32,
                      ),
                      CustomerCard(
                        name: "Mona R.",
                        review:
                            "Absolutely in love with Shop.co! Their quality is top-notch...",
                        width: widget.width * 0.26,
                      ),
                      CustomerCard(
                        name: "Liam P.",
                        review: "Was skeptical at first, but Shop.co delivered!",
                        width: widget.width * 0.24,
                      ),
                    ],
                  ),

                  // Fades
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 30,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [theme.scaffoldBackgroundColor, Colors.transparent],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      width: 30,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.transparent, theme.scaffoldBackgroundColor],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                    ),
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

class CustomerCard extends StatelessWidget {
  final String name;
  final String review;
  final double width;

  const CustomerCard({
    super.key,
    required this.name,
    required this.review,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: width, // ✅ fixed width from parent, no LayoutBuilder
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stars
          Row(
            children: List.generate(
              5,
              (index) => const Icon(Icons.star, size: 14, color: Colors.amber),
            ),
          ),
          const SizedBox(height: 6),
          // Name + verified
          Row(
            children: [
              Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.verified, size: 14, color: Colors.green),
            ],
          ),
          const SizedBox(height: 6),
          // Review
          Text(
            review,
            style: TextStyle(fontSize: 12, color: theme.hintColor),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
