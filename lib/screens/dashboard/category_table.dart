import 'package:flutter/material.dart';

class CategoryTable extends StatelessWidget {
  const CategoryTable({super.key});

  @override
  Widget build(BuildContext context) {
    final columns = ['Name', 'Status', 'Actions'];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        children: [
          // Table Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Checkbox(value: false, onChanged: (_) {}),
                const SizedBox(width: 8),
                Expanded(flex: 4, child: Text(columns[0], style: _headerStyle)),
                Expanded(flex: 2, child: Text(columns[1], style: _headerStyle)),
                Expanded(flex: 2, child: Text(columns[2], style: _headerStyle)),
              ],
            ),
          ),
          const Divider(height: 0),

          // Table Rows
          ...List.generate(5, (index) => _CategoryRow(index: index)),

          const Divider(),

          // Pagination Footer
          _PaginationBar(),
        ],
      ),
    );
  }
}

const TextStyle _headerStyle = TextStyle(fontWeight: FontWeight.bold, color: Colors.black87);

class _CategoryRow extends StatelessWidget {
  final int index;

  const _CategoryRow({required this.index});

  @override
  Widget build(BuildContext context) {
    final isPublished = index % 2 == 0;
    final statusText = isPublished ? 'Published' : 'Draft';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Checkbox(value: false, onChanged: (_) {}),
          const SizedBox(width: 8),

          // Name with image
          Expanded(
            flex: 4,
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    image: const DecorationImage(
                      image: NetworkImage("https://via.placeholder.com/40"),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Text('Category ${index + 1}'),
              ],
            ),
          ),

          // Status Badge
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isPublished ? Colors.green[100] : Colors.grey[300],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  color: isPublished ? Colors.green[800] : Colors.black54,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          ),

          // Actions
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility_outlined),
                  onPressed: () {},
                  tooltip: 'View',
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () {},
                  tooltip: 'Edit',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () {},
                  tooltip: 'Delete',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      alignment: Alignment.centerRight,
      child: Wrap(
        spacing: 8,
        children: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.arrow_back_ios_new, size: 16)),
          Text('1', style: TextStyle(fontWeight: FontWeight.bold)),
          Text('2'),
          Text('3'),
          IconButton(onPressed: () {}, icon: const Icon(Icons.arrow_forward_ios, size: 16)),
        ],
      ),
    );
  }
}
