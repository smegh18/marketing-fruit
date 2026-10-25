import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';

class BuyGameCurrencySection extends StatefulWidget {
  final double width;
  const BuyGameCurrencySection({super.key, required this.width});

  @override
  State<BuyGameCurrencySection> createState() => _BuyGameCurrencySectionState();
}

class _BuyGameCurrencySectionState extends State<BuyGameCurrencySection> {
  int? coinsPerGem; // coins per single gem ratio, fetched live from Firebase
  static const List<int> fixedGemsBundles = [99, 199, 399, 599];

  int? _customAmount;
  int? _customPriceGems;

  StreamSubscription<DatabaseEvent>? _financeSub;

  @override
  void initState() {
    super.initState();
    _listenRelationFromFirebase();
  }

  void _listenRelationFromFirebase() {
    final ref = FirebaseDatabase.instance.ref("game_finance/row1");
    _financeSub = ref.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null && data.containsKey("coins") && data.containsKey("gems")) {
        final coins = (data["coins"] as num).toDouble();
        final gems = (data["gems"] as num).toDouble();
        if (gems > 0) {
          setState(() {
            coinsPerGem = (coins / gems).round();
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _financeSub?.cancel();
    super.dispose();
  }

  int _calcCoinsForGems(int gems) {
    if (coinsPerGem == null) return 0;
    final coins = (coinsPerGem! * gems).ceil();
    return coins.clamp(1, 999999999);
  }

  int _calcGemsForCoins(int coins) {
    if (coinsPerGem == null || coinsPerGem == 0) return 0;
    final gems = (coins / coinsPerGem!).ceil();
    return gems.clamp(1, 999999999);
  }

  String _relationLabel() {
    // Shown next to the heading; updates as Firebase updates
    if (coinsPerGem == null) return "Loading relation…";
    return "1 gem ≈ $coinsPerGem coins";
  }

  List<Map<String, dynamic>> getBundles() {
    if (coinsPerGem == null) return [];

    const defaultIcons = [
      Icons.stars,
      Icons.bolt,
      Icons.diamond,
      Icons.workspace_premium,
    ];
    const defaultLabels = [
      "Starter Pack",
      "Value Pack",
      "Pro Pack",
      "Ultra Pack",
    ];

    return List<Map<String, dynamic>>.generate(fixedGemsBundles.length, (i) {
      final gems = fixedGemsBundles[i];
      return {
        'icon': defaultIcons[i],
        'label': defaultLabels[i],
        'amount': _calcCoinsForGems(gems),
        'gems': gems,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bundles = getBundles();

    final dpi = MediaQuery.of(context).devicePixelRatio;
    double scale = 1.0;
    if (dpi > 1.0 && dpi < 2.0) {
      scale = 1.2;
    } else if (dpi >= 2.0) {
      scale = 0.95;
    }

    final screenH = MediaQuery.of(context).size.height;
    final sectionH = (screenH * 0.42 * scale).clamp(330.0, 520.0);

    return Container(
      width: widget.width,
      height: sectionH,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.28),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: widget.width * 0.95,
          height: sectionH * 0.96,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row: heading + live relation
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Buy Game Currency',
                        style: GoogleFonts.poppins(
                          fontSize: 19,
                          fontWeight: FontWeight.w600,
                          color: theme.hintColor,
                        ),
                      ),
                    ),
                    // Relation chip (auto updates)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.purple.shade700, width: 0.8),
                      ),
                      child: Text(
                        _relationLabel(),
                        style: GoogleFonts.workSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.purple.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Show loading placeholder if bundles empty (fetching relation)
              if (bundles.isEmpty)
                const Expanded(child: Center(child: CupertinoActivityIndicator()))
              else
                Expanded(
                  child: widget.width < 800
                      ? ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            ...bundles.map((b) {
                              return SizedBox(
                                width: 150,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: _BundleCard(
                                    iconData: b['icon'] as IconData,
                                    label: b['label'] as String,
                                    amount: '${b['amount']} coins',
                                    priceText: '${b['gems']} gems',
                                    iconSize: 36,
                                    onTap: () {
                                      // TODO: purchase/top-up action
                                    },
                                  ),
                                ),
                              );
                            }),

                            // Custom Pack
                            SizedBox(
                              width: 150,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: _CustomPackCard(
                                  perCoinGemRate: coinsPerGem ?? 0,
                                  initialCoins: _customAmount ?? 0,
                                  onApply: (coins) {
                                    final gems = _calcGemsForCoins(coins);
                                    setState(() {
                                      _customAmount = coins;
                                      _customPriceGems = gems;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ...bundles.map((b) {
                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: _BundleCard(
                                    iconData: b['icon'] as IconData,
                                    label: b['label'] as String,
                                    amount: '${b['amount']} coins',
                                    priceText: '${b['gems']} gems',
                                    iconSize: 36,
                                    onTap: () {
                                      // TODO: purchase/top-up action
                                    },
                                  ),
                                ),
                              );
                            }),

                            // Custom Pack
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: _CustomPackCard(
                                  perCoinGemRate: coinsPerGem ?? 0,
                                  initialCoins: _customAmount ?? 0,
                                  onApply: (coins) {
                                    final gems = _calcGemsForCoins(coins);
                                    setState(() {
                                      _customAmount = coins;
                                      _customPriceGems = gems;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BundleCard extends StatelessWidget {
  final IconData iconData;
  final String label;
  final String amount;
  final String priceText;
  final double iconSize;
  final bool highlight;
  final VoidCallback? onTap;

  const _BundleCard({
    required this.iconData,
    required this.label,
    required this.amount,
    required this.priceText,
    this.iconSize = 28,
    this.highlight = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final borderColor =
        highlight ? Colors.purple.shade800 : Colors.purple.shade700;
    final chipBg =
        highlight ? Colors.purple.shade200 : Colors.purple.shade100;
    final chipFg =
        highlight ? Colors.purple.shade900 : Colors.purple.shade700;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5)),
          ],
          border: Border.all(color: borderColor, width: 1.0),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon circle
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.purple.shade200, width: 1),
              ),
              child: Icon(iconData, size: iconSize, color: borderColor),
            ),

            const SizedBox(height: 10),

            // Label
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.workSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
                color: Theme.of(context).hintColor,
              ),
            ),

            const SizedBox(height: 6),

            // Amount
            Text(
              amount,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.workSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).hintColor.withOpacity(0.95),
              ),
            ),

            const SizedBox(height: 10),

            // Price chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: chipBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                priceText,
                style: GoogleFonts.workSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: chipFg,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomPackCard extends StatefulWidget {
  final int perCoinGemRate;
  final int initialCoins;
  final void Function(int coins) onApply;

  const _CustomPackCard({
    required this.perCoinGemRate,
    required this.onApply,
    this.initialCoins = 0,
  });

  @override
  State<_CustomPackCard> createState() => _CustomPackCardState();
}

class _CustomPackCardState extends State<_CustomPackCard> {
  late final TextEditingController _coinsCtrl;
  late final TextEditingController _gemsCtrl;
  String? _error;

  int get _coins => int.tryParse(_coinsCtrl.text.trim()) ?? 0;
  int _calcGems(int coins) => widget.perCoinGemRate == 0
      ? 0
      : (coins / widget.perCoinGemRate).ceil().clamp(1, 999999999);

  @override
  void initState() {
    super.initState();
    _coinsCtrl = TextEditingController(
      text: widget.initialCoins > 0 ? '${widget.initialCoins}' : '',
    );
    _gemsCtrl = TextEditingController(text: '');
    _recompute();
  }

  @override
  void dispose() {
    _coinsCtrl.dispose();
    _gemsCtrl.dispose();
    super.dispose();
  }

  void _recompute() {
    final c = _coins;
    if (c <= 0) {
      _gemsCtrl.text = '';
      return;
    }
    _gemsCtrl.text = _calcGems(c).toString();
  }

  void _handleApply() {
    final coins = _coins;
    if (coins <= 0) {
      setState(() => _error = 'Enter a positive number.');
      return;
    }
    if (coins > 99999999) {
      setState(() => _error = 'That is too large. Try a smaller amount.');
      return;
    }
    setState(() => _error = null);
    widget.onApply(coins);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = Colors.purple.shade800;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))
        ],
        border: Border.all(color: borderColor, width: 1.1),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon + title
            Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.purple.shade200, width: 1),
            ),
            child: Icon(Icons.tune, size: 24, color: borderColor),
          ),
          const SizedBox(height: 8),
          Text(
            'Custom Pack',
            textAlign: TextAlign.center,
            style: GoogleFonts.workSans(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: theme.hintColor,
            ),
          ),
          const SizedBox(height: 12),

          // Input coins
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Coins',
              style: GoogleFonts.workSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.hintColor.withOpacity(0.9),
              ),
            ),
          ),
          const SizedBox(height: 4),
          CupertinoTextField(
            controller: _coinsCtrl,
            keyboardType: TextInputType.number,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            placeholder: 'e.g., 1500',
            decoration: BoxDecoration(
              color: theme.cardColor.withOpacity(0.9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.dividerColor),
            ),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
              setState(_recompute);
            },
          ),

          if (_error != null) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _error!,
                style: TextStyle(color: theme.colorScheme.error, fontSize: 11),
              ),
            ),
          ],

          const SizedBox(height: 10),

          // Output gems (read-only)
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Gems (≈)',
              style: GoogleFonts.workSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.hintColor.withOpacity(0.9),
              ),
            ),
          ),
          const SizedBox(height: 4),
          CupertinoTextField(
            controller: _gemsCtrl,
            enabled: false,
            readOnly: true,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            placeholder: '—',
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.purple.shade200),
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            height: 38.0,
            child: CupertinoButton.filled(
              padding: const EdgeInsets.symmetric(vertical: 8),
              borderRadius: BorderRadius.circular(10),
              onPressed: _handleApply,
              child: const Text(
                "Apply",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}
