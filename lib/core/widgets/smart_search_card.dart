import 'package:flutter/material.dart';

class SmartSearchCard extends StatelessWidget {
  final TextEditingController originController;
  final TextEditingController destinationController;
  final DateTime travelDate;
  final int passengersCount;
  final String tripType;
  final VoidCallback onSwap;
  final VoidCallback onSearch;
  final VoidCallback onDateTap;
  final Function(int) onPassengersChanged;
  final Function(String) onTripTypeChanged;

  const SmartSearchCard({
    super.key,
    required this.originController,
    required this.destinationController,
    required this.travelDate,
    required this.passengersCount,
    required this.tripType,
    required this.onSwap,
    required this.onSearch,
    required this.onDateTap,
    required this.onPassengersChanged,
    required this.onTripTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E1E1E).withValues(alpha: 0.8)
            : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // Origin & Destination with Swap
          Stack(
            alignment: Alignment.centerLeft,
            children: [
              Column(
                children: [
                  _buildTextField(
                    context,
                    controller: originController,
                    icon: Icons.my_location,
                    hint: 'من أين؟',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    context,
                    controller: destinationController,
                    icon: Icons.location_on,
                    hint: 'إلى أين؟',
                    isDark: isDark,
                    iconColor: Colors.red,
                  ),
                ],
              ),
              Positioned(
                left: 16,
                child: GestureDetector(
                  onTap: onSwap,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade800 : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.swap_vert,
                      color: Color(0xFF0B1F3A),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Date & Passengers
          Row(
            children: [
              Expanded(
                flex: 3,
                child: GestureDetector(
                  onTap: onDateTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.grey.shade800
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 18,
                          color: Color(0xFFF5A623),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${travelDate.year}/${travelDate.month}/${travelDate.day}',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person, size: 18, color: Colors.blue),
                      const SizedBox(width: 8),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: passengersCount,
                          isDense: true,
                          icon: const SizedBox.shrink(),
                          onChanged: (val) {
                            if (val != null) onPassengersChanged(val);
                          },
                          items: [1, 2, 3, 4, 5, 6].map((e) {
                            return DropdownMenuItem<int>(
                              value: e,
                              child: Text(
                                '$e ركاب',
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 13,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Trip Type
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildTripTypeChip('عادي', 'عادي'),
                const SizedBox(width: 8),
                _buildTripTypeChip('VIP', 'vip'),
                const SizedBox(width: 8),
                _buildTripTypeChip('عائلي', 'family'),
                const SizedBox(width: 8),
                _buildTripTypeChip('نسائي', 'women'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Search Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0B1F3A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              onPressed: onSearch,
              child: const Text(
                'بحث عن رحلة',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    required bool isDark,
    Color iconColor = Colors.blue,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontFamily: 'Cairo'),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
        prefixIcon: Icon(icon, color: iconColor, size: 20),
        filled: true,
        fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }

  Widget _buildTripTypeChip(String label, String value) {
    final isSelected = tripType == value;
    return GestureDetector(
      onTap: () => onTripTypeChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF5A623) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFF5A623) : Colors.grey.shade400,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}
