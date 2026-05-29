import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/item_manager_provider.dart';
import '../../providers/auth_provider.dart';
import '../../data/models/merged_item_model.dart';
import '../../core/app_theme.dart';

class ItemManagerPage extends StatefulWidget {
  const ItemManagerPage({super.key});

  @override
  State<ItemManagerPage> createState() => _ItemManagerPageState();
}

class _ItemManagerPageState extends State<ItemManagerPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().userModel;
      if (user != null) {
        context.read<ItemManagerProvider>().loadData(user.facilityId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ItemManagerProvider>();
    final currencyFormat = NumberFormat.currency(symbol: '₱', decimalDigits: 2);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Item Manager'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Filter Bar
          Container(
            padding: const EdgeInsets.all(24.0),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    onChanged: (v) => provider.updateSearch(v),
                    decoration: InputDecoration(
                      hintText: 'Search by Name or Code...',
                      prefixIcon: const Icon(Icons.search),
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    value: provider.selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Filter Category',
                      fillColor: Colors.grey.shade50,
                    ),
                    items: provider.categories.map((cat) {
                      return DropdownMenuItem(value: cat, child: Text(cat));
                    }).toList(),
                    onChanged: (v) => provider.updateCategory(v),
                  ),
                ),
                const SizedBox(width: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    final user = context.read<AuthProvider>().userModel;
                    if (user != null) {
                      provider.loadData(user.facilityId);
                    }
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('REFRESH'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Items List
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(24.0),
                    itemCount: provider.items.length,
                    itemBuilder: (context, index) {
                      return _ItemManagerCard(
                        item: provider.items[index],
                        currencyFormat: currencyFormat,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ItemManagerCard extends StatelessWidget {
  final MergedItem item;
  final NumberFormat currencyFormat;

  const _ItemManagerCard({
    required this.item,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(item.status);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Image & Basic Info
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.inventory_2_outlined, size: 40, color: Colors.grey),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.master.itemName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.master.itemCode,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                    Text(
                      item.master.category,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    _ImagePreviewButton(imageCount: item.count?.images.length ?? 0),
                  ],
                ),
              ),
              
              const VerticalDivider(width: 32, indent: 8, endIndent: 8),

              // 2. SSR Section
              Expanded(
                flex: 2,
                child: _CountDataColumn(
                  title: 'SSR',
                  cases: item.ssr?.ssrCase ?? 0,
                  subcases: item.ssr?.ssrSubcase ?? 0,
                  pieces: item.ssr?.ssrPiece ?? 0,
                  value: item.ssrValue,
                  currencyFormat: currencyFormat,
                ),
              ),

              const VerticalDivider(width: 32, indent: 8, endIndent: 8),

              // 3. Inventory Count Section
              Expanded(
                flex: 2,
                child: _CountDataColumn(
                  title: 'Inventory Count',
                  cases: item.count?.quantities.countCase ?? 0,
                  subcases: item.count?.quantities.countSubcase ?? 0,
                  pieces: item.count?.quantities.countPiece ?? 0,
                  value: item.countValue,
                  currencyFormat: currencyFormat,
                ),
              ),

              const VerticalDivider(width: 32, indent: 8, endIndent: 8),

              // 4. SSR vs Count Section
              Expanded(
                flex: 1,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'SSR vs Count',
                      style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.status,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                    const Text('Status', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Text(
                      '(${currencyFormat.format(item.discrepancyValue.abs())})',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Text('Value', style: TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Over': return Colors.blue;
      case 'Short': return AppTheme.errorColor;
      case 'Balanced': return AppTheme.successColor;
      default: return Colors.grey;
    }
  }
}

class _ImagePreviewButton extends StatelessWidget {
  final int imageCount;
  final int maxImages = 5;

  const _ImagePreviewButton({required this.imageCount});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        OutlinedButton(
          onPressed: () {
            // TODO: Show Image Gallery
          },
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          child: const Text('Images', style: TextStyle(fontSize: 12, color: Colors.black87)),
        ),
        Positioned(
          top: -8,
          right: -8,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              '$imageCount/$maxImages',
              style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}

class _CountDataColumn extends StatelessWidget {
  final String title;
  final int cases;
  final int subcases;
  final int pieces;
  final double value;
  final NumberFormat currencyFormat;

  const _CountDataColumn({
    required this.title,
    required this.cases,
    required this.subcases,
    required this.pieces,
    required this.value,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _QtyUnit(label: 'Case', value: cases),
            _QtyUnit(label: 'Subcase', value: subcases),
            _QtyUnit(label: 'Piece', value: pieces),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          currencyFormat.format(value),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const Text(
          'Value',
          style: TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }
}

class _QtyUnit extends StatelessWidget {
  final String label;
  final int value;

  const _QtyUnit({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          NumberFormat('#,###').format(value),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}
