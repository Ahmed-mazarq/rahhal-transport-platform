import 'package:flutter/material.dart';
import '../../../../core/utils/rtl_format.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  double _balance = 345.50;

  final List<Map<String, dynamic>> _transactions = [
    {
      'title': 'شحن الرصيد - بطاقة مدى',
      'type': 'credit',
      'amount': 150.00,
      'date': DateTime.now().subtract(const Duration(hours: 4)),
    },
    {
      'title': 'خصم قيمة رحلة - رقم #٨٧٢١',
      'type': 'debit',
      'amount': 45.00,
      'date': DateTime.now().subtract(const Duration(days: 1)),
    },
    {
      'title': 'شحن الرصيد - أبل باي',
      'type': 'credit',
      'amount': 200.00,
      'date': DateTime.now().subtract(const Duration(days: 2)),
    },
    {
      'title': 'خصم قيمة رحلة - رقم #٨١٠٢',
      'type': 'debit',
      'amount': 38.50,
      'date': DateTime.now().subtract(const Duration(days: 3)),
    },
  ];

  void _chargeBalance(double amount) {
    setState(() {
      _balance += amount;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تم شحن رصيدك بنجاح بمبلغ ${RtlFormat.formatPrice(amount)}',
          textAlign: TextAlign.right,
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'المحفظة الإلكترونية',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Premium Balance Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'الرصيد المتاح حالياً',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      RtlFormat.formatPrice(_balance),
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'العملة الرسمية: ريال سعودي',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            color: Colors.white60,
                            fontSize: 12,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.verified,
                                size: 16,
                                color: Colors.white,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'حساب نشط',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Charge Operations
              const Text(
                'شحن رصيد سريع',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildChargeOption(50.00),
                  const SizedBox(width: 12),
                  _buildChargeOption(100.00),
                  const SizedBox(width: 12),
                  _buildChargeOption(200.00),
                ],
              ),
              const SizedBox(height: 28),

              // Transaction History
              const Text(
                'سجل المعاملات والعمليات',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _transactions.length,
                itemBuilder: (context, index) {
                  final trans = _transactions[index];
                  final isCredit = trans['type'] == 'credit';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isCredit
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.red.withValues(alpha: 0.1),
                        child: Icon(
                          isCredit
                              ? Icons.add_circle_outline
                              : Icons.remove_circle_outline,
                          color: isCredit ? Colors.green : Colors.red,
                        ),
                      ),
                      title: Text(
                        trans['title'] as String,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        '${RtlFormat.formatDate(trans['date'] as DateTime)} - ${RtlFormat.formatTime(trans['date'] as DateTime)}',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                      trailing: Text(
                        '${isCredit ? '+' : '-'}${RtlFormat.formatPrice(trans['amount'] as double)}',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isCredit ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChargeOption(double amount) {
    final theme = Theme.of(context);
    return Expanded(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
          foregroundColor: theme.colorScheme.primary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onPressed: () => _chargeBalance(amount),
        child: Text(
          '+${amount.toInt()} ريال',
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
