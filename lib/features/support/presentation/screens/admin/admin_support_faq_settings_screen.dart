import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/admin_support_providers.dart';
import '../../../../common/widgets/app_error_widget.dart';
import '../../../domain/models/support_faq.dart';

class AdminSupportFaqSettingsScreen extends StatefulWidget {
  const AdminSupportFaqSettingsScreen({super.key});

  @override
  State<AdminSupportFaqSettingsScreen> createState() =>
      _AdminSupportFaqSettingsScreenState();
}

class _AdminSupportFaqSettingsScreenState
    extends State<AdminSupportFaqSettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الأسئلة الشائعة'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'الركاب', icon: Icon(Icons.person)),
            Tab(text: 'السائقين', icon: Icon(Icons.drive_eta)),
            Tab(text: 'الشركات', icon: Icon(Icons.business)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _FaqList(userType: 'passenger'),
          _FaqList(userType: 'driver'),
          _FaqList(userType: 'company'),
        ],
      ),
    );
  }
}

class _FaqList extends ConsumerStatefulWidget {
  final String userType;
  const _FaqList({required this.userType});

  @override
  ConsumerState<_FaqList> createState() => _FaqListState();
}

class _FaqListState extends ConsumerState<_FaqList> {
  void _showFaqDialog([SupportFaq? faq]) {
    final isEditing = faq != null;
    final formKey = GlobalKey<FormState>();
    final questionCtrl = TextEditingController(text: faq?.question ?? '');
    final answerCtrl = TextEditingController(text: faq?.answer ?? '');
    final categoryCtrl = TextEditingController(text: faq?.category ?? 'عام');
    bool isActive = faq?.isActive ?? true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(isEditing ? 'تعديل سؤال' : 'إضافة سؤال جديد'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: questionCtrl,
                        decoration: const InputDecoration(labelText: 'السؤال'),
                        validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: answerCtrl,
                        decoration: const InputDecoration(labelText: 'الإجابة'),
                        maxLines: 3,
                        validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: categoryCtrl,
                        decoration: const InputDecoration(labelText: 'التصنيف'),
                        validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('نشط'),
                        value: isActive,
                        onChanged: (v) => setStateDialog(() => isActive = v),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;

                    final newFaq = SupportFaq(
                      id: faq?.id ?? '',
                      category: categoryCtrl.text.trim(),
                      question: questionCtrl.text.trim(),
                      answer: answerCtrl.text.trim(),
                      order:
                          faq?.order ?? DateTime.now().millisecondsSinceEpoch,
                      isActive: isActive,
                    );

                    try {
                      if (isEditing) {
                        await ref
                            .read(adminSupportRepositoryProvider)
                            .updateFaq(widget.userType, newFaq);
                      } else {
                        await ref
                            .read(adminSupportRepositoryProvider)
                            .addFaq(widget.userType, newFaq);
                      }
                      if (context.mounted) Navigator.pop(context);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('خطأ: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('حفظ'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteFaq(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذا السؤال؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await ref
                    .read(adminSupportRepositoryProvider)
                    .deleteFaq(widget.userType, id);
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('خطأ: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final faqsAsync = ref.watch(adminFaqsProvider(widget.userType));

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFaqDialog(),
        child: const Icon(Icons.add),
      ),
      body: faqsAsync.when(
        data: (faqs) {
          if (faqs.isEmpty) {
            return const Center(child: Text('لا توجد أسئلة شائعة'));
          }

          return ReorderableListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: faqs.length,
            onReorderItem: (oldIndex, newIndex) {
              final item = faqs.removeAt(oldIndex);
              faqs.insert(newIndex, item);

              // Update all orders
              for (int i = 0; i < faqs.length; i++) {
                if (faqs[i].order != i) {
                  final updatedFaq = faqs[i].copyWith(order: i);
                  ref
                      .read(adminSupportRepositoryProvider)
                      .updateFaq(widget.userType, updatedFaq);
                }
              }
            },
            itemBuilder: (context, index) {
              final faq = faqs[index];
              return Card(
                key: ValueKey(faq.id),
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.drag_handle),
                  title: Text(
                    faq.question,
                    style: TextStyle(
                      color: faq.isActive ? Colors.black : Colors.grey,
                    ),
                  ),
                  subtitle: Text(faq.category),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: faq.isActive,
                        onChanged: (v) {
                          ref
                              .read(adminSupportRepositoryProvider)
                              .updateFaq(
                                widget.userType,
                                faq.copyWith(isActive: v),
                              );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showFaqDialog(faq),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteFaq(faq.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => AppErrorWidget(
          message: 'حدث خطأ: $e',
          onRetry: () => ref.refresh(adminFaqsProvider(widget.userType)),
        ),
      ),
    );
  }
}
