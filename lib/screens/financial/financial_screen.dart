import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../core/constants.dart';
import '../../widgets/common.dart';

class FinancialScreen extends StatefulWidget {
  const FinancialScreen({super.key});
  @override
  State<FinancialScreen> createState() => _FinancialScreenState();
}

class _FinancialScreenState extends State<FinancialScreen> {
  Map<String, dynamic>? _summary;
  List<dynamic> _invoices = [];
  bool _isLoading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final token = context.read<AuthService>().token!;
    final summary = await ApiService.get('/financial/summary', token);
    final invoices = await ApiService.get('/invoices', token);
    if (mounted) setState(() {
      _summary = summary['data'];
      _invoices = invoices['data'] ?? [];
      _isLoading = false;
    });
  }

  String _fmtCurrency(dynamic v) {
    final d = toDouble(v);
    return '\u20AC${d.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }

  Color _statusColor(String? s) {
    switch (s?.toLowerCase()) {
      case 'paid': return AppColors.success;
      case 'pending': return AppColors.warning;
      case 'overdue': return AppColors.danger;
      default: return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final revenue = toDouble(_summary?['total_revenue']);
    final cost = toDouble(_summary?['total_cost']);
    final profit = revenue - cost;
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: wolfAppBar(title: 'Financial', showBack: true),
      body: _isLoading
          ? const LoadingState()
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.6,
                      children: [
                        _KpiCard(label: 'TOTAL REVENUE', value: _fmtCurrency(revenue), color: AppColors.primary),
                        _KpiCard(label: 'TOTAL COST', value: _fmtCurrency(cost), color: AppColors.danger),
                        _KpiCard(label: 'NET PROFIT', value: _fmtCurrency(profit), color: profit >= 0 ? AppColors.success : AppColors.danger),
                        _KpiCard(label: 'PENDING', value: _fmtCurrency(_summary?['pending_invoice_amount']), color: AppColors.warning),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const SectionHeader(title: 'Recent Invoices'),
                    const SizedBox(height: 12),
                    if (_invoices.isEmpty)
                      const EmptyState(icon: Icons.receipt_long, message: 'No invoices')
                    else
                      ..._invoices.take(20).map((inv) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.bgCard,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.receipt, color: _statusColor(inv['status']), size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    inv['invoice_number'] ?? '#${inv['id']}',
                                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    inv['vendor_name'] ?? inv['customer_name'] ?? '',
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _fmtCurrency(inv['amount'] ?? inv['total_amount']),
                                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                                Container(
                                  margin: const EdgeInsets.only(top: 2),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _statusColor(inv['status']).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    inv['status'] ?? '',
                                    style: TextStyle(color: _statusColor(inv['status']), fontSize: 10, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )),
                  ],
                ),
              ),
            ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _KpiCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, letterSpacing: 0.4, fontWeight: FontWeight.w600)),
          Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
