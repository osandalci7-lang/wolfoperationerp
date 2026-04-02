import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../widgets/common.dart';

class PmsScreen extends StatefulWidget {
  const PmsScreen({super.key});

  @override
  State<PmsScreen> createState() => _PmsScreenState();
}

class _PmsScreenState extends State<PmsScreen> {
  List<dynamic> _categories = [];
  List<dynamic> _equipment = [];
  bool _isLoading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = context.read<AuthService>().token!;
    final data = await ApiService.get('/pms/categories', token);
    if (mounted) {
      setState(() {
        _categories = data['data']?['categories'] ?? [];
        _equipment = data['data']?['equipment'] ?? [];
        _isLoading = false;
      });
    }
  }

  // Build tree: root categories -> sub-categories -> equipment
  List<Map<String, dynamic>> get _rootCategories {
    return _categories.where((c) => c['parent_id'] == null).toList().cast<Map<String, dynamic>>();
  }

  List<Map<String, dynamic>> _subCategories(int parentId) {
    return _categories.where((c) => c['parent_id'] == parentId).toList().cast<Map<String, dynamic>>();
  }

  List<Map<String, dynamic>> _catEquipment(int catId) {
    var list = _equipment.where((e) => e['category_id'] == catId).toList().cast<Map<String, dynamic>>();
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((e) =>
        (e['name_en'] ?? '').toString().toLowerCase().contains(q) ||
        (e['code'] ?? '').toString().toLowerCase().contains(q)
      ).toList();
    }
    return list;
  }

  Color _equipmentStatusColor(Map<String, dynamic> eq) {
    if (toInt(eq['overdue_count']) > 0) return AppColors.msRed;
    if (toInt(eq['due_soon_count']) > 0) return AppColors.msOrange;
    if (toInt(eq['task_count']) > 0) return AppColors.msGreen;
    return AppColors.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: wolfAppBar(
        title: 'PMS',
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: () { setState(() => _isLoading = true); _load(); }),
        ],
      ),
      body: _isLoading
          ? const LoadingState()
          : RefreshIndicator(
              onRefresh: _load,
              child: Column(
                children: [
                  AppSearchBar(hint: 'Search equipment...', onChanged: (v) => setState(() => _search = v)),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: _rootCategories.map((cat) => _CategorySection(
                        category: cat,
                        subCategories: _subCategories(cat['id']),
                        getEquipment: _catEquipment,
                        getSubCategories: _subCategories,
                        statusColor: _equipmentStatusColor,
                        onEquipmentTap: (eq) => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => PmsEquipmentScreen(equipmentId: eq['id'], equipmentName: eq['name_en'] ?? ''),
                        )),
                      )).toList(),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _CategorySection extends StatefulWidget {
  final Map<String, dynamic> category;
  final List<Map<String, dynamic>> subCategories;
  final List<Map<String, dynamic>> Function(int) getEquipment;
  final List<Map<String, dynamic>> Function(int) getSubCategories;
  final Color Function(Map<String, dynamic>) statusColor;
  final void Function(Map<String, dynamic>) onEquipmentTap;

  const _CategorySection({
    required this.category,
    required this.subCategories,
    required this.getEquipment,
    required this.getSubCategories,
    required this.statusColor,
    required this.onEquipmentTap,
  });

  @override
  State<_CategorySection> createState() => _CategorySectionState();
}

class _CategorySectionState extends State<_CategorySection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final directEquipment = widget.getEquipment(widget.category['id']);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more, color: AppColors.textSecondary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.category['name_en'] ?? '',
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text('${directEquipment.length + widget.subCategories.fold<int>(0, (sum, s) => sum + widget.getEquipment(s['id']).length)}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            // Direct equipment
            ...directEquipment.map((eq) => _EquipmentTile(eq: eq, statusColor: widget.statusColor(eq), onTap: () => widget.onEquipmentTap(eq))),
            // Sub-categories
            ...widget.subCategories.map((sub) => _SubCategorySection(
              sub: sub,
              equipment: widget.getEquipment(sub['id']),
              statusColor: widget.statusColor,
              onEquipmentTap: widget.onEquipmentTap,
            )),
          ],
        ],
      ),
    );
  }
}

class _SubCategorySection extends StatefulWidget {
  final Map<String, dynamic> sub;
  final List<Map<String, dynamic>> equipment;
  final Color Function(Map<String, dynamic>) statusColor;
  final void Function(Map<String, dynamic>) onEquipmentTap;

  const _SubCategorySection({required this.sub, required this.equipment, required this.statusColor, required this.onEquipmentTap});

  @override
  State<_SubCategorySection> createState() => _SubCategorySectionState();
}

class _SubCategorySectionState extends State<_SubCategorySection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border, width: 0.5))),
            child: Row(
              children: [
                Icon(_expanded ? Icons.expand_less : Icons.expand_more, color: AppColors.textSecondary, size: 16),
                const SizedBox(width: 6),
                Expanded(child: Text(widget.sub['name_en'] ?? '', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
                Text('${widget.equipment.length}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
        ),
        if (_expanded)
          ...widget.equipment.map((eq) => _EquipmentTile(eq: eq, statusColor: widget.statusColor(eq), onTap: () => widget.onEquipmentTap(eq), indent: true)),
      ],
    );
  }
}

class _EquipmentTile extends StatelessWidget {
  final Map<String, dynamic> eq;
  final Color statusColor;
  final VoidCallback onTap;
  final bool indent;

  const _EquipmentTile({required this.eq, required this.statusColor, required this.onTap, this.indent = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.fromLTRB(indent ? 48 : 32, 10, 14, 10),
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border, width: 0.3))),
        child: Row(
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(eq['name_en'] ?? '', style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                  if (eq['code'] != null)
                    Text(eq['code'], style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                ],
              ),
            ),
            Text('${eq['task_count'] ?? 0}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 16),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// PMS Equipment Tasks
// ═══════════════════════════════════════════════

class PmsEquipmentScreen extends StatefulWidget {
  final int equipmentId;
  final String equipmentName;
  const PmsEquipmentScreen({super.key, required this.equipmentId, required this.equipmentName});

  @override
  State<PmsEquipmentScreen> createState() => _PmsEquipmentScreenState();
}

class _PmsEquipmentScreenState extends State<PmsEquipmentScreen> {
  Map<String, dynamic>? _equipment;
  List<dynamic> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = context.read<AuthService>().token!;
    final data = await ApiService.get('/pms/equipment/${widget.equipmentId}/tasks', token);
    if (mounted) {
      setState(() {
        _equipment = data['data']?['equipment'];
        _tasks = data['data']?['tasks'] ?? [];
        _isLoading = false;
      });
    }
  }

  Color _taskStatusColor(Map<String, dynamic> task) {
    if (task['task_type'] == 'unplanned') return AppColors.msPurple;
    final dueStr = task['next_due_date']?.toString();
    if (dueStr == null) return AppColors.textSecondary;
    try {
      final due = DateTime.parse(dueStr);
      if (due.isBefore(DateTime.now())) return AppColors.msRed;
      if (due.difference(DateTime.now()).inDays <= (task['warning_days'] ?? 14)) return AppColors.msOrange;
      return AppColors.msGreen;
    } catch (_) {
      return AppColors.textSecondary;
    }
  }

  Future<void> _completeTask(Map<String, dynamic> task) async {
    final token = context.read<AuthService>().token!;
    final res = await ApiService.post('/pms/tasks/${task['id']}/complete', token, {
      'done_date': DateTime.now().toIso8601String().substring(0, 10),
    });
    if (mounted) {
      if (res['status'] == 200) {
        showSuccess(context, 'Task completed. Next due: ${res['data']?['next_due_date'] ?? 'N/A'}');
        setState(() => _isLoading = true);
        _load();
      } else {
        showError(context, res['message'] ?? 'Failed');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: wolfAppBar(title: widget.equipmentName, showBack: true),
      body: _isLoading
          ? const LoadingState()
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_equipment != null)
                    Container(
                      padding: const EdgeInsets.all(14),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(10)),
                      child: Column(children: [
                        InfoRow(label: 'Code', value: _equipment!['code']),
                        InfoRow(label: 'Name', value: _equipment!['name_en']),
                      ]),
                    ),
                  const SectionHeader(title: 'Tasks'),
                  if (_tasks.isEmpty)
                    const EmptyState(icon: Icons.check_circle, message: 'No tasks'),
                  ..._tasks.map((task) {
                    final color = _taskStatusColor(task);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: color.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(task['name_en'] ?? '', style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                            Row(children: [
                              if (task['next_due_date'] != null)
                                Text('Due: ${task['next_due_date']}', style: TextStyle(color: color, fontSize: 12)),
                              if (task['week_number'] != null)
                                Text(' (W${task['week_number']})', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                            ]),
                            if (task['interval_days'] != null)
                              Text('Every ${task['interval_days']} days', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                          ])),
                          GestureDetector(
                            onTap: () => _completeTask(task),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.msGreen.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('Complete', style: TextStyle(color: AppColors.msGreen, fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}
