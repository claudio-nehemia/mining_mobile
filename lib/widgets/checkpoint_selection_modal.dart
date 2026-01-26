import 'package:flutter/material.dart';
import '../config/theme_config.dart';
import '../models/checkpoint_model.dart';

class CheckpointSelectionModal extends StatefulWidget {
  final List<CheckPointModel> checkpoints;
  final Function(CheckPointModel) onCheckpointSelected;

  const CheckpointSelectionModal({
    super.key,
    required this.checkpoints,
    required this.onCheckpointSelected,
  });

  @override
  State<CheckpointSelectionModal> createState() =>
      _CheckpointSelectionModalState();
}

class _CheckpointSelectionModalState extends State<CheckpointSelectionModal> {
  String _selectedCategory = 'all';
  String _searchQuery = '';
  CheckPointModel? _selectedCheckpoint;
  bool _isProcessing = false;

  List<CheckPointModel> get _filteredCheckpoints {
    var filtered = widget.checkpoints;

    // Filter by category
    if (_selectedCategory != 'all') {
      filtered = filtered
          .where((cp) => cp.kategori.toLowerCase() == _selectedCategory)
          .toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((cp) =>
              cp.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    // Sort by distance
    filtered.sort((a, b) => a.distance.compareTo(b.distance));

    return filtered;
  }

  String _getCategoryLabel(String category) {
    switch (category.toLowerCase()) {
      case 'quarry':
        return 'Quarry';
      case 'muat':
        return 'Muat';
      case 'bongkar':
        return 'Bongkar';
      default:
        return 'Semua';
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'quarry':
        return Colors.brown;
      case 'muat':
        return Colors.blue;
      case 'bongkar':
        return Colors.green;
      default:
        return ThemeConfig.goldPrimary;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'quarry':
        return Icons.terrain;
      case 'muat':
        return Icons.upload;
      case 'bongkar':
        return Icons.download;
      default:
        return Icons.location_on;
    }
  }

  void _handleCheckpointSelection(CheckPointModel checkpoint) {
    setState(() {
      _selectedCheckpoint = checkpoint;
    });
  }

  Future<void> _confirmCheckIn() async {
    if (_selectedCheckpoint == null || _isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Close modal first
      Navigator.pop(context);
      
      // Call the callback
      await widget.onCheckpointSelected(_selectedCheckpoint!);
    } catch (e) {
      // Error handling dilakukan di parent
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredCheckpoints = _filteredCheckpoints;

    return Container(
      decoration: const BoxDecoration(
        color: ThemeConfig.bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: ThemeConfig.bgSecondary,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: ThemeConfig.goldPrimary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: ThemeConfig.goldPrimary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pilih Checkpoint',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: ThemeConfig.textPrimary,
                            ),
                          ),
                          Text(
                            'Pilih lokasi untuk check-in',
                            style: TextStyle(
                              fontSize: 12,
                              color: ThemeConfig.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                      color: ThemeConfig.textSecondary,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Search Bar
                TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  style: const TextStyle(color: ThemeConfig.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Cari checkpoint...',
                    hintStyle: TextStyle(
                      color: ThemeConfig.textSecondary.withOpacity(0.5),
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: ThemeConfig.textSecondary,
                    ),
                    filled: true,
                    fillColor: ThemeConfig.bgPrimary,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Category Filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildCategoryChip('all', 'Semua'),
                      const SizedBox(width: 8),
                      _buildCategoryChip('quarry', 'Quarry'),
                      const SizedBox(width: 8),
                      _buildCategoryChip('muat', 'Muat'),
                      const SizedBox(width: 8),
                      _buildCategoryChip('bongkar', 'Bongkar'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Checkpoint List
          Flexible(
            child: filteredCheckpoints.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 48,
                          color: ThemeConfig.textSecondary,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Tidak ada checkpoint ditemukan',
                          style: TextStyle(
                            fontSize: 14,
                            color: ThemeConfig.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredCheckpoints.length,
                    itemBuilder: (context, index) {
                      final checkpoint = filteredCheckpoints[index];
                      final isSelected = _selectedCheckpoint?.id == checkpoint.id;
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _buildCheckpointItem(checkpoint, isSelected),
                      );
                    },
                  ),
          ),

          // Bottom Action Button
          if (_selectedCheckpoint != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ThemeConfig.bgSecondary,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _confirmCheckIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ThemeConfig.goldPrimary,
                      foregroundColor: ThemeConfig.bgPrimary,
                      disabledBackgroundColor: ThemeConfig.textSecondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Check-in di ${_selectedCheckpoint!.name}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String category, String label) {
    final isSelected = _selectedCategory == category;
    final color = category == 'all'
        ? ThemeConfig.goldPrimary
        : _getCategoryColor(category);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = category;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.15)
              : ThemeConfig.bgPrimary,
          border: Border.all(
            color: isSelected ? color : ThemeConfig.borderSecondary,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? color : ThemeConfig.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildCheckpointItem(CheckPointModel checkpoint, bool isSelected) {
    final categoryColor = _getCategoryColor(checkpoint.kategori);
    final categoryIcon = _getCategoryIcon(checkpoint.kategori);
    final categoryLabel = _getCategoryLabel(checkpoint.kategori);

    return GestureDetector(
      onTap: () => _handleCheckpointSelection(checkpoint),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? ThemeConfig.goldPrimary.withOpacity(0.1)
              : ThemeConfig.bgSecondary,
          border: Border.all(
            color: isSelected
                ? ThemeConfig.goldPrimary
                : ThemeConfig.borderSecondary,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Category Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  categoryIcon,
                  color: categoryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              
              // Checkpoint Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      checkpoint.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? ThemeConfig.goldPrimary
                            : ThemeConfig.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: categoryColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            categoryLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: categoryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.location_on,
                          size: 12,
                          color: ThemeConfig.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          checkpoint.distanceText,
                          style: const TextStyle(
                            fontSize: 11,
                            color: ThemeConfig.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Selection Indicator
              if (isSelected)
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: ThemeConfig.goldPrimary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                )
              else
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: ThemeConfig.borderSecondary,
                      width: 2,
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}