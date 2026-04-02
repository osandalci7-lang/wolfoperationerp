import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../widgets/common.dart';

class WarehouseScreen extends StatefulWidget {
  const WarehouseScreen({super.key});

  @override
  State<WarehouseScreen> createState() => _WarehouseScreenState();
}

class _WarehouseScreenState extends State<WarehouseScreen> {
  List<dynamic> _items = [];
  bool _isLoading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = context.read<AuthService>().token!;
    final data = await ApiService.get('/warehouse/items?q=$_search', token);
    if (mounted) {
      setState(() {
        _items = data['data'] ?? [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: wolfAppBar(
        title: 'Warehouse (${_items.length})',
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: () { setState(() => _isLoading = true); _load(); }),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search by code or name...',
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.bgCard,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (v) {
                setState(() { _search = v; _isLoading = true; });
                _load();
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const LoadingState()
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _items.length,
                      itemBuilder: (context, i) {
                        final item = _items[i];
                        final stock = toDouble(item['current_stock']);
                        final min = toDouble(item['min_stock']);
                        final isLow = stock <= min && min > 0;
                        final isZero = stock <= 0;

                        return GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(
                            builder: (_) => WarehouseItemDetailScreen(itemId: item['id'], itemName: item['name'] ?? ''),
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
                                  width: 48, height: 48,
                                  decoration: BoxDecoration(
                                    color: (isZero ? AppColors.msRed : isLow ? AppColors.msOrange : AppColors.primary).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(Icons.inventory_2,
                                      color: isZero ? AppColors.msRed : isLow ? AppColors.msOrange : AppColors.primary),
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(item['item_code'] ?? '', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                                  Text(item['name'] ?? '', style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                                  Row(children: [
                                    Text(item['category'] ?? '', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                    if (item['location'] != null) ...[
                                      const Text(' \u2022 ', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                      Text(item['location'], style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                    ],
                                  ]),
                                ])),
                                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                  Text(stock.toStringAsFixed(stock == stock.roundToDouble() ? 0 : 1),
                                      style: TextStyle(
                                        color: isZero ? AppColors.msRed : isLow ? AppColors.msOrange : AppColors.msGreen,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      )),
                                  Text(item['unit'] ?? '', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                                  if (isLow || isZero)
                                    Container(
                                      margin: const EdgeInsets.only(top: 2),
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: (isZero ? AppColors.msRed : AppColors.msOrange).withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(isZero ? 'OUT' : 'LOW',
                                          style: TextStyle(color: isZero ? AppColors.msRed : AppColors.msOrange, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ),
                                ]),
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

// ─── Item Detail ───
class WarehouseItemDetailScreen extends StatefulWidget {
  final int itemId;
  final String itemName;
  const WarehouseItemDetailScreen({super.key, required this.itemId, required this.itemName});

  @override
  State<WarehouseItemDetailScreen> createState() => _WarehouseItemDetailScreenState();
}

class _WarehouseItemDetailScreenState extends State<WarehouseItemDetailScreen> {
  Map<String, dynamic>? _item;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = context.read<AuthService>().token!;
    final data = await ApiService.get('/warehouse/items/${widget.itemId}', token);
    if (mounted) {
      setState(() {
        _item = data['data'];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: wolfAppBar(title: widget.itemName, showBack: true),
      body: _isLoading
          ? const LoadingState()
          : _item == null
              ? const EmptyState(icon: Icons.inventory, message: 'Not found')
              : RefreshIndicator(
                  onRefresh: _load,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Info card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(12)),
                          child: Column(children: [
                            InfoRow(label: 'Code', value: _item!['item_code']),
                            const Divider(color: AppColors.border, height: 1),
                            InfoRow(label: 'Name', value: _item!['name']),
                            const Divider(color: AppColors.border, height: 1),
                            InfoRow(label: 'Category', value: _item!['category']),
                            const Divider(color: AppColors.border, height: 1),
                            InfoRow(label: 'Unit', value: _item!['unit']),
                            const Divider(color: AppColors.border, height: 1),
                            InfoRow(label: 'Stock', value: toDouble(_item!['current_stock']).toStringAsFixed(1)),
                            const Divider(color: AppColors.border, height: 1),
                            InfoRow(label: 'Min Stock', value: toDouble(_item!['min_stock']).toStringAsFixed(1)),
                            const Divider(color: AppColors.border, height: 1),
                            InfoRow(label: 'Unit Price', value: '\u20AC${toDouble(_item!['unit_price']).toStringAsFixed(2)}'),
                            const Divider(color: AppColors.border, height: 1),
                            InfoRow(label: 'Location', value: _item!['location']),
                            const Divider(color: AppColors.border, height: 1),
                            InfoRow(label: 'Supplier', value: _item!['supplier']),
                          ]),
                        ),
                        const SizedBox(height: 24),
                        const SectionHeader(title: 'Stock Movements'),
                        if (_item!['movements'] != null)
                          ...(_item!['movements'] as List).map((m) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(8)),
                            child: Row(
                              children: [
                                Icon(
                                  m['movement_type'] == 'in' ? Icons.add_circle : Icons.remove_circle,
                                  color: m['movement_type'] == 'in' ? AppColors.msGreen : AppColors.msRed,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(m['employee_name'] ?? '', style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                                  if (m['notes'] != null)
                                    Text(m['notes'], style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                                ])),
                                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                  Text('${m['movement_type'] == 'in' ? '+' : '-'}${toDouble(m['quantity']).toStringAsFixed(1)}',
                                      style: TextStyle(color: m['movement_type'] == 'in' ? AppColors.msGreen : AppColors.msRed, fontSize: 14, fontWeight: FontWeight.bold)),
                                  Text(m['created_at']?.toString().substring(0, 10) ?? '', style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                                ]),
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
