import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';

double _toDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0.0;
}

class FinancialScreen extends StatefulWidget {
  const FinancialScreen({super.key});

  @override
  State<FinancialScreen> createState() => _FinancialScreenState();
}

class _FinancialScreenState extends State<FinancialScreen> {
  Map<String, dynamic>? _summary;
  List<dynamic> _projects = [];
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
      ApiService.get('/projects', token),
      ApiService.get('/quotes', token),
    ]);
    if (mounted) {
      setState(() {
        _summary = results[0]['data'];
        _projects = results[1]['data'] ?? [];
        _invoices = results[2]['data'] ?? [];
        _isLoading = false;
      });
    }
  }

  String _formatCurrency(dynamic value) {
    final v = _toDouble(value);
    if (v >= 1000000) {
      return '\$${(v / 1000000).toStringAsFixed(1)}M';
    } else if (v >= 1000) {
      return '\$${(v / 1000).toStringAsFixed(1)}K';
    }
    return '\$${v.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0d1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161b22),
        title: const Text('Financial', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1a73e8)))
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // KPI Cards
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.5,
                      children: [
                        _KpiCard(
                          title: 'Total Revenue',
                          value: _formatCurrency(_summary?['total_revenue']),
                          icon: Icons.trending_up,
                          color: Colors.green,
                        ),
                        _KpiCard(
                          title: 'Total Cost',
                          value: _formatCurrency(_summary?['total_cost']),
                          icon: Icons.trending_down,
                          color: Colors.red,
                        ),
                        _KpiCard(
                          title: 'Net Profit',
                          value: _formatCurrency(_summary?['net_profit']),
                          icon: Icons.account_balance,
                          color: const Color(0xFF1a73e8),
                        ),
                        _KpiCard(
                          title: 'Pending Invoices',
                          value: '${_summary?['pending_invoices_count'] ?? 0}',
                          subtitle: _formatCurrency(_summary?['pending_invoices_amount']),
                          icon: Icons.receipt_long,
                          color: Colors.orange,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Project Revenue table
                    const Text('Project Revenue', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF161b22),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          // Header
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: const BoxDecoration(
                              border: Border(bottom: BorderSide(color: Colors.white12)),
                            ),
                            child: const Row(
                              children: [
                                Expanded(flex: 3, child: Text('Project', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold))),
                                Expanded(flex: 2, child: Text('Revenue', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                              ],
                            ),
                          ),
                          ..._projects.take(10).map((p) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: const BoxDecoration(
                              border: Border(bottom: BorderSide(color: Colors.white12, width: 0.5)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(p['project_title'] ?? p['name'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 13), overflow: TextOverflow.ellipsis),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    _formatCurrency(p['revenue'] ?? p['total_revenue'] ?? p['budget']),
                                    style: const TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ],
                            ),
                          )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Sales Invoices
                    const Text('Sales Invoices', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    if (_invoices.isEmpty)
                      const Center(child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('No invoices found', style: TextStyle(color: Colors.grey)),
                      ))
                    else
                      ..._invoices.take(15).map((inv) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF161b22),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.receipt, color: Color(0xFF1a73e8), size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(inv['quote_number'] ?? inv['invoice_number'] ?? inv['title'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                                  Text(inv['customer_name'] ?? inv['client'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(_formatCurrency(inv['total'] ?? inv['amount']), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                                Text(inv['status'] ?? '', style: TextStyle(
                                  color: (inv['status']?.toString().toLowerCase() == 'paid' || inv['status']?.toString().toLowerCase() == 'approved') ? Colors.green : Colors.orange,
                                  fontSize: 11,
                                )),
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
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;

  const _KpiCard({
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161b22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 28),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
              if (subtitle != null)
                Text(subtitle!, style: const TextStyle(color: Colors.grey, fontSize: 11)),
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}
