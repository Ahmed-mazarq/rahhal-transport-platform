import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/admin_system_provider.dart';

class AdminGeoManagementScreen extends ConsumerStatefulWidget {
  const AdminGeoManagementScreen({super.key});

  @override
  ConsumerState<AdminGeoManagementScreen> createState() =>
      _AdminGeoManagementScreenState();
}

class _AdminGeoManagementScreenState
    extends ConsumerState<AdminGeoManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'الإدارة الجغرافية (Geo Management)',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: const TextStyle(fontFamily: 'Cairo'),
          labelColor: const Color(0xFF0B1F3A),
          indicatorColor: const Color(0xFF0B1F3A),
          tabs: const [
            Tab(text: 'المدن والمحافظات'),
            Tab(text: 'نقاط التجمع (Stations)'),
            Tab(text: 'المسارات (Routes)'),
            Tab(text: 'مصفوفة المسافات'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _GeoTabView(
            type: 'city',
            title: 'المدن والمحافظات المدعومة',
            icon: Icons.location_city,
          ),
          _GeoTabView(
            type: 'station',
            title: 'نقاط التجمع والانطلاق',
            icon: Icons.store,
          ),
          _GeoTabView(
            type: 'route',
            title: 'مسارات الرحلات الثابتة',
            icon: Icons.route,
          ),
          _GeoTabView(
            type: 'matrix',
            title: 'مصفوفة المسافات والتسعير',
            icon: Icons.map,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.add_location_alt),
        label: const Text(
          'إضافة عنصر جغرافي',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0B1F3A),
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _GeoTabView extends ConsumerWidget {
  final String type;
  final String title;
  final IconData icon;

  const _GeoTabView({
    required this.type,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streamAsync = ref.watch(
      systemStreamProvider(
        SystemCollectionParams('geo_data', typeFilter: type),
      ),
    );

    return streamAsync.when(
      data: (geoData) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (geoData.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Text(
                      'لا توجد بيانات جغرافية',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: geoData.length,
                  itemBuilder: (context, index) =>
                      _buildGeoCard(context, geoData[index]),
                ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('خطأ: $e')),
    );
  }

  Widget _buildGeoCard(BuildContext context, Map<String, dynamic> data) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: Colors.blue.withValues(alpha: 0.1),
          child: Icon(icon, color: Colors.blue),
        ),
        title: Text(
          data['name'] ?? 'بدون اسم',
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          data['status'] == 'active' ? 'نشط' : 'غير نشط',
          style: TextStyle(
            fontFamily: 'Cairo',
            color: data['status'] == 'active' ? Colors.green : Colors.red,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.orange),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
