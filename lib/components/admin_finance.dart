import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';

class AddGameFinanceSection extends StatefulWidget {
  final double? initialGemsPrice;
  final double? initialCoinsPrice;
  final double? initialCoins2Price;
  final double? initialPolyPrice;
  final void Function(Map<String, dynamic> data)? onPricesChanged;

  const AddGameFinanceSection({
    super.key,
    this.initialGemsPrice,
    this.initialCoinsPrice,
    this.initialCoins2Price,
    this.initialPolyPrice,
    this.onPricesChanged,
  });

  @override
  State<AddGameFinanceSection> createState() => _AddGameFinanceSectionState();
}

class _AddGameFinanceSectionState extends State<AddGameFinanceSection> {
  late final TextEditingController _gemsCtrl;
  late final TextEditingController _coinsCtrl;
  late final TextEditingController _coins2Ctrl;
  late final TextEditingController _polyCtrl;

  final FocusNode _gemsFocus = FocusNode();
  final FocusNode _coinsFocus = FocusNode();
  final FocusNode _coins2Focus = FocusNode();
  final FocusNode _polyFocus = FocusNode();

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _gemsCtrl = TextEditingController(text: _fmt(widget.initialGemsPrice ?? 0));
    _coinsCtrl = TextEditingController(text: _fmt(widget.initialCoinsPrice ?? 0));
    _coins2Ctrl = TextEditingController(text: _fmt(widget.initialCoins2Price ?? 0));
    _polyCtrl = TextEditingController(text: _fmt(widget.initialPolyPrice ?? 0));
    _fetchFromFirebase();
  }

  @override
  void dispose() {
    _gemsFocus.dispose();
    _coinsFocus.dispose();
    _coins2Focus.dispose();
    _polyFocus.dispose();
    _gemsCtrl.dispose();
    _coinsCtrl.dispose();
    _coins2Ctrl.dispose();
    _polyCtrl.dispose();
    super.dispose();
  }

  String _fmt(num v) =>
      (v == v.roundToDouble()) ? v.toStringAsFixed(0) : v.toString();

  Future<void> _fetchFromFirebase() async {
    setState(() {
      _loading = true;
    });

    final ref = FirebaseDatabase.instance.ref("game_finance");
    final snapshot = await ref.get();

    if (snapshot.exists) {
      // Assuming only one object at 'game_finance', otherwise take the latest (sort by timestamp)
      dynamic data = snapshot.value;
      if (data is Map) {
        // Sometimes might be a map of keys
        if (data.containsKey('row1') && data.containsKey('row2')) {
          // Single value at root
        } else {
          // If there are push-child keys, pick the latest
          var entries = data.entries.toList();
          entries.sort((a, b) {
            final aTime = DateTime.tryParse(a.value['timestamp'] ?? '') ?? DateTime(1970);
            final bTime = DateTime.tryParse(b.value['timestamp'] ?? '') ?? DateTime(1970);
            return bTime.compareTo(aTime);
          });
          data = entries.isNotEmpty ? entries.first.value : null;
        }
        if (data != null) {
          final gems = data['row1']?['gems'] ?? 0.0;
          final coins = data['row1']?['coins'] ?? 0.0;
          final coins2 = data['row2']?['gems2'] ?? 0.0;
          final poly = data['row2']?['poly'] ?? 0.0;

          _gemsCtrl.text = _fmt(gems);
          _coinsCtrl.text = _fmt(coins);
          _coins2Ctrl.text = _fmt(coins2);
          _polyCtrl.text = _fmt(poly);
        }
      }
    }
    setState(() {
      _loading = false;
    });
  }

  Future<void> _replaceInFirebase() async {
    final gems = double.tryParse(_gemsCtrl.text.trim()) ?? 0.0;
    final coins = double.tryParse(_coinsCtrl.text.trim()) ?? 0.0;
    final coins2 = double.tryParse(_coins2Ctrl.text.trim()) ?? 0.0;
    final poly = double.tryParse(_polyCtrl.text.trim()) ?? 0.0;

    if ((gems == 0 && coins == 0 && coins2 == 0 && poly == 0)) {
      return;
    }

    final data = {
      'row1': {
        'gems': gems,
        'coins': coins,
      },
      'row2': {
        'gems2': gems,
        'poly': poly,
      },
      'timestamp': DateTime.now().toIso8601String(),
    };

    final ref = FirebaseDatabase.instance.ref("game_finance");

    // Remove previous data
    await ref.remove();

    // Set new data (as a single object)
    await ref.set(data);

    // Optionally notify the app
    widget.onPricesChanged?.call(data);

    // Optionally show feedback and re-fetch updated state
    await _fetchFromFirebase();
  }

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.of(context).textScaleFactor.clamp(1.0, 1.2);
    const outerRadius = 16.0;
    const gap = 20.0;
    const cardHeight = 250.0;

    final gemsCard = SizedBox(
      height: cardHeight,
      child: _PriceCard(
        title: 'Gems',
        controller: _gemsCtrl,
        focusNode: _gemsFocus,
        accentBg: const Color(0xffe8e4ff),
        accentIconColor: const Color(0xff6f3ff2),
        icon: Icons.diamond,
        textScale: textScale,
        enabled: !_loading,
      ),
    );

    final coinsCard = SizedBox(
      height: cardHeight,
      child: _PriceCard(
        title: 'Coins',
        controller: _coinsCtrl,
        focusNode: _coinsFocus,
        accentBg: const Color(0xffe0f7fa),
        accentIconColor: const Color(0xff00acc1),
        icon: Icons.monetization_on,
        textScale: textScale,
        enabled: !_loading,
      ),
    );

    final coins2Card = SizedBox(
      height: cardHeight,
      child: _PriceCard(
        title: 'Gems',
        controller: _coins2Ctrl,
        focusNode: _coins2Focus,
        accentBg: const Color(0xffe0f7fa),
        accentIconColor: const Color(0xff00acc1),
        icon: Icons.monetization_on,
        textScale: textScale,
        enabled: !_loading,
      ),
    );

    final polyCard = SizedBox(
      height: cardHeight,
      child: _PriceCard(
        title: 'Poly Matic',
        controller: _polyCtrl,
        focusNode: _polyFocus,
        accentBg: const Color(0xfff7e8fa),
        accentIconColor: const Color(0xff9c27b0),
        icon: Icons.hexagon,
        textScale: textScale,
        enabled: !_loading,
      ),
    );

    final equalsPill = _EqualsPill(textScale: textScale);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(outerRadius),
          boxShadow: [
            BoxShadow(
              blurRadius: 10,
              offset: const Offset(0, 6),
              color: Colors.black.withOpacity(0.05),
            ),
          ],
          border: Border.all(color: Colors.grey.shade200),
        ),
        padding: const EdgeInsets.all(20),
        child: _loading
            ? Center(child: CircularProgressIndicator())
            : LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final bool vertical = width < 680;

                  final row1 = vertical
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            gemsCard,
                            const SizedBox(height: 16),
                            Center(child: equalsPill),
                            const SizedBox(height: 16),
                            coinsCard,
                          ],
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.max,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(child: gemsCard),
                            const SizedBox(width: gap),
                            equalsPill,
                            const SizedBox(width: gap),
                            Expanded(child: coinsCard),
                          ],
                        );

                  final row2 = vertical
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            coins2Card,
                            const SizedBox(height: 16),
                            Center(child: equalsPill),
                            const SizedBox(height: 16),
                            polyCard,
                          ],
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.max,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(child: coins2Card),
                            const SizedBox(width: gap),
                            equalsPill,
                            const SizedBox(width: gap),
                            Expanded(child: polyCard),
                          ],
                        );

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ADD Game Finance',
                        style: TextStyle(
                          fontSize: 22 * textScale,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade900,
                        ),
                      ),
                      const SizedBox(height: 16),
                      row1,
                      const SizedBox(height: 30),
                      row2,
                      const SizedBox(height: 32),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            padding: EdgeInsets.symmetric(
                              horizontal: 40 * textScale,
                              vertical: 20 * textScale,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.save, color: Colors.white),
                          label: Text(
                            'Apply',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16 * textScale,
                            ),
                          ),
                          onPressed: _loading ? null : _replaceInFirebase,
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}

class _PriceCard extends StatefulWidget {
  final String title;
  final TextEditingController controller;
  final FocusNode focusNode;
  final Color accentBg;
  final Color accentIconColor;
  final IconData icon;
  final double textScale;
  final bool enabled;

  const _PriceCard({
    required this.title,
    required this.controller,
    required this.focusNode,
    required this.accentBg,
    required this.accentIconColor,
    required this.icon,
    required this.textScale,
    this.enabled = true,
  });

  @override
  State<_PriceCard> createState() => _PriceCardState();
}

class _PriceCardState extends State<_PriceCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeInOut,
        padding: EdgeInsets.all(16 * widget.textScale),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16 * widget.textScale),
          boxShadow: [
            BoxShadow(
              blurRadius: _hover ? 20 : 10,
              offset: const Offset(0, 6),
              color: _hover
                  ? Colors.grey.withOpacity(0.28)
                  : Colors.black.withOpacity(0.06),
            ),
          ],
          border: _hover
              ? Border.all(color: widget.accentIconColor, width: 1.6)
              : Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + accent icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 18 * widget.textScale,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade800,
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: widget.accentBg,
                    shape: BoxShape.circle,
                  ),
                  padding: EdgeInsets.all(16 * widget.textScale),
                  child: Icon(
                    widget.icon,
                    color: widget.accentIconColor,
                    size: 32 * widget.textScale,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Price',
              style: t.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
                fontSize: 12 * widget.textScale,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 48 * widget.textScale,
              child: TextField(
                enabled: widget.enabled,
                focusNode: widget.focusNode,
                controller: widget.controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,4}')),
                ],
                decoration: InputDecoration(
                  hintText: '0',
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 14 * widget.textScale,
                    vertical: 12 * widget.textScale,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12 * widget.textScale),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12 * widget.textScale),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12 * widget.textScale),
                    borderSide: BorderSide(color: widget.accentIconColor),
                  ),
                  prefixIcon: const Icon(Icons.edit),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EqualsPill extends StatelessWidget {
  final double textScale;
  const _EqualsPill({required this.textScale});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56 * textScale,
      width: 56 * textScale,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            offset: const Offset(0, 6),
            color: Colors.black.withOpacity(0.06),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        '=',
        style: TextStyle(
          fontSize: 28 * textScale,
          fontWeight: FontWeight.w800,
          color: Colors.grey.shade700,
          height: 1,
        ),
      ),
    );
  }
}
