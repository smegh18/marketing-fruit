import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:Marketing_Fruit/ecommerce/cart_service.dart';
import 'package:Marketing_Fruit/ecommerce/stripe_service.dart';
import 'package:Marketing_Fruit/ecommerce/order_success_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _stateCtrl;
  late final TextEditingController _postalCtrl;
  String _country = 'United States';

  int _selectedPaymentMethod = 0; // 0 = Stripe Live PaymentSheet, 1 = Stripe Instant Test Flow
  bool _isProcessing = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _nameCtrl = TextEditingController(text: user?.displayName ?? '');
    _emailCtrl = TextEditingController(text: user?.email ?? '');
    _phoneCtrl = TextEditingController(text: user?.phoneNumber ?? '');
    _addressCtrl = TextEditingController(text: '742 Evergreen Terrace');
    _cityCtrl = TextEditingController(text: 'Springfield');
    _stateCtrl = TextEditingController(text: 'OR');
    _postalCtrl = TextEditingController(text: '97477');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _postalCtrl.dispose();
    super.dispose();
  }

  Future<void> _handlePayment() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required shipping fields.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final cart = CartService.instance;
    if (cart.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your cart is empty.')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _statusMessage = _selectedPaymentMethod == 0
          ? 'Connecting to Stripe...'
          : 'Processing test payment with Stripe...';
    });

    try {
      StripePaymentResult result;

      if (_selectedPaymentMethod == 0) {
        // Stripe Payment Sheet / Web Checkout
        result = await StripeService.instance.payWithPaymentSheet(
          amountInDollars: cart.total,
          currency: 'usd',
          items: cart.items,
          customerEmail: _emailCtrl.text.trim(),
          customerName: _nameCtrl.text.trim(),
          shippingAddress: {
            'address': _addressCtrl.text.trim(),
            'city': _cityCtrl.text.trim(),
            'state': _stateCtrl.text.trim(),
            'postalCode': _postalCtrl.text.trim(),
            'country': _country == 'United States' ? 'US' : 'CA',
          },
        );
      } else {
        // Stripe Instant Test Mode
        result = await StripeService.instance.simulateTestPayment(
          amount: cart.total,
          items: cart.items,
        );
      }

      if (!mounted) return;

      if (result.status == StripePaymentStatus.success) {
        final orderId = 'MF-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
        final totalPaid = cart.total;
        final purchasedItems = List<CartItem>.from(cart.items);
        final fullAddress =
            '${_addressCtrl.text.trim()}, ${_cityCtrl.text.trim()}, ${_stateCtrl.text.trim()} ${_postalCtrl.text.trim()}, $_country';

        // Clear cart now that purchase was completed
        cart.clear();

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => OrderSuccessScreen(
              orderId: orderId,
              amount: totalPaid,
              customerName: _nameCtrl.text.trim(),
              email: _emailCtrl.text.trim(),
              address: fullAddress,
              items: purchasedItems,
              paymentMethod: _selectedPaymentMethod == 0 ? 'Stripe Card / Pay' : 'Stripe Test Mode',
            ),
          ),
        );
      } else if (result.status == StripePaymentStatus.cancelled) {
        setState(() {
          _isProcessing = false;
          _statusMessage = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment cancelled.'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        setState(() {
          _isProcessing = false;
          _statusMessage = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'Payment failed. Please try again.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _statusMessage = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment exception: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardBg = theme.cardColor;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Checkout',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: CartService.instance,
          builder: (context, _) {
            final cart = CartService.instance;
            if (cart.items.isEmpty && !_isProcessing) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.white38),
                    const SizedBox(height: 16),
                    const Text('Your cart is empty', style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Return to Shop'),
                    ),
                  ],
                ),
              );
            }

            return Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- 1. Order Summary Accordion Card ---
                        _buildSectionHeader('1. Order Summary (${cart.itemCount} items)'),
                        const SizedBox(height: 10),
                        _buildOrderSummaryCard(cardBg, cart),
                        const SizedBox(height: 24),

                        // --- 2. Shipping Details Card ---
                        _buildSectionHeader('2. Shipping & Contact Information'),
                        const SizedBox(height: 10),
                        _buildShippingCard(cardBg),
                        const SizedBox(height: 24),

                        // --- 3. Payment Method Card ---
                        _buildSectionHeader('3. Payment Method (Stripe)'),
                        const SizedBox(height: 10),
                        _buildPaymentMethodCard(cardBg),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                // --- Floating Bottom Checkout Button ---
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: cardBg.withOpacity(0.96),
                      border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 16,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'TOTAL DUE',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '\$${cart.total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isProcessing ? null : _handlePayment,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple,
                                foregroundColor: Colors.white,
                                elevation: 6,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _isProcessing
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.lock_outline, size: 18),
                                        const SizedBox(width: 8),
                                        Text(
                                          _selectedPaymentMethod == 0
                                              ? 'Pay with Stripe'
                                              : 'Complete Test Order',
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // --- Processing Overlay Indicator ---
                if (_isProcessing)
                  Container(
                    color: Colors.black.withOpacity(0.65),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.purple.withOpacity(0.5)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(color: Colors.purpleAccent),
                            const SizedBox(height: 18),
                            Text(
                              _statusMessage ?? 'Processing...',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        color: Colors.white,
        fontWeight: FontWeight.w700,
        fontSize: 16,
      ),
    );
  }

  Widget _buildOrderSummaryCard(Color cardBg, CartService cart) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Items preview strip
          SizedBox(
            height: 60,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: cart.items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, idx) {
                final item = cart.items[idx];
                return Container(
                  width: 180,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _buildThumb(item.image),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '${item.quantity} × \$${item.price.toStringAsFixed(0)}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const Divider(height: 24, thickness: 1, color: Colors.white10),

          _summaryRow('Subtotal', '\$${cart.subtotal.toStringAsFixed(2)}'),
          if (cart.discount > 0) ...[
            const SizedBox(height: 8),
            _summaryRow(
              'Promo Discount (${cart.appliedPromo ?? ""})',
              '-\$${cart.discount.toStringAsFixed(2)}',
              isGreen: true,
            ),
          ],
          const SizedBox(height: 8),
          _summaryRow(
            'Shipping',
            cart.shippingFee == 0 ? 'FREE' : '\$${cart.shippingFee.toStringAsFixed(2)}',
            isGreen: cart.shippingFee == 0,
          ),
          const Divider(height: 20, thickness: 1, color: Colors.white10),
          _summaryRow('Total', '\$${cart.total.toStringAsFixed(2)}', isBold: true),
        ],
      ),
    );
  }

  Widget _buildShippingCard(Color cardBg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          _buildTextField(
            controller: _nameCtrl,
            label: 'Full Name',
            icon: Icons.person_outline,
            validator: (v) => v == null || v.trim().isEmpty ? 'Please enter your name' : null,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _emailCtrl,
                  label: 'Email Address',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                      v == null || !v.contains('@') ? 'Enter a valid email' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _phoneCtrl,
                  label: 'Phone Number',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Enter phone number' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _addressCtrl,
            label: 'Street Address',
            icon: Icons.home_outlined,
            validator: (v) => v == null || v.trim().isEmpty ? 'Enter address' : null,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildTextField(
                  controller: _cityCtrl,
                  label: 'City',
                  validator: (v) => v == null || v.trim().isEmpty ? 'City' : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 1,
                child: _buildTextField(
                  controller: _stateCtrl,
                  label: 'State',
                  validator: (v) => v == null || v.trim().isEmpty ? 'State' : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: _buildTextField(
                  controller: _postalCtrl,
                  label: 'Postal Code',
                  validator: (v) => v == null || v.trim().isEmpty ? 'Postal' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Country selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _country,
                isExpanded: true,
                dropdownColor: const Color(0xFF232736),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                items: const [
                  DropdownMenuItem(value: 'United States', child: Text('United States (US)')),
                  DropdownMenuItem(value: 'Canada', child: Text('Canada (CA)')),
                  DropdownMenuItem(value: 'India', child: Text('India (IN)')),
                  DropdownMenuItem(value: 'United Kingdom', child: Text('United Kingdom (UK)')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _country = val);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard(Color cardBg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          // Stripe Live Payment Option
          _paymentOptionTile(
            index: 0,
            title: 'Stripe Payment Sheet (Live / Integrated)',
            subtitle: 'Credit / Debit Card, Apple Pay, Google Pay via Stripe',
            icon: Icons.credit_card,
            badge: 'LIVE STRIPE',
            badgeColor: Colors.purpleAccent,
          ),
          const SizedBox(height: 12),

          // Stripe Instant Test Flow Option
          _paymentOptionTile(
            index: 1,
            title: 'Stripe Instant Test Mode',
            subtitle: 'Simulates instant verified payment without charging your card',
            icon: Icons.science_outlined,
            badge: 'TEST MODE',
            badgeColor: Colors.blueAccent,
          ),
        ],
      ),
    );
  }

  Widget _paymentOptionTile({
    required int index,
    required String title,
    required String subtitle,
    required IconData icon,
    required String badge,
    required Color badgeColor,
  }) {
    final isSelected = _selectedPaymentMethod == index;

    return InkWell(
      onTap: () => setState(() => _selectedPaymentMethod = index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.purple.withOpacity(0.15) : Colors.black26,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.purpleAccent : Colors.white12,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Radio<int>(
              value: index,
              groupValue: _selectedPaymentMethod,
              activeColor: Colors.purpleAccent,
              onChanged: (v) => setState(() => _selectedPaymentMethod = v ?? 0),
            ),
            Icon(icon, color: isSelected ? Colors.purpleAccent : Colors.white60, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: badgeColor.withOpacity(0.5)),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            color: badgeColor,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.55),
                      fontSize: 11,
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.white, fontSize: 13.5),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white60, fontSize: 12),
        prefixIcon: icon != null ? Icon(icon, color: Colors.white54, size: 18) : null,
        filled: true,
        fillColor: Colors.black26,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.purpleAccent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isGreen = false, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isBold ? Colors.white : Colors.white70,
            fontSize: isBold ? 15 : 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isGreen
                ? const Color(0xFF00E676)
                : (isBold ? Colors.purpleAccent : Colors.white),
            fontSize: isBold ? 18 : 13,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildThumb(String image) {
    if (image.isEmpty) {
      return const Icon(Icons.image, size: 20, color: Colors.white38);
    }
    if (image.startsWith('assets/')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(image, fit: BoxFit.cover),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        image,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 20, color: Colors.white38),
      ),
    );
  }
}
