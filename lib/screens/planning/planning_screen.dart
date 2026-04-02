import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../widgets/common.dart';

class PlanningScreen extends StatefulWidget {
  const PlanningScreen({super.key});

  @override
  State<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends State<PlanningScreen> {
  List<dynamic> _entries = [];
  bool _isLoading = true;

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
        _entries = data['data'] ?? [];
        _isLoading = false;
      });
    }
  }

  // Web'deki status renkleri
  Color _statusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'planned':
        return const Color(0xFFFFD700);
      case 'active':
      case 'in_progress':
        return const Color(0xFFFFA500);
      case 'completed':
        return const Color(0xFF6B7280);
      case 'cancelled':
        return const Color(0xFFE5E7EB);
      default:
        return AppColors.textSecondary;
    }
  }

  Map<String, List<dynamic>> get _grouped {
    final map = <String, List<dynamic>>{};
    for (final e in _entries) {
      final loc = e['location_name']?.toString() ?? 'Other';
      map.putIfAbsent(loc, () => []).add(e);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _grouped;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: wolfAppBar(title: 'Planning', showBack: true),
      body: _isLoading
          ? const LoadingState()
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: grouped.entries.map((entry) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Location header
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 12, height: 12,
                              decoration: BoxDecoration(
                                color: _parseColor(entry.value.first['location_color']),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(entry.key, style: const TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                          ],
                        ),
                      ),
                      ...entry.value.map((e) {
                        final statusColor = _statusColor(e['status']);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.bgCard,
                            borderRadius: BorderRadius.circular(10),
                            border: Border(left: BorderSide(color: statusColor, width: 4)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(child: Text(e['vessel_name'] ?? e['ship_name'] ?? '', style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600))),
                                  StatusBadge(text: e['status'] ?? '', color: statusColor),
                                ],
                              ),
                              const SizedBox(height: 4),
                              if (e['company_name'] != null)
                                Text(e['company_name'], style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today, color: AppColors.textSecondary, size: 14),
                                  const SizedBox(width: 4),
                                  Text('${e['planned_entry']?.toString().substring(0, 10) ?? ''} \u2192 ${e['planned_exit']?.toString().substring(0, 10) ?? ''}',
                                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                ],
                              ),
                              if (e['scope'] != null) ...[
                                const SizedBox(height: 4),
                                Text(e['scope'], style: const TextStyle(color: AppColors.textSecondary, fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
                              ],
                              // Progress bar
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: LinearProgressIndicator(
                                  value: _progress(e['planned_entry'], e['planned_exit']),
                                  backgroundColor: AppColors.border,
                                  valueColor: AlwaysStoppedAnimation(statusColor),
                                  minHeight: 6,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                    ],
                  );
                }).toList(),
              ),
            ),
    );
  }

  double _progress(dynamic startStr, dynamic endStr) {
    try {
      final start = DateTime.parse(startStr.toString());
      final end = DateTime.parse(endStr.toString());
      final now = DateTime.now();
      if (now.isBefore(start)) return 0.0;
      if (now.isAfter(end)) return 1.0;
      final total = end.difference(start).inDays;
      if (total <= 0) return 1.0;
      return now.difference(start).inDays / total;
    } catch (_) {
      return 0.0;
    }
  }

  Color _parseColor(dynamic hex) {
    if (hex == null) return AppColors.primary;
    try {
      final str = hex.toString().replaceFirst('#', '');
      return Color(int.parse('FF$str', radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }
}
