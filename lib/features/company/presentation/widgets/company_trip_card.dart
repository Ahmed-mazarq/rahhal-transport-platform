import 'package:flutter/material.dart';

class CompanyTripCard extends StatelessWidget {
  final String tripNumber;
  final String tripType;
  final String origin;
  final String destination;
  final String departureTime;
  final String arrivalTime;
  final String assignedDriver;
  final String assignedVehicle;
  final int totalSeats;
  final int reservedSeats;
  final double price;
  final String status;
  final VoidCallback onViewDetails;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onPauseBooking;
  final VoidCallback onCancel;
  final VoidCallback onDelete;

  const CompanyTripCard({
    super.key,
    required this.tripNumber,
    required this.tripType,
    required this.origin,
    required this.destination,
    required this.departureTime,
    required this.arrivalTime,
    required this.assignedDriver,
    required this.assignedVehicle,
    required this.totalSeats,
    required this.reservedSeats,
    required this.price,
    required this.status,
    required this.onViewDetails,
    required this.onEdit,
    required this.onDuplicate,
    required this.onPauseBooking,
    required this.onCancel,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final double occupancy = totalSeats > 0 ? reservedSeats / totalSeats : 0;

    Color statusColor;
    if (status == 'مكتملة') {
      statusColor = Colors.green;
    } else if (status == 'جارية') {
      statusColor = Colors.blue;
    } else if (status == 'مجدولة') {
      statusColor = Colors.orange;
    } else if (status == 'مسودة') {
      statusColor = Colors.grey;
    } else {
      statusColor = Colors.red;
    }

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Status & Trip Number
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.directions_bus, color: statusColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'رحلة #$tripNumber',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        tripType,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 10,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  status,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Origin and Destination
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'من',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            origin,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            departureTime,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward, color: Colors.grey),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'إلى',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            destination,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            arrivalTime,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(),
                ),

                // Driver & Vehicle info
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        Icons.person,
                        'السائق',
                        assignedDriver,
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        Icons.directions_car,
                        'المركبة',
                        assignedVehicle,
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        Icons.attach_money,
                        'السعر',
                        '$price ريال',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Seats Occupancy
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'الإشغال: ${(occupancy * 100).toInt()}%',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$reservedSeats / $totalSeats محجوز',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: occupancy,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      occupancy > 0.8
                          ? Colors.green
                          : (occupancy > 0.5 ? Colors.orange : Colors.blue),
                    ),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 16),

                // Buttons
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildActionButton(
                      'التفاصيل',
                      Icons.visibility,
                      Colors.blue,
                      onViewDetails,
                    ),
                    _buildActionButton(
                      'تعديل',
                      Icons.edit,
                      Colors.orange,
                      onEdit,
                    ),
                    _buildActionButton(
                      'تكرار',
                      Icons.copy,
                      Colors.teal,
                      onDuplicate,
                    ),
                    _buildActionButton(
                      'إيقاف الحجز',
                      Icons.pause_circle_outline,
                      Colors.brown,
                      onPauseBooking,
                    ),
                    _buildActionButton(
                      'إلغاء',
                      Icons.cancel,
                      Colors.red,
                      onCancel,
                    ),
                    _buildActionButton(
                      'حذف',
                      Icons.delete,
                      Colors.grey,
                      onDelete,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
