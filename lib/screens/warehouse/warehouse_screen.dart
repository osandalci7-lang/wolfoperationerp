import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';

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
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final token = context.read<AuthService>().token!;
    final data = await ApiService.get('/warehouse/items?q=$_search', token);
    if (mounted) setState(() { _items = data['data'] ?? []; _isLoading = false; });
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0d1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161b22),
        title: const Text('Warehouse', style: TextStyle(color: Colors.white)),
        actions: [IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: () { setState(() => _isLoading = true); _load(); })],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search items...',
              hintStyle: const TextStyle(color: Colors.grey),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true, fillColor: const Color(0xFF161b22),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
            onChanged: (v) { setState(() { _search = v; _isLoading = true; }); _load(); })),
        Expanded(child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1a73e8)))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _items.length,
              itemBuilder: (context, i) {
                final item = _items[i];
                final stock = _toDouble(item['current_stock']);
                final min = _toDouble(item['min_stock']);
                final isLow = stock <= min && min > 0;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: const Color(0xFF161b22), borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: isLow ? Colors.red.withOpacity(0.15) : const Color(0xFF1a73e8).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10)),
                      child: Icon(Icons.inventory_2, color: isLow ? Colors.red : const Color(0xFF1a73e8))),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(item['item_code'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                      Text(item['name'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                      Text(item['category'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12))])),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text(stock.toStringAsFixed(1), style: TextStyle(color: isLow ? Colors.red : Colors.green, fontSize: 20, fontWeight: FontWeight.bold)),
                      Text(item['unit'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                      if (isLow) const Text('LOW', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold))])])
                );
              }))
      ]));
  }
}
