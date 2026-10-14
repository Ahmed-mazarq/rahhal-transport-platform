import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/driver_profile.dart';
import '../widgets/document_card.dart';
import '../providers/driver_providers.dart';
import '../utils/driver_tokens.dart';

class DriverDocumentsScreen extends ConsumerWidget {
  const DriverDocumentsScreen({super.key});

  String _getDocStatus(DriverProfile profile, String docKey) {
    if (profile.status == 'approved' &&
        profile.verificationStatus == 'approved') {
      try {
        final doc = profile.documents.firstWhere((d) => d.type == docKey);
        if (doc.status == 'rejected' ||
            doc.status == 'needs_update' ||
            doc.status == 'expired') {
          return doc.status;
        }
      } catch (_) {}
      return 'approved';
    }

    try {
      final doc = profile.documents.firstWhere((d) => d.type == docKey);
      if (doc.status.isNotEmpty) {
        return doc.status;
      }
    } catch (_) {}

    return 'pending_review';
  }

  String _getDocLastUpdated(DriverProfile profile, String docKey) {
    try {
      final doc = profile.documents.firstWhere((d) => d.type == docKey);
      return '${doc.issueDate.year}/${doc.issueDate.month}/${doc.issueDate.day}';
    } catch (_) {
      return '';
    }
  }

  int _getDaysUntilExpiry(String? expiryDateStr) {
    if (expiryDateStr == null || expiryDateStr.isEmpty) return -1;
    try {
      final parts = expiryDateStr.split('/');
      if (parts.length == 3) {
        final expiry = DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
        return expiry.difference(DateTime.now()).inDays;
      }
      final parsed = DateTime.parse(expiryDateStr);
      return parsed.difference(DateTime.now()).inDays;
    } catch (_) {
      return -1;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final profileAsync = ref.watch(driverProfileProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF101928)
            : DriverTokens.lightBackground,
        appBar: AppBar(
          title: const Text(
            'مركز الوثائق المهني',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          backgroundColor: isDark ? const Color(0xFF101928) : Colors.white,
          elevation: 0,
        ),
        body: profileAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: DriverTokens.accentGold),
          ),
          error: (err, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: DriverTokens.semanticError,
                ),
                const SizedBox(height: 12),
                const Text(
                  'حدث خطأ في تحميل بيانات الحساب',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => ref.invalidate(driverProfileProvider),
                  child: const Text(
                    'إعادة المحاولة',
                    style: TextStyle(fontFamily: 'Cairo'),
                  ),
                ),
              ],
            ),
          ),
          data: (profile) {
            if (profile == null) {
              return const Center(
                child: Text(
                  'لم يتم العثور على بيانات السائق',
                  style: TextStyle(fontFamily: 'Cairo'),
                ),
              );
            }

            final bool isAccountApproved =
                profile.status == 'approved' &&
                profile.verificationStatus == 'approved';

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(driverProfileProvider);
              },
              color: DriverTokens.accentGold,
              child: ListView(
                padding: const EdgeInsets.all(DriverTokens.spaceMd),
                children: [
                  // Verification Status Header (Part 41)
                  Container(
                    padding: const EdgeInsets.all(DriverTokens.spaceMd),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(
                        DriverTokens.radiusCard,
                      ),
                      border: Border.all(
                        color: isDark
                            ? Colors.white10
                            : Colors.black.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color:
                                    (isAccountApproved
                                            ? DriverTokens.semanticSuccess
                                            : (profile.status == 'rejected'
                                                  ? DriverTokens.semanticError
                                                  : DriverTokens
                                                        .semanticWarning))
                                        .withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isAccountApproved
                                    ? Icons.verified_user_rounded
                                    : (profile.status == 'rejected'
                                          ? Icons.cancel_rounded
                                          : Icons.hourglass_top_rounded),
                                color: isAccountApproved
                                    ? DriverTokens.semanticSuccess
                                    : (profile.status == 'rejected'
                                          ? DriverTokens.semanticError
                                          : DriverTokens.semanticWarning),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'حالة اعتماد الحساب',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 11,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                  Text(
                                    isAccountApproved
                                        ? 'حساب معتمد ومفعل بالكامل'
                                        : (profile.status == 'rejected'
                                              ? 'طلب الحساب مرفوض'
                                              : 'الحساب قيد المراجعة والتدقيق'),
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: isAccountApproved
                                          ? DriverTokens.semanticSuccess
                                          : (profile.status == 'rejected'
                                                ? DriverTokens.semanticError
                                                : DriverTokens.semanticWarning),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'تخضع جميع الوثائق لمراجعة إدارة رحال، يرجى التأكد من سريان مفعول الوثائق لتجنب توقف الحساب عن العمل.',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: DriverTokens.spaceMd),

                  // 1. Passport
                  DocumentCard(
                    title: 'جواز السفر',
                    type: 'passport',
                    status: _getDocStatus(profile, 'passport'),
                    fields: [
                      DocumentInfoField(
                        label: 'رقم الجواز',
                        value: profile.passportNumber?.isNotEmpty == true
                            ? profile.passportNumber!
                            : 'غير متوفر',
                      ),
                      DocumentInfoField(
                        label: 'تاريخ الانتهاء',
                        value: profile.passportExpiry?.isNotEmpty == true
                            ? profile.passportExpiry!
                            : 'غير متوفر',
                      ),
                    ],
                    lastUpdated: _getDocLastUpdated(profile, 'passport'),
                    daysUntilExpiry: _getDaysUntilExpiry(
                      profile.passportExpiry,
                    ),
                  ),

                  // 2. Identity
                  DocumentCard(
                    title: 'الهوية الوطنية / الإقامة',
                    type: 'identity',
                    status: _getDocStatus(profile, 'idFront'),
                    fields: [
                      DocumentInfoField(
                        label: 'رقم الهوية',
                        value: 'غير متوفر',
                      ),
                    ],
                    lastUpdated: _getDocLastUpdated(profile, 'idFront'),
                  ),

                  // 3. Driving License
                  DocumentCard(
                    title: 'رخصة القيادة',
                    type: 'driving_license',
                    status: _getDocStatus(profile, 'licenseFront'),
                    fields: [
                      DocumentInfoField(
                        label: 'رقم الرخصة',
                        value: profile.licenseNumber?.isNotEmpty == true
                            ? profile.licenseNumber!
                            : 'غير متوفر',
                      ),
                      DocumentInfoField(
                        label: 'نوع الرخصة',
                        value: profile.licenseType?.isNotEmpty == true
                            ? profile.licenseType!
                            : 'غير متوفر',
                      ),
                      DocumentInfoField(
                        label: 'دولة الإصدار',
                        value: profile.licenseCountry?.isNotEmpty == true
                            ? profile.licenseCountry!
                            : 'غير متوفر',
                      ),
                      DocumentInfoField(
                        label: 'تاريخ الإصدار',
                        value: profile.licenseIssueDate?.isNotEmpty == true
                            ? profile.licenseIssueDate!
                            : 'غير متوفر',
                      ),
                      DocumentInfoField(
                        label: 'تاريخ الانتهاء',
                        value: profile.licenseExpiryDate?.isNotEmpty == true
                            ? profile.licenseExpiryDate!
                            : 'غير متوفر',
                      ),
                    ],
                    lastUpdated: _getDocLastUpdated(profile, 'licenseFront'),
                    daysUntilExpiry: _getDaysUntilExpiry(
                      profile.licenseExpiryDate,
                    ),
                  ),

                  // 4. Vehicle Registration (Estemara)
                  DocumentCard(
                    title: 'استمارة المركبة',
                    type: 'vehicle_registration',
                    status: _getDocStatus(profile, 'vehicleFront'),
                    fields: [
                      DocumentInfoField(
                        label: 'رقم الاستمارة',
                        value: profile.registrationNumber?.isNotEmpty == true
                            ? profile.registrationNumber!
                            : 'غير متوفر',
                      ),
                      DocumentInfoField(
                        label: 'تاريخ الانتهاء',
                        value: profile.registrationExpiry?.isNotEmpty == true
                            ? profile.registrationExpiry!
                            : 'غير متوفر',
                      ),
                    ],
                    lastUpdated: _getDocLastUpdated(profile, 'vehicleFront'),
                    daysUntilExpiry: _getDaysUntilExpiry(
                      profile.registrationExpiry,
                    ),
                  ),

                  // 5. Vehicle Insurance
                  DocumentCard(
                    title: 'تأمين المركبة',
                    type: 'insurance',
                    status: _getDocStatus(profile, 'insurance'),
                    fields: [
                      DocumentInfoField(
                        label: 'رقم التأمين',
                        value: profile.insuranceNumber?.isNotEmpty == true
                            ? profile.insuranceNumber!
                            : 'غير متوفر',
                      ),
                      DocumentInfoField(
                        label: 'تاريخ الانتهاء',
                        value: profile.insuranceExpiry?.isNotEmpty == true
                            ? profile.insuranceExpiry!
                            : 'غير متوفر',
                      ),
                    ],
                    lastUpdated: _getDocLastUpdated(profile, 'insurance'),
                    daysUntilExpiry: _getDaysUntilExpiry(
                      profile.insuranceExpiry,
                    ),
                  ),

                  // 6. Vehicle Info
                  DocumentCard(
                    title: 'معلومات وفحص المركبة',
                    type: 'vehicle_info',
                    status: isAccountApproved ? 'approved' : 'pending',
                    fields: [
                      DocumentInfoField(
                        label: 'نوع المركبة',
                        value: profile.vehicleType?.isNotEmpty == true
                            ? profile.vehicleType!
                            : 'غير متوفر',
                      ),
                      DocumentInfoField(
                        label: 'الشركة المصنعة',
                        value: profile.vehicleManufacturer?.isNotEmpty == true
                            ? profile.vehicleManufacturer!
                            : 'غير متوفر',
                      ),
                      DocumentInfoField(
                        label: 'الموديل',
                        value: profile.vehicleModel?.isNotEmpty == true
                            ? profile.vehicleModel!
                            : 'غير متوفر',
                      ),
                      DocumentInfoField(
                        label: 'السنة',
                        value: profile.vehicleYear?.isNotEmpty == true
                            ? profile.vehicleYear!
                            : 'غير متوفر',
                      ),
                      DocumentInfoField(
                        label: 'رقم اللوحة',
                        value: profile.plateNumber?.isNotEmpty == true
                            ? profile.plateNumber!
                            : 'غير متوفر',
                      ),
                      DocumentInfoField(
                        label: 'VIN',
                        value: profile.vin?.isNotEmpty == true
                            ? profile.vin!
                            : 'غير متوفر',
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
