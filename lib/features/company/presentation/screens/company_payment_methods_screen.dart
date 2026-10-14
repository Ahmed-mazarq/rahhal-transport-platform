import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/bank_catalog.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../driver/domain/models/driver_payment_method.dart';
import '../providers/company_providers.dart';

class CompanyPaymentMethodsScreen extends ConsumerStatefulWidget {
  const CompanyPaymentMethodsScreen({super.key});

  @override
  ConsumerState<CompanyPaymentMethodsScreen> createState() =>
      _CompanyPaymentMethodsScreenState();
}

class _CompanyPaymentMethodsScreenState
    extends ConsumerState<CompanyPaymentMethodsScreen> {
  @override
  Widget build(BuildContext context) {
    final methodsAsync = ref.watch(companyPaymentMethodsProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'طرق استلام المدفوعات',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
        ),
        body: methodsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
            child: Text(
              'حدث خطأ في تحميل طرق الدفع',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
          ),
          data: (methods) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'أضف الحسابات البنكية والمحافظ الإلكترونية لاستلام مستحقاتك من منصة رحال.',
                  style: TextStyle(fontFamily: 'Cairo', color: Colors.grey),
                ),
                const SizedBox(height: 24),
                if (methods.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text(
                        'لا توجد طرق دفع مسجلة',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ...methods.map((m) => _buildPaymentCard(m)),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            _showAddMethodDialog();
          },
          icon: const Icon(Icons.add),
          label: const Text(
            'إضافة طريقة دفع',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF0B1F3A),
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildPaymentCard(DriverPaymentMethod method) {
    IconData icon;
    Color color;
    switch (method.type) {
      case 'bank':
        icon = Icons.account_balance;
        color = Colors.blue;
        break;
      case 'wallet':
        icon = Icons.account_balance_wallet;
        color = Colors.orange;
        break;
      default:
        icon = Icons.credit_card;
        color = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          method.providerName,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (method.accountNumber.isNotEmpty)
              Text(
                method.accountNumber,
                style: const TextStyle(fontFamily: 'Cairo', color: Colors.grey),
                textDirection: TextDirection.ltr,
              ),
            if (method.iban.isNotEmpty)
              Text(
                method.iban,
                style: const TextStyle(fontFamily: 'Cairo', color: Colors.grey),
                textDirection: TextDirection.ltr,
              ),
            if (method.rejectionReason.isNotEmpty &&
                method.approvalStatus == 'rejected')
              Text(
                'السبب: ${method.rejectionReason}',
                style: const TextStyle(fontFamily: 'Cairo', color: Colors.red),
              ),
          ],
        ),
        trailing: _buildStatusIcon(method.approvalStatus),
        onLongPress: () => _deleteMethod(method),
      ),
    );
  }

  Widget _buildStatusIcon(String status) {
    switch (status) {
      case 'approved':
        return const Icon(Icons.verified, color: Colors.green);
      case 'rejected':
        return const Icon(Icons.error, color: Colors.red);
      default:
        return const Icon(Icons.pending, color: Colors.orange);
    }
  }

  void _deleteMethod(DriverPaymentMethod method) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف', style: TextStyle(fontFamily: 'Cairo')),
        content: const Text(
          'هل أنت متأكد من حذف طريقة الدفع هذه؟',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final firestore = ref.read(firestoreProvider);
      await firestore
          .collection('company_payment_methods')
          .doc(method.id)
          .delete();
    }
  }

  void _showAddMethodDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.8,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'اختر طريقة الاستلام',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: BankCatalog.banks.length,
                        itemBuilder: (context, index) {
                          final bank = BankCatalog.banks[index];
                          return ListTile(
                            leading: Icon(
                              bank['type'] == 'bank'
                                  ? Icons.account_balance
                                  : Icons.account_balance_wallet,
                              color: bank['type'] == 'bank'
                                  ? Colors.blue
                                  : Colors.orange,
                            ),
                            title: Text(
                              bank['nameAr'],
                              style: const TextStyle(fontFamily: 'Cairo'),
                            ),
                            subtitle: Text(
                              bank['nameEn'],
                              style: const TextStyle(fontSize: 12),
                            ),
                            onTap: () {
                              Navigator.pop(ctx);
                              _showMethodForm(bank);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showMethodForm(Map<String, dynamic> bank) {
    final accountNameController = TextEditingController();
    final accountNumberController = TextEditingController();
    final ibanController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'إضافة ${bank['nameAr']}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: accountNameController,
                    decoration: const InputDecoration(
                      labelText: 'الاسم الكامل للمستفيد',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: accountNumberController,
                    decoration: const InputDecoration(
                      labelText: 'رقم الحساب / المحفظة',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  if (bank['supportsIban'] == true) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: ibanController,
                      decoration: const InputDecoration(
                        labelText: 'رقم الآيبان (IBAN)',
                      ),
                      textDirection: TextDirection.ltr,
                    ),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      backgroundColor: const Color(0xFF0B1F3A),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      final name = accountNameController.text.trim();
                      final number = accountNumberController.text.trim();
                      final iban = ibanController.text.trim();

                      if (name.isEmpty || number.isEmpty) return;

                      final authState = ref.read(authProvider);
                      if (authState is! Authenticated) return;

                      final firestore = ref.read(firestoreProvider);
                      await firestore.collection('company_payment_methods').add({
                        'companyId': authState.user.uid, // Use companyId
                        'driverId': authState
                            .user
                            .uid, // DriverId field also populated for model compatibility
                        'type': bank['type'],
                        'providerName': bank['nameAr'],
                        'country': bank['country'],
                        'currency': bank['currency'],
                        'accountNumber': number,
                        'accountHolderName': name,
                        'iban': iban,
                        'isActive': true,
                        'approvalStatus': 'pending', // Requires admin approval
                        'createdAt': FieldValue.serverTimestamp(),
                        'updatedAt': FieldValue.serverTimestamp(),
                      });

                      if (context.mounted) Navigator.pop(ctx);
                    },
                    child: const Text(
                      'حفظ',
                      style: TextStyle(fontFamily: 'Cairo'),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
