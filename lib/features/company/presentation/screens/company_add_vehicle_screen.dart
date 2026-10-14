import 'package:flutter/material.dart';

class CompanyAddVehicleScreen extends StatelessWidget {
  const CompanyAddVehicleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'إضافة مركبة جديدة',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionTitle('المعلومات الأساسية'),
            _buildTextField('الشركة المصنعة (Brand)'),
            _buildTextField('الموديل (Model)'),
            Row(
              children: [
                Expanded(child: _buildTextField('سنة الصنع')),
                const SizedBox(width: 16),
                Expanded(child: _buildTextField('اللون')),
              ],
            ),
            Row(
              children: [
                Expanded(child: _buildTextField('رقم اللوحة')),
                const SizedBox(width: 16),
                Expanded(child: _buildTextField('عدد المقاعد')),
              ],
            ),
            _buildTextField('رقم الهيكل (VIN)'),

            const SizedBox(height: 24),
            _buildSectionTitle('الوثائق والتراخيص'),
            _buildTextField('رقم الاستمارة (Registration Number)'),
            _buildTextField(
              'تاريخ انتهاء الاستمارة',
              suffixIcon: Icons.calendar_today,
            ),
            _buildTextField('رقم وثيقة التأمين'),
            _buildTextField(
              'تاريخ انتهاء التأمين',
              suffixIcon: Icons.calendar_today,
            ),
            _buildTextField(
              'تاريخ انتهاء الفحص الدوري',
              suffixIcon: Icons.calendar_today,
            ),

            const SizedBox(height: 24),
            _buildSectionTitle('صور المركبة'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildPhotoUploader('من الأمام'),
                _buildPhotoUploader('من الخلف'),
                _buildPhotoUploader('الجانب'),
                _buildPhotoUploader('من الداخل'),
              ],
            ),

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
                'حفظ المركبة',
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

  Widget _buildTextField(String label, {IconData? suffixIcon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
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

  Widget _buildPhotoUploader(String label) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade300,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.add_a_photo, color: Colors.grey),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 10,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
