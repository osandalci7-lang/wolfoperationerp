import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';

double _toDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0.0;
}

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

  Color _scoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  Color _statusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'in progress':
        return Colors.orange;
      case 'draft':
        return Colors.grey;
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
        title: const Text('Safety Inspections', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1a73e8)))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _inspections.length,
                itemBuilder: (context, index) {
                  final ins = _inspections[index];
                  final score = _toDouble(ins['score']);
                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SafetyDetailScreen(inspectionId: ins['id']),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  ins['project_name'] ?? 'Inspection',
                                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _statusColor(ins['status']).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  ins['status'] ?? '',
                                  style: TextStyle(color: _statusColor(ins['status']), fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.person, color: Colors.grey, size: 14),
                              const SizedBox(width: 4),
                              Text(ins['inspector_name'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                              const Spacer(),
                              const Icon(Icons.calendar_today, color: Colors.grey, size: 14),
                              const SizedBox(width: 4),
                              Text(ins['inspection_date'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Text('Score: ', style: TextStyle(color: Colors.grey, fontSize: 13)),
                              Text(
                                '${score.toStringAsFixed(0)}%',
                                style: TextStyle(color: _scoreColor(score), fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: score / 100,
                                    backgroundColor: Colors.white12,
                                    valueColor: AlwaysStoppedAnimation(_scoreColor(score)),
                                    minHeight: 6,
                                  ),
                                ),
                              ),
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
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    final token = context.read<AuthService>().token!;
    final data = await ApiService.get('/safety-inspections/${widget.inspectionId}', token);
    if (mounted) {
      setState(() {
        _inspection = data['data'];
        _isLoading = false;
      });
    }
  }

  Color _scoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0d1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161b22),
        title: const Text('Inspection Detail', style: TextStyle(color: Colors.white, fontSize: 16)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1a73e8)))
          : _inspection == null
              ? const Center(child: Text('Not found', style: TextStyle(color: Colors.grey)))
              : RefreshIndicator(
                  onRefresh: _loadDetail,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF161b22),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              _infoRow('Project', _inspection!['project_name']),
                              const Divider(color: Colors.white12),
                              _infoRow('Inspector', _inspection!['inspector_name']),
                              const Divider(color: Colors.white12),
                              _infoRow('Date', _inspection!['inspection_date']),
                              const Divider(color: Colors.white12),
                              _infoRow('Status', _inspection!['status']),
                              const Divider(color: Colors.white12),
                              Row(
                                children: [
                                  const SizedBox(width: 120, child: Text('Score', style: TextStyle(color: Colors.grey, fontSize: 13))),
                                  Text(
                                    '${_toDouble(_inspection!['score']).toStringAsFixed(0)}%',
                                    style: TextStyle(
                                      color: _scoreColor(_toDouble(_inspection!['score'])),
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text('Categories', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        // Categories accordion
                        if (_inspection!['categories'] != null)
                          ...(_inspection!['categories'] as List).map((cat) => _CategoryAccordion(category: cat)),
                      ],
                    ),
                  ),
                ),
    );
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
}

class _CategoryAccordion extends StatefulWidget {
  final Map<String, dynamic> category;
  const _CategoryAccordion({required this.category});

  @override
  State<_CategoryAccordion> createState() => _CategoryAccordionState();
}

class _CategoryAccordionState extends State<_CategoryAccordion> {
  bool _expanded = false;

  Widget _answerIcon(String? answer) {
    switch (answer?.toLowerCase()) {
      case 'yes':
        return const Text('\u2705', style: TextStyle(fontSize: 16));
      case 'no':
        return const Text('\u274C', style: TextStyle(fontSize: 16));
      case 'n/a':
        return const Text('\u2796', style: TextStyle(fontSize: 16));
      default:
        return const Text('-', style: TextStyle(color: Colors.grey));
    }
  }

  @override
  Widget build(BuildContext context) {
    final questions = widget.category['questions'] as List? ?? [];
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF161b22),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.category['name'] ?? widget.category['title'] ?? '',
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            ...questions.map((q) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Colors.white12, width: 0.5)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      q['question'] ?? q['text'] ?? '',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _answerIcon(q['answer']),
                ],
              ),
            )),
        ],
      ),
    );
  }
}
