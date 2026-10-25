import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Representation of an individual item in the user's shopping cart.
class CartItem {
  final String id; // unique key e.g. "${productId}_${size}_${colorName}"
  final String productId;
  final String title;
  final double price;
  final double? regularPrice;
  final String image;
  int quantity;
  final String size;
  final String colorName;
  final Color? color;

  CartItem({
    required this.id,
    required this.productId,
    required this.title,
    required this.price,
    this.regularPrice,
    required this.image,
    this.quantity = 1,
    this.size = 'M',
    this.colorName = '',
    this.color,
  });

  double get totalPrice => price * quantity;

  CartItem copyWith({
    String? id,
    String? productId,
    String? title,
    double? price,
    double? regularPrice,
    String? image,
    int? quantity,
    String? size,
    String? colorName,
    Color? color,
  }) {
    return CartItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      title: title ?? this.title,
      price: price ?? this.price,
      regularPrice: regularPrice ?? this.regularPrice,
      image: image ?? this.image,
      quantity: quantity ?? this.quantity,
      size: size ?? this.size,
      colorName: colorName ?? this.colorName,
      color: color ?? this.color,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'productId': productId,
        'title': title,
        'price': price,
        'regularPrice': regularPrice,
        'image': image,
        'quantity': quantity,
        'size': size,
        'colorName': colorName,
      };

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] as String? ?? '',
      productId: json['productId'] as String? ?? '',
      title: json['title'] as String? ?? 'Product',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      regularPrice: (json['regularPrice'] as num?)?.toDouble(),
      image: json['image'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      size: json['size'] as String? ?? 'M',
      colorName: json['colorName'] as String? ?? '',
    );
  }
}

/// Global Cart Controller / Service holding the user's shopping bag state.
class CartService extends ChangeNotifier {
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  static CartService get instance => _instance;

  CartService._internal();

  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  /// Total number of physical pieces in cart
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  /// Subtotal before promo codes and shipping
  double get subtotal => _items.fold(0.0, (sum, item) => sum + item.totalPrice);

  double _discount = 0.0;
  String? _appliedPromo;

  double get discount => _discount;
  String? get appliedPromo => _appliedPromo;

  /// Free shipping threshold over $150; otherwise $15 flat rate.
  double get shippingFee {
    if (_items.isEmpty) return 0.0;
    if (subtotal >= 150) return 0.0;
    return 15.0;
  }

  /// Final grand total payable
  double get total {
    if (_items.isEmpty) return 0.0;
    final calc = subtotal - _discount + shippingFee;
    return calc < 0 ? 0.0 : calc;
  }

  /// Adds a new product or increments quantity if matching variant already exists.
  void addItem(CartItem item) {
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index >= 0) {
      _items[index].quantity += item.quantity;
    } else {
      _items.add(item);
    }
    _recalcDiscount();
    notifyListeners();
  }

  /// Adjusts quantity directly. If <= 0, removes the item.
  void updateQuantity(String id, int quantity) {
    final index = _items.indexWhere((i) => i.id == id);
    if (index >= 0) {
      if (quantity <= 0) {
        _items.removeAt(index);
      } else {
        _items[index].quantity = quantity;
      }
      _recalcDiscount();
      notifyListeners();
    }
  }

  /// Removes an item completely from cart.
  void removeItem(String id) {
    _items.removeWhere((i) => i.id == id);
    _recalcDiscount();
    notifyListeners();
  }

  /// Clears all items in the cart (e.g. after successful order).
  void clear() {
    _items.clear();
    _discount = 0.0;
    _appliedPromo = null;
    notifyListeners();
  }

  /// Applies a promo code discount. Returns true if valid, false if not found.
  bool applyPromo(String code) {
    final clean = code.trim().toUpperCase();
    if (clean.isEmpty) return false;

    if (clean == 'FRUIT20' || clean == 'MARKETINGFRUIT' || clean == 'SAVE20') {
      _appliedPromo = clean;
      _discount = subtotal * 0.20; // 20% off
      notifyListeners();
      return true;
    } else if (clean == 'FRUIT10' || clean == 'SUMMER10' || clean == 'SAVE10') {
      _appliedPromo = clean;
      _discount = subtotal * 0.10; // 10% off
      notifyListeners();
      return true;
    } else if (clean == 'FLAT50') {
      if (subtotal >= 100) {
        _appliedPromo = clean;
        _discount = 50.0;
        notifyListeners();
        return true;
      }
    }

    return false;
  }

  /// Removes any active promo code
  void removePromo() {
    _discount = 0.0;
    _appliedPromo = null;
    notifyListeners();
  }

  void _recalcDiscount() {
    if (_appliedPromo != null) {
      applyPromo(_appliedPromo!);
    } else {
      _discount = 0.0;
    }
  }
}
