import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

class AddNFTFormScreen extends StatefulWidget {
  final void Function()? onCancel;
  final void Function()? onComplete;
  final void Function(Map<String, dynamic> nftObject, String firebaseId)? onBrandComplete;
  const AddNFTFormScreen({super.key, this.onCancel, this.onComplete, this.onBrandComplete});

  @override
  State<AddNFTFormScreen> createState() => _AddNFTFormScreenState();
}

class _AddNFTFormScreenState extends State<AddNFTFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _valueController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _walletAddressController = TextEditingController();
  final _validityController = TextEditingController();

  String? selectedType;
  String? selectedCategory;
  String? selectedBrand;
  String? uploadedImageBase64;
  String? selectedBenefit;

  static const benefitOptions = [
    'Profit',
    'Cost of Operations',
    'Bonus',
    'Brand Discount',
  ];

  List<String> getCategories() {
    switch (selectedType) {
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

  void _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result != null && result.files.single.bytes != null) {
        final pickedFile = result.files.single;
        setState(() {
          uploadedImageBase64 = base64Encode(pickedFile.bytes!);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No image selected.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("File picker failed: $e")),
      );
    }
  }

  Future<Map<String, dynamic>?> _mintNftOnChain({
    required String toAddress,
    required String name,
    required String description,
    required String imageBase64,
    required Map<String, dynamic> attributes,
    required int quantity,
    required double price,
    required int validity, // Unix timestamp
  }) async {
    try {
      final url = Uri.parse('https://us-central1-marketingfruit-9e24d.cloudfunctions.net/mintNft');
      final body = {
        "name": name,
        "description": description,
        "imageBase64": imageBase64,
        "attributes": attributes,
        "quantity": quantity,
        "priceWei": (price * 1e18).toStringAsFixed(0), // convert to wei
        "validity": validity,
      };

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result["success"] == true) {
          return result;
        } else {
          debugPrint("Minting returned failure: ${response.body}");
          return null;
        }
      } else {
        debugPrint("Minting HTTP error (${response.statusCode}): ${response.body}");
        return null;
      }
    } catch (e) {
      debugPrint("Minting exception: $e");
      return null;
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate() && uploadedImageBase64 != null) {
      final wallet = await showDialog<String>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Recipient Wallet Address"),
          content: TextField(
            controller: _walletAddressController,
            decoration: const InputDecoration(labelText: "Wallet Address (0x...)"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, _walletAddressController.text.trim()),
              child: const Text("Mint"),
            ),
          ],
        ),
      );

      if (wallet == null || wallet.isEmpty || !wallet.startsWith("0x")) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter a valid wallet address.")),
        );
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      Map<String, dynamic> attributes = {
        "benefit": selectedType == "Sponsor" ? null : selectedBenefit,
        "value": selectedType == "Sponsor" ? null : double.tryParse(_valueController.text) ?? 0,
        "price": double.tryParse(_priceController.text) ?? 0,
        "quantity": int.tryParse(_quantityController.text) ?? 1,
        "type": selectedType,
        "category": selectedCategory,
        "brand": selectedType == 'Brands' ? selectedBrand : null,
      };

      // Compute validity as Unix timestamp (seconds)
      int validitySeconds = 0;
      if (_validityController.text.isNotEmpty) {
        try {
          final entered = int.tryParse(_validityController.text);
          if (entered != null && entered > 0) {
            validitySeconds = DateTime.now().add(Duration(days: entered)).millisecondsSinceEpoch ~/ 1000;
          } else {
            final dt = DateTime.tryParse(_validityController.text);
            if (dt != null) {
              validitySeconds = dt.millisecondsSinceEpoch ~/ 1000;
            }
          }
        } catch (e) {
          debugPrint('Invalid validity field: $e');
        }
      }

      final mintResult = await _mintNftOnChain(
        toAddress: wallet,
        name: _nameController.text,
        description: _descController.text,
        imageBase64: uploadedImageBase64!,
        attributes: attributes,
        quantity: int.tryParse(_quantityController.text) ?? 1,
        price: double.tryParse(_priceController.text) ?? 0,
        validity: validitySeconds,
      );

      Navigator.of(context).pop(); // Close progress

      if (mintResult == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Minting failed. Please try again.")),
        );
        return;
      }

      // Safely fetch tokenId returned by backend; fallback to 0 if not present
      final int tokenId = mintResult["tokenId"] != null
          ? int.tryParse(mintResult["tokenId"].toString()) ?? 0
          : 0;

      final nftRefKey = await _saveToFirebase(
        imageUrl: mintResult["image"] ?? "",
        metadataUrl: mintResult["tokenURI"] ?? "",
        txHash: mintResult["txHash"] ?? "",
        blockNumber: mintResult["blockNumber"] ?? 0,
        quantity: int.tryParse(_quantityController.text) ?? 1,
        price: double.tryParse(_priceController.text) ?? 0,
        validity: validitySeconds,
        tokenId: tokenId, // <-- store in database
      );

      if (nftRefKey != null && widget.onBrandComplete != null) {
        // Fetch the NFT object from Firebase to display in preview
        final dbRef = FirebaseDatabase.instance.ref('nft/$nftRefKey');
        final nftSnap = await dbRef.get();
        if (nftSnap.exists) {
          final nftObj = Map<String, dynamic>.from(nftSnap.value as Map);
          widget.onBrandComplete!(nftObj, nftRefKey);
        }
      }


      if (widget.onComplete != null) widget.onComplete!();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all the fields and upload an image.")),
      );
    }
  }

  Future<String?> _saveToFirebase({
    required String imageUrl,
    required String metadataUrl,
    required String txHash,
    required int blockNumber,
    required int quantity,
    required double price,
    required int validity,
    required int tokenId,
  }) async {
    try {
      final dbRef = FirebaseDatabase.instance.ref('nft');
      int resolvedTokenId = tokenId;

      if (resolvedTokenId == 0) {
        // Fetch all NFTs, find the one with the highest/latest timestamp, get its tokenId, and add 1
        final snapshot = await dbRef.get();
        int maxTokenId = 0;
        int latestTimestamp = 0;

        if (snapshot.exists) {
          final Map data = snapshot.value as Map;
          data.forEach((key, value) {
            final entry = value as Map;
            // Parse timestamp (as milliseconds since epoch)
            int entryTimestamp = 0;
            if (entry['timestamp'] != null) {
              try {
                entryTimestamp = DateTime.parse(entry['timestamp'].toString()).millisecondsSinceEpoch;
              } catch (_) {
                entryTimestamp = 0;
              }
            }
            // If timestamp is later, use this tokenId
            if (entryTimestamp > latestTimestamp) {
              latestTimestamp = entryTimestamp;
              maxTokenId = entry['tokenId'] is int
                  ? entry['tokenId'] as int
                  : int.tryParse(entry['tokenId']?.toString() ?? '') ?? maxTokenId;
            }
          });
        }
        resolvedTokenId = maxTokenId + 1;
      }

      final newRef = dbRef.push();
      await newRef.set({
        'name': _nameController.text,
        'description': _descController.text,
        'type': selectedType,
        'category': selectedCategory,
        'brand': selectedType == 'Brands' ? selectedBrand : null,
        'benefit': selectedType == "Sponsor" ? null : selectedBenefit,
        'value': selectedType == "Sponsor" ? null : double.tryParse(_valueController.text) ?? 0,
        'graphic': imageUrl,
        'metadata': metadataUrl,
        'active': true,
        'timestamp': DateTime.now().toIso8601String(),
        'price': price,
        'quantity': quantity,
        'validity': validity, // unix seconds
        'txHash': txHash,
        'blockNumber': blockNumber,
        'tokenId': resolvedTokenId, // always set
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("NFT minted and saved successfully!")),
      );



      _formKey.currentState!.reset();
      setState(() {
        uploadedImageBase64 = null;
        selectedType = null;
        selectedCategory = null;
        selectedBrand = null;
        selectedBenefit = null;
      });
      _priceController.clear();
      _quantityController.clear();
      _walletAddressController.clear();
      _valueController.clear();
      _validityController.clear();

      return newRef.key;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save NFT data: $e")),
      );
      return null;
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;
          final isNarrow = maxWidth < 900;
          final double sectionWidth = isNarrow ? maxWidth : maxWidth * 0.45;

          if (isNarrow) {
            return SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBasicInfoSection(theme, sectionWidth),
                      _buildPriceSection(theme, sectionWidth),
                      const SizedBox(height: 24),
                      _buildRightPanel(theme, sectionWidth),
                      const SizedBox(height: 24),
                      _buildSubmitButton(),
                    ],
                  ),
                ),
              ),
            );
          } else {
            return SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          _buildBasicInfoSection(theme, sectionWidth),
                          _buildPriceSection(theme, sectionWidth),
                        ],
                      ),
                      const SizedBox(width: 24),
                      _buildRightPanel(theme, sectionWidth),
                    ],
                  ),
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildBasicInfoSection(ThemeData theme, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: _boxDecoration(theme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Basic Info", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: "Name *", border: OutlineInputBorder()),
            validator: (val) => val == null || val.isEmpty ? "Required" : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _descController,
            decoration: const InputDecoration(labelText: "Description *", border: OutlineInputBorder()),
            maxLines: 3,
            validator: (val) => val == null || val.isEmpty ? "Required" : null,
          ),
          const SizedBox(height: 12),
          const Text("NFT Graphic"),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: uploadedImageBase64 != null
                  ? Image.memory(
                base64Decode(uploadedImageBase64!),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                const Center(child: Text("Invalid image")),
              )
                  : const Center(child: Text("+ Upload")),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSection(ThemeData theme, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 24),
      decoration: _boxDecoration(theme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Price Info", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 12),
          TextFormField(
            controller: _priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            decoration: const InputDecoration(
              labelText: "Selling price per NFT (\$) *",
              border: OutlineInputBorder(),
              hintText: "This entered price will be shown in marketplace",
              hintStyle: TextStyle(color: Colors.grey),
            ),
            validator: (val) => (val == null || val.isEmpty || double.tryParse(val) == null)
                ? "Enter a valid price"
                : null,
          ),
          const SizedBox(height: 12),
          // const Text("Quantity"),
          TextFormField(
            controller: _quantityController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(labelText: "Quantity *", border: OutlineInputBorder()),
            validator: (val) => (val == null || val.isEmpty || int.tryParse(val) == null)
                ? "Enter a valid quantity"
                : null,
          ),
          const SizedBox(height: 12),
          // const Text("Validity (days or YYYY-MM-DD, optional)"),
          TextFormField(
            controller: _validityController,
            keyboardType: TextInputType.text,
            decoration: const InputDecoration(
              labelText: "Expiry (days or YYYY-MM-DD) (optional)",
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(elevation: 10, shadowColor: Colors.black.withOpacity(0.5)),
        onPressed: _submitForm,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Text("Next"),
        ),
      ),
    );
  }

  BoxDecoration _boxDecoration(ThemeData theme) {
    return BoxDecoration(
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
    );
  }

  Widget _buildRightPanel(ThemeData theme, double width) {
    bool isBrandType = selectedType == "Brands";
    bool isSponsorType = selectedType == "Sponsor";
    return SizedBox(
      width: width,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _boxDecoration(theme),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Summary", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: "NFT Type *", border: OutlineInputBorder()),
                  items: ['Game', 'Brands', 'Sponsor']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (val) {
                    setState(() {
                      selectedType = val;
                      selectedCategory = null;
                      selectedBrand = null;
                      if (val != "Brands") selectedBrand = null;
                      if (val != "Sponsor") {
                        selectedBenefit = null;
                        _valueController.clear();
                      }
                    });
                  },
                  validator: (val) => val == null ? "Required" : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(labelText: "Category *", border: OutlineInputBorder()),
                  items: getCategories()
                      .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: isBrandType
                      ? null
                      : (val) => setState(() => selectedCategory = val),
                  validator: (val) {
                    if (isBrandType) return null;
                    return val == null ? "Required" : null;
                  },
                  disabledHint: selectedCategory != null
                      ? Text(selectedCategory!)
                      : const Text('Disabled for Brands'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  enabled: isBrandType,
                  decoration: const InputDecoration(labelText: "Brand", border: OutlineInputBorder()),
                  controller: isBrandType
                      ? TextEditingController(text: selectedBrand)
                      : null,
                  onChanged: (val) => selectedBrand = val,
                ),
                const SizedBox(height: 24),
                const Text("Attributes", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 12),
                AbsorbPointer(
                  absorbing: isSponsorType,
                  child: Opacity(
                    opacity: isSponsorType ? 0.5 : 1.0,
                    child: Column(
                      children: [
                        DropdownButtonFormField<String>(
                          value: selectedBenefit,
                          decoration: const InputDecoration(labelText: "Benefit *", border: OutlineInputBorder()),
                          items: benefitOptions
                              .map((e) => DropdownMenuItem<String>(value: e, child: Text(e)))
                              .toList(),
                          onChanged: isSponsorType ? null : (val) => setState(() => selectedBenefit = val),
                          validator: (val) {
                            if (isSponsorType) return null;
                            return val == null ? "Required" : null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          enabled: !isSponsorType,
                          controller: _valueController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                          ],
                          decoration: const InputDecoration(
                            labelText: "Value *",
                            border: OutlineInputBorder(),
                            hintText: "Enter only numeric value",
                            hintStyle: TextStyle(color: Colors.grey),
                          ),
                          validator: (val) {
                            if (isSponsorType) return null;
                            return val == null || val.isEmpty || double.tryParse(val) == null
                                ? "Enter a valid number"
                                : null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSubmitButton(),
        ],
      ),
    );
  }
}
