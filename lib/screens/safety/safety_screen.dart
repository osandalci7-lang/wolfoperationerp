import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../widgets/common.dart';

class SafetyScreen extends StatefulWidget {
  const SafetyScreen({super.key});

  @override
  State<SafetyScreen> createState() => _SafetyScreenState();
}

class _SafetyScreenState extends State<SafetyScreen> {
  List<dynamic> _inspections = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = context.read<AuthService>().token!;
    final data = await ApiService.get('/safety-inspections', token);
    if (mounted) {
      setState(() {
        _inspections = data['data'] ?? [];
        _isLoading = false;
      });
    }
  }

  // Web'deki status renkleri
  Color _statusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'draft':
        return AppColors.textSecondary;
      case 'submitted':
        return AppColors.msOrange;
      case 'approved':
        return AppColors.msGreen;
      case 'rejected':
        return AppColors.msRed;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: wolfAppBar(title: 'Safety Inspections', showBack: true),
      body: _isLoading
          ? const LoadingState()
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _inspections.length,
                itemBuilder: (context, index) {
                  final ins = _inspections[index];
                  final answered = toInt(ins['answered_count']);
                  final total = toInt(ins['total_questions']);
                  final progress = total > 0 ? answered / total : 0.0;

                  return GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => SafetyDetailScreen(inspectionId: ins['id']),
                    )),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border.withOpacity(0.5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('Week ${ins['week_number'] ?? ''}', style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                              const SizedBox(width: 6),
                              Text('${ins['year'] ?? ''}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                              const Spacer(),
                              StatusBadge(text: ins['status'] ?? '', color: _statusColor(ins['status'])),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Progress bar (web'deki gibi)
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    backgroundColor: AppColors.border,
                                    valueColor: const AlwaysStoppedAnimation(AppColors.msBlue),
                                    minHeight: 6,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('${(progress * 100).toStringAsFixed(0)}%', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.person, color: AppColors.textSecondary, size: 14),
                              const SizedBox(width: 4),
                              Text(ins['created_by_name'] ?? '', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                              const Spacer(),
                              if (ins['submitted_at'] != null)
                                Text(ins['submitted_at'].toString().substring(0, 10), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

// ═══════════════════════════════════════════════
// SAFETY DETAIL — accordion categories + questions
// ═══════════════════════════════════════════════

class SafetyDetailScreen extends StatefulWidget {
  final int inspectionId;
  const SafetyDetailScreen({super.key, required this.inspectionId});

  @override
  State<SafetyDetailScreen> createState() => _SafetyDetailScreenState();
}

class _SafetyDetailScreenState extends State<SafetyDetailScreen> {
  Map<String, dynamic>? _inspection;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = context.read<AuthService>().token!;
    final data = await ApiService.get('/safety-inspections/${widget.inspectionId}', token);
    if (mounted) {
      setState(() {
        _inspection = data['data'];
        _isLoading = false;
      });
    }
  }

  Color _statusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'draft':
        return AppColors.textSecondary;
      case 'submitted':
        return AppColors.msOrange;
      case 'approved':
        return AppColors.msGreen;
      case 'rejected':
        return AppColors.msRed;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: wolfAppBar(title: 'Inspection Detail', showBack: true),
      body: _isLoading
          ? const LoadingState()
          : _inspection == null
              ? const EmptyState(icon: Icons.shield, message: 'Not found')
              : RefreshIndicator(
                  onRefresh: _load,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Rejection banner
                        if (_inspection!['status'] == 'rejected' && _inspection!['rejection_reason'] != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: AppColors.msRed.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.msRed.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error, color: AppColors.msRed, size: 20),
                                const SizedBox(width: 8),
                                Expanded(child: Text('Rejected: ${_inspection!['rejection_reason']}',
                                    style: const TextStyle(color: AppColors.msRed, fontSize: 13))),
                              ],
                            ),
                          ),

                        // Header card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(12)),
                          child: Column(children: [
                            InfoRow(label: 'Week', value: '${_inspection!['week_number']}'),
                            const Divider(color: AppColors.border, height: 1),
                            InfoRow(label: 'Year', value: '${_inspection!['year']}'),
                            const Divider(color: AppColors.border, height: 1),
                            InfoRow(label: 'Status', value: _inspection!['status']),
                            const Divider(color: AppColors.border, height: 1),
                            InfoRow(label: 'Created By', value: _inspection!['created_by_name']),
                            const Divider(color: AppColors.border, height: 1),
                            if (_inspection!['reviewed_by_name'] != null)
                              InfoRow(label: 'Reviewed By', value: _inspection!['reviewed_by_name']),
                          ]),
                        ),
                        const SizedBox(height: 24),

                        // Questions grouped by category
                        const SectionHeader(title: 'Inspection Items'),
                        if (_inspection!['items'] != null)
                          ..._buildCategoryAccordions(_inspection!['items'] as List),
                      ],
                    ),
                  ),
                ),
    );
  }

  List<Widget> _buildCategoryAccordions(List items) {
    // Group items by category
    final grouped = <String, List<dynamic>>{};
    for (final item in items) {
      final cat = item['category'] ?? item['section'] ?? 'General';
      grouped.putIfAbsent(cat.toString(), () => []).add(item);
    }

    return grouped.entries.map((entry) => _CategoryAccordion(title: entry.key, items: entry.value)).toList();
  }
}

class _CategoryAccordion extends StatefulWidget {
  final String title;
  final List<dynamic> items;
  const _CategoryAccordion({required this.title, required this.items});

  @override
  State<_CategoryAccordion> createState() => _CategoryAccordionState();
}

class _CategoryAccordionState extends State<_CategoryAccordion> {
  bool _expanded = false;

  Widget _answerWidget(String? answer) {
    switch (answer?.toLowerCase()) {
      case 'yes':
        return const Text('\u2705', style: TextStyle(fontSize: 16));
      case 'no':
        return const Text('\u274C', style: TextStyle(fontSize: 16));
      case 'n/a':
      case 'na':
        return const Text('\u2796', style: TextStyle(fontSize: 16));
      default:
        return const Text('-', style: TextStyle(color: AppColors.textSecondary));
    }
  }

  @override
  Widget build(BuildContext context) {
    final yesCount = widget.items.where((i) => i['answer']?.toString().toLowerCase() == 'yes').length;

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
                  Expanded(child: Text(widget.title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600))),
                  Text('$yesCount/${widget.items.length}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(width: 8),
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
          if (_expanded)
            ...widget.items.map((item) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border, width: 0.5))),
              child: Row(
                children: [
                  Expanded(child: Text(item['question'] ?? item['item_text'] ?? '', style: const TextStyle(color: AppColors.textPrimary, fontSize: 13))),
                  const SizedBox(width: 8),
                  _answerWidget(item['answer']),
                ],
              ),
            )),
        ],
      ),
    );
  }
}
