import 'package:flutter/material.dart';

class CompanyAddDriverScreen extends StatelessWidget {
  const CompanyAddDriverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'إضافة سائق جديد',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionTitle('المعلومات الشخصية'),
            _buildTextField('الاسم الكامل (كما في الهوية)'),
            _buildTextField(
              'رقم الهاتف (المرتبط بالواتساب)',
              keyboardType: TextInputType.phone,
            ),
            _buildTextField('الجنسية'),
            _buildTextField('رقم الهوية / الإقامة'),
            _buildTextField('تاريخ الانتهاء', suffixIcon: Icons.calendar_today),

            const SizedBox(height: 24),
            _buildSectionTitle('رخصة القيادة'),
            _buildTextField('رقم رخصة القيادة'),
            _buildDropdown('نوع الرخصة', [
              'رخصة قيادة عامة',
              'رخصة نقل ثقيل',
              'رخصة خاصة',
            ]),
            _buildTextField(
              'تاريخ إصدار الرخصة',
              suffixIcon: Icons.calendar_today,
            ),
            _buildTextField(
              'تاريخ انتهاء الرخصة',
              suffixIcon: Icons.calendar_today,
            ),

            const SizedBox(height: 24),
            _buildSectionTitle('تعيينات مبدئية'),
            _buildDropdown('تعيين مركبة للسائق', [
              'لا يوجد (تعيين لاحقاً)',
              'مرسيدس بنز 2022 (متاحة)',
            ]),
            _buildDropdown('منطقة العمل', [
              'جميع المناطق',
              'الرياض',
              'جدة',
              'الدمام',
            ]),

            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0B1F3A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'حفظ السائق وإرسال دعوة',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label, {
    IconData? suffixIcon,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
          suffixIcon: suffixIcon != null ? Icon(suffixIcon, size: 20) : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
        ),
        items: items
            .map(
              (e) => DropdownMenuItem(
                value: e,
                child: Text(e, style: const TextStyle(fontFamily: 'Cairo')),
              ),
            )
            .toList(),
        onChanged: (v) {},
      ),
    );
  }
}
