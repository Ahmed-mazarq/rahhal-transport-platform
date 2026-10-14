import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CompanyDriversTab extends StatelessWidget {
  const CompanyDriversTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4, // Mock data
        itemBuilder: (context, index) {
          return _buildDriverCard(context, index);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/company-add-driver'),
        icon: const Icon(Icons.add),
        label: const Text(
          'إضافة سائق',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0B1F3A),
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildDriverCard(BuildContext context, int index) {
    final isOnline = index % 2 == 0;
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: const NetworkImage(
                        'https://randomuser.me/api/portraits/men/32.jpg',
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: isOnline ? Colors.green : Colors.grey,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'محمد عبدالله محمد',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 14),
                          Text(
                            ' 4.8 (120 رحلة)',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isOnline ? 'متاح للعمل' : 'مشغول برحلة',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          color: isOnline ? Colors.green : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: () => context.push('/company-driver-assignment'),
                  icon: const Icon(
                    Icons.assignment_ind,
                    size: 16,
                    color: Color(0xFF0B1F3A),
                  ),
                  label: const Text(
                    'تعيين لرحلة',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      color: Color(0xFF0B1F3A),
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.directions_car,
                    size: 16,
                    color: Colors.blue,
                  ),
                  label: const Text(
                    'تخصيص مركبة',
                    style: TextStyle(fontFamily: 'Cairo', color: Colors.blue),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
