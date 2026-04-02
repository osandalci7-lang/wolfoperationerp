import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';

double _toDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0.0;
}

class NcrScreen extends StatefulWidget {
  const NcrScreen({super.key});

  @override
  State<NcrScreen> createState() => _NcrScreenState();
}

class _NcrScreenState extends State<NcrScreen> {
  List<dynamic> _ncrs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = context.read<AuthService>().token!;
    final data = await ApiService.get('/ncr', token);
    if (mounted) {
      setState(() {
        _ncrs = data['data'] ?? [];
        _isLoading = false;
      });
    }
  }

  Color _statusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'open':
        return Colors.red;
      case 'in progress':
        return Colors.orange;
      case 'closed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _severityColor(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0d1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161b22),
        title: const Text('NCR', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1a73e8)))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _ncrs.length,
                itemBuilder: (context, index) {
                  final ncr = _ncrs[index];
                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NcrDetailScreen(ncrId: ncr['id']),
                      ),
                    ),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161b22),
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
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1a73e8).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  ncr['ncr_number'] ?? '',
                                  style: const TextStyle(color: Color(0xFF1a73e8), fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _severityColor(ncr['severity']).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  ncr['severity'] ?? '',
                                  style: TextStyle(color: _severityColor(ncr['severity']), fontSize: 11),
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _statusColor(ncr['status']).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  ncr['status'] ?? '',
                                  style: TextStyle(color: _statusColor(ncr['status']), fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            ncr['title'] ?? '',
                            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.folder, color: Colors.grey, size: 14),
                              const SizedBox(width: 4),
                              Text(ncr['project_name'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                              const Spacer(),
                              Text(ncr['created_at'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
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
    _loadDetail();
  }

  Future<void> _loadDetail() async {
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
    final result = await ApiService.post('/ncr/${widget.ncrId}/status', token, {'status': newStatus});
    if (mounted) {
      setState(() => _updating = false);
      if (result['status'] == 200) {
        _loadDetail();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated to $newStatus'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Update failed'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Color _statusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'open':
        return Colors.red;
      case 'in progress':
        return Colors.orange;
      case 'closed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _severityColor(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
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
        title: Text(_ncr?['ncr_number'] ?? 'NCR Detail', style: const TextStyle(color: Colors.white, fontSize: 16)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1a73e8)))
          : _ncr == null
              ? const Center(child: Text('Not found', style: TextStyle(color: Colors.grey)))
              : RefreshIndicator(
                  onRefresh: _loadDetail,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status & Severity badges
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _statusColor(_ncr!['status']).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(_ncr!['status'] ?? '', style: TextStyle(color: _statusColor(_ncr!['status']), fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _severityColor(_ncr!['severity']).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('${_ncr!['severity'] ?? ''} Severity', style: TextStyle(color: _severityColor(_ncr!['severity']), fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(_ncr!['title'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF161b22),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              _infoRow('NCR Number', _ncr!['ncr_number']),
                              const Divider(color: Colors.white12),
                              _infoRow('Project', _ncr!['project_name']),
                              const Divider(color: Colors.white12),
                              _infoRow('Created', _ncr!['created_at']),
                              const Divider(color: Colors.white12),
                              _infoRow('Assigned To', _ncr!['assigned_to']),
                            ],
                          ),
                        ),
                        if (_ncr!['description'] != null) ...[
                          const SizedBox(height: 16),
                          const Text('Description', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF161b22),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(_ncr!['description'], style: const TextStyle(color: Colors.white70, fontSize: 13)),
                          ),
                        ],
                        if (_ncr!['corrective_action'] != null) ...[
                          const SizedBox(height: 16),
                          const Text('Corrective Action', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF161b22),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.green.withOpacity(0.3)),
                            ),
                            child: Text(_ncr!['corrective_action'], style: const TextStyle(color: Colors.white70, fontSize: 13)),
                          ),
                        ],
                        const SizedBox(height: 24),
                        const Text('Update Status', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _StatusButton(
                                label: 'Open',
                                color: Colors.red,
                                isActive: _ncr!['status']?.toLowerCase() == 'open',
                                isLoading: _updating,
                                onTap: () => _updateStatus('Open'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _StatusButton(
                                label: 'In Progress',
                                color: Colors.orange,
                                isActive: _ncr!['status']?.toLowerCase() == 'in progress',
                                isLoading: _updating,
                                onTap: () => _updateStatus('In Progress'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _StatusButton(
                                label: 'Closed',
                                color: Colors.green,
                                isActive: _ncr!['status']?.toLowerCase() == 'closed',
                                isLoading: _updating,
                                onTap: () => _updateStatus('Closed'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}

class _StatusButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool isActive;
  final bool isLoading;
  final VoidCallback onTap;

  const _StatusButton({
    required this.label,
    required this.color,
    required this.isActive,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.2) : const Color(0xFF161b22),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isActive ? color : Colors.white12),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(color: isActive ? color : Colors.grey, fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
