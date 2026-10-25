import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';

/// ===== Models =====
enum DiscountType { percent, flat }

DiscountType _typeFromString(String s) =>
    s.toLowerCase() == 'flat' ? DiscountType.flat : DiscountType.percent;

String _typeToString(DiscountType t) => t == DiscountType.flat ? 'flat' : 'percent';

class PromoCode {
  final String id; // RTDB autoId (key)
  final String code;
  final String role;
  final String description;
  final DiscountType type;
  final double discount;
  final int quantity;
  final DateTime createdAt;

  PromoCode({
    required this.id,
    required this.code,
    required this.role,
    required this.description,
    required this.type,
    required this.discount,
    required this.quantity,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'code': code,
        'role': role,
        'description': description,
        'type': _typeToString(type),
        'discount': discount,
        'quantity': quantity,
        'createdAt': ServerValue.timestamp,
      };

  factory PromoCode.fromMap(String id, Map<dynamic, dynamic> map) {
    final createdAtMs = (map['createdAt'] is int) ? map['createdAt'] as int : DateTime.now().millisecondsSinceEpoch;
    return PromoCode(
      id: id,
      code: (map['code'] ?? '').toString(),
      role: (map['role'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      type: _typeFromString((map['type'] ?? 'percent').toString()),
      discount: (map['discount'] is num)
          ? (map['discount'] as num).toDouble()
          : double.tryParse('${map['discount']}') ?? 0,
      quantity: (map['quantity'] is num)
          ? (map['quantity'] as num).toInt()
          : int.tryParse('${map['quantity']}') ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMs),
    );
  }
}

/// ===== Page =====
class SubscriptionListPage extends StatefulWidget {
  const SubscriptionListPage({super.key});

  @override
  State<SubscriptionListPage> createState() => _SubscriptionListPageState();
}

class _SubscriptionListPageState extends State<SubscriptionListPage> {
  final DatabaseReference _root = FirebaseDatabase.instance.ref();

  final List<String> _roles = const ['Student', 'School', 'Brand', 'Guardian'];

  Map<String, String> _prices = {
    'Student': '100',
    'School': '29.99',
    'Brand': '49.99',
    'Guardian': '9.99',
  };

  List<PromoCode> _promos = [];

  bool _loadingPrices = true;
  bool _loadingPromos = true;

  @override
  void initState() {
    super.initState();
    _listenPrices();
    _listenPromos();
  }

  /// ===== RTDB: Prices =====
  void _listenPrices() async {
    final pricesRef = _root.child('subscriptions/prices');

    // Ensure defaults exist once, if node missing
    final snap = await pricesRef.get();
    if (!snap.exists) {
      final defaults = {
        'Student': '100',
        'School': '29.99',
        'Brand': '49.99',
        'Guardian': '9.99',
      };
      await pricesRef.set(defaults);
    }

    pricesRef.onValue.listen((event) {
      final data = (event.snapshot.value as Map?)?.map(
            (k, v) => MapEntry(k.toString(), v.toString()),
          ) ??
          {};
      setState(() {
        _prices = {for (final r in _roles) r: (data[r] ?? _prices[r] ?? '0')};
        _loadingPrices = false;
      });
    }, onError: (_) {
      setState(() => _loadingPrices = false);
    });
  }

  Future<void> _savePrice(String role, String newValue) async {
    final pricesRef = _root.child('subscriptions/prices/$role');
    await pricesRef.set(newValue);
  }

  /// ===== RTDB: Promos =====
  void _listenPromos() {
    final promosRef = _root.child('subscriptions/promos');

    promosRef.onValue.listen((event) {
      final map = (event.snapshot.value as Map?) ?? {};
      final list = <PromoCode>[];
      map.forEach((key, value) {
        if (value is Map) list.add(PromoCode.fromMap(key, value));
      });
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      setState(() {
        _promos = list;
        _loadingPromos = false;
      });
    }, onError: (_) {
      setState(() => _loadingPromos = false);
    });
  }

  Future<void> _addPromoToDB(PromoCode data) async {
    final ref = _root.child('subscriptions/promos').push();
    await ref.set(data.toMap());
  }

  // ===== Helpers =====
  void _editPriceDialog(BuildContext context, String role) {
    final controller = TextEditingController(text: _prices[role]);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit $role Price'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Subscription Cost',
            hintText: 'e.g. 9.99',
            border: OutlineInputBorder(),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final newValue = controller.text.trim();
              if (newValue.isEmpty || double.tryParse(newValue) == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enter a valid price')),
                );
                return;
              }
              try {
                await _savePrice(role, newValue);
                if (mounted) {
                  setState(() => _prices[role] = newValue);
                  Navigator.pop(ctx);
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to save: $e')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  String _generateCode(String role) {
    final prefix = switch (role) {
      'Student' => 'STU',
      'School' => 'SCH',
      'Brand' => 'BRN',
      'Guardian' => 'GRD',
      _ => 'GEN',
    };
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = Random.secure();
    final tail = List.generate(6, (_) => chars[rnd.nextInt(chars.length)]).join();
    return '$prefix-$tail';
  }

  void _openAddPromoDialog() {
    String selectedRole = 'Student';
    final descCtrl = TextEditingController();
    final discountCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    DiscountType type = DiscountType.percent;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Add Promo Code'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  items: const [
                    DropdownMenuItem(value: 'Student', child: Text('Student')),
                    DropdownMenuItem(value: 'School', child: Text('School')),
                    DropdownMenuItem(value: 'Brand', child: Text('Brand')),
                    DropdownMenuItem(value: 'Guardian', child: Text('Guardian')),
                  ],
                  onChanged: (v) => setLocal(() => selectedRole = v ?? 'Student'),
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'e.g. Launch offer',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<DiscountType>(
                        segments: const [
                          ButtonSegment(value: DiscountType.percent, label: Text('Percent')),
                          ButtonSegment(value: DiscountType.flat, label: Text('Flat')),
                        ],
                        selected: {type},
                        onSelectionChanged: (s) => setLocal(() => type = s.first),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 140,
                      child: TextField(
                        controller: discountCtrl,
                        decoration: InputDecoration(
                          labelText: type == DiscountType.percent ? 'Discount %' : 'Flat \$',
                          hintText: type == DiscountType.percent ? 'e.g. 20' : 'e.g. 200',
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: qtyCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Quantity',
                    hintText: 'e.g. 50',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(signed: false),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final d = double.tryParse(discountCtrl.text.trim());
                final q = int.tryParse(qtyCtrl.text.trim());
                if (d == null || d <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Enter a valid discount')),
                  );
                  return;
                }
                if (type == DiscountType.percent && (d <= 0 || d > 100)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Percent must be 1–100')),
                  );
                  return;
                }
                if (q == null || q <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Enter a valid quantity')),
                  );
                  return;
                }

                final code = _generateCode(selectedRole);
                try {
                  await _addPromoToDB(
                    PromoCode(
                      id: '_',
                      code: code,
                      role: selectedRole,
                      description: descCtrl.text.trim(),
                      type: type,
                      discount: d,
                      quantity: q,
                      createdAt: DateTime.now(),
                    ),
                  );
                  if (mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Promo created: $code')),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to create promo: $e')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  // ===== UI =====
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 14, offset: const Offset(0, 6))],
            border: Border.all(color: Colors.black.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Subscription List Page', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              // ===== Subscriptions table =====
              _TableShell(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(Colors.grey.shade200),
                      columnSpacing: 32,
                      dataRowMinHeight: 54,
                      dataRowMaxHeight: 62,
                      columns: const [
                        DataColumn(label: _Header('Type', Alignment.centerLeft)),
                        DataColumn(label: _Header('Price', Alignment.centerLeft)),
                        DataColumn(label: _Header('Edit', Alignment.centerLeft)),
                      ],
                      rows: _roles.map((role) {
                        final priceText = _loadingPrices ? '—' : '\$${_prices[role] ?? '—'}';
                        return DataRow(
                          cells: [
                            DataCell(_Cell(align: Alignment.centerLeft, child: Text(role))),
                            DataCell(_Cell(align: Alignment.centerLeft, child: Text(priceText))),
                            DataCell(
                              _Cell(
                                align: Alignment.centerLeft,
                                child: _PillButton(
                                  label: 'Edit',
                                  onPressed: _loadingPrices ? null : () => _editPriceDialog(context, role),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 6),

              // ===== Promo Codes header & Add
              Row(
                children: [
                  const Expanded(
                    child: Text('Promo Codes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  ),
                  _PillButton(icon: Icons.add, label: 'Add', onPressed: _openAddPromoDialog),
                ],
              ),
              const SizedBox(height: 12),

              // ===== Promo Codes TABLE (fills remaining height; scrolls vertically inside) =====
              Expanded(
                child: _TableShell(
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minWidth: constraints.maxWidth),
                        child: _loadingPromos
                            ? const SizedBox(
                                height: 120,
                                child: Center(child: CircularProgressIndicator()),
                              )
                            : Scrollbar(
                                thumbVisibility: true,
                                notificationPredicate: (notif) => notif.metrics.axis == Axis.vertical,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.vertical,
                                  child: DataTable(
                                    headingRowColor: WidgetStateProperty.all(Colors.grey.shade200),
                                    columnSpacing: 32,
                                    dataRowMinHeight: 50,
                                    dataRowMaxHeight: 58,
                                    columns: const [
                                      DataColumn(label: _Header('Code', Alignment.centerLeft)),
                                      DataColumn(label: _Header('Description', Alignment.centerLeft)),
                                      DataColumn(label: _Header('Role', Alignment.centerLeft)),
                                      DataColumn(label: _Header('Discount', Alignment.centerLeft)),
                                      DataColumn(label: _Header('Qty', Alignment.centerLeft)),
                                    ],
                                    rows: _promos.map((p) {
                                      final discountText = p.type == DiscountType.percent
                                          ? '${p.discount.toStringAsFixed(0)}%'
                                          : '\$${p.discount.toStringAsFixed(0)}';
                                      return DataRow(
                                        cells: [
                                          DataCell(
                                            _Cell(
                                              align: Alignment.centerLeft,
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      p.code,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  InkWell(
                                                    onTap: () async {
                                                      await Clipboard.setData(ClipboardData(text: p.code));
                                                      if (context.mounted) {
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          SnackBar(content: Text('Copied ${p.code}')),
                                                        );
                                                      }
                                                    },
                                                    borderRadius: BorderRadius.circular(16),
                                                    child: const Padding(
                                                      padding: EdgeInsets.all(6.0),
                                                      child: Icon(Icons.copy, size: 16),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          DataCell(_Cell(
                                            align: Alignment.centerLeft,
                                            child: Text(p.description.isEmpty ? '—' : p.description),
                                          )),
                                          DataCell(_Cell(align: Alignment.centerLeft, child: Text(p.role))),
                                          DataCell(_Cell(align: Alignment.centerLeft, child: Text(discountText))),
                                          DataCell(_Cell(align: Alignment.centerLeft, child: Text(p.quantity.toString()))),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// ===== Small UI helpers =====
class _Header extends StatelessWidget {
  final String text;
  final Alignment align;
  const _Header(this.text, this.align);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: align,
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

class _Cell extends StatelessWidget {
  final Widget child;
  final Alignment align;
  const _Cell({required this.child, required this.align});

  @override
  Widget build(BuildContext context) {
    return Align(alignment: align, child: child);
  }
}

class _TableShell extends StatelessWidget {
  final Widget child;
  const _TableShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black.withOpacity(0.05)),
          color: Colors.white,
        ),
        child: child,
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  const _PillButton({required this.label, required this.onPressed, this.icon});

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF4EDFF);
    const fg = Color(0xFF7B61FF);

    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: 6),
        ],
        Text(label, style: const TextStyle(color: fg, fontWeight: FontWeight.w600)),
      ],
    );

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: child,
        ),
      ),
    );
  }
}
