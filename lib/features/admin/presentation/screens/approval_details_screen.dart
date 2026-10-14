import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:rahal/core/theme/admin_theme.dart';
import 'package:rahal/features/common/models/user_model.dart';
import 'package:rahal/features/common/models/driver_model.dart';
import 'package:rahal/features/common/models/company_model.dart';
import 'package:rahal/features/common/models/verification_document.dart';
import 'package:rahal/features/admin/presentation/screens/document_viewer_screen.dart';
import 'package:rahal/features/admin/presentation/widgets/modification_request_dialog.dart';
import 'package:rahal/features/common/constants/modification_keys.dart';
import 'package:rahal/features/auth/presentation/providers/auth_provider.dart';
import 'package:rahal/features/admin/presentation/providers/admin_users_provider.dart';

import 'package:rahal/core/widgets/secure_document_image.dart';

class ApprovalDetailsScreen extends ConsumerStatefulWidget {
  final String uid;
  const ApprovalDetailsScreen({super.key, required this.uid});

  @override
  ConsumerState<ApprovalDetailsScreen> createState() =>
      _ApprovalDetailsScreenState();
}

class _ApprovalDetailsScreenState extends ConsumerState<ApprovalDetailsScreen> {
  UserModel? _user;
  DriverModel? _driver;
  CompanyModel? _company;
  bool _isLoading = true;
  bool _isProfileMissing = false;
  final Map<String, bool> _documentLoadState = {};
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _loadData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final currentOffset = _scrollController.hasClients
        ? _scrollController.offset
        : 0.0;
    setState(() => _isLoading = true);
    try {
      final user = await ref
          .read(adminUsersRepositoryProvider)
          .getUserById(widget.uid);
      _user = user;

      if (user != null) {
        if (user.role == 'driver') {
          var driver = await ref
              .read(adminUsersRepositoryProvider)
              .getDriverById(widget.uid);
          if (driver == null) {
            _isProfileMissing = true;
            driver = DriverModel(
              id: widget.uid,
              userId: widget.uid,
              fullName: user.name,
              phone: user.phone,
              email: user.email,
              licenseNumber: '',
              rating: 5.0,
              totalTrips: 0,
              isVerified: false,
            );
            await ref
                .read(adminUsersRepositoryProvider)
                .updateDriver(widget.uid, driver.toFirestore());
            await ref.read(adminUsersRepositoryProvider).updateUser(
              widget.uid,
              {'status': 'need_modification'},
            );
          } else {
            _isProfileMissing = false;
          }
          _driver = driver;
        } else if (user.role == 'company') {
          var company = await ref
              .read(adminUsersRepositoryProvider)
              .getCompanyById(widget.uid);
          if (company == null) {
            _isProfileMissing = true;
            company = CompanyModel(
              id: widget.uid,
              ownerId: widget.uid,
              name: user.name,
              businessType: '',
              commercialRegister: '',
              walletBalance: 0.0,
              status: 'need_modification',
            );
            await ref
                .read(adminUsersRepositoryProvider)
                .updateCompany(widget.uid, company.toFirestore());
            await ref.read(adminUsersRepositoryProvider).updateUser(
              widget.uid,
              {'status': 'need_modification'},
            );
          } else {
            _isProfileMissing = false;
          }
          _company = company;
        }
      }
    } catch (e) {
      debugPrint('Error loading approval details: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !_scrollController.hasClients) return;
          final maxOffset = _scrollController.position.maxScrollExtent;
          _scrollController.jumpTo(currentOffset.clamp(0.0, maxOffset));
        });
      }
    }
  }

  Future<void> _updateUserStatus(String status) async {
    List<String> checklist = [];
    String? customRejectedReason;

    if (status == 'need_modification') {
      final result = await showDialog<List<String>>(
        context: context,
        builder: (context) => const ModificationRequestDialog(),
      );
      if (result == null || result.isEmpty) return; // Cancelled
      checklist = result;
    } else if (status == 'rejected') {
      final controller = TextEditingController();
      final result = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(
            'سبب رفض الحساب',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'الرجاء كتابة سبب الرفض هنا...',
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'الرجاء كتابة سبب الرفض',
                        style: TextStyle(fontFamily: 'Cairo'),
                      ),
                    ),
                  );
                  return;
                }
                Navigator.pop(context, controller.text.trim());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'تأكيد الرفض',
                style: TextStyle(fontFamily: 'Cairo'),
              ),
            ),
          ],
        ),
      );
      if (result == null || result.isEmpty) return; // Cancelled
      customRejectedReason = result;
    }

    try {
      final authState = ref.read(authProvider);
      final adminId = (authState is Authenticated)
          ? authState.user.id
          : 'unknown';
      String readableReason = '';
      if (status == 'rejected' && customRejectedReason != null) {
        readableReason = customRejectedReason;
      } else if (checklist.isNotEmpty) {
        final List<String> parts = [];
        for (var item in checklist) {
          try {
            final decoded = jsonDecode(item);
            if (decoded is Map<String, dynamic>) {
              final fields = List<String>.from(decoded['fields'] ?? []);
              parts.addAll(fields.map((f) => ModificationKeys.labels[f] ?? f));
            }
          } catch (e) {
            parts.add(ModificationKeys.labels[item] ?? item);
          }
        }
        readableReason = parts.where((p) => p.isNotEmpty).join('، ');
      }

      final historyEntry = {
        'action': status,
        'adminId': adminId,
        'time': DateTime.now().toIso8601String(),
        'reason': readableReason,
      };

      final updatedHistory = List<Map<String, dynamic>>.from(
        _user!.approvalHistory,
      )..add(historyEntry);

      await ref
          .read(adminUsersRepositoryProvider)
          .updateUserStatus(
            widget.uid,
            status,
            rejectedReason: readableReason.isNotEmpty ? readableReason : null,
            modificationChecklist: checklist,
            approvalHistory: updatedHistory,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث حالة المستخدم بنجاح')),
      );
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطأ: $e')));
    }
  }

  Future<void> _updateDocStatus(String docKey, String newStatus) async {
    if (newStatus == 'needs_reupload') {
      final controller = TextEditingController();
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(
            'سبب طلب التعديل',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            maxLines: 2,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _performDocUpdate(docKey, newStatus, controller.text);
              },
              child: const Text('تأكيد'),
            ),
          ],
        ),
      );
    } else {
      await _performDocUpdate(docKey, newStatus, '');
    }
  }

  Future<void> _performDocUpdate(
    String docKey,
    String newStatus,
    String notes,
  ) async {
    try {
      await ref
          .read(adminUsersRepositoryProvider)
          .updateDocumentStatus(
            uid: widget.uid,
            role: _user!.role,
            documentKey: docKey,
            status: newStatus,
            notes: notes,
          );
      if (!mounted) return;

      if (_user?.role == 'driver' && _driver != null) {
        final currentDoc = _driver!.documents[docKey];
        if (currentDoc != null) {
          final updatedDoc = currentDoc.copyWith(
            status: newStatus,
            notes: notes,
            updatedAt: DateTime.now(),
          );
          final updatedDocs = Map<String, VerificationDocument>.from(
            _driver!.documents,
          );
          updatedDocs[docKey] = updatedDoc;

          setState(() {
            _driver = _driver!.copyWith(documents: updatedDocs);
          });
        }
      } else if (_user?.role == 'company' && _company != null) {
        final currentDoc = _company!.documents[docKey];
        if (currentDoc != null) {
          final updatedDoc = currentDoc.copyWith(
            status: newStatus,
            notes: notes,
            updatedAt: DateTime.now(),
          );
          final updatedDocs = Map<String, VerificationDocument>.from(
            _company!.documents,
          );
          updatedDocs[docKey] = updatedDoc;

          setState(() {
            _company = _company!.copyWith(documents: updatedDocs);
          });
        }
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم تحديث حالة المستند')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطأ: $e')));
    }
  }

  Widget _buildMissingProfileWarning(String role) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.red.shade700,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ملف ال$role غير مكتمل',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'تم إنشاء حساب المستخدم، ولكن بيانات ال$role الأساسية مفقودة أو لم تكتمل عملية التسجيل. يمكنك طلب تعديلات من المستخدم لاستكمال التسجيل.',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AdminTheme.primary,
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    bool isInvalid = false,
    String? errorBadge,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Cairo',
                color: isInvalid || errorBadge != null
                    ? Colors.red
                    : AdminTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w600,
                      color: isInvalid || errorBadge != null
                          ? Colors.red
                          : null,
                    ),
                  ),
                ),
                if (errorBadge != null)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.red),
                    ),
                    child: Text(
                      errorBadge,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 10,
                        color: Colors.red,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocCard(
    String label,
    String docKey,
    Map<String, VerificationDocument> docs, {
    List<String>? viewerDocumentKeys,
  }) {
    final doc = docs[docKey];
    if (doc == null || doc.url.isEmpty) {
      return Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 200,
                width: double.infinity,
                color: Colors.red[50],
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red),
                    SizedBox(height: 8),
                    Text(
                      'المستند مفقود',
                      style: TextStyle(fontFamily: 'Cairo', color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    Color statusColor;
    String statusLabel;
    switch (doc.status) {
      case 'approved':
        statusColor = Colors.green;
        statusLabel = 'معتمد';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusLabel = 'مرفوض';
        break;
      case 'needs_reupload':
        statusColor = Colors.orange;
        statusLabel = 'مطلوب تعديل';
        break;
      default:
        statusColor = Colors.blue;
        statusLabel = 'قيد المراجعة';
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
              ],
            ),
            if (doc.notes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'ملاحظة: ${doc.notes}',
                  style: const TextStyle(
                    color: Colors.red,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                List<MapEntry<String, VerificationDocument>> viewerDocs;
                int initialIndex;

                if (viewerDocumentKeys != null) {
                  viewerDocs = viewerDocumentKeys
                      .map((k) => MapEntry(k, docs[k]))
                      .where((e) => e.value != null)
                      .cast<MapEntry<String, VerificationDocument>>()
                      .toList();
                  initialIndex = viewerDocs.indexWhere((e) => e.key == docKey);
                  if (initialIndex == -1) initialIndex = 0;
                } else {
                  viewerDocs = docs.entries.toList();
                  initialIndex = docs.keys.toList().indexOf(docKey);
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DocumentViewerScreen(
                      documents: viewerDocs,
                      initialIndex: initialIndex,
                    ),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: SecureDocumentImage(
                    storedReference: doc.url,
                    fit: BoxFit.cover,
                    placeholder: Container(
                      height: 200,
                      width: double.infinity,
                      color: Colors.grey[200],
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    onLoaded: (success) {
                      if (!mounted) return;
                      if (_documentLoadState[docKey] != success) {
                        setState(() {
                          _documentLoadState[docKey] = success;
                        });
                      }
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (doc.status == 'approved')
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                alignment: Alignment.center,
                child: const Text(
                  '✓ تم اعتماد المرفق',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _documentLoadState[docKey] == true
                        ? Colors.green
                        : Colors.grey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: _documentLoadState[docKey] == true
                      ? () => _updateDocStatus(docKey, 'approved')
                      : null,
                  child: Text(
                    _documentLoadState[docKey] == true
                        ? 'اعتماد المرفق'
                        : 'غير متوفر للاعتماد',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String? _getDateError(String dateString) {
    if (dateString.isEmpty) return 'تاريخ غير صالح';
    try {
      final date = DateTime.parse(dateString);
      if (date.isBefore(DateTime.now())) {
        return 'منتهي الصلاحية';
      }
      return null;
    } catch (e) {
      if (dateString.length == 4 && int.tryParse(dateString) != null) {
        int year = int.parse(dateString);
        if (year < DateTime.now().year) {
          return 'منتهي الصلاحية';
        }
        return null;
      }
      return 'تاريخ غير صالح';
    }
  }

  Widget _buildDriverDetails(DriverModel driver) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExpansionTile(
          title: const Text(
            'المعلومات الشخصية',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              color: AdminTheme.primary,
            ),
          ),
          initiallyExpanded: true,
          children: [
            _buildInfoRow(
              'الاسم بالكامل',
              driver.fullName,
              isInvalid: driver.fullName.isEmpty,
            ),
            _buildInfoRow(
              'رقم الهاتف',
              driver.phone,
              isInvalid: driver.phone.isEmpty,
            ),
            _buildInfoRow(
              'البريد الإلكتروني',
              driver.email,
              isInvalid: driver.email.isEmpty,
            ),
            _buildInfoRow(
              'الجنسية',
              driver.nationality,
              isInvalid: driver.nationality.isEmpty,
            ),
            _buildInfoRow(
              'الجنس',
              driver.gender,
              isInvalid: driver.gender.isEmpty,
            ),
            _buildInfoRow(
              'تاريخ الميلاد',
              driver.dateOfBirth,
              isInvalid: driver.dateOfBirth.isEmpty,
            ),
            _buildInfoRow(
              'الدولة',
              driver.country,
              isInvalid: driver.country.isEmpty,
            ),
            _buildInfoRow(
              'المحافظة',
              driver.governorate,
              isInvalid: driver.governorate.isEmpty,
            ),
            _buildInfoRow(
              'المدينة',
              driver.city,
              isInvalid: driver.city.isEmpty,
            ),
            _buildInfoRow(
              'العنوان',
              driver.detailedAddress,
              isInvalid: driver.detailedAddress.isEmpty,
            ),
            _buildInfoRow('هاتف إضافي', driver.secondaryPhone),
            _buildDocCard(
              'الصورة الشخصية',
              'personalPhoto',
              driver.documents,
              viewerDocumentKeys: ['personalPhoto'],
            ),
          ],
        ),

        ExpansionTile(
          title: const Text(
            'بيانات الجواز / الهوية',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              color: AdminTheme.primary,
            ),
          ),
          children: [
            _buildInfoRow(
              'رقم الجواز',
              driver.passportNumber,
              isInvalid: driver.passportNumber.isEmpty,
            ),
            _buildInfoRow(
              'انتهاء الجواز',
              driver.passportExpiry,
              errorBadge: _getDateError(driver.passportExpiry),
            ),
            _buildDocCard(
              'صورة الجواز الأمامية',
              'idFront',
              driver.documents,
              viewerDocumentKeys: ['idFront', 'idBack'],
            ),
            _buildDocCard(
              'صورة الجواز الخلفية',
              'idBack',
              driver.documents,
              viewerDocumentKeys: ['idFront', 'idBack'],
            ),
          ],
        ),

        ExpansionTile(
          title: const Text(
            'رخصة القيادة',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              color: AdminTheme.primary,
            ),
          ),
          children: [
            _buildInfoRow(
              'رقم الرخصة',
              driver.licenseNumber,
              isInvalid: driver.licenseNumber.isEmpty,
            ),
            _buildInfoRow(
              'نوع الرخصة',
              driver.licenseType,
              isInvalid: driver.licenseType.isEmpty,
            ),
            _buildInfoRow(
              'دولة الإصدار',
              driver.licenseCountry,
              isInvalid: driver.licenseCountry.isEmpty,
            ),
            _buildInfoRow(
              'تاريخ الإصدار',
              driver.licenseIssueDate,
              isInvalid: driver.licenseIssueDate.isEmpty,
            ),
            _buildInfoRow(
              'تاريخ الانتهاء',
              driver.licenseExpiryDate,
              errorBadge: _getDateError(driver.licenseExpiryDate),
            ),
            _buildDocCard(
              'الرخصة - أمامي',
              'licenseFront',
              driver.documents,
              viewerDocumentKeys: ['licenseFront', 'licenseBack'],
            ),
            _buildDocCard(
              'الرخصة - خلفي',
              'licenseBack',
              driver.documents,
              viewerDocumentKeys: ['licenseFront', 'licenseBack'],
            ),
          ],
        ),

        ExpansionTile(
          title: const Text(
            'المركبة',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              color: AdminTheme.primary,
            ),
          ),
          children: [
            _buildInfoRow(
              'النوع',
              driver.vehicleType,
              isInvalid: driver.vehicleType.isEmpty,
            ),
            _buildInfoRow(
              'نوع الوقود',
              driver.fuelType,
              isInvalid: driver.fuelType.isEmpty,
            ),
            _buildInfoRow(
              'الشركة المصنعة',
              driver.vehicleManufacturer,
              isInvalid: driver.vehicleManufacturer.isEmpty,
            ),
            _buildInfoRow(
              'الموديل',
              driver.vehicleModel,
              isInvalid: driver.vehicleModel.isEmpty,
            ),
            _buildInfoRow(
              'سنة الصنع',
              driver.vehicleYear,
              isInvalid: driver.vehicleYear.isEmpty,
            ),
            _buildInfoRow(
              'اللون',
              driver.vehicleColor,
              isInvalid: driver.vehicleColor.isEmpty,
            ),
            _buildInfoRow(
              'رقم اللوحة',
              driver.plateNumber,
              isInvalid: driver.plateNumber.isEmpty,
            ),
            _buildInfoRow(
              'دولة اللوحة',
              driver.plateCountry,
              isInvalid: driver.plateCountry.isEmpty,
            ),
            _buildInfoRow(
              'عدد المقاعد',
              driver.seatCount.toString(),
              isInvalid: driver.seatCount <= 0,
            ),
            _buildInfoRow(
              'رقم الشاصي',
              driver.vin,
              isInvalid: driver.vin.isEmpty,
            ),
            _buildDocCard(
              'المركبة - أمامي',
              'vehicleFront',
              driver.documents,
              viewerDocumentKeys: [
                'vehicleFront',
                'vehicleBack',
                'vehicleRight',
                'vehicleLeft',
                'vehicleInterior',
                'vehiclePlate',
              ],
            ),
            _buildDocCard(
              'المركبة - خلفي',
              'vehicleBack',
              driver.documents,
              viewerDocumentKeys: [
                'vehicleFront',
                'vehicleBack',
                'vehicleRight',
                'vehicleLeft',
                'vehicleInterior',
                'vehiclePlate',
              ],
            ),
            _buildDocCard(
              'المركبة - يمين',
              'vehicleRight',
              driver.documents,
              viewerDocumentKeys: [
                'vehicleFront',
                'vehicleBack',
                'vehicleRight',
                'vehicleLeft',
                'vehicleInterior',
                'vehiclePlate',
              ],
            ),
            _buildDocCard(
              'المركبة - يسار',
              'vehicleLeft',
              driver.documents,
              viewerDocumentKeys: [
                'vehicleFront',
                'vehicleBack',
                'vehicleRight',
                'vehicleLeft',
                'vehicleInterior',
                'vehiclePlate',
              ],
            ),
            _buildDocCard(
              'المركبة - داخلي',
              'vehicleInterior',
              driver.documents,
              viewerDocumentKeys: [
                'vehicleFront',
                'vehicleBack',
                'vehicleRight',
                'vehicleLeft',
                'vehicleInterior',
                'vehiclePlate',
              ],
            ),
            _buildDocCard(
              'لوحة المركبة',
              'vehiclePlate',
              driver.documents,
              viewerDocumentKeys: [
                'vehicleFront',
                'vehicleBack',
                'vehicleRight',
                'vehicleLeft',
                'vehicleInterior',
                'vehiclePlate',
              ],
            ),
          ],
        ),

        ExpansionTile(
          title: const Text(
            'الاستمارة والتأمين',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              color: AdminTheme.primary,
            ),
          ),
          children: [
            _buildInfoRow(
              'رقم الاستمارة',
              driver.registrationNumber,
              isInvalid: driver.registrationNumber.isEmpty,
            ),
            _buildInfoRow(
              'انتهاء الاستمارة',
              driver.registrationExpiry,
              errorBadge: _getDateError(driver.registrationExpiry),
            ),
            _buildInfoRow(
              'رقم التأمين',
              driver.insuranceNumber,
              isInvalid: driver.insuranceNumber.isEmpty,
            ),
            _buildInfoRow(
              'انتهاء التأمين',
              driver.insuranceExpiry,
              errorBadge: _getDateError(driver.insuranceExpiry),
            ),
            if (driver.documents.containsKey('insuranceDoc') &&
                driver.documents['insuranceDoc']!.url.isNotEmpty)
              _buildDocCard(
                'التأمين',
                'insuranceDoc',
                driver.documents,
                viewerDocumentKeys: ['insuranceDoc'],
              ),
          ],
        ),

        ExpansionTile(
          title: const Text(
            'الطوارئ',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              color: AdminTheme.primary,
            ),
          ),
          children: [
            _buildInfoRow('الاسم', driver.emergencyContactName),
            _buildInfoRow('صلة القرابة', driver.emergencyContactRelation),
            _buildInfoRow('الهاتف', driver.emergencyContactPhone),
          ],
        ),

        ExpansionTile(
          title: const Text(
            'التشغيل',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              color: AdminTheme.primary,
            ),
          ),
          children: [
            _buildInfoRow(
              'مناطق التشغيل',
              driver.operatingAreas.join('، '),
              isInvalid: driver.operatingAreas.isEmpty,
            ),
          ],
        ),

        ExpansionTile(
          title: const Text(
            'البيانات المالية',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              color: AdminTheme.primary,
            ),
          ),
          children: [
            _buildInfoRow('رصيد المحفظة', '${driver.walletBalance} ريال'),
            _buildInfoRow('البنك', driver.bankName),
            _buildInfoRow('اسم الحساب', driver.accountHolder),
            _buildInfoRow('رقم الحساب', driver.accountNumber),
            _buildInfoRow('الآيبان', driver.iban),
            _buildInfoRow('المحفظة الإلكترونية', driver.ewalletName),
            _buildInfoRow('رقم المحفظة', driver.ewalletNumber),
          ],
        ),
      ],
    );
  }

  Widget _buildCompanyDetails(CompanyModel company) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExpansionTile(
          title: const Text(
            'المسؤول',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              color: AdminTheme.primary,
            ),
          ),
          initiallyExpanded: true,
          children: [
            _buildInfoRow(
              'الاسم',
              company.managerName,
              isInvalid: company.managerName.isEmpty,
            ),
            _buildInfoRow(
              'الهاتف',
              company.managerPhone,
              isInvalid: company.managerPhone.isEmpty,
            ),
            _buildInfoRow(
              'المنصب',
              company.managerPosition,
              isInvalid: company.managerPosition.isEmpty,
            ),
            _buildInfoRow(
              'الجنسية',
              company.managerNationality,
              isInvalid: company.managerNationality.isEmpty,
            ),
            _buildInfoRow(
              'رقم الجواز',
              company.managerPassportNumber,
              isInvalid: company.managerPassportNumber.isEmpty,
            ),
          ],
        ),

        ExpansionTile(
          title: const Text(
            'معلومات الشركة',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              color: AdminTheme.primary,
            ),
          ),
          children: [
            _buildInfoRow(
              'اسم الشركة',
              company.name,
              isInvalid: company.name.isEmpty,
            ),
            _buildInfoRow(
              'نوع النشاط',
              company.businessType,
              isInvalid: company.businessType.isEmpty,
            ),
            _buildInfoRow(
              'وصف الشركة',
              company.companyDescription,
              isInvalid: company.companyDescription.isEmpty,
            ),
            _buildInfoRow(
              'سنة التأسيس',
              company.establishmentYear,
              isInvalid: company.establishmentYear.isEmpty,
            ),
            _buildInfoRow(
              'عدد الفروع',
              company.branchCount.toString(),
              isInvalid: company.branchCount <= 0,
            ),
            _buildInfoRow(
              'عدد المركبات',
              company.fleetSize.toString(),
              isInvalid: company.fleetSize <= 0,
            ),
            _buildInfoRow(
              'عدد السائقين',
              company.driverCount.toString(),
              isInvalid: company.driverCount <= 0,
            ),
          ],
        ),

        ExpansionTile(
          title: const Text(
            'التواصل والعنوان',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              color: AdminTheme.primary,
            ),
          ),
          children: [
            _buildInfoRow(
              'هاتف الشركة',
              company.companyPhone,
              isInvalid: company.companyPhone.isEmpty,
            ),
            _buildInfoRow('هاتف بديل', company.alternativePhone),
            _buildInfoRow(
              'الدولة',
              company.country,
              isInvalid: company.country.isEmpty,
            ),
            _buildInfoRow(
              'المحافظة',
              company.governorate,
              isInvalid: company.governorate.isEmpty,
            ),
            _buildInfoRow(
              'المدينة',
              company.mainCity,
              isInvalid: company.mainCity.isEmpty,
            ),
            _buildInfoRow(
              'العنوان',
              company.detailedAddress,
              isInvalid: company.detailedAddress.isEmpty,
            ),
          ],
        ),

        ExpansionTile(
          title: const Text(
            'التسجيل والتراخيص',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              color: AdminTheme.primary,
            ),
          ),
          children: [
            _buildInfoRow(
              'رقم السجل التجاري',
              company.commercialRegister,
              isInvalid: company.commercialRegister.isEmpty,
            ),
            _buildInfoRow(
              'انتهاء السجل',
              company.registrationExpiry,
              errorBadge: _getDateError(company.registrationExpiry),
            ),
            _buildInfoRow(
              'الرقم الضريبي',
              company.taxNumber,
              isInvalid: company.taxNumber.isEmpty,
            ),
            _buildInfoRow(
              'رخصة المزاولة',
              company.operatingLicense,
              isInvalid: company.operatingLicense.isEmpty,
            ),
            _buildInfoRow(
              'انتهاء الرخصة',
              company.licenseExpiry,
              errorBadge: _getDateError(company.licenseExpiry),
            ),
          ],
        ),

        ExpansionTile(
          title: const Text(
            'البيانات المالية',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              color: AdminTheme.primary,
            ),
          ),
          children: [
            _buildInfoRow('رصيد المحفظة', '${company.walletBalance} ريال'),
            _buildInfoRow('البنك', company.bankName),
            _buildInfoRow('اسم الحساب', company.accountHolder),
            _buildInfoRow('رقم الحساب', company.accountNumber),
            _buildInfoRow('الآيبان', company.iban),
            _buildInfoRow('المحفظة الإلكترونية', company.ewalletName),
            _buildInfoRow('رقم المحفظة', company.ewalletNumber),
          ],
        ),

        ExpansionTile(
          title: const Text(
            'الوثائق والمرفقات',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              color: AdminTheme.primary,
            ),
          ),
          children: [
            _buildDocCard('شعار الشركة', 'companyLogo', company.documents),
            _buildDocCard('هوية المدير', 'managerId', company.documents),
            _buildDocCard(
              'السجل التجاري',
              'commercialRegistration',
              company.documents,
            ),
            _buildDocCard(
              'رخصة المزاولة',
              'operatingLicense',
              company.documents,
            ),
            _buildDocCard('واجهة المكتب', 'officeFront', company.documents),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeline(UserModel user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('سجل الحالات'),
        _buildTimelineTile(
          'إنشاء الحساب',
          user.createdAt.toString().split(' ')[0],
          true,
        ),
        if (user.reviewedAt != null)
          _buildTimelineTile(
            'تمت المراجعة',
            user.reviewedAt.toString().split(' ')[0],
            true,
          ),
        if (user.status == 'approved')
          _buildTimelineTile(
            'معتمد',
            user.updatedAt.toString().split(' ')[0],
            true,
            isTerminal: true,
            color: Colors.green,
          ),
        if (user.status == 'rejected')
          _buildTimelineTile(
            'مرفوض',
            user.updatedAt.toString().split(' ')[0],
            true,
            isTerminal: true,
            color: Colors.red,
            subtitle: user.rejectedReason,
          ),
        if (user.status == 'need_modification')
          _buildTimelineTile(
            'طلب تعديل',
            user.updatedAt.toString().split(' ')[0],
            true,
            isTerminal: true,
            color: Colors.orange,
            subtitle: user.rejectedReason,
          ),
      ],
    );
  }

  Widget _buildTimelineTile(
    String title,
    String date,
    bool isCompleted, {
    bool isTerminal = false,
    Color color = Colors.blue,
    String? subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted ? color : Colors.grey,
              ),
            ),
            if (!isTerminal)
              Container(width: 2, height: 40, color: Colors.grey[300]),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                  color: isCompleted ? Colors.black : Colors.grey,
                ),
              ),
              Text(
                date,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              if (subtitle != null && subtitle.isNotEmpty)
                Text(
                  'السبب: $subtitle',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontFamily: 'Cairo',
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_user == null) {
      return const Scaffold(body: Center(child: Text('المستخدم غير موجود')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'تفاصيل الحساب',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundImage: _user!.profileImage.isNotEmpty
                      ? NetworkImage(_user!.profileImage)
                      : null,
                  child: _user!.profileImage.isEmpty
                      ? const Icon(Icons.person, size: 32)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _user!.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      Text(
                        _user!.phone,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      Text(
                        'الحالة: ${_user!.status}',
                        style: const TextStyle(
                          color: AdminTheme.primary,
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),

            if (_isProfileMissing)
              _buildMissingProfileWarning(
                _user!.role == 'driver' ? 'سائق' : 'شركة',
              ),
            if (_user!.role == 'driver' && _driver != null)
              _buildDriverDetails(_driver!),
            if (_user!.role == 'company' && _company != null)
              _buildCompanyDetails(_company!),

            const Divider(height: 32),
            _buildTimeline(_user!),

            const SizedBox(height: 32),
            // Global Actions
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width < 600
                      ? double.infinity
                      : null,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 24,
                      ),
                    ),
                    onPressed: () {
                      if (_user!.role == 'driver' && _driver != null) {
                        final docs = _driver!.documents;
                        final requiredKeys = {
                          'personalPhoto': 'الصورة الشخصية',
                          'idFront': 'الهوية أمامي',
                          'idBack': 'الهوية خلفي',
                          'licenseFront': 'الرخصة أمامي',
                          'licenseBack': 'الرخصة خلفي',
                          'vehicleFront': 'المركبة أمامي',
                          'vehicleBack': 'المركبة خلفي',
                          'vehicleRight': 'المركبة يمين',
                          'vehicleLeft': 'المركبة يسار',
                          'vehicleInterior': 'المركبة من الداخل',
                          'vehiclePlate': 'لوحة المركبة',
                        };
                        List<String> unapprovedNames = [];
                        for (var entry in requiredKeys.entries) {
                          final doc = docs[entry.key];
                          if (doc == null || doc.status != 'approved') {
                            unapprovedNames.add(entry.value);
                          }
                        }
                        if (unapprovedNames.isNotEmpty) {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text(
                                'المستندات غير مكتملة',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  color: Colors.red,
                                ),
                              ),
                              content: SingleChildScrollView(
                                child: ListBody(
                                  children: [
                                    const Text(
                                      'لا يمكن اعتماد الحساب حتى يتم اعتماد كافة المستندات المطلوبة. المستندات التالية غير معتمدة:',
                                      style: TextStyle(fontFamily: 'Cairo'),
                                    ),
                                    const SizedBox(height: 8),
                                    ...unapprovedNames.map(
                                      (n) => Text(
                                        '• $n',
                                        style: const TextStyle(
                                          fontFamily: 'Cairo',
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text(
                                    'حسناً',
                                    style: TextStyle(fontFamily: 'Cairo'),
                                  ),
                                ),
                              ],
                            ),
                          );
                          return;
                        }
                      }
                      _updateUserStatus('approved');
                    },
                    icon: const Icon(Icons.check_circle),
                    label: const Text(
                      'اعتماد الحساب بالكامل',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width < 600
                      ? double.infinity
                      : null,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 24,
                      ),
                    ),
                    onPressed: () => _updateUserStatus('need_modification'),
                    icon: const Icon(Icons.edit_note),
                    label: const Text(
                      'طلب تعديلات',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width < 600
                      ? double.infinity
                      : null,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 24,
                      ),
                    ),
                    onPressed: () => _updateUserStatus('rejected'),
                    icon: const Icon(Icons.cancel),
                    label: const Text(
                      'رفض الحساب',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width < 600
                      ? double.infinity
                      : null,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black87,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 24,
                      ),
                    ),
                    onPressed: () => _updateUserStatus('blocked'),
                    icon: const Icon(Icons.block),
                    label: const Text(
                      'حظر',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width < 600
                      ? double.infinity
                      : null,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[900],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 24,
                      ),
                    ),
                    onPressed: () => _updateUserStatus('deleted'),
                    icon: const Icon(Icons.delete_forever),
                    label: const Text(
                      'حذف',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
