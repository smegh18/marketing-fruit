import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';

import 'add_nft_helpers_stub.dart'
if (dart.library.html) 'add_nft_helpers_web.dart';

class AddNFT extends StatefulWidget {
  final VoidCallback? onAddNFT;
  final void Function(String txnHash)? onTxnTap;
  final void Function(Map<String, dynamic> nft)? onNftTap;

  const AddNFT({super.key, this.onAddNFT, this.onNftTap, this.onTxnTap});

  @override
  State<AddNFT> createState() => _AddNFTState();
}

class _AddNFTState extends State<AddNFT> {
  String? selectedCategory;
  String? selectedType;
  String selectedTab = "All"; // Can be "All", "Drafts", "Minted", "Sold"

  List<Map<String, dynamic>> nftList = [];
  bool isLoading = true;
  String searchQuery = '';

  List<String> getTypeOptions() {
    switch (selectedCategory) {
      case 'Game':
        return ['Mechanics', 'Collectibles'];
      case 'Brands':
        return ['Nike', 'Adidas', 'Puma'];
      case 'Sponsor':
        return ['Bronze', 'Gold', 'Titanium'];
      default:
        return [];
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchNFTs();
  }

  void _fetchNFTs() async {
    final dbRef = FirebaseDatabase.instance.ref('nft');
    final snapshot = await dbRef.get();

    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);

      final List<Map<String, dynamic>> loadedNFTs = data.entries.map((entry) {
        final item = Map<String, dynamic>.from(entry.value);
        item['id'] = entry.key;
        return item;
      }).toList();

      setState(() {
        nftList = loadedNFTs;
        isLoading = false;
      });
    } else {
      setState(() {
        nftList = [];
        isLoading = false;
      });
    }
  }

  // Helper: image preview widget
  Widget buildImageCell(String? graphicUrl, {double size = 40}) {
    final displayUrl = getHttpUrlFromGraphic(graphicUrl);
    if (displayUrl == null) {
      return const Icon(Icons.broken_image, color: Colors.red);
    }
    return InkWell(
      onTap: () {
        openImageInNewTab(displayUrl); // <-- Platform safe!
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.network(
          displayUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.broken_image, color: Colors.red);
          },
          loadingBuilder: (context, widget, event) {
            if (event == null) return widget;
            return Container(
              width: size,
              height: size,
              color: Colors.grey.shade200,
              child: const Center(
                  child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))),
            );
          },
        ),
      ),
    );
  }

  // Translate firebase storage URL and ipfs://... to http (if needed)
  String? getHttpUrlFromGraphic(String? graphicField) {
    if (graphicField == null || graphicField.isEmpty) return null;
    if (graphicField.startsWith("ipfs://")) {
      return "https://gateway.pinata.cloud/ipfs/${graphicField.substring(7)}";
    }
    if (graphicField.startsWith("http://") || graphicField.startsWith("https://")) {
      return graphicField;
    }
    return graphicField;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Filtering and searching
    List<Map<String, dynamic>> filteredList = nftList.where((nft) {
      // Tab filtering
      if (selectedTab == "Drafts") return nft['active'] == false;
      if (selectedTab == "Minted") return nft['minted'] == true;
      if (selectedTab == "Sold") return nft['sold'] == true;
      // Search by name or type or category
      if (searchQuery.trim().isEmpty) return true;
      final name = (nft['name'] ?? '').toString().toLowerCase();
      final category = (nft['category'] ?? '').toString().toLowerCase();
      final type = (nft['type'] ?? '').toString().toLowerCase();
      return name.contains(searchQuery.toLowerCase()) ||
          type.contains(searchQuery.toLowerCase()) ||
          category.contains(searchQuery.toLowerCase());
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.3,
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: "Search",
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  hint: const Text("Select category"),
                  value: selectedCategory,
                  onChanged: (value) {
                    setState(() {
                      selectedCategory = value;
                      selectedType = null;
                    });
                  },
                  items: ['Game', 'Brands', 'Sponsor']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  hint: const Text("Select type"),
                  value: selectedType,
                  onChanged: (value) {
                    setState(() {
                      selectedType = value;
                    });
                  },
                  items: getTypeOptions()
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: widget.onAddNFT,
                  icon: const Icon(Icons.add),
                  label: const Text("Add NFT"),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // NFT Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "NFT",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: const Text("All"),
                      selected: selectedTab == "All",
                      onSelected: (_) => setState(() => selectedTab = "All"),
                    ),
                    FilterChip(
                      label: const Text("Drafts"),
                      selected: selectedTab == "Drafts",
                      onSelected: (_) => setState(() => selectedTab = "Drafts"),
                    ),
                    FilterChip(
                      label: const Text("Minted"),
                      selected: selectedTab == "Minted",
                      onSelected: (_) => setState(() => selectedTab = "Minted"),
                    ),
                    FilterChip(
                      label: const Text("Sold"),
                      selected: selectedTab == "Sold",
                      onSelected: (_) => setState(() => selectedTab = "Sold"),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                LayoutBuilder(
                  builder: (context, constraints) {
                    return Scrollbar(
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minWidth: constraints.maxWidth),
                            child: isLoading
                                ? const Center(child: SizedBox(height: 120, child: CircularProgressIndicator()))
                                : DataTable(
                              columnSpacing: 24,
                              columns: const [
                                DataColumn(label: Text("ID"),headingRowAlignment: MainAxisAlignment.center),
                                DataColumn(label: Text("Graphic"),headingRowAlignment: MainAxisAlignment.center),
                                DataColumn(label: Text("Name"),headingRowAlignment: MainAxisAlignment.center),
                                DataColumn(label: Text("Description"),headingRowAlignment: MainAxisAlignment.center),
                                DataColumn(label: Text("Category"),headingRowAlignment: MainAxisAlignment.center),
                                DataColumn(label: Text("Type"),headingRowAlignment: MainAxisAlignment.center),
                                DataColumn(label: Text("Active"),headingRowAlignment: MainAxisAlignment.center),
                                DataColumn(label: Text("Options"),headingRowAlignment: MainAxisAlignment.center),
                              ],
                              rows: filteredList.map((nft) {
                                return DataRow(cells: [
                                  DataCell(Center(child: Text((nft['id'] ?? '').toString().substring(0, 6)))),
                                  DataCell(
                                    Center(
                                      child: InkWell(
                                        onTap: () => widget.onNftTap?.call(nft),
                                        child: buildImageCell(nft['graphic']),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Center(
                                      child: InkWell(
                                        onTap: () => widget.onNftTap?.call(nft),
                                        child: Text(nft['name'] ?? '', style: TextStyle(
                                          color: Colors.blue,
                                          decoration: TextDecoration.underline,
                                        )),
                                      ),
                                    ),
                                  ),

                                  DataCell(Center(child: Text(nft['description'] ?? ''))),
                                  DataCell(Center(child: Text(nft['category'] ?? ''))),
                                  DataCell(Center(child: Text(nft['type'] ?? ''))),
                                  DataCell(Center(
                                    child: Switch(
                                      value: nft['active'] == true,
                                      onChanged: (val) {
                                        FirebaseDatabase.instance
                                            .ref('nft/${nft['id']}')
                                            .update({'active': val});
                                        setState(() {
                                          nft['active'] = val;
                                        });
                                      },
                                    ),
                                  )),
                                  DataCell(Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            barrierDismissible: false,
                                            builder: (ctx) => Dialog(
                                              backgroundColor: Colors.transparent,
                                              insetPadding: const EdgeInsets.all(32),
                                              child: _DeleteNFTConfirmationPopup(
                                                onConfirm: () {
                                                  Navigator.of(ctx).pop();
                                                  FirebaseDatabase.instance
                                                      .ref('nft/${nft['id']}')
                                                      .remove();
                                                  setState(() {
                                                    nftList.remove(nft);
                                                  });
                                                },
                                                onCancel: () => Navigator.of(ctx).pop(),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  )),
                                ]);
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeleteNFTConfirmationPopup extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _DeleteNFTConfirmationPopup({
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.45,
        height: MediaQuery.of(context).size.height * 0.54,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFDED08B), Color(0xFF918D64)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Are you sure you want to delete this NFT?",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "This action cannot be undone.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 22,
                color: Colors.black87,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: onConfirm,
                    child: const Text(
                      'Yes, Delete',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.black),
                      ),
                    ),
                    onPressed: onCancel,
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
