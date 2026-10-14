import 'package:flutter/material.dart';

class CompanyTripCreationScreen extends StatefulWidget {
  const CompanyTripCreationScreen({super.key});

  @override
  State<CompanyTripCreationScreen> createState() =>
      _CompanyTripCreationScreenState();
}

class _CompanyTripCreationScreenState extends State<CompanyTripCreationScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form controllers would go here...

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'إنشاء رحلة جديدة',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          actions: [
            TextButton(
              onPressed: () {},
              child: const Text(
                'مسودة',
                style: TextStyle(fontFamily: 'Cairo', color: Colors.blue),
              ),
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionTitle('المسار والوقت'),
              _buildTextField(
                'نقطة الانطلاق (المدينة)',
                Icons.location_on_outlined,
              ),
              _buildTextField('نقطة الوصول (المدينة)', Icons.flag_outlined),
              _buildTextField('تاريخ السفر', Icons.calendar_today),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField('وقت الانطلاق', Icons.access_time),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      'وقت الوصول (المتوقع)',
                      Icons.access_time,
                    ),
                  ),
                ],
              ),
              _buildTextField('نقاط التجمع (الركوب)', Icons.pin_drop),
              _buildTextField('نقاط النزول', Icons.pin_drop),

              const SizedBox(height: 24),
              _buildSectionTitle('الأسطول والسائق'),
              _buildDropdown('نوع الرحلة', ['داخلي', 'دولي', 'نقل طرود']),
              _buildDropdown('المركبة المخصصة', [
                'اختر مركبة (تظهر المتاحة فقط)',
              ]),
              _buildDropdown('السائق المخصص', ['اختر سائق (يظهر المتاح فقط)']),

              const SizedBox(height: 24),
              _buildSectionTitle('المقاعد والأسعار'),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField('سعة الركاب', Icons.event_seat),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField('سعر التذكرة', Icons.attach_money),
                  ),
                ],
              ),
              _buildDropdown('تخطيط المقاعد', [
                'قياسي (45 مقعد)',
                'VIP (30 مقعد)',
              ]),

              const SizedBox(height: 24),
              _buildSectionTitle('السياسات والشروط'),
              SwitchListTile(
                title: const Text(
                  'الحجز الفوري متاح',
                  style: TextStyle(fontFamily: 'Cairo'),
                ),
                value: true,
                onChanged: (v) {},
              ),
              SwitchListTile(
                title: const Text(
                  'السماح بالركوب من منتصف الطريق',
                  style: TextStyle(fontFamily: 'Cairo'),
                ),
                value: false,
                onChanged: (v) {},
              ),
              SwitchListTile(
                title: const Text(
                  'السماح بالنزول في منتصف الطريق',
                  style: TextStyle(fontFamily: 'Cairo'),
                ),
                value: true,
                onChanged: (v) {},
              ),
              _buildTextField('شروط الأمتعة (كجم)', Icons.luggage),
              _buildTextField(
                'وصف الرحلة (اختياري)',
                Icons.description,
                maxLines: 3,
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // Trigger validation and save
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'تم نشر الرحلة بنجاح',
                            style: TextStyle(fontFamily: 'Cairo'),
                          ),
                        ),
                      );
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B1F3A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'نشر وتفعيل الرحلة',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
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
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0B1F3A),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
          prefixIcon: maxLines == 1 ? Icon(icon) : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1E1E1E)
              : Colors.white,
        ),
        validator: (value) =>
            (value?.isEmpty ?? true) ? 'هذا الحقل مطلوب' : null,
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1E1E1E)
              : Colors.white,
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
