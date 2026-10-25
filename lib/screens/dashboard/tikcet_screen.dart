import 'package:flutter/material.dart';

import '../../components/ticket_search_section.dart';

class TicketsPage extends StatelessWidget {
  const TicketsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth > 1000 ? screenWidth * 0.001 : 16.0;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: 8,
      ),
      child: Column(
        children: [
          /// Ticket Search Section
          TicketSearchSection(),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Tickets",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                /// Table
                LayoutBuilder(
                  builder: (context, constraints) {
                    return Table(
                      columnWidths: const {
                        0: FlexColumnWidth(1.5), // Order ID
                        1: FlexColumnWidth(2),   // Customer
                        2: FlexColumnWidth(2.5), // Email
                        3: FlexColumnWidth(2),   // Product
                        4: FlexColumnWidth(2),   // Raised
                        5: FlexColumnWidth(2),   // Category
                        6: FlexColumnWidth(1),   // Bell
                        7: FlexColumnWidth(1.5), // Option
                      },
                      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                      children: [
                        /// Header row
                        TableRow(
                          decoration: BoxDecoration(color: Colors.grey[200]),
                          children: const [
                            Padding(
                              padding: EdgeInsets.all(12),
                              child: Text('Order ID', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            Padding(
                              padding: EdgeInsets.all(12),
                              child: Text('Customer', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            Padding(
                              padding: EdgeInsets.all(12),
                              child: Text('Email', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            Padding(
                              padding: EdgeInsets.all(12),
                              child: Text('Product', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            Padding(
                              padding: EdgeInsets.all(12),
                              child: Text('Raised', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            Padding(
                              padding: EdgeInsets.all(12),
                              child: Text('Category', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            Padding(
                              padding: EdgeInsets.all(12),
                              child: Icon(Icons.notifications, size: 20),
                            ),
                            Padding(
                              padding: EdgeInsets.all(12),
                              child: Text('Option', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),

                        /// Data rows
                        ...List.generate(8, (index) {
                          final isUnread = index % 3 == 0;
                          final isResolved = index % 2 == 0;
                          final categories = ['Student', 'Guardian', 'School', 'Brand'];
                          final raisedDate = '2025-07-${20 + index}';

                          return TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text('#ORD10$index'),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text('User $index'),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text('user$index@example.com'),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text('Item $index'),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(raisedDate),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(categories[index % categories.length]),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: isUnread
                                    ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                                    : const SizedBox(),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isResolved ? Colors.green.shade100 : Colors.orange.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    isResolved ? 'Resolved' : 'Open',
                                    style: TextStyle(
                                      color: isResolved ? Colors.green : Colors.orange,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      )
    );
  }
}
