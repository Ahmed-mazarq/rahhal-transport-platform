import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/admin_theme.dart';
import '../../domain/models/admin_unified_document.dart';
import '../providers/admin_unified_documents_provider.dart';
import '../providers/admin_users_provider.dart';
import '../providers/admin_operations_provider.dart';
import '../../../common/models/verification_document.dart';

import 'package:rahal/core/widgets/secure_document_image.dart';
import '../../../common/constants/document_labels.dart';

class AdminDocumentsScreen extends ConsumerStatefulWidget {
  const AdminDocumentsScreen({super.key});

  @override
  ConsumerState<AdminDocumentsScreen> createState() =>
      _AdminDocumentsScreenState();
}

class _AdminDocumentsScreenState extends ConsumerState<AdminDocumentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Use the first 4 as tabs to preserve existing UX, but add others if needed or map them.
    // The prompt says "Keep the existing: بانتظار المراجعة, معتمدة, مرفوضة, منتهية الصلاحية and make them actually correspond to the unified document status. Also support يحتاج إعادة رفع, مرفوع, غير متوفر when appropriate."
    // We will keep 4 tabs and a "More" or just handle the first 4 in tabs and use dropdown for the rest, or just expand to 7 tabs. The prompt says "Do not break the existing four-tab functionality." So we keep 4 tabs.
    _tabController = TabController(length: 4, vsync: this);

    // Set initial filter to pending
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminUnifiedStatusFilterProvider.notifier).state = 'pending';
    });

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        String status;
        switch (_tabController.index) {
          case 0:
            status = 'pending';
            break;
          case 1:
            status = 'approved';
            break;
          case 2:
            status = 'rejected';
            break;
          case 3:
            status = 'expired';
            break;
          default:
            status = 'pending';
        }
        ref.read(adminUnifiedStatusFilterProvider.notifier).state = status;
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roleFilter = ref.watch(adminUnifiedRoleFilterProvider);

    return Scaffold(
      backgroundColor: AdminTheme.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'مراجعة المستندات',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                color: AdminTheme.textPrimary,
              ),
            ),
            Text(
              'مركز التحقق من بيانات ومستندات المستخدمين',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                color: AdminTheme.textSecondary,
              ),
            ),
          ],
        ),
        backgroundColor: AdminTheme.topBar,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                isScrollable: true,
                labelStyle: const TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelStyle: const TextStyle(fontFamily: 'Cairo'),
                labelColor: AdminTheme.primary,
                indicatorColor: AdminTheme.primary,
                tabs: const [
                  Tab(text: 'بانتظار المراجعة'),
                  Tab(text: 'معتمدة'),
                  Tab(text: 'مرفوضة'),
                  Tab(text: 'منتهية الصلاحية'),
                ],
              ),
              Container(color: AdminTheme.border, height: 1.0),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          _buildFilters(context, ref, roleFilter),
          Expanded(child: _UnifiedDocumentsView()),
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context, WidgetRef ref, String roleFilter) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (val) =>
                      ref.read(adminUnifiedSearchQueryProvider.notifier).state =
                          val,
                  decoration: InputDecoration(
                    hintText: 'بحث بالاسم، رقم الهاتف، الإيميل، الكود...',
                    hintStyle: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AdminTheme.textSecondary,
                    ),
                    filled: true,
                    fillColor: AdminTheme.background,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              DropdownButtonHideUnderline(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AdminTheme.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButton<String>(
                    value:
                        [
                          'all',
                          'driver',
                          'passenger',
                          'company',
                        ].contains(roleFilter)
                        ? roleFilter
                        : 'all',
                    icon: const Icon(Icons.filter_list),
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      color: AdminTheme.textPrimary,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('الكل')),
                      DropdownMenuItem(
                        value: 'driver',
                        child: Text('السائقون'),
                      ),
                      DropdownMenuItem(
                        value: 'passenger',
                        child: Text('الركاب'),
                      ),
                      DropdownMenuItem(
                        value: 'company',
                        child: Text('شركات النقل'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        ref
                                .read(adminUnifiedRoleFilterProvider.notifier)
                                .state =
                            val;
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UnifiedDocumentsView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docs = ref.watch(filteredAdminUnifiedDocumentsProvider);

    if (docs.isEmpty) {
      return const Center(
        child: Text(
          'لا توجد مستندات',
          style: TextStyle(
            fontFamily: 'Cairo',
            color: AdminTheme.textSecondary,
            fontSize: 18,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth >= 1200
            ? 4
            : (constraints.maxWidth >= 800 ? 2 : 1);

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: crossAxisCount == 1 ? 2.8 : 1.2,
            mainAxisExtent: crossAxisCount == 1
                ? 240
                : 380, // Allow more height on mobile for all texts
          ),
          itemCount: docs.length,
          itemBuilder: (context, index) => _DocumentCard(doc: docs[index]),
        );
      },
    );
  }
}

class _DocumentCard extends ConsumerWidget {
  final AdminUnifiedDocument doc;

  const _DocumentCard({required this.doc});

  String _getArabicDocumentName(String key) {
    return DocumentLabels.getLabel(key);
  }

  IconData _getIconForType(String key) {
    if (key.toLowerCase().contains('id') ||
        key.toLowerCase().contains('photo')) {
      return Icons.badge_outlined;
    }
    if (key.toLowerCase().contains('license')) {
      return Icons.card_membership_outlined;
    }
    if (key.toLowerCase().contains('vehicle')) {
      return Icons.directions_car_outlined;
    }
    if (key.toLowerCase().contains('plate')) return Icons.pin_outlined;
    if (key.toLowerCase().contains('commercial') ||
        key.toLowerCase().contains('company')) {
      return Icons.business_outlined;
    }
    if (key.toLowerCase().contains('account')) return Icons.person_outline;
    return Icons.description_outlined;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return AdminTheme.success;
      case 'rejected':
        return AdminTheme.danger;
      case 'expired':
        return Colors.deepOrange;
      case 'needs_reupload':
        return Colors.purple;
      case 'uploaded':
        return Colors.blue;
      case 'missing':
        return Colors.grey;
      case 'pending':
      default:
        return AdminTheme.warning;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'approved':
        return 'معتمد';
      case 'rejected':
        return 'مرفوض';
      case 'expired':
        return 'منتهي الصلاحية';
      case 'needs_reupload':
        return 'يحتاج إعادة رفع';
      case 'uploaded':
        return 'مرفوع';
      case 'missing':
        return 'غير متوفر';
      case 'pending':
      default:
        return 'بانتظار المراجعة';
    }
  }

  String _getRoleArabic(String role) {
    if (role == 'driver') return 'سائق';
    if (role == 'company') return 'شركة نقل';
    if (role == 'passenger' || role == 'user') return 'راكب';
    return role;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = MediaQuery.of(context).size.width < 800;

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header / Owner Info
          Container(
            padding: const EdgeInsets.all(12),
            color: AdminTheme.background.withValues(alpha: 0.5),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AdminTheme.primary.withValues(alpha: 0.1),
                  child: Icon(
                    doc.ownerRole == 'driver'
                        ? Icons.drive_eta
                        : (doc.ownerRole == 'company'
                              ? Icons.business
                              : Icons.person),
                    color: AdminTheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doc.ownerName,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'رقم الهاتف: ${doc.ownerPhone}',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11,
                          color: AdminTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AdminTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _getRoleArabic(doc.ownerRole),
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 10,
                          color: AdminTheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'الحالة: ${doc.ownerStatus}',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 10,
                        color: AdminTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1, color: AdminTheme.border),

          // Document Info
          Expanded(
            child: isMobile
                ? _buildMobileBody(context, ref)
                : _buildDesktopBody(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileBody(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AdminTheme.border),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: doc.documentUrl.isNotEmpty
                  ? _buildResolvedImage(doc.documentUrl)
                  : Icon(
                      _getIconForType(doc.documentType),
                      size: 40,
                      color: Colors.grey,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _getArabicDocumentName(doc.documentType),
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _buildBadge(),
                  ],
                ),
                const SizedBox(height: 8),
                if (doc.isMissing)
                  const Text(
                    'لا توجد مستندات مرفوعة لهذا الحساب',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      color: Colors.red,
                    ),
                  )
                else ...[
                  Text(
                    'الرفع: ${doc.uploadedAt?.toString().substring(0, 10) ?? '-'}',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      color: AdminTheme.textSecondary,
                    ),
                  ),
                  if (doc.expirationDate != null)
                    Text(
                      'الانتهاء: ${doc.expirationDate?.toString().substring(0, 10)}',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        color: Colors.deepOrange,
                      ),
                    ),
                ],
                const Spacer(),
                _buildActionButtons(context, ref, true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopBody(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // Thumbnail large
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              doc.documentUrl.isNotEmpty
                  ? _buildResolvedImage(doc.documentUrl)
                  : Container(
                      color: Colors.grey.shade100,
                      child: Icon(
                        _getIconForType(doc.documentType),
                        size: 64,
                        color: Colors.grey,
                      ),
                    ),
              Positioned(top: 8, right: 8, child: _buildBadge()),
            ],
          ),
        ),
        // Details
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getArabicDocumentName(doc.documentType),
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              if (doc.isMissing)
                const Text(
                  'لا توجد مستندات مرفوعة لهذا الحساب',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    color: Colors.red,
                  ),
                )
              else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'الرفع: ${doc.uploadedAt?.toString().substring(0, 10) ?? '-'}',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        color: AdminTheme.textSecondary,
                      ),
                    ),
                    if (doc.expirationDate != null)
                      Text(
                        'الانتهاء: ${doc.expirationDate?.toString().substring(0, 10)}',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11,
                          color: Colors.deepOrange,
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              _buildActionButtons(context, ref, false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBadge() {
    final color = _getStatusColor(doc.documentStatus);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        _getStatusLabel(doc.documentStatus),
        style: TextStyle(
          color: color,
          fontFamily: 'Cairo',
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    WidgetRef ref,
    bool isMobile,
  ) {
    if (isMobile) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            if (!doc.isMissing && doc.documentUrl.isNotEmpty)
              _buildBtn(
                'معاينة',
                Icons.visibility,
                AdminTheme.primary,
                () => _preview(context, ref),
              ),
            if (doc.documentStatus == 'pending') ...[
              _buildBtn(
                'اعتماد',
                Icons.check,
                AdminTheme.success,
                () => _updateStatus(context, ref, 'approved'),
              ),
              _buildBtn(
                'رفض',
                Icons.close,
                AdminTheme.danger,
                () => _showRejectDialog(context, ref),
              ),
            ],
            _buildBtn(
              'الملف',
              Icons.person,
              AdminTheme.secondary,
              () => _openProfile(context),
            ),
          ],
        ),
      );
    } else {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (!doc.isMissing && doc.documentUrl.isNotEmpty)
            _buildBtn(
              'معاينة',
              Icons.visibility,
              AdminTheme.primary,
              () => _preview(context, ref),
            ),
          if (doc.documentStatus == 'pending') ...[
            _buildBtn(
              'اعتماد',
              Icons.check,
              AdminTheme.success,
              () => _updateStatus(context, ref, 'approved'),
            ),
            _buildBtn(
              'رفض',
              Icons.close,
              AdminTheme.danger,
              () => _showRejectDialog(context, ref),
            ),
            _buildBtn(
              'إعادة رفع',
              Icons.refresh,
              Colors.purple,
              () => _showReuploadDialog(context, ref),
            ),
          ],
          _buildBtn(
            'فتح ملف الحساب',
            Icons.person,
            AdminTheme.secondary,
            () => _openProfile(context),
          ),
        ],
      );
    }
  }

  Widget _buildBtn(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: color.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(6),
            color: color.withValues(alpha: 0.05),
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
      ),
    );
  }

  void _preview(BuildContext context, WidgetRef ref) {
    final allDocs = ref.read(filteredAdminUnifiedDocumentsProvider);
    final ownerDocs = allDocs.where((d) => d.ownerUid == doc.ownerUid).toList();

    final viewerDocs = ownerDocs.map((d) {
      return MapEntry(
        d.documentKey,
        VerificationDocument(
          url: d.documentUrl,
          status: d.documentStatus,
          updatedAt: d.uploadedAt ?? DateTime.now(),
        ),
      );
    }).toList();

    final initialIndex = ownerDocs.indexWhere((d) => d.id == doc.id);

    context.push(
      '/admin/operations/document-viewer',
      extra: {
        'documents': viewerDocs,
        'initialIndex': initialIndex != -1 ? initialIndex : 0,
      },
    );
  }

  void _openProfile(BuildContext context) {
    if (doc.ownerRole == 'driver' || doc.ownerRole == 'company') {
      context.push('/admin/approvals/details/${doc.ownerUid}');
    } else {
      context.push('/admin/users/details/${doc.ownerUid}');
    }
  }

  Future<void> _updateStatus(
    BuildContext context,
    WidgetRef ref,
    String status, {
    String notes = '',
  }) async {
    try {
      if (doc.sourceCollection == 'drivers' ||
          doc.sourceCollection == 'companies') {
        final repo = ref.read(adminUsersRepositoryProvider);
        await repo.updateDocumentStatus(
          uid: doc.ownerUid,
          role: doc.ownerRole,
          documentKey: doc.documentKey,
          status: status,
          notes: notes,
        );
      } else {
        // Top-level document
        final repo = ref.read(adminOperationsRepositoryProvider);
        await repo.updateDocument(
          doc.sourceCollection,
          doc.id.replaceFirst('${doc.sourceCollection}_', ''),
          {'status': status, 'notes': notes},
        );
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم $status بنجاح',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: AdminTheme.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'حدث خطأ: $e',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: AdminTheme.danger,
          ),
        );
      }
    }
  }

  void _showRejectDialog(BuildContext context, WidgetRef ref) {
    final tc = TextEditingController();
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text(
          'سبب الرفض',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: tc,
          decoration: const InputDecoration(
            hintText: 'اكتب سبب الرفض...',
            hintStyle: TextStyle(fontFamily: 'Cairo'),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminTheme.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(c);
              if (tc.text.isNotEmpty) {
                _updateStatus(context, ref, 'rejected', notes: tc.text);
              }
            },
            child: const Text(
              'تأكيد الرفض',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
          ),
        ],
      ),
    );
  }

  void _showReuploadDialog(BuildContext context, WidgetRef ref) {
    final tc = TextEditingController();
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text(
          'سبب طلب إعادة الرفع',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: tc,
          decoration: const InputDecoration(
            hintText: 'اكتب السبب...',
            hintStyle: TextStyle(fontFamily: 'Cairo'),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(c);
              if (tc.text.isNotEmpty) {
                _updateStatus(context, ref, 'needs_reupload', notes: tc.text);
              }
            },
            child: const Text(
              'تأكيد الطلب',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResolvedImage(String url) {
    return SecureDocumentImage(
      storedReference: url,
      fit: BoxFit.cover,
      placeholder: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}
