import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/working_area.dart';
import '../providers/driver_providers.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../geo/domain/models/country.dart';
import '../../../geo/domain/models/governorate.dart';
import '../../../geo/domain/models/city.dart';
import '../../../geo/presentation/providers/geo_providers.dart';
import '../utils/driver_tokens.dart';

class WorkingAreasScreen extends ConsumerStatefulWidget {
  const WorkingAreasScreen({super.key});

  @override
  ConsumerState<WorkingAreasScreen> createState() => _WorkingAreasScreenState();
}

class _WorkingAreasScreenState extends ConsumerState<WorkingAreasScreen> {
  bool _isSaving = false;

  Future<void> _toggleAreaStatus(
    WorkingArea area,
    List<WorkingArea> allAreas,
  ) async {
    final authState = ref.read(authProvider);
    if (authState is! Authenticated) return;

    setState(() => _isSaving = true);
    try {
      final updatedList = allAreas.map((a) {
        if (a.id == area.id) {
          return a.copyWith(isActive: !a.isActive);
        }
        return a;
      }).toList();

      final repo = ref.read(driverRepositoryProvider);
      await repo.updateWorkingAreas(authState.user.uid, updatedList);
      ref.invalidate(driverProfileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              area.isActive
                  ? 'تم إيقاف تفعيل المنطقة'
                  : 'تم تفعيل المنطقة بنجاح',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: DriverTokens.semanticSuccess,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تعذر تحديث حالة المنطقة',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: DriverTokens.semanticError,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _removeArea(WorkingArea area, List<WorkingArea> allAreas) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'حذف منطقة العمل',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        content: Text(
          'هل أنت متأكد من رغبتك في إزالة "${area.city} (${area.country})"?',
          style: const TextStyle(fontFamily: 'Cairo'),
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
            child: const Text(
              'حذف',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final authState = ref.read(authProvider);
    if (authState is! Authenticated) return;

    setState(() => _isSaving = true);
    try {
      final updatedList = allAreas.where((a) => a.id != area.id).toList();
      final repo = ref.read(driverRepositoryProvider);
      await repo.updateWorkingAreas(authState.user.uid, updatedList);
      ref.invalidate(driverProfileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تم حذف منطقة العمل بنجاح',
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
              'تعذر إزالة منطقة العمل',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: DriverTokens.semanticError,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showAddAreaDialog(List<WorkingArea> currentAreas) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddAreaSheet(
        currentAreas: currentAreas,
        onAreaAdded: () {
          ref.invalidate(driverProfileProvider);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          backgroundColor: isDark ? const Color(0xFF101928) : Colors.white,
          elevation: 0,
          title: const Text(
            'مناطق العمل',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        body: profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: DriverTokens.semanticError,
                ),
                const SizedBox(height: 12),
                const Text(
                  'تعذر تحميل مناطق العمل',
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
            final areas = profile?.workingAreas ?? [];

            return Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(DriverTokens.spaceMd),
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.03)
                      : Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            color: DriverTokens.accentGold,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'المسارات والمدن المستهدفة',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'حدد المدن والمناطق التي ترغب في العمل واستقبال طلبات الرحلات والطرود فيها.',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isSaving)
                  const LinearProgressIndicator(
                    backgroundColor: Colors.transparent,
                    color: DriverTokens.accentGold,
                  ),
                Expanded(
                  child: areas.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(DriverTokens.spaceXl),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.map_outlined,
                                  size: 64,
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                                const SizedBox(height: DriverTokens.spaceMd),
                                Text(
                                  'لم تقم بإضافة مناطق عمل بعد',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: DriverTokens.spaceXs),
                                Text(
                                  'أضف المدن والمحافظات التي تنشط فيها لتصلك الرحلات المناسبة.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 13,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                                const SizedBox(height: DriverTokens.spaceLg),
                                ElevatedButton.icon(
                                  onPressed: () => _showAddAreaDialog(areas),
                                  icon: const Icon(
                                    Icons.add_location_alt_rounded,
                                  ),
                                  label: const Text(
                                    'إضافة منطقة عمل',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: DriverTokens.primaryNavy,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        DriverTokens.radiusSmall,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(DriverTokens.spaceMd),
                          itemCount: areas.length,
                          itemBuilder: (context, index) {
                            final area = areas[index];
                            return _buildAreaCard(context, area, areas);
                          },
                        ),
                ),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            final profile = ref.read(driverProfileProvider).value;
            _showAddAreaDialog(profile?.workingAreas ?? []);
          },
          backgroundColor: DriverTokens.primaryNavy,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_location_alt_rounded),
          label: const Text(
            'إضافة منطقة',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildAreaCard(
    BuildContext context,
    WorkingArea area,
    List<WorkingArea> allAreas,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: DriverTokens.spaceSm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DriverTokens.radiusSmall),
        side: BorderSide(
          color: area.isActive
              ? (isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06))
              : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      elevation: 0,
      color: theme.colorScheme.surface,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: area.isActive
                ? DriverTokens.semanticSuccess.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            area.isActive
                ? Icons.check_circle_rounded
                : Icons.pause_circle_rounded,
            color: area.isActive ? DriverTokens.semanticSuccess : Colors.grey,
            size: 22,
          ),
        ),
        title: Text(
          area.city,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: area.isActive
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        subtitle: Text(
          area.governorate.isNotEmpty
              ? '${area.governorate} — ${area.country}'
              : area.country,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 12,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: area.isActive,
              activeThumbColor: DriverTokens.semanticSuccess,
              onChanged: _isSaving
                  ? null
                  : (_) => _toggleAreaStatus(area, allAreas),
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: DriverTokens.semanticError,
                size: 20,
              ),
              tooltip: 'حذف المنطقة',
              onPressed: _isSaving ? null : () => _removeArea(area, allAreas),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddAreaSheet extends ConsumerStatefulWidget {
  final List<WorkingArea> currentAreas;
  final VoidCallback onAreaAdded;

  const _AddAreaSheet({required this.currentAreas, required this.onAreaAdded});

  @override
  ConsumerState<_AddAreaSheet> createState() => _AddAreaSheetState();
}

class _AddAreaSheetState extends ConsumerState<_AddAreaSheet> {
  Country? _selectedCountry;
  Governorate? _selectedGovernorate;
  City? _selectedCity;
  bool _isSubmitting = false;

  Future<void> _submit() async {
    if (_selectedCountry == null || _selectedCity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'يرجى تحديد الدولة والمدينة',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: DriverTokens.semanticWarning,
        ),
      );
      return;
    }

    // Check duplicate
    final exists = widget.currentAreas.any(
      (a) =>
          a.city.trim().toLowerCase() ==
              _selectedCity!.nameAr.trim().toLowerCase() &&
          a.country.trim().toLowerCase() ==
              _selectedCountry!.nameAr.trim().toLowerCase(),
    );

    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'منطقة العمل هذه مضافة مسبقاً',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: DriverTokens.semanticWarning,
        ),
      );
      return;
    }

    final authState = ref.read(authProvider);
    if (authState is! Authenticated) return;

    setState(() => _isSubmitting = true);
    try {
      final newArea = WorkingArea(
        id: const Uuid().v4(),
        country: _selectedCountry!.nameAr,
        city: _selectedCity!.nameAr,
        governorate: _selectedGovernorate?.nameAr ?? '',
        countryId: _selectedCountry!.id,
        governorateId: _selectedGovernorate?.id ?? '',
        cityId: _selectedCity!.id,
        isActive: true,
      );

      final updated = [...widget.currentAreas, newArea];
      final repo = ref.read(driverRepositoryProvider);
      await repo.updateWorkingAreas(authState.user.uid, updated);

      widget.onAreaAdded();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تمت إضافة منطقة العمل بنجاح',
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
              'تعذر إضافة منطقة العمل',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: DriverTokens.semanticError,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final countriesAsync = ref.watch(countriesProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: EdgeInsets.only(
          left: DriverTokens.spaceLg,
          right: DriverTokens.spaceLg,
          top: DriverTokens.spaceLg,
          bottom:
              MediaQuery.of(context).viewInsets.bottom + DriverTokens.spaceLg,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(DriverTokens.radiusHero),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(
                    Icons.add_location_alt_rounded,
                    color: DriverTokens.accentGold,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'إضافة منطقة عمل جديدة',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DriverTokens.spaceMd),

              // Country Dropdown
              countriesAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => const Text(
                  'تعذر تحميل الدول',
                  style: TextStyle(fontFamily: 'Cairo'),
                ),
                data: (countries) {
                  return DropdownButtonFormField<Country>(
                    decoration: InputDecoration(
                      labelText: 'الدولة',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          DriverTokens.radiusSmall,
                        ),
                      ),
                      prefixIcon: const Icon(Icons.public_rounded),
                    ),
                    value: _selectedCountry,
                    items: countries
                        .map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text(
                              c.nameAr,
                              style: const TextStyle(fontFamily: 'Cairo'),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (c) {
                      setState(() {
                        _selectedCountry = c;
                        _selectedGovernorate = null;
                        _selectedCity = null;
                      });
                    },
                  );
                },
              ),

              const SizedBox(height: DriverTokens.spaceSm),

              // Governorate Dropdown
              if (_selectedCountry != null)
                Consumer(
                  builder: (context, ref, _) {
                    final provAsync = ref.watch(
                      provincesProvider(_selectedCountry!.id),
                    );
                    return provAsync.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => const SizedBox.shrink(),
                      data: (provinces) {
                        return DropdownButtonFormField<Governorate>(
                          decoration: InputDecoration(
                            labelText: 'المحافظة / المنطقة',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                DriverTokens.radiusSmall,
                              ),
                            ),
                            prefixIcon: const Icon(Icons.map_rounded),
                          ),
                          value: _selectedGovernorate,
                          items: provinces
                              .map(
                                (p) => DropdownMenuItem(
                                  value: p,
                                  child: Text(
                                    p.nameAr,
                                    style: const TextStyle(fontFamily: 'Cairo'),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (p) {
                            setState(() {
                              _selectedGovernorate = p;
                              _selectedCity = null;
                            });
                          },
                        );
                      },
                    );
                  },
                ),

              const SizedBox(height: DriverTokens.spaceSm),

              // City Dropdown
              if (_selectedGovernorate != null)
                Consumer(
                  builder: (context, ref, _) {
                    final citiesAsync = ref.watch(
                      citiesProvider(_selectedGovernorate!.id),
                    );
                    return citiesAsync.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => const SizedBox.shrink(),
                      data: (cities) {
                        return DropdownButtonFormField<City>(
                          decoration: InputDecoration(
                            labelText: 'المدينة',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                DriverTokens.radiusSmall,
                              ),
                            ),
                            prefixIcon: const Icon(Icons.location_city_rounded),
                          ),
                          value: _selectedCity,
                          items: cities
                              .map(
                                (city) => DropdownMenuItem(
                                  value: city,
                                  child: Text(
                                    city.nameAr,
                                    style: const TextStyle(fontFamily: 'Cairo'),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (c) => setState(() => _selectedCity = c),
                        );
                      },
                    );
                  },
                ),

              const SizedBox(height: DriverTokens.spaceLg),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting || _selectedCity == null
                      ? null
                      : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DriverTokens.primaryNavy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        DriverTokens.radiusSmall,
                      ),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'تأكيد الإضافة',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
