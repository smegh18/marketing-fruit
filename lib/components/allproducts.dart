import 'package:Marketing_Fruit/ecommerce/shopsection.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AllProductsGridPage extends StatefulWidget {
  final String title;
  final void Function(WooProduct product) onProductTap;

  const AllProductsGridPage({
    super.key,
    required this.title,
    required this.onProductTap,
  });

  @override
  _AllProductsGridPageState createState() => _AllProductsGridPageState();
}

class _AllProductsGridPageState extends State<AllProductsGridPage> {
  final WooStoreApi _api = WooStoreApi();
  final int _perPage = 10;

  final List<WooProduct> _products = [];
  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 100 &&
        !_isLoading &&
        _hasMore) {
      _loadProducts();
    }
  }

  Future<void> _loadProducts() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final products = await _api.fetchProducts(
        page: _currentPage,
        perPage: _perPage,
        orderBy: 'date',
        order: 'desc',
      );

      for (var prod in products) {
        if (prod.image != null && prod.firebaseImageUrl == null) {
          prod.firebaseImageUrl = await getOrUploadFirebaseImageUrl(
            imageUrl: prod.image!,
            productId: prod.id.toString(),
          );
        }
      }

      setState(() {
        _products.addAll(products);
        _currentPage++;
        if (products.length < _perPage) {
          _hasMore = false;
        }
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = theme.cardColor;
    var scale = MediaQuery.of(context).devicePixelRatio;
    if (scale == 2.0) scale = 1.0;

    return Scaffold(
      body: _error != null
          ? Center(child: Text('Error: $_error'))
          : CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverAppBar(
  pinned: true,
  floating: false,
  snap: false,
  automaticallyImplyLeading: true, // Shows the default back button
  backgroundColor: Colors.white,
  leading: IconButton(
    icon: Icon(Icons.arrow_back, color: Colors.black),
    onPressed: () => Navigator.of(context).pop(),
  ),
  title: Text(
    widget.title.toUpperCase(),
    style: GoogleFonts.poppins(color: Colors.black),
  ),
),

                SliverPadding(
                  padding: const EdgeInsets.all(12.0),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          _buildProductCard(_products[index], scale, cardColor),
                      childCount: _products.length,
                    ),
                  ),
                ),
                if (_isLoading)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                if (!_hasMore && !_isLoading)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Center(
                        child: Text(
                          'No more products.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildProductCard(
      WooProduct product, double scale, Color cardColor) {
    return InkWell(
      onTap: () => widget.onProductTap(product),
      borderRadius: BorderRadius.circular(12 * scale),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12 * scale),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 6 * scale,
              spreadRadius: 0.8 * scale,
            ),
          ],
        ),
        padding: EdgeInsets.all(10 * scale),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10 * scale),
                child: Container(
                  color: Colors.grey[300],
                  child: product.firebaseImageUrl != null
                      ? Image.network(product.firebaseImageUrl!,
                          fit: BoxFit.cover)
                      : const Icon(Icons.image, color: Colors.grey),
                ),
              ),
            ),
            SizedBox(height: 8 * scale),
            Text(
              product.name,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12 * scale,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 4 * scale),
            Row(
              children: [
                Icon(Icons.star, size: 12 * scale, color: Colors.amber),
                SizedBox(width: 4 * scale),
                Text(
                  "${product.rating?.toStringAsFixed(1) ?? '4.0'}/5",
                  style: TextStyle(fontSize: 11 * scale),
                )
              ],
            ),
            SizedBox(height: 4 * scale),
            Row(
              children: [
                Text(
                  "\$${product.price?.toStringAsFixed(2) ?? '--'}",
                  style: TextStyle(
                    fontSize: 13 * scale,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (product.regularPrice != null &&
                    product.regularPrice != product.price) ...[
                  SizedBox(width: 6 * scale),
                  Text(
                    "\$${product.regularPrice?.toStringAsFixed(2)}",
                    style: TextStyle(
                      fontSize: 11 * scale,
                      decoration: TextDecoration.lineThrough,
                      color: Colors.grey,
                    ),
                  ),
                ],
                if (product.discount != null && product.discount! > 0) ...[
                  SizedBox(width: 6 * scale),
                  Text(
                    "-${product.discount}%",
                    style: TextStyle(color: Colors.red, fontSize: 11 * scale),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
