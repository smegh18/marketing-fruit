import 'dart:ui';
import 'package:flutter/material.dart';
import 'shopsection.dart';

// -- include your API client and WooProduct model import here --

// Replace this with your WooStoreApi or equivalent service.
class WooStoreApi {
  // Dummy endpoint, replace with your actual endpoint if different
  Future<List<Map<String, dynamic>>> fetchProductReviews(int productId) async {
    // API call to WooCommerce REST: /products/<productId>/reviews
    // Replace with your correct endpoint and authentication
    // Here is a simple dummy simulation:
    await Future.delayed(const Duration(seconds: 1));
    return [
      {
        'stars': 4.5,
        'name': 'John Doe',
        'content': 'Fantastic fit and superb material.',
        'date': 'Sep 15, 2025'
      },
      {
        'stars': 4.0,
        'name': 'Mary Jane',
        'content': 'Good quality, delivery took some time.',
        'date': 'Sep 17, 2025'
      },
    ];
  }
}

class RatingsReviewsSection extends StatefulWidget {
  final WooProduct product;
  final double cardHeight;
  final bool fullWidth;
  final double horizontalPadding;

  const RatingsReviewsSection({
    super.key,
    required this.product,
    this.cardHeight = 140,
    this.fullWidth = false,
    this.horizontalPadding = 16,
  });

  @override
  State<RatingsReviewsSection> createState() => _RatingsReviewsSectionState();
}

class _RatingsReviewsSectionState extends State<RatingsReviewsSection> {
  String selectedTab = 'Product Details';
  late Future<List<Map<String, dynamic>>> reviewsFuture;
  final WooStoreApi _api = WooStoreApi();

  @override
  void initState() {
    super.initState();
    reviewsFuture = _api.fetchProductReviews(widget.product.id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final pixelRatio = mediaQuery.devicePixelRatio;
    const baselinePixelRatio = 1.0;

    double t = ((pixelRatio - baselinePixelRatio) / baselinePixelRatio).clamp(0.0, 1.0);
    double scale = lerpDouble(1.0, 0.8, t)!;

    if (pixelRatio < 2.0 && pixelRatio > baselinePixelRatio) {
      final ratio = baselinePixelRatio / pixelRatio;
      if ((pixelRatio - 1.0).abs() < 0.3) {
        scale = ratio * 1.25;
      } else {
        scale = ratio * 1.6;
      }
    }

    final cardColor = theme.cardColor;
    final textColor = theme.hintColor;
    final borderColor = theme.scaffoldBackgroundColor;

    final section = SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: widget.horizontalPadding * scale,
        vertical: 24 * scale,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTabBar(scale, cardColor, textColor, borderColor),
          SizedBox(height: 24 * scale),
          if (selectedTab == 'Product Details')
            _buildProductDetailCard(scale, cardColor, textColor, borderColor)
          else if (selectedTab == 'Rating & Reviews')
            FutureBuilder<List<Map<String, dynamic>>>(
              future: reviewsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(
                      padding: EdgeInsets.all(30), child: CircularProgressIndicator()));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text("There are no reviews for this product yet.",
                        style: const TextStyle(color: Colors.grey)),
                  );
                }
                final reviews = snapshot.data!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeaderRow(scale, textColor, borderColor, reviews.length),
                    SizedBox(height: 24 * scale),
                    _buildReviewGrid(scale, cardColor, textColor, borderColor, reviews),
                    SizedBox(height: 24 * scale),
                    Center(
                      child: TextButton(
                        onPressed: () {},
                        child: Text("Load More Reviews", style: TextStyle(fontSize: 13 * scale)),
                      ),
                    ),
                  ],
                );
              },
            )
          else
            _buildFAQsPlaceholder(scale),
        ],
      ),
    );

    if (widget.fullWidth) {
      final screenWidth = mediaQuery.size.width;
      return Align(
        alignment: Alignment.center,
        child: SizedBox(width: screenWidth, child: section),
      );
    }
    return SizedBox(width: double.infinity, child: section);
  }

  Widget _buildTabBar(double scale, Color cardColor, Color textColor, Color borderColor) {
    final tabs = ['Product Details', 'Rating & Reviews', 'FAQs'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: tabs.map((tab) {
        final isActive = tab == selectedTab;
        return GestureDetector(
          onTap: () => setState(() => selectedTab = tab),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12 * scale),
            child: Column(
              children: [
                Text(
                  tab,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13 * scale,
                    color: isActive ? textColor : Colors.grey,
                  ),
                ),
                if (isActive)
                  Container(
                    margin: EdgeInsets.only(top: 4 * scale),
                    height: 2,
                    width: 24 * scale,
                    color: Colors.black,
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHeaderRow(double scale, Color textColor, Color borderColor, int reviewsCount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('All Reviews ($reviewsCount)',
            style: TextStyle(fontSize: 16 * scale, fontWeight: FontWeight.w600, color: textColor)),
        Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8 * scale, vertical: 6 * scale),
              decoration: BoxDecoration(
                border: Border.all(color: borderColor),
                borderRadius: BorderRadius.circular(6 * scale),
              ),
              child: Row(
                children: [
                  Icon(Icons.sort, size: 14 * scale),
                  SizedBox(width: 4 * scale),
                  Text('Latest', style: TextStyle(fontSize: 11 * scale, color: textColor)),
                  Icon(Icons.keyboard_arrow_down, size: 13 * scale),
                ],
              ),
            ),
            SizedBox(width: 8 * scale),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: EdgeInsets.symmetric(horizontal: 12 * scale, vertical: 10 * scale),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6 * scale),
                ),
              ),
              child: Text('Write a Review', style: TextStyle(fontSize: 11 * scale)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReviewGrid(double scale, Color cardColor, Color textColor, Color borderColor,
      List<Map<String, dynamic>> reviews) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10 * scale),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10.0 * scale,
            spreadRadius: 1.0 * scale,
          ),
        ],
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: reviews.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          mainAxisExtent: widget.cardHeight,
        ),
        itemBuilder: (context, index) {
          return _buildReviewCard(reviews[index], scale, cardColor, textColor, borderColor);
        },
      ),
    );
  }

  Widget _buildReviewCard(
      Map<String, dynamic> review, double scale, Color cardColor, Color textColor, Color borderColor) {
    return Container(
      padding: EdgeInsets.all(10 * scale),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(8 * scale),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10.0 * scale,
            spreadRadius: 1.0 * scale,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Row(
                children: List.generate(5, (i) {
                  final double stars = (review['stars'] as num).toDouble();
                  return Icon(
                    i + 1 <= stars
                        ? Icons.star
                        : (i + 0.5 < stars ? Icons.star_half : Icons.star_border),
                    size: 12 * scale,
                    color: Colors.amber,
                  );
                }),
              ),
              const Spacer(),
              Icon(Icons.more_horiz, size: 14 * scale),
            ],
          ),
          SizedBox(height: 4 * scale),
          Row(
            children: [
              Text(review['name'] ?? '',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12 * scale)),
              SizedBox(width: 4 * scale),
              Icon(Icons.verified, color: Colors.green, size: 13 * scale),
            ],
          ),
          SizedBox(height: 4 * scale),
          Text(
            review['content'] ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13 * scale, height: 1.2, color: textColor),
          ),
          const Spacer(),
          Text('Posted on ${review['date'] ?? ''}',
              style: TextStyle(fontSize: 12 * scale, color: textColor)),
        ],
      ),
    );
  }

  Widget _buildProductDetailCard(
      double scale, Color cardColor, Color textColor, Color borderColor) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16 * scale),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(10 * scale),
        color: cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10.0 * scale,
            spreadRadius: 1.0 * scale,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Product Description",
              style: TextStyle(fontSize: 16 * scale, fontWeight: FontWeight.w600, color: textColor)),
          SizedBox(height: 8 * scale),
          Text(
            widget.product.name,
            style: TextStyle(fontSize: 13 * scale, height: 1.4, color: textColor),
          ),
          SizedBox(height: 16 * scale),
          if (widget.product.slug.isNotEmpty)
            Text("Slug: ${widget.product.slug}", style: TextStyle(fontSize: 13 * scale, color: textColor)),
          // Add more product details as needed
        ],
      ),
    );
  }

  Widget _buildFAQsPlaceholder(double scale) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16 * scale),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10 * scale),
      ),
      child: Text(
        "FAQs will be displayed here...",
        style: TextStyle(fontSize: 14 * scale, color: Colors.grey.shade700),
      ),
    );
  }
}
