import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../fleet/domain/models/vehicle.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../common/presentation/widgets/safe_network_image.dart';
import '../utils/driver_tokens.dart';

class VehicleDetailsScreen extends ConsumerStatefulWidget {
  final Vehicle vehicle;

  const VehicleDetailsScreen({super.key, required this.vehicle});

  @override
  ConsumerState<VehicleDetailsScreen> createState() =>
      _VehicleDetailsScreenState();
}

class _VehicleDetailsScreenState extends ConsumerState<VehicleDetailsScreen> {
  late Vehicle _vehicle;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _vehicle = widget.vehicle;
  }

  Future<void> _refreshVehicle() async {
    try {
      final updated = await ref
          .read(fleetRepositoryProvider)
          .getVehicle(_vehicle.id);
      if (updated != null && mounted) {
        setState(() {
          _vehicle = updated;
        });
      }
    } catch (_) {}
  }

  Future<void> _showAddMaintenanceDialog() async {
    String selectedType = 'oil_change';
    DateTime performedDate = DateTime.now();
    DateTime nextDueDate = DateTime.now().add(const Duration(days: 90));
    final mileageCtrl = TextEditingController(
      text: _vehicle.currentMileage > 0
          ? _vehicle.currentMileage.toString()
          : '',
    );
    final costCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DriverTokens.radiusCard),
              ),
              title: const Text(
                'إضافة سجل صيانة حقيقي',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: const InputDecoration(
                        labelText: 'نوع الصيانة',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'oil_change',
                          child: Text(
                            'تغيير زيت وفلتر',
                            style: TextStyle(fontFamily: 'Cairo'),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'tires',
                          child: Text(
                            'فحص وتغيير إطارات',
                            style: TextStyle(fontFamily: 'Cairo'),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'brakes',
                          child: Text(
                            'فرامل ومكابح',
                            style: TextStyle(fontFamily: 'Cairo'),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'battery',
                          child: Text(
                            'بطارية وكهرباء',
                            style: TextStyle(fontFamily: 'Cairo'),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'engine',
                          child: Text(
                            'محرك وميكانيكا',
                            style: TextStyle(fontFamily: 'Cairo'),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'general',
                          child: Text(
                            'فحص دوري وصيانة عامة',
                            style: TextStyle(fontFamily: 'Cairo'),
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null)
                          setDialogState(() => selectedType = val);
                      },
                    ),
                    const SizedBox(height: DriverTokens.spaceMd),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'تاريخ إجراء الصيانة',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 13),
                      ),
                      subtitle: Text(
                        DateFormat('yyyy-MM-dd').format(performedDate),
                      ),
                      trailing: const Icon(Icons.calendar_today, size: 20),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: performedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setDialogState(() => performedDate = picked);
                        }
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'موعد الصيانة القادمة',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 13),
                      ),
                      subtitle: Text(
                        DateFormat('yyyy-MM-dd').format(nextDueDate),
                      ),
                      trailing: const Icon(Icons.event_repeat, size: 20),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: nextDueDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 730),
                          ),
                        );
                        if (picked != null) {
                          setDialogState(() => nextDueDate = picked);
                        }
                      },
                    ),
                    const SizedBox(height: DriverTokens.spaceSm),
                    TextField(
                      controller: mileageCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'العداد عند الصيانة (كم)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: DriverTokens.spaceSm),
                    TextField(
                      controller: costCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'التكلفة (ريال)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: DriverTokens.spaceSm),
                    TextField(
                      controller: notesCtrl,
                      decoration: const InputDecoration(
                        labelText: 'ملاحظات الصيانة (اختياري)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'إلغاء',
                    style: TextStyle(fontFamily: 'Cairo'),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DriverTokens.primaryNavy,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    final mileage =
                        int.tryParse(mileageCtrl.text.trim()) ??
                        _vehicle.currentMileage;
                    final cost = double.tryParse(costCtrl.text.trim()) ?? 0.0;

                    final newRecord = MaintenanceRecord(
                      id: 'maint_${DateTime.now().millisecondsSinceEpoch}',
                      vehicleId: _vehicle.id,
                      type: selectedType,
                      datePerformed: performedDate,
                      nextDueDate: nextDueDate,
                      mileageAtMaintenance: mileage,
                      cost: cost,
                      notes: notesCtrl.text.trim(),
                    );

                    Navigator.pop(ctx);
                    setState(() => _isLoading = true);

                    try {
                      await ref
                          .read(fleetRepositoryProvider)
                          .addMaintenanceRecord(_vehicle.id, newRecord);
                      await _refreshVehicle();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'تمت إضافة سجل الصيانة بنجاح',
                              style: TextStyle(fontFamily: 'Cairo'),
                            ),
                            backgroundColor: DriverTokens.semanticSuccess,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'تعذر حفظ سجل الصيانة',
                              style: TextStyle(fontFamily: 'Cairo'),
                            ),
                            backgroundColor: DriverTokens.semanticError,
                          ),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _isLoading = false);
                    }
                  },
                  child: const Text(
                    'حفظ السجل',
                    style: TextStyle(fontFamily: 'Cairo'),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteMaintenanceRecord(String recordId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف', style: TextStyle(fontFamily: 'Cairo')),
        content: const Text(
          'هل أنت متأكد من حذف هذا السجل؟',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: DriverTokens.semanticError,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await ref
          .read(fleetRepositoryProvider)
          .deleteMaintenanceRecord(_vehicle.id, recordId);
      await _refreshVehicle();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تم حذف سجل الصيانة',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تعذر حذف سجل الصيانة',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            '${_vehicle.make} ${_vehicle.model}',
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: DriverTokens.primaryNavy,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                await context.push('/add-vehicle', extra: _vehicle);
                _refreshVehicle();
              },
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(DriverTokens.spaceMd),
                children: [
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(
                        DriverTokens.radiusCard,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _vehicle.photoUrl.isNotEmpty
                        ? SafeNetworkImage(
                            url: _vehicle.photoUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          )
                        : const Icon(
                            Icons.directions_car,
                            size: 80,
                            color: Colors.grey,
                          ),
                  ),
                  const SizedBox(height: DriverTokens.spaceMd),
                  _buildGallery(),
                  const SizedBox(height: DriverTokens.spaceMd),

                  // Basic Info
                  _buildInfoCard(
                    title: 'معلومات المركبة الأساسية',
                    children: [
                      _buildInfoRow(
                        'المصنّع والموديل',
                        '${_vehicle.make} ${_vehicle.model}',
                      ),
                      _buildInfoRow('رقم اللوحة', _vehicle.plateNumber),
                      _buildInfoRow('سنة الصنع', _vehicle.year.toString()),
                      _buildInfoRow('اللون', _vehicle.color),
                      _buildInfoRow('نوع المركبة', _vehicle.type),
                      _buildInfoRow('نوع الوقود', _vehicle.fuelType),
                      _buildInfoRow(
                        'عدد المقاعد',
                        _vehicle.seatsCount.toString(),
                      ),
                      _buildInfoRow('الحالة الحالية', _vehicle.status),
                    ],
                  ),
                  const SizedBox(height: DriverTokens.spaceMd),

                  // Expiry Center (Part 40)
                  _buildExpiryCenter(),
                  const SizedBox(height: DriverTokens.spaceMd),

                  // Maintenance Center (Part 39)
                  _buildMaintenanceCenter(),
                  const SizedBox(height: DriverTokens.spaceLg),
                ],
              ),
      ),
    );
  }

  Widget _buildExpiryCenter() {
    return _buildInfoCard(
      title: 'مركز الصلاحية والوثائق',
      children: [
        _buildInfoRow(
          'رقم الهيكل (VIN)',
          _vehicle.vin.isEmpty ? 'غير متوفر' : _vehicle.vin,
        ),
        _buildInfoRow(
          'رقم الاستمارة',
          _vehicle.registrationNumber.isEmpty
              ? 'غير متوفر'
              : _vehicle.registrationNumber,
        ),
        _buildExpiryRow('استمارة المركبة', _vehicle.registrationExpiry),
        const Divider(),
        _buildInfoRow(
          'رقم التأمين',
          _vehicle.insuranceNumber.isEmpty
              ? 'غير متوفر'
              : _vehicle.insuranceNumber,
        ),
        _buildExpiryRow('تأمين المركبة', _vehicle.insuranceExpiry),
      ],
    );
  }

  Widget _buildExpiryRow(String title, DateTime? expiry) {
    if (expiry == null) {
      return _buildInfoRow(title, 'غير مسجل');
    }

    final now = DateTime.now();
    final isExpired = expiry.isBefore(now);
    final daysRemaining = expiry.difference(now).inDays;
    final isExpiringSoon = !isExpired && daysRemaining <= 30;

    Color badgeColor;
    String statusText;

    if (isExpired) {
      badgeColor = DriverTokens.semanticError;
      statusText = 'منتهي (${DateFormat('yyyy-MM-dd').format(expiry)})';
    } else if (isExpiringSoon) {
      badgeColor = DriverTokens.semanticWarning;
      statusText =
          'ينتهي خلال $daysRemaining يوم (${DateFormat('yyyy-MM-dd').format(expiry)})';
    } else {
      badgeColor = DriverTokens.semanticSuccess;
      statusText = 'ساري (${DateFormat('yyyy-MM-dd').format(expiry)})';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.grey, fontFamily: 'Cairo'),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(DriverTokens.radiusSmall),
              border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
                fontSize: 12,
                color: badgeColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceCenter() {
    final records = _vehicle.maintenanceRecords;

    return _buildInfoCard(
      title: 'مركز الصيانة المعتمد',
      children: [
        _buildInfoRow('العداد الحالي', '${_vehicle.currentMileage} كم'),
        const Divider(),
        if (records.isEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                'لا توجد سجلات صيانة مسجلة حتى الآن.',
                style: TextStyle(fontFamily: 'Cairo', color: Colors.grey),
              ),
            ),
          ),
        ] else ...[
          ...records.map((rec) {
            final typeLabel = _getMaintenanceTypeLabel(rec.type);
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              color: DriverTokens.backgroundLight,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DriverTokens.radiusSmall),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: DriverTokens.primaryNavy.withValues(
                    alpha: 0.1,
                  ),
                  child: const Icon(
                    Icons.build,
                    color: DriverTokens.primaryNavy,
                    size: 20,
                  ),
                ),
                title: Text(
                  typeLabel,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'أجريت: ${DateFormat("yyyy-MM-dd").format(rec.datePerformed)} • عند ${rec.mileageAtMaintenance} كم',
                      style: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
                    ),
                    Text(
                      'الموعد القادم: ${DateFormat("yyyy-MM-dd").format(rec.nextDueDate)}${rec.cost > 0 ? " • التكلفة: ${rec.cost.toInt()} ريال" : ""}',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                    if (rec.notes.isNotEmpty)
                      Text(
                        'ملاحظات: ${rec.notes}',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: DriverTokens.semanticError,
                    size: 20,
                  ),
                  onPressed: () => _deleteMaintenanceRecord(rec.id),
                ),
              ),
            );
          }),
        ],
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: DriverTokens.primaryNavy,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DriverTokens.radiusSmall),
              ),
            ),
            onPressed: _showAddMaintenanceDialog,
            icon: const Icon(Icons.add),
            label: const Text(
              'إضافة سجل صيانة جديد',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
          ),
        ),
      ],
    );
  }

  String _getMaintenanceTypeLabel(String type) {
    switch (type) {
      case 'oil_change':
        return 'تغيير زيت وفلتر';
      case 'tires':
        return 'إطارات وترصيص';
      case 'brakes':
        return 'فرامل ومكابح';
      case 'battery':
        return 'بطارية وكهرباء';
      case 'engine':
        return 'محرك وميكانيكا';
      case 'general':
      default:
        return 'صيانة دورية عامة';
    }
  }

  Widget _buildGallery() {
    final Map<String, String> mapped = {};
    for (final url in _vehicle.additionalPhotos) {
      if (url.contains('exterior_front')) {
        mapped['الأمام'] = url;
      } else if (url.contains('exterior_rear')) {
        mapped['الخلف'] = url;
      } else if (url.contains('exterior_side_right')) {
        mapped['الجانب الأيمن'] = url;
      } else if (url.contains('exterior_side_left')) {
        mapped['الجانب الأيسر'] = url;
      } else if (url.contains('exterior_side') &&
          !mapped.containsKey('الجانب الأيمن')) {
        mapped['الجانب الأيمن'] = url;
      } else if (url.contains('interior')) {
        mapped['الداخل'] = url;
      }
    }

    if (mapped.isEmpty) return const SizedBox.shrink();

    return _buildInfoCard(
      title: 'معرض صور المركبة',
      children: [
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: mapped.length,
            itemBuilder: (context, index) {
              final key = mapped.keys.elementAt(index);
              final url = mapped[key]!;
              return Container(
                width: 120,
                margin: const EdgeInsets.only(left: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(DriverTokens.radiusSmall),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    SafeNetworkImage(url: url, fit: BoxFit.cover),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        color: Colors.black.withValues(alpha: 0.6),
                        child: Text(
                          key,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'Cairo',
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DriverTokens.radiusCard),
      ),
      child: Padding(
        padding: const EdgeInsets.all(DriverTokens.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: DriverTokens.primaryNavy,
              ),
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey, fontFamily: 'Cairo'),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }
}
