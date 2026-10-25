import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_stripe/flutter_stripe.dart';
import 'dart:io' show Platform;

import 'package:Marketing_Fruit/ecommerce/newsletter.dart';
import 'package:Marketing_Fruit/ecommerce/rating.dart';
import 'package:Marketing_Fruit/ecommerce/shopsection.dart';
import 'package:Marketing_Fruit/ecommerce/cart_service.dart';
import 'package:Marketing_Fruit/ecommerce/cart_screen.dart';
import 'package:Marketing_Fruit/ecommerce/checkout_screen.dart';

class TShirtDetailPage extends StatefulWidget {
  final WooProduct product;
  const TShirtDetailPage({super.key, required this.product});

  @override
  State<TShirtDetailPage> createState() => _TShirtDetailPageState();
}

class _TShirtDetailPageState extends State<TShirtDetailPage> {
  int quantity = 1;
  String selectedSize = 'Large';
  int selectedImageIndex = 0;

  List<String> get imageAssets {
    if (widget.product.image != null) {
      return [widget.product.firebaseImageUrl ?? widget.product.image!];
    }
    return [''];
  }

  @override
  void initState() {
    super.initState();
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      Stripe.publishableKey = 'pk_live_51RUEBJG0SSdz1yc5ZSYn8HTMfDYyppox7MqrbJjz8UqMLtg3GI6zjlCjjH55W3ZDoVfOWvzUlGAXKXiQwEhI0Rdu00uio2AcA1';
      Stripe.merchantIdentifier = 'merchant.com.yourapp';
      Stripe.instance.applySettings();
    }
  }

  void _addToCart({bool navigateToCheckout = false}) {
    final item = CartItem(
      id: '${widget.product.id}_$selectedSize',
      productId: widget.product.id.toString(),
      title: widget.product.name,
      price: widget.product.price ?? 0.0,
      regularPrice: widget.product.regularPrice,
      image: widget.product.firebaseImageUrl ?? widget.product.image ?? '',
      quantity: quantity,
      size: selectedSize,
      colorName: 'Default',
    );

    CartService.instance.addItem(item);

    if (navigateToCheckout) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const CheckoutScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added $quantity × ${widget.product.name} to cart!'),
          backgroundColor: const Color(0xFF25293A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: Colors.purple.withOpacity(0.5)),
          ),
          action: SnackBarAction(
            label: 'VIEW CART',
            textColor: Colors.purpleAccent,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CartScreen()),
              );
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final scale = screenWidth / 1440;

    final price = widget.product.price ?? 0;
    final regularPrice = widget.product.regularPrice ?? price;
    final discount = widget.product.discount != null && widget.product.discount! > 0
        ? '-${widget.product.discount}%'
        : null;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.cardColor,
        iconTheme: IconThemeData(color: theme.hintColor),
        elevation: 0,
        title: Text(widget.product.name.toUpperCase(),
            style: TextStyle(color: theme.hintColor, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          AnimatedBuilder(
            animation: CartService.instance,
            builder: (context, _) {
              final count = CartService.instance.itemCount;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.shopping_bag_outlined, color: theme.hintColor),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CartScreen()),
                      );
                    },
                  ),
                  if (count > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.purple,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                        child: Center(
                          child: Text(
                            '$count',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(32 * scale),
          child: Column(
            children: [
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      flex: 2,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (imageAssets.length > 1)
                            Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: List.generate(imageAssets.length, (index) {
                                return GestureDetector(
                                  onTap: () => setState(() => selectedImageIndex = index),
                                  child: Container(
                                    margin: EdgeInsets.symmetric(vertical: 12 * scale),
                                    width: 90 * scale,
                                    height: 90 * scale,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: selectedImageIndex == index
                                            ? theme.scaffoldBackgroundColor
                                            : Colors.grey.shade300,
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      image: imageAssets[index].isNotEmpty
                                          ? DecorationImage(
                                        image: NetworkImage(imageAssets[index]),
                                        fit: BoxFit.cover,
                                      )
                                          : null,
                                    ),
                                    child: imageAssets[index].isEmpty
                                        ? Icon(Icons.image, size: 36 * scale, color: Colors.grey)
                                        : null,
                                  ),
                                );
                              }),
                            ),
                          if (imageAssets.length > 1) SizedBox(width: 24 * scale),
                          Expanded(
                            child: Container(
                              height: (screenWidth * 0.3) * 1.15,
                              padding: EdgeInsets.all(24 * scale),
                              decoration: BoxDecoration(
                                color: theme.cardColor,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: imageAssets[selectedImageIndex].isNotEmpty
                                  ? Image.network(
                                imageAssets[selectedImageIndex],
                                fit: BoxFit.contain,
                              )
                                  : Icon(Icons.image, size: 80 * scale, color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 48 * scale),
                    Flexible(
                      flex: 3,
                      child: SizedBox(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.product.name.toUpperCase(),
                              style: TextStyle(
                                fontSize: 30 * scale,
                                fontWeight: FontWeight.bold,
                                color: theme.hintColor,
                              ),
                            ),
                            SizedBox(height: 16 * scale),
                            Row(
                              children: [
                                ...List.generate(
                                  5,
                                      (i) => Icon(
                                    Icons.star,
                                    size: 20 * scale,
                                    color: Colors.amber,
                                  ),
                                ),
                                SizedBox(width: 10 * scale),
                                Text("${widget.product.rating?.toStringAsFixed(1) ?? '4.5'}/5",
                                    style: TextStyle(fontSize: 14 * scale)),
                              ],
                            ),
                            SizedBox(height: 24 * scale),
                            Row(
                              children: [
                                Text(
                                  "\$${price.toStringAsFixed(2)}",
                                  style: TextStyle(
                                    fontSize: 28 * scale,
                                    fontWeight: FontWeight.bold,
                                    color: theme.hintColor,
                                  ),
                                ),
                                if (regularPrice > price) ...[
                                  SizedBox(width: 16 * scale),
                                  Text(
                                    "\$${regularPrice.toStringAsFixed(2)}",
                                    style: TextStyle(
                                      fontSize: 18 * scale,
                                      decoration: TextDecoration.lineThrough,
                                      color: theme.hintColor,
                                    ),
                                  ),
                                ],
                                if (discount != null) ...[
                                  SizedBox(width: 16 * scale),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 10 * scale, vertical: 4 * scale),
                                    decoration: BoxDecoration(
                                      color: Colors.pink[50],
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      discount,
                                      style: TextStyle(color: Colors.red, fontSize: 14 * scale),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            SizedBox(height: 20 * scale),
                            Text(
                              widget.product.slug.replaceAll('-', ' ').replaceAll('_', ' '),
                              style: TextStyle(
                                  fontSize: 16 * scale, color: theme.hintColor, height: 1.5),
                            ),
                            Divider(height: 40 * scale, thickness: 1),
                            SizedBox(height: 30 * scale),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Colors.purpleAccent, width: 1.5),
                                      padding: EdgeInsets.symmetric(vertical: 18 * scale),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                    ),
                                    onPressed: () => _addToCart(navigateToCheckout: false),
                                    icon: const Icon(Icons.add_shopping_cart, color: Colors.purpleAccent),
                                    label: const Text(
                                      "Add to Cart",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 16 * scale),
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      elevation: 8,
                                      backgroundColor: Colors.purple,
                                      padding: EdgeInsets.symmetric(vertical: 18 * scale),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                    ),
                                    onPressed: () => _addToCart(navigateToCheckout: true),
                                    child: const Text(
                                      "Buy Now",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 60),
              RatingsReviewsSection(
                fullWidth: true,
                horizontalPadding: 0,
                product: widget.product,
              ),
              NewsletterSection(fullWidth: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorDot(Color color, double scale) {
    return Container(
      margin: EdgeInsets.only(right: 12 * scale),
      width: 30 * scale,
      height: 30 * scale,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade400, width: 1),
      ),
    );
  }

  Widget _buildSizeButton(String size, double scale) {
    final isSelected = selectedSize == size;
    return GestureDetector(
      onTap: () => setState(() => selectedSize = size),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20 * scale, vertical: 12 * scale),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          size,
          style: TextStyle(
            fontSize: 14 * scale,
            color: isSelected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}
