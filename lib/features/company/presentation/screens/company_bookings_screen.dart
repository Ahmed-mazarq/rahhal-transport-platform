import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CompanyBookingsScreen extends StatefulWidget {
  const CompanyBookingsScreen({super.key});

  @override
  State<CompanyBookingsScreen> createState() => _CompanyBookingsScreenState();
}

class _CompanyBookingsScreenState extends State<CompanyBookingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: DefaultTabController(
        length: 5,
        child: Scaffold(
          appBar: AppBar(
            title: const Text(
              'إدارة الحجوزات',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
              ),
            ),
            bottom: const TabBar(
              isScrollable: true,
              labelStyle: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
              ),
              tabs: [
                Tab(text: 'قيد الانتظار'),
                Tab(text: 'مؤكد'),
                Tab(text: 'مرفوض'),
                Tab(text: 'ملغي'),
                Tab(text: 'مكتمل'),
              ],
            ),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  onChanged: (val) {},
                  decoration: InputDecoration(
                    hintText: 'ابحث برقم الحجز، الراكب، الرحلة...',
                    hintStyle: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                    ),
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF1E1E1E)
                        : Colors.white,
                  ),
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildBookingsList(context, 'قيد الانتظار', Colors.orange),
                    _buildBookingsList(context, 'مؤكد', Colors.green),
                    _buildBookingsList(context, 'مرفوض', Colors.red),
                    _buildBookingsList(context, 'ملغي', Colors.grey),
                    _buildBookingsList(context, 'مكتمل', Colors.blue),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookingsList(BuildContext context, String status, Color color) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 2, // Mock count
      itemBuilder: (context, index) {
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'BKG-9921',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(child: Icon(Icons.person)),
                  title: Text(
                    'سالم عبدالله',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'الرحلة: TRP-1002 (الرياض - جدة)\nمقعد: 12 | الدفع: تم الدفع',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 12),
                  ),
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (status == 'قيد الانتظار') ...[
                      TextButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.check, color: Colors.green),
                        label: const Text(
                          'قبول',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            color: Colors.green,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.close, color: Colors.red),
                        label: const Text(
                          'رفض',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                    TextButton.icon(
                      onPressed: () => context.push('/company-booking-details'),
                      icon: const Icon(Icons.visibility),
                      label: const Text(
                        'التفاصيل',
                        style: TextStyle(fontFamily: 'Cairo'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
