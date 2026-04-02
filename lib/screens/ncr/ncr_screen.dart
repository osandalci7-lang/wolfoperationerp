import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../widgets/common.dart';

class NcrScreen extends StatefulWidget {
  const NcrScreen({super.key});

  @override
  State<NcrScreen> createState() => _NcrScreenState();
}

class _NcrScreenState extends State<NcrScreen> {
  List<dynamic> _ncrs = [];
  bool _isLoading = true;
  String _statusFilter = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = context.read<AuthService>().token!;
    final query = _statusFilter.isNotEmpty ? '/ncr?status=$_statusFilter' : '/ncr';
    final data = await ApiService.get(query, token);
    if (mounted) {
      setState(() {
        _ncrs = data['data'] ?? [];
        _isLoading = false;
      });
    }
  }

  // Web'deki NCR status renkleri
  Color _statusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'open':
        return AppColors.msRed;
      case 'in_progress':
      case 'in progress':
        return AppColors.msOrange;
      case 'closed':
        return AppColors.msGreen;
      case 'overdue':
        return AppColors.msDarkRed;
      default:
        return AppColors.textSecondary;
    }
  }

  // Web'deki severity renkleri
  Color _severityColor(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'low':
        return AppColors.msGreen;
      case 'medium':
        return AppColors.msOrange;
      case 'high':
        return AppColors.msRed;
      case 'critical':
        return AppColors.msDarkRed;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Stats (web'deki gibi)
    final openCount = _ncrs.where((n) => n['status']?.toString().toLowerCase() == 'open').length;
    final overdueCount = _ncrs.where((n) {
      if (n['due_date'] == null) return false;
      try { return DateTime.parse(n['due_date']).isBefore(DateTime.now()) && n['status'] != 'closed'; } catch (_) { return false; }
    }).length;
    final closedThisMonth = _ncrs.where((n) {
      if (n['closed_at'] == null) return false;
      try {
        final d = DateTime.parse(n['closed_at'].toString());
        return d.month == DateTime.now().month && d.year == DateTime.now().year;
      } catch (_) { return false; }
    }).length;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: wolfAppBar(title: 'NCR', showBack: true),
      body: _isLoading
          ? const LoadingState()
          : RefreshIndicator(
              onRefresh: _load,
              child: Column(
                children: [
                  // Stats row
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Row(
                      children: [
                        Expanded(child: _MiniStat(label: 'Open', value: '$openCount', color: AppColors.msRed)),
                        const SizedBox(width: 8),
                        Expanded(child: _MiniStat(label: 'Overdue', value: '$overdueCount', color: AppColors.msDarkRed)),
                        const SizedBox(width: 8),
                        Expanded(child: _MiniStat(label: 'Closed (mo)', value: '$closedThisMonth', color: AppColors.msGreen)),
                      ],
                    ),
                  ),
                  // Filter
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _Chip(label: 'All', isActive: _statusFilter.isEmpty, onTap: () { setState(() { _statusFilter = ''; _isLoading = true; }); _load(); }),
                          const SizedBox(width: 6),
                          _Chip(label: 'Open', isActive: _statusFilter == 'open', onTap: () { setState(() { _statusFilter = 'open'; _isLoading = true; }); _load(); }),
                          const SizedBox(width: 6),
                          _Chip(label: 'In Progress', isActive: _statusFilter == 'in_progress', onTap: () { setState(() { _statusFilter = 'in_progress'; _isLoading = true; }); _load(); }),
                          const SizedBox(width: 6),
                          _Chip(label: 'Closed', isActive: _statusFilter == 'closed', onTap: () { setState(() { _statusFilter = 'closed'; _isLoading = true; }); _load(); }),
                        ],
                      ),
                    ),
                  ),
                  // List
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _ncrs.length,
                      itemBuilder: (context, index) {
                        final ncr = _ncrs[index];
                        return GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(
                            builder: (_) => NcrDetailScreen(ncrId: ncr['id']),
                          )),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.bgCard,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _statusColor(ncr['status']).withOpacity(0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                                      child: Text(ncr['ncr_number'] ?? '', style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(width: 8),
                                    if (ncr['severity'] != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(color: _severityColor(ncr['severity']), borderRadius: BorderRadius.circular(6)),
                                        child: Text(ncr['severity'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                      ),
                                    const Spacer(),
                                    StatusBadge(text: ncr['status'] ?? '', color: _statusColor(ncr['status'])),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(ncr['title'] ?? '', style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                                if (ncr['source_reference'] != null)
                                  Text(ncr['source_reference'], style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    if (ncr['source'] != null) ...[
                                      Text(ncr['source'], style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                      const SizedBox(width: 12),
                                    ],
                                    if (ncr['due_date'] != null) ...[
                                      const Icon(Icons.event, color: AppColors.textSecondary, size: 14),
                                      const SizedBox(width: 4),
                                      Text(ncr['due_date'].toString(), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                    ],
                                    const Spacer(),
                                    Text(ncr['opened_by_name'] ?? '', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : AppColors.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? AppColors.primary : AppColors.border),
        ),
        child: Text(label, style: TextStyle(color: isActive ? Colors.white : AppColors.textSecondary, fontSize: 13)),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// NCR DETAIL
// ═══════════════════════════════════════════════

class NcrDetailScreen extends StatefulWidget {
  final int ncrId;
  const NcrDetailScreen({super.key, required this.ncrId});

  @override
  State<NcrDetailScreen> createState() => _NcrDetailScreenState();
}

class _NcrDetailScreenState extends State<NcrDetailScreen> {
  Map<String, dynamic>? _ncr;
  bool _isLoading = true;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = context.read<AuthService>().token!;
    final data = await ApiService.get('/ncr/${widget.ncrId}', token);
    if (mounted) {
      setState(() {
        _ncr = data['data'];
        _isLoading = false;
      });
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _updating = true);
    final token = context.read<AuthService>().token!;
    final res = await ApiService.put('/ncr/${widget.ncrId}/status', token, {'status': newStatus});
    if (mounted) {
      setState(() => _updating = false);
      if (res['status'] == 200) {
        showSuccess(context, 'Status updated');
        _load();
      } else {
        showError(context, res['message'] ?? 'Failed');
      }
    }
  }

  Color _statusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'open':
        return AppColors.msRed;
      case 'in_progress':
        return AppColors.msOrange;
      case 'closed':
        return AppColors.msGreen;
      default:
        return AppColors.textSecondary;
    }
  }

  Color _severityColor(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'low':
        return AppColors.msGreen;
      case 'medium':
        return AppColors.msOrange;
      case 'high':
        return AppColors.msRed;
      case 'critical':
        return AppColors.msDarkRed;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: wolfAppBar(title: _ncr?['ncr_number'] ?? 'NCR', showBack: true),
      body: _isLoading
          ? const LoadingState()
          : _ncr == null
              ? const EmptyState(icon: Icons.report_problem, message: 'Not found')
              : RefreshIndicator(
                  onRefresh: _load,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Badges
                        Row(children: [
                          StatusBadge(text: _ncr!['status'] ?? '', color: _statusColor(_ncr!['status'])),
                          const SizedBox(width: 8),
                          if (_ncr!['severity'] != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(color: _severityColor(_ncr!['severity']), borderRadius: BorderRadius.circular(6)),
                              child: Text('${_ncr!['severity']} Severity', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                        ]),
                        const SizedBox(height: 16),
                        Text(_ncr!['title'] ?? '', style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),

                        // Info card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(12)),
                          child: Column(children: [
                            InfoRow(label: 'NCR Number', value: _ncr!['ncr_number']),
                            const Divider(color: AppColors.border, height: 1),
                            InfoRow(label: 'Source', value: _ncr!['source']),
                            const Divider(color: AppColors.border, height: 1),
                            InfoRow(label: 'Reference', value: _ncr!['source_reference']),
                            const Divider(color: AppColors.border, height: 1),
                            InfoRow(label: 'Location', value: _ncr!['location']),
                            const Divider(color: AppColors.border, height: 1),
                            InfoRow(label: 'Due Date', value: _ncr!['due_date']?.toString()),
                            const Divider(color: AppColors.border, height: 1),
                            InfoRow(label: 'Opened By', value: _ncr!['opened_by_name']),
                            if (_ncr!['closed_by_name'] != null) ...[
                              const Divider(color: AppColors.border, height: 1),
                              InfoRow(label: 'Closed By', value: _ncr!['closed_by_name']),
                            ],
                          ]),
                        ),

                        if (_ncr!['description'] != null) ...[
                          const SizedBox(height: 16),
                          const SectionHeader(title: 'Description'),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(10)),
                            child: Text(_ncr!['description'], style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                          ),
                        ],

                        if (_ncr!['root_cause'] != null) ...[
                          const SizedBox(height: 16),
                          const SectionHeader(title: 'Root Cause'),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(10)),
                            child: Text(_ncr!['root_cause'], style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                          ),
                        ],

                        if (_ncr!['corrective_action'] != null) ...[
                          const SizedBox(height: 16),
                          const SectionHeader(title: 'Corrective Action'),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.bgCard,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.msGreen.withOpacity(0.3)),
                            ),
                            child: Text(_ncr!['corrective_action'], style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                          ),
                        ],

                        // Status update buttons
                        const SizedBox(height: 24),
                        const SectionHeader(title: 'Update Status'),
                        Row(children: [
                          Expanded(child: _StatusBtn(label: 'Open', color: AppColors.msRed, isActive: _ncr!['status'] == 'open', isLoading: _updating, onTap: () => _updateStatus('open'))),
                          const SizedBox(width: 8),
                          Expanded(child: _StatusBtn(label: 'In Progress', color: AppColors.msOrange, isActive: _ncr!['status'] == 'in_progress', isLoading: _updating, onTap: () => _updateStatus('in_progress'))),
                          const SizedBox(width: 8),
                          Expanded(child: _StatusBtn(label: 'Closed', color: AppColors.msGreen, isActive: _ncr!['status'] == 'closed', isLoading: _updating, onTap: () => _updateStatus('closed'))),
                        ]),
                      ],
                    ),
                  ),
                ),
    );
  }
}

class _StatusBtn extends StatelessWidget {
  final String label;
  final Color color;
  final bool isActive;
  final bool isLoading;
  final VoidCallback onTap;

  const _StatusBtn({required this.label, required this.color, required this.isActive, required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.2) : AppColors.bgCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isActive ? color : AppColors.border),
        ),
        child: Center(child: Text(label, style: TextStyle(color: isActive ? color : AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold))),
      ),
    );
  }
}
