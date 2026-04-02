import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';

double _toDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0.0;
}

class CertificatesScreen extends StatefulWidget {
  const CertificatesScreen({super.key});

  @override
  State<CertificatesScreen> createState() => _CertificatesScreenState();
}

class _CertificatesScreenState extends State<CertificatesScreen> {
  List<dynamic> _certificates = [];
  bool _isLoading = true;
  bool _apiUnavailable = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = context.read<AuthService>().token!;

    // Try /certificates first, fallback to /admin/certificates
    var data = await ApiService.get('/certificates', token);
    if (data['status'] == 404 || data['data'] == null) {
      data = await ApiService.get('/admin/certificates', token);
    }

    if (mounted) {
      setState(() {
        if (data['data'] != null) {
          _certificates = data['data'] is List ? data['data'] : [];
          _apiUnavailable = false;
        } else {
          _apiUnavailable = true;
          // Mock data for placeholder
          _certificates = [
            {'id': 1, 'name': 'ISO 9001:2015', 'issuer': 'Bureau Veritas', 'expiry_date': '2026-08-15', 'status': 'Valid'},
            {'id': 2, 'name': 'ISO 14001:2015', 'issuer': 'DNV GL', 'expiry_date': '2026-05-01', 'status': 'Valid'},
            {'id': 3, 'name': 'OHSAS 18001', 'issuer': 'Lloyd\'s Register', 'expiry_date': '2026-04-10', 'status': 'Expiring'},
            {'id': 4, 'name': 'Welding Certificate', 'issuer': 'TWI', 'expiry_date': '2026-03-01', 'status': 'Expired'},
          ];
        }
        _isLoading = false;
      });
    }
  }

  int _daysRemaining(String? dateStr) {
    if (dateStr == null) return 0;
    try {
      final expiry = DateTime.parse(dateStr);
      return expiry.difference(DateTime.now()).inDays;
    } catch (_) {
      return 0;
    }
  }

  Color _expiryColor(int days) {
    if (days < 0) return Colors.red;
    if (days <= 30) return Colors.orange;
    if (days <= 60) return Colors.yellow.shade700;
    if (days <= 90) return const Color(0xFF1a73e8);
    return Colors.green;
  }

  String _expiryLabel(int days) {
    if (days < 0) return 'Expired ${-days}d ago';
    if (days == 0) return 'Expires today';
    return '$days days left';
  }

  @override
  Widget build(BuildContext context) {
    final total = _certificates.length;
    final valid = _certificates.where((c) => _daysRemaining(c['expiry_date']) > 90).length;
    final expiring = _certificates.where((c) {
      final d = _daysRemaining(c['expiry_date']);
      return d > 0 && d <= 90;
    }).length;
    final expired = _certificates.where((c) => _daysRemaining(c['expiry_date']) < 0).length;

    return Scaffold(
      backgroundColor: const Color(0xFF0d1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161b22),
        title: const Text('Certificates', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1a73e8)))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_apiUnavailable)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange, size: 20),
                          SizedBox(width: 8),
                          Expanded(child: Text('API unavailable - showing placeholder data', style: TextStyle(color: Colors.orange, fontSize: 12))),
                        ],
                      ),
                    ),
                  // Summary cards
                  Row(
                    children: [
                      Expanded(child: _MiniCard(label: 'Total', value: '$total', color: Colors.white)),
                      const SizedBox(width: 8),
                      Expanded(child: _MiniCard(label: 'Valid', value: '$valid', color: Colors.green)),
                      const SizedBox(width: 8),
                      Expanded(child: _MiniCard(label: 'Expiring', value: '$expiring', color: Colors.orange)),
                      const SizedBox(width: 8),
                      Expanded(child: _MiniCard(label: 'Expired', value: '$expired', color: Colors.red)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Certificate list
                  ..._certificates.map((cert) {
                    final days = _daysRemaining(cert['expiry_date']);
                    final color = _expiryColor(days);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161b22),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: color.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.verified, color: color),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(cert['name'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                                Text(cert['issuer'] ?? cert['issuing_authority'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                Text('Expires: ${cert['expiry_date'] ?? '-'}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _expiryLabel(days),
                              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
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

class _MiniCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF161b22),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ],
      ),
    );
  }
}
