import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';

double _toDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0.0;
}

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
      (v['contact_person'] ?? '').toString().toLowerCase().contains(q) ||
      (v['country'] ?? '').toString().toLowerCase().contains(q)
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0d1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161b22),
        title: const Text('Vendors', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search vendors...',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF161b22),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF1a73e8)))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filtered.length,
                      itemBuilder: (context, index) {
                        final vendor = _filtered[index];
                        return GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => VendorDetailScreen(
                                vendorId: vendor['id'],
                                vendorName: vendor['name'] ?? '',
                              ),
                            ),
                          ),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF161b22),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withOpacity(0.05)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1a73e8).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.business, color: Color(0xFF1a73e8)),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(vendor['name'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on, color: Colors.grey, size: 14),
                                          const SizedBox(width: 4),
                                          Text(vendor['country'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                          const SizedBox(width: 12),
                                          const Icon(Icons.monetization_on, color: Colors.grey, size: 14),
                                          const SizedBox(width: 4),
                                          Text(vendor['currency'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                        ],
                                      ),
                                      Text(vendor['contact_person'] ?? '', style: const TextStyle(color: Color(0xFF1a73e8), fontSize: 12)),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right, color: Colors.grey),
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

  const VendorDetailScreen({
    super.key,
    required this.vendorId,
    required this.vendorName,
  });

  @override
  State<VendorDetailScreen> createState() => _VendorDetailScreenState();
}

class _VendorDetailScreenState extends State<VendorDetailScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _vendor;
  List<dynamic> _purchaseOrders = [];
  List<dynamic> _invoices = [];
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    final token = context.read<AuthService>().token!;
    final results = await Future.wait([
      ApiService.get('/vendors/${widget.vendorId}', token),
      ApiService.get('/purchase-orders?vendor_id=${widget.vendorId}', token),
    ]);
    if (mounted) {
      setState(() {
        _vendor = results[0]['data'];
        _purchaseOrders = results[1]['data'] ?? [];
        _invoices = (_vendor?['invoices'] as List?) ?? [];
        _isLoading = false;
      });
    }
  }

  Widget _infoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13))),
          Expanded(child: Text(value ?? '-', style: const TextStyle(color: Colors.white, fontSize: 13))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0d1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161b22),
        title: Text(widget.vendorName, style: const TextStyle(color: Colors.white, fontSize: 16)),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF1a73e8),
          labelColor: const Color(0xFF1a73e8),
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Info'),
            Tab(text: 'Purchase Orders'),
            Tab(text: 'Invoices'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1a73e8)))
          : TabBarView(
              controller: _tabController,
              children: [
                // Info tab
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161b22),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _infoRow('Name', _vendor?['name']),
                        const Divider(color: Colors.white12),
                        _infoRow('Contact', _vendor?['contact_person']),
                        const Divider(color: Colors.white12),
                        _infoRow('Email', _vendor?['email']),
                        const Divider(color: Colors.white12),
                        _infoRow('Phone', _vendor?['phone']),
                        const Divider(color: Colors.white12),
                        _infoRow('Country', _vendor?['country']),
                        const Divider(color: Colors.white12),
                        _infoRow('Currency', _vendor?['currency']),
                        const Divider(color: Colors.white12),
                        _infoRow('Address', _vendor?['address']),
                        const Divider(color: Colors.white12),
                        _infoRow('Tax Number', _vendor?['tax_number']),
                      ],
                    ),
                  ),
                ),
                // Purchase Orders tab
                _purchaseOrders.isEmpty
                    ? const Center(child: Text('No purchase orders', style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _purchaseOrders.length,
                        itemBuilder: (context, index) {
                          final po = _purchaseOrders[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF161b22),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.receipt_long, color: Color(0xFF1a73e8), size: 24),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(po['po_number'] ?? po['title'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                                      Text(po['date'] ?? po['created_at'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${_vendor?['currency'] ?? '\$'}${_toDouble(po['total']).toStringAsFixed(2)}',
                                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                // Invoices tab
                _invoices.isEmpty
                    ? const Center(child: Text('No invoices', style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _invoices.length,
                        itemBuilder: (context, index) {
                          final inv = _invoices[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF161b22),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.description, color: Colors.green, size: 24),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(inv['invoice_number'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                                      Text(inv['date'] ?? inv['created_at'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${_vendor?['currency'] ?? '\$'}${_toDouble(inv['amount']).toStringAsFixed(2)}',
                                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                    ),
                                    Text(inv['status'] ?? '', style: TextStyle(color: inv['status']?.toLowerCase() == 'paid' ? Colors.green : Colors.orange, fontSize: 11)),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ],
            ),
    );
  }
}
