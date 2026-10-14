import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/admin_system_provider.dart';

class AdminCMSScreen extends ConsumerStatefulWidget {
  const AdminCMSScreen({super.key});

  @override
  ConsumerState<AdminCMSScreen> createState() => _AdminCMSScreenState();
}

class _AdminCMSScreenState extends ConsumerState<AdminCMSScreen>
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
          'نظام إدارة المحتوى (CMS)',
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
            Tab(text: 'اللافتات الإعلانية (Banners)'),
            Tab(text: 'الأسئلة الشائعة (FAQ)'),
            Tab(text: 'سياسات التطبيق'),
            Tab(text: 'رسائل منبثقة (Popups)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _CMSTabView(type: 'banner', title: 'اللافتات الإعلانية النشطة'),
          _CMSTabView(type: 'faq', title: 'الأسئلة الشائعة'),
          _CMSTabView(type: 'policy', title: 'السياسات والشروط'),
          _CMSTabView(type: 'popup', title: 'الرسائل المنبثقة'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.add),
        label: const Text(
          'إضافة محتوى جديد',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0B1F3A),
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _CMSTabView extends ConsumerWidget {
  final String type;
  final String title;

  const _CMSTabView({required this.type, required this.title});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streamAsync = ref.watch(
      systemStreamProvider(
        SystemCollectionParams('cms_content', typeFilter: type),
      ),
    );

    return streamAsync.when(
      data: (contentList) {
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
              if (contentList.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Text(
                      'لا يوجد محتوى مضاف',
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
                  itemCount: contentList.length,
                  itemBuilder: (context, index) =>
                      _buildContentCard(context, contentList[index]),
                ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('خطأ: $e')),
    );
  }

  Widget _buildContentCard(BuildContext context, Map<String, dynamic> content) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: content['imageUrl'] != null
            ? Image.network(
                content['imageUrl'],
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              )
            : Container(
                width: 60,
                height: 60,
                color: Colors.grey.shade200,
                child: const Icon(Icons.article, color: Colors.grey),
              ),
        title: Text(
          content['title'] ?? 'بدون عنوان',
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          content['status'] == 'active' ? 'نشط' : 'غير نشط',
          style: TextStyle(
            fontFamily: 'Cairo',
            color: content['status'] == 'active' ? Colors.green : Colors.red,
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
