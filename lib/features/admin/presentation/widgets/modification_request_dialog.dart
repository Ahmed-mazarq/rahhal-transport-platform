import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:rahal/features/common/constants/modification_keys.dart';

class ModificationRequestDialog extends StatefulWidget {
  const ModificationRequestDialog({super.key});

  @override
  State<ModificationRequestDialog> createState() =>
      _ModificationRequestDialogState();
}

class _ModificationRequestDialogState extends State<ModificationRequestDialog> {
  // Categories and their respective fields
  final Map<String, List<String>> _categories = {
    'البيانات الشخصية والهوية': [
      ModificationKeys.fullName,
      ModificationKeys.nationalId,
      ModificationKeys.passportNumber,
      ModificationKeys.nationality,
      ModificationKeys.birthDate,
      ModificationKeys.gender,
      ModificationKeys.phone,
      ModificationKeys.secondaryPhone,
      ModificationKeys.passportExpiry,
    ],
    'العنوان': [
      ModificationKeys.country,
      ModificationKeys.province,
      ModificationKeys.city,
      ModificationKeys.district,
      ModificationKeys.street,
      ModificationKeys.detailedAddress,
      ModificationKeys.gpsLocation,
    ],
    'رخصة القيادة': [
      ModificationKeys.licenseNumber,
      ModificationKeys.licenseIssueDate,
      ModificationKeys.licenseExpiryDate,
      ModificationKeys.licenseType,
      ModificationKeys.licenseCountry,
    ],
    'بيانات المركبة': [
      ModificationKeys.vehicleBrand,
      ModificationKeys.vehicleModel,
      ModificationKeys.vehicleYear,
      ModificationKeys.vehicleColor,
      ModificationKeys.vehiclePlate,
      ModificationKeys.vin,
      ModificationKeys.seats,
      ModificationKeys.vehicleType,
      ModificationKeys.transmission,
      ModificationKeys.fuelType,
      ModificationKeys.vehicleCategory,
      ModificationKeys.vehicleRegistrationExpiry,
      ModificationKeys.registrationNumber,
      ModificationKeys.plateCountry,
    ],
    'التأمين': [
      ModificationKeys.insuranceCompany,
      ModificationKeys.insuranceNumber,
      ModificationKeys.policyNumber,
      ModificationKeys.insuranceExpiry,
      ModificationKeys.coverage,
    ],
    'مناطق العمل': [
      ModificationKeys.operatingAreas,
      ModificationKeys.operatingCities,
    ],
    'البيانات المالية': [
      ModificationKeys.bankName,
      ModificationKeys.accountHolder,
      ModificationKeys.accountNumber,
      ModificationKeys.iban,
      ModificationKeys.ewalletName,
      ModificationKeys.ewalletNumber,
    ],
    'جهة الاتصال (طوارئ)': [
      ModificationKeys.emergencyContactName,
      ModificationKeys.emergencyContactRelation,
      ModificationKeys.emergencyContactPhone,
    ],
    'المستندات والصور': [
      ModificationKeys.passportFrontImage,
      ModificationKeys.passportBackImage,
      ModificationKeys.driverPhoto,
      ModificationKeys.licenseFrontImage,
      ModificationKeys.licenseBackImage,
      ModificationKeys.vehicleFrontImage,
      ModificationKeys.vehicleBackImage,
      ModificationKeys.vehicleRightImage,
      ModificationKeys.vehicleLeftImage,
      ModificationKeys.vehicleInteriorImage,
      ModificationKeys.vehiclePlateImage,
      ModificationKeys.insurancePhoto,
    ],
  };

  // State
  final Map<String, List<String>> _selectedFields = {};
  final Map<String, TextEditingController> _notesControllers = {};
  final Map<String, bool> _expandedCategories = {};

  @override
  void initState() {
    super.initState();
    for (var cat in _categories.keys) {
      _selectedFields[cat] = [];
      _notesControllers[cat] = TextEditingController();
      _expandedCategories[cat] = false;
    }
  }

  @override
  void dispose() {
    for (var controller in _notesControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'طلب تعديلات (KYC)',
        style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 600,
        child: ListView(
          shrinkWrap: true,
          children: [
            const Text(
              'حدد الأقسام والحقول المطلوبة، مع كتابة ملاحظات إن لزم الأمر.',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            ..._categories.keys.map(
              (category) => _buildCategorySection(category),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'إلغاء',
            style: TextStyle(fontFamily: 'Cairo', color: Colors.grey),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          onPressed: _submit,
          child: const Text(
            'تأكيد طلب التعديل',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySection(String category) {
    final bool isExpanded = _expandedCategories[category] ?? false;
    final int selectedCount = _selectedFields[category]?.length ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          ListTile(
            title: Row(
              children: [
                Text(
                  category,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                ),
                if (selectedCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '\$selectedCount',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),
            trailing: Icon(
              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
            ),
            onTap: () {
              setState(() {
                _expandedCategories[category] = !isExpanded;
              });
            },
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: _categories[category]!.map((field) {
                      final bool isSelected = _selectedFields[category]!
                          .contains(field);
                      final label = ModificationKeys.labels[field] ?? field;
                      return FilterChip(
                        label: Text(
                          label,
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: Colors.orange.shade100,
                        checkmarkColor: Colors.orange,
                        onSelected: (bool selected) {
                          setState(() {
                            if (selected) {
                              _selectedFields[category]!.add(field);
                            } else {
                              _selectedFields[category]!.remove(field);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _notesControllers[category],
                    decoration: InputDecoration(
                      labelText: 'ملاحظات للمراجع (اختياري)',
                      labelStyle: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _submit() {
    // Generate a structured list of strings to be compatible with modificationChecklist logic in models
    // Format JSON strings
    List<String> finalReasons = [];

    for (var cat in _categories.keys) {
      final fields = _selectedFields[cat]!;
      final note = _notesControllers[cat]!.text.trim();

      if (fields.isNotEmpty || note.isNotEmpty) {
        // Build JSON representation safely using jsonEncode
        String jsonStr = jsonEncode({"fields": fields, "note": note});
        finalReasons.add(jsonStr);
      }
    }

    if (finalReasons.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'يجب تحديد حقل واحد على الأقل أو كتابة ملاحظة',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
        ),
      );
      return;
    }

    Navigator.pop(context, finalReasons);
  }
}
