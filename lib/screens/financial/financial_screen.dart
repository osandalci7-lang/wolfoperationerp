import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
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
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = context.read<AuthService>().token!;
    final results = await Future.wait([
      ApiService.get('/financial/summary', token),
      ApiService.get('/invoices', token),
    ]);
    if (mounted) {
      setState(() {
        _summary = results[0]['data'];
        _invoices = results[1]['data'] ?? [];
        _isLoading = false;
      });
    }
  }

  String _fmtCurrency(dynamic value) {
    final v = toDouble(value);
    if (v.abs() >= 1000000) return '\u20AC${(v / 1000000).toStringAsFixed(1)}M';
    if (v.abs() >= 1000) return '\u20AC${(v / 1000).toStringAsFixed(1)}K';
    return '\u20AC${v.toStringAsFixed(0)}';
  }

  Color _invoiceStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'paid':
        return AppColors.msGreen;
      case 'pending':
      case 'received':
        return AppColors.msOrange;
      case 'draft':
        return AppColors.textSecondary;
      default:
        return AppColors.msRed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final revenue = toDouble(_summary?['revenue']);
    final cost = toDouble(_summary?['cost']);
    final profit = toDouble(_summary?['profit']);

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
                children: [
                  // KPI Cards — web'deki 4'lü grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.6,
                    children: [
                      _KpiCard(label: 'TOTAL REVENUE', value: _fmtCurrency(revenue), color: AppColors.msBlue),
                      _KpiCard(label: 'TOTAL COST', value: _fmtCurrency(cost), color: AppColors.msRed),
                      _KpiCard(label: 'NET PROFIT', value: _fmtCurrency(profit), color: profit >= 0 ? AppColors.msGreen : AppColors.msRed),
                      _KpiCard(label: 'PENDING INVOICES', value: _fmtCurrency(_summary?['pending_invoice_amount']), color: AppColors.msOrange),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Month info
                  if (_summary?['month'] != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text('Period: ${_summary!['month']}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    ),

                  // Recent Invoices
                  const SectionHeader(title: 'Recent Invoices'),
                  if (_invoices.isEmpty)
                    const EmptyState(icon: Icons.receipt_long, message: 'No invoices')
                  else
                    ..._invoices.take(20).map((inv) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        children: [
                          Icon(Icons.receipt, color: _invoiceStatusColor(inv['status']), size: 24),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(inv['invoice_number'] ?? inv['title'] ?? '#${inv['id']}',
                                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                            Text(inv['vendor_name'] ?? '', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          ])),
                          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                            Text('\u20AC${toDouble(inv['amount'] ?? inv['total']).toStringAsFixed(2)}',
                                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
                            // Web'deki invoice status badge
                            Container(
                              margin: const EdgeInsets.only(top: 2),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _invoiceStatusColor(inv['status']).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(inv['status'] ?? '', style: TextStyle(color: _invoiceStatusColor(inv['status']), fontSize: 10, fontWeight: FontWeight.w600)),
                            ),
                          ]),
                        ],
                      ),
                    )),
                ],
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
