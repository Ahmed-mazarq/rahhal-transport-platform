import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/bank_catalog.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/widgets/rahhal_app_bar.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/driver_payment_method.dart';
import '../providers/driver_providers.dart';
import '../utils/driver_tokens.dart';

class PaymentMethodsScreen extends ConsumerStatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  ConsumerState<PaymentMethodsScreen> createState() =>
      _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends ConsumerState<PaymentMethodsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final methodsAsync = ref.watch(driverPaymentMethodsProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF101928)
            : DriverTokens.lightBackground,
        appBar: const RahhalAppBar(
          titleText: 'طرق الدفع واستلام الأرباح',
        ),
        body: methodsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
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
                  'حدث خطأ في تحميل طرق الدفع',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => ref.invalidate(driverPaymentMethodsProvider),
                  child: const Text(
                    'إعادة المحاولة',
                    style: TextStyle(fontFamily: 'Cairo'),
                  ),
                ),
              ],
            ),
          ),
          data: (methods) {
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
                            Icons.account_balance_wallet_rounded,
                            color: DriverTokens.accentGold,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'الحسابات البنكية والمحافظ المعتمدة',
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
                        'تستخدم هذه الحسابات لاستقبال مبالغ الحجوزات من الركاب والطرود. يمكنك تفعيل أو تعطيل أي حساب لاستخدامه في رحلاتك مباشرة.',
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
                Expanded(
                  child: methods.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(DriverTokens.spaceXl),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.account_balance_outlined,
                                  size: 64,
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                                const SizedBox(height: DriverTokens.spaceMd),
                                Text(
                                  'لا توجد طرق دفع مسجلة بعد',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: DriverTokens.spaceXs),
                                Text(
                                  'أضف حسابك البنكي أو محفظتك لتتمكن من إنشاء رحلات واستلام العربون',
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
                                  onPressed: () => _showAddMethodWizard(),
                                  icon: const Icon(Icons.add_rounded),
                                  label: const Text(
                                    'إضافة طريقة دفع',
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
                          itemCount: methods.length,
                          itemBuilder: (ctx, i) =>
                              _buildPaymentCard(context, methods[i]),
                        ),
                ),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddMethodWizard(),
          icon: const Icon(Icons.add_rounded),
          label: const Text(
            'إضافة طريقة جديدة',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          ),
          backgroundColor: DriverTokens.primaryNavy,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildPaymentCard(BuildContext context, DriverPaymentMethod method) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    IconData icon;
    Color iconColor;
    if (method.type == 'bank') {
      icon = Icons.account_balance_rounded;
      iconColor = DriverTokens.semanticInfo;
    } else if (method.type == 'wallet') {
      icon = Icons.account_balance_wallet_rounded;
      iconColor = DriverTokens.accentGold;
    } else {
      icon = Icons.credit_card_rounded;
      iconColor = Colors.grey;
    }

    final isRejected = method.approvalStatus.toLowerCase() == 'rejected';

    return Card(
      margin: const EdgeInsets.only(bottom: DriverTokens.spaceMd),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DriverTokens.radiusCard),
        side: BorderSide(
          color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      elevation: 0,
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(DriverTokens.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(
                      DriverTokens.radiusSmall,
                    ),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        method.providerName,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        method.accountHolderName.isNotEmpty
                            ? method.accountHolderName
                            : (method.type == 'bank'
                                  ? 'حساب بنكي'
                                  : 'محفظة إلكترونية'),
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
                _buildApprovalBadge(method),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, color: Colors.grey),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showAddMethodWizard(method: method);
                    } else if (value == 'delete') {
                      _deleteMethod(method);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('تعديل', style: TextStyle(fontFamily: 'Cairo')),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline,
                            color: DriverTokens.semanticError,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'حذف',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              color: DriverTokens.semanticError,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (method.accountNumber.isNotEmpty)
                      Row(
                        children: [
                          Text(
                            'رقم الحساب: ',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                          Text(
                            method.accountNumber,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            textDirection: TextDirection.ltr,
                          ),
                        ],
                      ),
                    if (method.iban.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'IBAN: ',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                          Text(
                            method.iban,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            textDirection: TextDirection.ltr,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
                // Activation Switch
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      method.isActive ? 'مفعلة' : 'غير مفعلة',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        color: method.isActive
                            ? DriverTokens.semanticSuccess
                            : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Switch(
                      value: method.isActive,
                      activeThumbColor: DriverTokens.semanticSuccess,
                      onChanged: (val) => _toggleActive(method, val),
                    ),
                  ],
                ),
              ],
            ),
            if (isRejected && method.rejectionReason.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: DriverTokens.semanticError.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(DriverTokens.radiusSmall),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: DriverTokens.semanticError,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'سبب الرفض: ${method.rejectionReason}',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11,
                          color: DriverTokens.semanticError,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildApprovalBadge(DriverPaymentMethod method) {
    Color bg;
    Color fg;
    String label;
    IconData icon;

    if (method.approvalStatus.toLowerCase() == 'rejected') {
      bg = DriverTokens.semanticError.withValues(alpha: 0.12);
      fg = DriverTokens.semanticError;
      label = 'مرفوضة';
      icon = Icons.cancel_rounded;
    } else if (method.isActive) {
      bg = DriverTokens.semanticSuccess.withValues(alpha: 0.12);
      fg = DriverTokens.semanticSuccess;
      label = 'مفعلة';
      icon = Icons.check_circle_rounded;
    } else {
      bg = Colors.grey.withValues(alpha: 0.12);
      fg = Colors.grey;
      label = 'غير مفعلة';
      icon = Icons.pause_circle_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(DriverTokens.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: fg, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Cairo',
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleActive(DriverPaymentMethod method, bool isActive) async {
    try {
      final repo = ref.read(driverRepositoryProvider);
      await repo.toggleDriverPaymentMethodActive(method.id, isActive);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تعذر تحديث حالة تفعيل طريقة الدفع',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: DriverTokens.semanticError,
          ),
        );
      }
    }
  }

  Future<void> _deleteMethod(DriverPaymentMethod method) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'تأكيد الحذف',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        content: Text(
          'هل أنت متأكد من حذف طريقة الدفع "${method.providerName}"؟',
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

    if (confirm == true) {
      try {
        final repo = ref.read(driverRepositoryProvider);
        await repo.deleteDriverPaymentMethod(method.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'تم حذف طريقة الدفع بنجاح',
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
                'تعذر حذف طريقة الدفع',
                style: TextStyle(fontFamily: 'Cairo'),
              ),
              backgroundColor: DriverTokens.semanticError,
            ),
          );
        }
      }
    }
  }

  void _showAddMethodWizard({DriverPaymentMethod? method}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _AddPaymentMethodWizard(initialMethod: method),
    );
  }
}

class _AddPaymentMethodWizard extends ConsumerStatefulWidget {
  final DriverPaymentMethod? initialMethod;
  const _AddPaymentMethodWizard({this.initialMethod});

  @override
  ConsumerState<_AddPaymentMethodWizard> createState() =>
      _AddPaymentMethodWizardState();
}

class _AddPaymentMethodWizardState
    extends ConsumerState<_AddPaymentMethodWizard> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 5;

  String? _selectedType;
  String? _selectedCountry;
  Map<String, dynamic>? _selectedProvider;

  final _holderNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _ibanController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialMethod != null) {
      final method = widget.initialMethod!;
      _selectedType = method.type;
      _selectedCountry = method.country.isNotEmpty ? method.country : 'YE';
      _holderNameController.text = method.accountHolderName;
      _accountNumberController.text = method.accountNumber;
      _ibanController.text = method.iban;

      final providers = BankCatalog.getProvidersByCountryAndType(
        _selectedCountry!,
        _selectedType!,
      );
      try {
        _selectedProvider = providers.firstWhere(
          (p) => p['nameAr'] == method.providerName,
        );
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _holderNameController.dispose();
    _accountNumberController.dispose();
    _ibanController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0 && _selectedType == null) return;
    if (_currentStep == 1 && _selectedCountry == null) return;
    if (_currentStep == 2 && _selectedProvider == null) return;
    if (_currentStep == 3) {
      if (_holderNameController.text.trim().isEmpty ||
          _accountNumberController.text.trim().isEmpty) {
        return;
      }
      if (_selectedProvider?['supportsIban'] == true &&
          _ibanController.text.trim().isEmpty) {
        return;
      }
    }

    if (_currentStep == 4) {
      _submit();
      return;
    }

    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);

    final authState = ref.read(authProvider);
    if (authState is! Authenticated) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final methodToSave = DriverPaymentMethod(
        id: widget.initialMethod?.id ?? '',
        driverId: authState.user.uid,
        type:
            _selectedProvider!['type']?.toString() ?? (_selectedType ?? 'bank'),
        providerName: _selectedProvider!['nameAr']?.toString() ?? '',
        country: _selectedCountry ?? 'YE',
        currency: _selectedProvider!['currency']?.toString() ?? 'YER',
        accountNumber: _accountNumberController.text.trim(),
        accountHolderName: _holderNameController.text.trim(),
        iban: _ibanController.text.trim(),
        isActive: widget.initialMethod?.isActive ?? true,
        approvalStatus: 'not_required',
      );

      final repo = ref.read(driverRepositoryProvider);
      await repo.saveDriverPaymentMethod(methodToSave);

      if (!mounted) return;
      setState(() => _isLoading = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.initialMethod != null
                ? 'تم تحديث بيانات طريقة الدفع بنجاح'
                : 'تمت إضافة طريقة الدفع بنجاح وهي مفعلة للاستخدام',
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: DriverTokens.semanticSuccess,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تعذر حفظ بيانات طريقة الدفع',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: DriverTokens.semanticError,
        ),
      );
    }
  }

  bool _isNextEnabled() {
    if (_currentStep == 0 && _selectedType == null) return false;
    if (_currentStep == 1 && _selectedCountry == null) return false;
    if (_currentStep == 2 && _selectedProvider == null) return false;
    if (_currentStep == 3) {
      if (_holderNameController.text.trim().isEmpty ||
          _accountNumberController.text.trim().isEmpty) {
        return false;
      }
      if (_selectedProvider?['supportsIban'] == true &&
          _ibanController.text.trim().isEmpty) {
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.initialMethod != null
                ? 'تعديل طريقة الدفع'
                : 'إضافة حساب جديد',
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4.0),
            child: LinearProgressIndicator(
              value: (_currentStep + 1) / _totalSteps,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(
                DriverTokens.primaryNavy,
              ),
            ),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildStep1(),
                          _buildStep2(),
                          _buildStep3(),
                          _buildStep4(),
                          _buildStep5(),
                        ],
                      ),
                    ),
                    _buildBottomControls(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStep1() {
    return _WizardPage(
      title: 'نوع الحساب',
      subtitle: 'اختر نوع الحساب الذي ترغب في إضافته',
      content: Column(
        children: [
          _buildOptionTile(
            title: 'حساب بنكي',
            value: 'bank',
            groupValue: _selectedType,
            onTap: () => setState(() => _selectedType = 'bank'),
            icon: Icons.account_balance_rounded,
          ),
          const SizedBox(height: 12),
          _buildOptionTile(
            title: 'محفظة إلكترونية',
            value: 'wallet',
            groupValue: _selectedType,
            onTap: () => setState(() => _selectedType = 'wallet'),
            icon: Icons.account_balance_wallet_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return _WizardPage(
      title: 'الدولة',
      subtitle: 'اختر الدولة التي يتبع لها الحساب',
      content: Column(
        children: [
          _buildOptionTile(
            title: 'اليمن',
            value: 'YE',
            groupValue: _selectedCountry,
            onTap: () => setState(() {
              _selectedCountry = 'YE';
              _selectedProvider = null;
            }),
            icon: Icons.flag_rounded,
          ),
          const SizedBox(height: 12),
          _buildOptionTile(
            title: 'السعودية',
            value: 'SA',
            groupValue: _selectedCountry,
            onTap: () => setState(() {
              _selectedCountry = 'SA';
              _selectedProvider = null;
            }),
            icon: Icons.flag_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    List<Map<String, dynamic>> providers = [];
    if (_selectedCountry != null && _selectedType != null) {
      providers = BankCatalog.getProvidersByCountryAndType(
        _selectedCountry!,
        _selectedType!,
      );
    }

    return _WizardPage(
      title: 'البنك / المزود',
      subtitle: 'اختر مزود الخدمة من القائمة الرسمية',
      content: providers.isEmpty
          ? const Center(
              child: Text(
                'لا يوجد مزودين متاحين لهذا الاختيار',
                style: TextStyle(fontFamily: 'Cairo', color: Colors.grey),
              ),
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: providers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final p = providers[i];
                final isSelected = _selectedProvider?['id'] == p['id'];
                return InkWell(
                  onTap: () => setState(() => _selectedProvider = p),
                  borderRadius: BorderRadius.circular(DriverTokens.radiusSmall),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected
                            ? DriverTokens.primaryNavy
                            : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(
                        DriverTokens.radiusSmall,
                      ),
                      color: isSelected
                          ? DriverTokens.primaryNavy.withValues(alpha: 0.05)
                          : Colors.transparent,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.business_rounded,
                          color: isSelected
                              ? DriverTokens.primaryNavy
                              : Colors.grey,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            p['nameAr'],
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: DriverTokens.primaryNavy,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildStep4() {
    final supportsIban = _selectedProvider?['supportsIban'] == true;
    return _WizardPage(
      title: 'بيانات الحساب',
      subtitle: 'أدخل تفاصيل حسابك بدقة لضمان استقبال الحوالات',
      content: Column(
        children: [
          TextField(
            controller: _holderNameController,
            decoration: InputDecoration(
              labelText: 'اسم صاحب الحساب / المحفظة',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DriverTokens.radiusSmall),
              ),
              prefixIcon: const Icon(Icons.person_outline_rounded),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _accountNumberController,
            decoration: InputDecoration(
              labelText: 'رقم الحساب / المحفظة',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DriverTokens.radiusSmall),
              ),
              prefixIcon: const Icon(Icons.pin_rounded),
            ),
            keyboardType: TextInputType.number,
            textDirection: TextDirection.ltr,
            onChanged: (_) => setState(() {}),
          ),
          if (supportsIban) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _ibanController,
              decoration: InputDecoration(
                labelText: 'رقم الآيبان (IBAN)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DriverTokens.radiusSmall),
                ),
                prefixIcon: const Icon(Icons.account_balance_outlined),
                hintText: 'SA...',
              ),
              textDirection: TextDirection.ltr,
              onChanged: (_) => setState(() {}),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStep5() {
    return _WizardPage(
      title: 'مراجعة البيانات',
      subtitle: 'تأكد من صحة بيانات الحساب قبل الحفظ',
      content: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(DriverTokens.radiusSmall),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _reviewRow(
              'الدولة',
              _selectedCountry == 'SA' ? 'السعودية' : 'اليمن',
            ),
            _reviewRow('المزود', _selectedProvider?['nameAr'] ?? ''),
            _reviewRow(
              'النوع',
              _selectedType == 'bank' ? 'حساب بنكي' : 'محفظة إلكترونية',
            ),
            const Divider(height: 24),
            _reviewRow('صاحب الحساب', _holderNameController.text.trim()),
            _reviewRow('رقم الحساب', _accountNumberController.text.trim()),
            if (_selectedProvider?['supportsIban'] == true)
              _reviewRow('IBAN', _ibanController.text.trim()),
            _reviewRow('العملة', _selectedProvider?['currency'] ?? ''),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required String title,
    required String value,
    required String? groupValue,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    final isSelected = value == groupValue;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DriverTokens.radiusSmall),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? DriverTokens.primaryNavy : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(DriverTokens.radiusSmall),
          color: isSelected
              ? DriverTokens.primaryNavy.withValues(alpha: 0.05)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? DriverTokens.primaryNavy : Colors.grey,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 15,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: DriverTokens.primaryNavy,
              )
            else
              const Icon(Icons.radio_button_unchecked, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _previousStep,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DriverTokens.radiusSmall),
                ),
              ),
              child: const Text(
                'رجوع',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isNextEnabled() ? _nextStep : null,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 48),
                backgroundColor: DriverTokens.primaryNavy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DriverTokens.radiusSmall),
                ),
              ),
              child: Text(
                _currentStep == 4 ? 'إرسال الحساب للاعتماد' : 'التالي',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Cairo',
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _WizardPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget content;

  const _WizardPage({
    required this.title,
    required this.subtitle,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: DriverTokens.primaryNavy,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: content,
            ),
          ),
        ],
      ),
    );
  }
}
