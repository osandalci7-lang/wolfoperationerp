import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';

double _toDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0.0;
}

class PlanningScreen extends StatefulWidget {
  const PlanningScreen({super.key});

  @override
  State<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends State<PlanningScreen> {
  List<dynamic> _items = [];
  bool _isLoading = true;
  String _filter = 'all'; // all, week, month

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = context.read<AuthService>().token!;
    final data = await ApiService.get('/planning', token);
    if (mounted) {
      setState(() {
        _items = data['data'] ?? [];
        _isLoading = false;
      });
    }
  }

  List<dynamic> get _filtered {
    if (_filter == 'all') return _items;
    final now = DateTime.now();
    return _items.where((item) {
      final startStr = item['start_date']?.toString() ?? '';
      final endStr = item['end_date']?.toString() ?? '';
      DateTime? start, end;
      try { start = DateTime.parse(startStr); } catch (_) {}
      try { end = DateTime.parse(endStr); } catch (_) {}

      if (_filter == 'week') {
        final weekEnd = now.add(const Duration(days: 7));
        return (start != null && start.isBefore(weekEnd)) && (end == null || end.isAfter(now));
      } else {
        final monthEnd = DateTime(now.year, now.month + 1, 0);
        return (start != null && start.isBefore(monthEnd)) && (end == null || end.isAfter(now));
      }
    }).toList();
  }

  Map<String, List<dynamic>> get _grouped {
    final map = <String, List<dynamic>>{};
    for (final item in _filtered) {
      final loc = item['location']?.toString() ?? 'Other';
      map.putIfAbsent(loc, () => []).add(item);
    }
    return map;
  }

  Color _statusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
      case 'in progress':
        return Colors.green;
      case 'planned':
        return const Color(0xFF1a73e8);
      case 'completed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _grouped;

    return Scaffold(
      backgroundColor: const Color(0xFF0d1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161b22),
        title: const Text('Planning', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1a73e8)))
          : RefreshIndicator(
              onRefresh: _load,
              child: Column(
                children: [
                  // Filter chips
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        _FilterChip(label: 'All', isActive: _filter == 'all', onTap: () => setState(() => _filter = 'all')),
                        const SizedBox(width: 8),
                        _FilterChip(label: 'This Week', isActive: _filter == 'week', onTap: () => setState(() => _filter = 'week')),
                        const SizedBox(width: 8),
                        _FilterChip(label: 'This Month', isActive: _filter == 'month', onTap: () => setState(() => _filter = 'month')),
                      ],
                    ),
                  ),
                  // Gantt-style list grouped by location
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: grouped.entries.map((entry) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  const Icon(Icons.location_on, color: Color(0xFF1a73e8), size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    entry.key,
                                    style: const TextStyle(color: Color(0xFF1a73e8), fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1),
                                  ),
                                ],
                              ),
                            ),
                            ...entry.value.map((item) => _PlanningCard(item: item, statusColor: _statusColor(item['status']))),
                            const SizedBox(height: 8),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF1a73e8) : const Color(0xFF161b22),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(color: isActive ? Colors.white : Colors.grey, fontSize: 13)),
      ),
    );
  }
}

class _PlanningCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final Color statusColor;
  const _PlanningCard({required this.item, required this.statusColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161b22),
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: statusColor, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item['project_title'] ?? '',
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(item['status'] ?? '', style: TextStyle(color: statusColor, fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (item['ship_name'] != null)
            Row(
              children: [
                const Icon(Icons.directions_boat, color: Colors.grey, size: 14),
                const SizedBox(width: 4),
                Text(item['ship_name'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.calendar_today, color: Colors.grey, size: 14),
              const SizedBox(width: 4),
              Text(
                '${item['start_date'] ?? ''} \u2192 ${item['end_date'] ?? ''}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Gantt bar
          LayoutBuilder(
            builder: (context, constraints) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: Container(
                  height: 8,
                  width: constraints.maxWidth,
                  color: Colors.white.withOpacity(0.05),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _calculateProgress(item['start_date'], item['end_date']),
                    child: Container(
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  double _calculateProgress(String? startStr, String? endStr) {
    try {
      final start = DateTime.parse(startStr ?? '');
      final end = DateTime.parse(endStr ?? '');
      final now = DateTime.now();
      if (now.isBefore(start)) return 0.0;
      if (now.isAfter(end)) return 1.0;
      final total = end.difference(start).inDays;
      if (total <= 0) return 1.0;
      return now.difference(start).inDays / total;
    } catch (_) {
      return 0.5;
    }
  }
}
