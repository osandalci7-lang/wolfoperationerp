import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../widgets/common.dart';

class VendorsScreen extends StatefulWidget {
  const VendorsScreen({super.key});

  @override
  State<VendorsScreen> createState() => _VendorsScreenState();
}

class _VendorsScreenState extends State<VendorsScreen> {
  List<dynamic> _vendors = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = context.read<AuthService>().token!;
    final data = await ApiService.get('/vendors', token);
    if (mounted) {
      setState(() {
        _vendors = data['data'] ?? [];
        _isLoading = false;
      });
    }
  }

  List<dynamic> get _filtered {
    if (_searchQuery.isEmpty) return _vendors;
    final q = _searchQuery.toLowerCase();
    return _vendors.where((v) =>
      (v['name'] ?? '').toString().toLowerCase().contains(q) ||
      (v['contact_person'] ?? '').toString().toLowerCase().contains(q)
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: wolfAppBar(title: 'Vendors', showBack: true),
      body: Column(
        children: [
          AppSearchBar(hint: 'Search vendors...', onChanged: (v) => setState(() => _searchQuery = v)),
          Expanded(
            child: _isLoading
                ? const LoadingState()
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filtered.length,
                      itemBuilder: (context, index) {
                        final v = _filtered[index];
                        return GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(
                            builder: (_) => VendorDetailScreen(vendorId: v['id'], vendorName: v['name'] ?? ''),
                          )),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.bgCard,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border.withOpacity(0.5)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44, height: 44,
                                  decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                                  child: const Icon(Icons.business, color: AppColors.primary),
                                ),
                                const SizedBox(width: 14),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(v['name'] ?? '', style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                                  if (v['contact_person'] != null)
                                    Text(v['contact_person'], style: const TextStyle(color: AppColors.primary, fontSize: 12)),
                                  if (v['email'] != null)
                                    Text(v['email'], style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                                ])),
                                const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class VendorDetailScreen extends StatefulWidget {
  final int vendorId;
  final String vendorName;
  const VendorDetailScreen({super.key, required this.vendorId, required this.vendorName});

  @override
  State<VendorDetailScreen> createState() => _VendorDetailScreenState();
}

class _VendorDetailScreenState extends State<VendorDetailScreen> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _vendor;
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final token = context.read<AuthService>().token!;
    final data = await ApiService.get('/vendors/${widget.vendorId}', token);
    if (mounted) {
      setState(() {
        _vendor = data['data'];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgCard,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(widget.vendorName, style: const TextStyle(color: Colors.white, fontSize: 16)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [Tab(text: 'Info'), Tab(text: 'Purchase Orders'), Tab(text: 'Invoices')],
        ),
      ),
      body: _isLoading
          ? const LoadingState()
          : TabBarView(
              controller: _tabController,
              children: [
                // Info
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(12)),
                    child: Column(children: [
                      InfoRow(label: 'Name', value: _vendor?['name']),
                      const Divider(color: AppColors.border, height: 1),
                      InfoRow(label: 'Contact', value: _vendor?['contact_person']),
                      const Divider(color: AppColors.border, height: 1),
                      InfoRow(label: 'Email', value: _vendor?['email']),
                      const Divider(color: AppColors.border, height: 1),
                      InfoRow(label: 'Phone', value: _vendor?['phone']),
                      const Divider(color: AppColors.border, height: 1),
                      InfoRow(label: 'Country', value: _vendor?['country']),
                      const Divider(color: AppColors.border, height: 1),
                      InfoRow(label: 'Currency', value: _vendor?['currency']),
                      const Divider(color: AppColors.border, height: 1),
                      InfoRow(label: 'Address', value: _vendor?['address']),
                      const Divider(color: AppColors.border, height: 1),
                      InfoRow(label: 'Tax Number', value: _vendor?['tax_number']),
                    ]),
                  ),
                ),
                // POs
                _buildList(_vendor?['purchase_orders'] ?? [], isPo: true),
                // Invoices
                _buildList(_vendor?['invoices'] ?? [], isPo: false),
              ],
            ),
    );
  }

  Widget _buildList(List<dynamic> items, {required bool isPo}) {
    if (items.isEmpty) return EmptyState(icon: isPo ? Icons.receipt_long : Icons.description, message: isPo ? 'No purchase orders' : 'No invoices');
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(10)),
          child: Row(
            children: [
              Icon(isPo ? Icons.receipt_long : Icons.description, color: isPo ? AppColors.primary : AppColors.msGreen, size: 24),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item['po_number'] ?? item['invoice_number'] ?? '#${item['id']}',
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                Text(item['description'] ?? item['notes'] ?? '', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('\u20AC${toDouble(item['total_amount'] ?? item['amount'] ?? item['total']).toStringAsFixed(2)}',
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
                if (item['status'] != null)
                  StatusBadge.fromStatus(item['status']),
              ]),
            ],
          ),
        );
      },
    );
  }
}
