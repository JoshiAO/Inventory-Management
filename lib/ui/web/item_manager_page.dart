import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/item_manager_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/admin_provider.dart';
import '../../data/models/merged_item_model.dart';
import '../../core/app_theme.dart';

class ItemManagerPage extends StatefulWidget {
  const ItemManagerPage({super.key});

  @override
  State<ItemManagerPage> createState() => _ItemManagerPageState();
}

class _ItemManagerPageState extends State<ItemManagerPage> {
  String? _selectedFacilityId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().userModel;
      if (user != null) {
        setState(() => _selectedFacilityId = user.facilityId);
        context.read<ItemManagerProvider>().loadData(user.facilityId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ItemManagerProvider>();
    final adminProvider = context.watch<AdminProvider>();
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
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    value: _selectedFacilityId,
                    decoration: InputDecoration(
                      labelText: 'Facility',
                      fillColor: Colors.grey.shade50,
                    ),
                    items: adminProvider.facilities.map((f) {
                      return DropdownMenuItem(value: f.id, child: Text(f.name));
                    }).toList(),
                    onChanged: (v) {
                      setState(() => _selectedFacilityId = v);
                      provider.loadData(v!);
                    },
                  ),
                ),
                const SizedBox(width: 24),
                ElevatedButton.icon(
                  onPressed: () => provider.toggleSSRFilter(!provider.showOnlyWithSSR),
                  icon: Icon(provider.showOnlyWithSSR ? Icons.filter_alt : Icons.filter_alt_off),
                  label: Text(provider.showOnlyWithSSR ? 'SHOWING SSR ONLY' : 'SHOW ALL ITEMS'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: provider.showOnlyWithSSR ? Colors.blue.shade700 : null,
                  ),
                ),
                const SizedBox(width: 24),
                IconButton(
                  onPressed: () {
                    if (_selectedFacilityId != null) {
                      provider.loadData(_selectedFacilityId!);
                    }
                  },
                  icon: const Icon(Icons.refresh),
                  tooltip: 'REFRESH',
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
                  image: item.master.imageUrl != null ? DecorationImage(
                    image: NetworkImage(item.master.imageUrl!),
                    fit: BoxFit.cover,
                  ) : null,
                ),
                child: item.master.imageUrl == null ? const Icon(Icons.inventory_2_outlined, size: 40, color: Colors.grey) : null,
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
                    _ImagePreviewButton(
                      imageCount: item.count?.images.length ?? 0,
                      images: item.count?.images ?? [],
                      itemName: item.master.itemName,
                    ),
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
  final List<String> images;
  final String itemName;
  final int maxImages = 5;

  const _ImagePreviewButton({
    required this.imageCount, 
    required this.images,
    required this.itemName,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasImages = images.isNotEmpty;
    
    return Stack(
      clipBehavior: Clip.none,
      children: [
        OutlinedButton(
          onPressed: hasImages ? () => _showGallery(context) : null,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            side: BorderSide(color: hasImages ? Colors.blue.shade300 : Colors.grey.shade300),
            backgroundColor: hasImages ? Colors.blue.withOpacity(0.02) : null,
          ),
          child: Text(
            'Images', 
            style: TextStyle(
              fontSize: 12, 
              color: hasImages ? Colors.blue : Colors.grey.shade400,
              fontWeight: hasImages ? FontWeight.bold : FontWeight.normal,
            )
          ),
        ),
        Positioned(
          top: -8,
          right: -8,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: hasImages ? Colors.blue : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: hasImages ? Colors.blue : Colors.grey.shade300),
            ),
            child: Text(
              '$imageCount/$maxImages',
              style: TextStyle(
                fontSize: 8, 
                fontWeight: FontWeight.bold, 
                color: hasImages ? Colors.white : Colors.black
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showGallery(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _ImageGalleryDialog(images: images, title: itemName),
    );
  }
}

class _ImageGalleryDialog extends StatefulWidget {
  final List<String> images;
  final String title;
  const _ImageGalleryDialog({required this.images, required this.title});

  @override
  State<_ImageGalleryDialog> createState() => _ImageGalleryDialogState();
}

class _ImageGalleryDialogState extends State<_ImageGalleryDialog> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(40),
      child: Container(
        width: 800,
        height: 600,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            // 1. Image PageView
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentIndex = index),
                itemCount: widget.images.length,
                itemBuilder: (context, index) {
                  return InteractiveViewer(
                    child: Image.network(
                      widget.images[index],
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(child: CircularProgressIndicator(color: Colors.white));
                      },
                      errorBuilder: (context, error, stackTrace) => const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.broken_image, color: Colors.white, size: 48),
                            SizedBox(height: 8),
                            Text('Failed to load image', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // 2. Header (Title + Counter)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          Text(
                            'Photo ${_currentIndex + 1} of ${widget.images.length}',
                            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
            ),

            // 3. Navigation Buttons
            if (widget.images.length > 1) ...[
              // Left
              if (_currentIndex > 0)
                Positioned(
                  left: 20,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: FloatingActionButton.small(
                      heroTag: 'prev',
                      backgroundColor: Colors.white.withOpacity(0.2),
                      elevation: 0,
                      onPressed: () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                      child: const Icon(Icons.chevron_left, color: Colors.white),
                    ),
                  ),
                ),
              // Right
              if (_currentIndex < widget.images.length - 1)
                Positioned(
                  right: 20,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: FloatingActionButton.small(
                      heroTag: 'next',
                      backgroundColor: Colors.white.withOpacity(0.2),
                      elevation: 0,
                      onPressed: () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                      child: const Icon(Icons.chevron_right, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
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
