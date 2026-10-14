import 'package:flutter/material.dart';

class PassengerLocationPickerItem {
  final String id;
  final String titleAr;
  final String? subtitle;

  const PassengerLocationPickerItem({
    required this.id,
    required this.titleAr,
    this.subtitle,
  });
}

class PassengerLocationPickerSheet extends StatefulWidget {
  final String title;
  final List<PassengerLocationPickerItem> items;
  final String? selectedId;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final ValueChanged<PassengerLocationPickerItem> onSelected;

  const PassengerLocationPickerSheet({
    super.key,
    required this.title,
    required this.items,
    this.selectedId,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
    required this.onSelected,
  });

  static Future<PassengerLocationPickerItem?> show({
    required BuildContext context,
    required String title,
    required List<PassengerLocationPickerItem> items,
    String? selectedId,
    bool isLoading = false,
    String? errorMessage,
    VoidCallback? onRetry,
  }) {
    return showModalBottomSheet<PassengerLocationPickerItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PassengerLocationPickerSheet(
        title: title,
        items: items,
        selectedId: selectedId,
        isLoading: isLoading,
        errorMessage: errorMessage,
        onRetry: onRetry,
        onSelected: (item) => Navigator.of(context).pop(item),
      ),
    );
  }

  @override
  State<PassengerLocationPickerSheet> createState() =>
      _PassengerLocationPickerSheetState();
}

class _PassengerLocationPickerSheetState
    extends State<PassengerLocationPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _normalize(String input) {
    if (input.isEmpty) return '';
    var s = input.trim().replaceAll(RegExp(r'\s+'), ' ');
    s = s.replaceAll(RegExp(r'[أإآ]'), 'ا');
    s = s.replaceAll('ى', 'ي');
    s = s.replaceAll('ة', 'ه');
    s = s.replaceAll('ـ', '');
    return s.toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final sheetBg = isDark ? const Color(0xFF141F30) : Colors.white;
    const navyPrimary = Color(0xFF0B1F3A);
    const goldAccent = Color(0xFFF5A623);

    final filteredItems = widget.items.where((item) {
      if (_searchQuery.trim().isEmpty) return true;
      final normQuery = _normalize(_searchQuery);
      final normTitle = _normalize(item.titleAr);
      final normSub = _normalize(item.subtitle ?? '');
      return normTitle.contains(normQuery) || normSub.contains(normQuery);
    }).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            // Header title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : navyPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Search field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'ابحث هنا...',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: goldAccent,
                    size: 22,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF0B132B)
                      : const Color(0xFFF7F8FA),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Items list / state
            Expanded(
              child: widget.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: goldAccent),
                    )
                  : widget.errorMessage != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            size: 40,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            widget.errorMessage!,
                            style: const TextStyle(fontSize: 14),
                          ),
                          if (widget.onRetry != null) ...[
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: widget.onRetry,
                              child: const Text('إعادة المحاولة'),
                            ),
                          ],
                        ],
                      ),
                    )
                  : filteredItems.isEmpty
                  ? Center(
                      child: Text(
                        'لا توجد نتائج مطابقة',
                        style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.black45,
                          fontSize: 14,
                        ),
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        final isSelected = item.id == widget.selectedId;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? goldAccent.withValues(alpha: 0.12)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            border: isSelected
                                ? Border.all(color: goldAccent)
                                : null,
                          ),
                          child: ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            title: Text(
                              item.titleAr,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSelected
                                    ? (isDark ? goldAccent : navyPrimary)
                                    : (isDark ? Colors.white : Colors.black87),
                              ),
                            ),
                            subtitle: item.subtitle != null
                                ? Text(
                                    item.subtitle!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? Colors.white54
                                          : Colors.black54,
                                    ),
                                  )
                                : null,
                            trailing: isSelected
                                ? const Icon(
                                    Icons.check_circle_rounded,
                                    color: goldAccent,
                                    size: 22,
                                  )
                                : null,
                            onTap: () => widget.onSelected(item),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
