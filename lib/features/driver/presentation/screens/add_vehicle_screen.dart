import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import '../../../fleet/domain/models/vehicle.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/services/storage/supabase_storage_service.dart';
import '../../../common/presentation/widgets/safe_network_image.dart';

class AddVehicleScreen extends ConsumerStatefulWidget {
  final Vehicle? initialVehicle;
  const AddVehicleScreen({super.key, this.initialVehicle});

  @override
  ConsumerState<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends ConsumerState<AddVehicleScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late String _vehicleId;
  String? _mainImageUrl;
  String? _frontImageUrl;
  String? _rearImageUrl;
  String? _rightSideImageUrl;
  String? _leftSideImageUrl;
  String? _interiorImageUrl;
  final List<String> _unmappedPhotos = [];

  late TextEditingController _makeCtrl;
  late TextEditingController _modelCtrl;
  late TextEditingController _yearCtrl;
  late TextEditingController _colorCtrl;
  late TextEditingController _plateCtrl;
  late TextEditingController _vinCtrl;
  late TextEditingController _regNumberCtrl;
  late TextEditingController _insNumberCtrl;

  String _selectedType = 'سيارة';
  String _selectedFuelType = 'بنزين';
  int _seatsCount = 4;

  final List<String> _vehicleTypes = [
    'سيارة',
    'حافلة صغيرة',
    'SUV',
    'باص',
    'فان',
    'بيك أب',
  ];

  String _normalizeVehicleType(String? value) {
    switch (value?.trim()) {
      case 'سيارة':
      case 'Sedan':
        return 'سيارة';
      case 'Minibus':
      case 'حافلة صغيرة':
        return 'حافلة صغيرة';
      case 'Bus':
      case 'باص':
        return 'باص';
      case 'Van':
      case 'فان':
        return 'فان';
      case 'Pickup':
      case 'بيك أب':
        return 'بيك أب';
      case 'SUV':
        return 'SUV';
      default:
        return value?.trim().isNotEmpty == true ? value!.trim() : 'سيارة';
    }
  }

  final List<String> _fuelTypes = ['بنزين', 'ديزل', 'كهربائي', 'هجين'];

  @override
  void initState() {
    super.initState();
    final v = widget.initialVehicle;
    _vehicleId = v?.id ?? const Uuid().v4();
    _makeCtrl = TextEditingController(text: v?.make ?? '');
    _modelCtrl = TextEditingController(text: v?.model ?? '');
    _yearCtrl = TextEditingController(text: v?.year.toString() ?? '');
    _colorCtrl = TextEditingController(text: v?.color ?? '');
    _plateCtrl = TextEditingController(text: v?.plateNumber ?? '');
    _vinCtrl = TextEditingController(text: v?.vin ?? '');
    _regNumberCtrl = TextEditingController(text: v?.registrationNumber ?? '');
    _insNumberCtrl = TextEditingController(text: v?.insuranceNumber ?? '');
    if (v != null) {
      _selectedType = _normalizeVehicleType(v.type);
      if (!_vehicleTypes.contains(_selectedType)) {
        _vehicleTypes.add(_selectedType);
      }
      _seatsCount = v.seatsCount;
      _mainImageUrl = v.photoUrl.isNotEmpty ? v.photoUrl : null;
      for (final url in v.additionalPhotos) {
        if (url.contains('exterior_front')) {
          _frontImageUrl = url;
        } else if (url.contains('exterior_rear')) {
          _rearImageUrl = url;
        } else if (url.contains('exterior_side_right')) {
          _rightSideImageUrl = url;
        } else if (url.contains('exterior_side_left')) {
          _leftSideImageUrl = url;
        } else if (url.contains('exterior_side') &&
            _rightSideImageUrl == null) {
          // Fallback for legacy generic side image
          _rightSideImageUrl = url;
        } else if (url.contains('interior')) {
          _interiorImageUrl = url;
        } else {
          _unmappedPhotos.add(url);
        }
      }
      if (_fuelTypes.contains(v.fuelType)) {
        _selectedFuelType = v.fuelType;
      }
    }
  }

  Future<void> _pickAndUploadImage(String type) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() => _isLoading = true);
    try {
      final authState = ref.read(authProvider);
      if (authState is! Authenticated) {
        throw Exception('المستخدم غير مسجل الدخول');
      }

      final storageService = SupabaseStorageService();
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final url = await storageService.uploadVehiclePhoto(
        authState.user.id,
        _vehicleId,
        type,
        image,
        isPrivate: false,
      );

      final urlWithTimestamp = '$url?t=$timestamp';

      setState(() {
        if (type == 'exterior_main') {
          _mainImageUrl = urlWithTimestamp;
        } else if (type == 'exterior_front') {
          _frontImageUrl = urlWithTimestamp;
        } else if (type == 'exterior_rear') {
          _rearImageUrl = urlWithTimestamp;
        } else if (type == 'exterior_side_right') {
          _rightSideImageUrl = urlWithTimestamp;
        } else if (type == 'exterior_side_left') {
          _leftSideImageUrl = urlWithTimestamp;
        } else if (type == 'interior') {
          _interiorImageUrl = urlWithTimestamp;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تم رفع الصورة بنجاح',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطأ في رفع الصورة: $e',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'يرجى التحقق من الحقول المطلوبة',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_mainImageUrl == null || _mainImageUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'يرجى إرفاق الصورة الرئيسية للمركبة أولاً',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final authState = ref.read(authProvider);
    if (authState is! Authenticated) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(fleetRepositoryProvider);

      final photos = [
        ?_frontImageUrl,
        ?_rearImageUrl,
        ?_rightSideImageUrl,
        ?_leftSideImageUrl,
        ?_interiorImageUrl,
        ..._unmappedPhotos,
      ];

      if (widget.initialVehicle != null) {
        final vehicle = widget.initialVehicle!.copyWith(
          make: _makeCtrl.text.trim(),
          model: _modelCtrl.text.trim(),
          year: int.tryParse(_yearCtrl.text) ?? DateTime.now().year,
          color: _colorCtrl.text.trim(),
          plateNumber: _plateCtrl.text.trim(),
          vin: _vinCtrl.text.trim(),
          registrationNumber: _regNumberCtrl.text.trim(),
          insuranceNumber: _insNumberCtrl.text.trim(),
          type: _selectedType,
          fuelType: _selectedFuelType,
          seatsCount: _seatsCount,
          photoUrl: _mainImageUrl ?? '',
          additionalPhotos: photos,
        );
        await repo.updateVehicle(vehicle);
      } else {
        final vehicle = Vehicle(
          id: _vehicleId,
          driverId: authState.user.uid,
          make: _makeCtrl.text.trim(),
          model: _modelCtrl.text.trim(),
          year: int.tryParse(_yearCtrl.text) ?? DateTime.now().year,
          color: _colorCtrl.text.trim(),
          plateNumber: _plateCtrl.text.trim(),
          vin: _vinCtrl.text.trim(),
          registrationNumber: _regNumberCtrl.text.trim(),
          insuranceNumber: _insNumberCtrl.text.trim(),
          type: _selectedType,
          fuelType: _selectedFuelType,
          seatsCount: _seatsCount,
          status: 'Pending',
          photoUrl: _mainImageUrl ?? '',
          additionalPhotos: photos,
        );
        await repo.addVehicle(vehicle);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تم الحفظ بنجاح',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تعذر حفظ بيانات المركبة، يرجى التحقق من المدخلات والمحاولة لاحقاً',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            widget.initialVehicle != null ? 'تعديل مركبة' : 'إضافة مركبة',
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildCardSection(
                title: 'صور المركبة',
                children: [
                  const Text(
                    'الصورة الرئيسية (مطلوب)',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildPhotoItem(
                    'exterior_main',
                    _mainImageUrl,
                    label: 'رئيسية',
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'صور إضافية (اختياري)',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildPhotoItem(
                          'exterior_front',
                          _frontImageUrl,
                          label: 'الأمام',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildPhotoItem(
                          'exterior_rear',
                          _rearImageUrl,
                          label: 'الخلف',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildPhotoItem(
                          'exterior_side_right',
                          _rightSideImageUrl,
                          label: 'الجانب الأيمن',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildPhotoItem(
                          'exterior_side_left',
                          _leftSideImageUrl,
                          label: 'الجانب الأيسر',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildPhotoItem(
                          'interior',
                          _interiorImageUrl,
                          label: 'داخل السيارة',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: const SizedBox.shrink()),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildCardSection(
                title: 'المعلومات الأساسية',
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _makeCtrl,
                          label: 'الماركة',
                          validator: (val) => val!.isEmpty ? 'مطلوب' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: _modelCtrl,
                          label: 'الموديل',
                          validator: (val) => val!.isEmpty ? 'مطلوب' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _yearCtrl,
                          label: 'السنة',
                          keyboardType: TextInputType.number,
                          validator: (val) {
                            if (val!.isEmpty) return 'مطلوب';
                            if (int.tryParse(val) == null) return 'رقم فقط';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: _colorCtrl,
                          label: 'اللون',
                          validator: (val) => val!.isEmpty ? 'مطلوب' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedType,
                    decoration: InputDecoration(
                      labelText: 'نوع المركبة',
                      labelStyle: const TextStyle(fontFamily: 'Cairo'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    items: _vehicleTypes
                        .map(
                          (t) => DropdownMenuItem(
                            value: t,
                            child: Text(
                              t,
                              style: const TextStyle(fontFamily: 'Cairo'),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => _selectedType = val!),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedFuelType,
                    decoration: InputDecoration(
                      labelText: 'نوع الوقود',
                      labelStyle: const TextStyle(fontFamily: 'Cairo'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    items: _fuelTypes
                        .map(
                          (t) => DropdownMenuItem(
                            value: t,
                            child: Text(
                              t,
                              style: const TextStyle(fontFamily: 'Cairo'),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) =>
                        setState(() => _selectedFuelType = val!),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: _seatsCount.toString(),
                    decoration: InputDecoration(
                      labelText: 'عدد المقاعد',
                      labelStyle: const TextStyle(fontFamily: 'Cairo'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (val) => _seatsCount = int.tryParse(val) ?? 4,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildCardSection(
                title: 'معلومات التسجيل',
                children: [
                  _buildTextField(
                    controller: _plateCtrl,
                    label: 'رقم اللوحة',
                    validator: (val) {
                      if (val!.isEmpty) return 'مطلوب';
                      if (val.length < 3) return 'غير صالح';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _vinCtrl,
                    label: 'رقم الهيكل (VIN)',
                    validator: (val) {
                      if (val != null && val.isNotEmpty && val.length < 17) {
                        return 'رقم الهيكل قصير';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _regNumberCtrl,
                    label: 'رقم الاستمارة',
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _insNumberCtrl,
                    label: 'رقم التأمين',
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            child: SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B1F3A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'حفظ المركبة',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoItem(String type, String? url, {String? label}) {
    return GestureDetector(
      onTap: () => _pickAndUploadImage(type),
      child: Container(
        height: type == 'exterior_main' ? 200 : 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: type == 'exterior_main' && url == null
                ? Colors.red.shade200
                : Colors.grey.shade300,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (url != null)
              SafeNetworkImage(
                url: url,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              )
            else
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_a_photo,
                    size: type == 'exterior_main' ? 48 : 24,
                    color: Colors.grey.shade400,
                  ),
                  if (label != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            if (url != null)
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      if (type == 'exterior_main') {
                        _mainImageUrl = null;
                      } else if (type == 'exterior_front') {
                        _frontImageUrl = null;
                      } else if (type == 'exterior_rear') {
                        _rearImageUrl = null;
                      } else if (type == 'exterior_side_right') {
                        _rightSideImageUrl = null;
                      } else if (type == 'exterior_side_left') {
                        _leftSideImageUrl = null;
                      } else if (type == 'interior') {
                        _interiorImageUrl = null;
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            if (_isLoading)
              Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0B1F3A),
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontFamily: 'Cairo'),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }
}
