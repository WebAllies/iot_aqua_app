import 'dart:io';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

class SuperAdminAiReportsPage extends StatefulWidget {
  const SuperAdminAiReportsPage({super.key});

  @override
  State<SuperAdminAiReportsPage> createState() => _SuperAdminAiReportsPageState();
}

class _SuperAdminAiReportsPageState extends State<SuperAdminAiReportsPage> {
  // Filters
  String _role = "All"; // All/Admin/Employee/SuperAdmin
  String _label = "All"; // All/Healthy/Unhealthy
  String _userId = "All"; // All or specific uid

  DateTime? _from; // start date
  DateTime? _to;   // end date

  // Users list for dropdown
  bool _loadingUsers = true;
  List<_UserItem> _users = [];

  // Results cache (so export uses the same filtered data)
  List<_ScanRow> _lastFiltered = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _setDefaultRange();
  }

  void _setDefaultRange() {
    final now = DateTime.now();
    // Default: last 7 days
    _to = DateTime(now.year, now.month, now.day, 23, 59, 59);
    _from = _to!.subtract(const Duration(days: 7));
  }

  Future<void> _loadUsers() async {
    setState(() => _loadingUsers = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .orderBy('email')
          .get();

      final list = <_UserItem>[
        const _UserItem(uid: "All", display: "All Users"),
      ];

      for (final d in snap.docs) {
        final data = d.data();
        final email = (data['email'] ?? '').toString();
        final username = (data['username'] ?? '').toString();
        final role = (data['role'] ?? '').toString();

        final display = [
          if (username.isNotEmpty) username,
          if (email.isNotEmpty) "($email)",
          if (role.isNotEmpty) "• $role",
        ].join(' ');

        list.add(_UserItem(uid: d.id, display: display.isEmpty ? d.id : display));
      }

      setState(() {
        _users = list;
        _loadingUsers = false;
      });
    } catch (e) {
      setState(() => _loadingUsers = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load users: $e")),
        );
      }
    }
  }

  Future<void> _pickFromDate() async {
    final initial = _from ?? DateTime.now().subtract(const Duration(days: 7));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      _from = DateTime(picked.year, picked.month, picked.day, 0, 0, 0);
    });
  }

  Future<void> _pickToDate() async {
    final initial = _to ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      _to = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
    });
  }

  /// Base query uses only date range + order (to avoid Firestore composite index headaches).
  /// Other filters are applied client-side after fetching.
  Query _baseQuery() {
    Query q = FirebaseFirestore.instance.collection('ai_scans');

    if (_from != null) {
      q = q.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(_from!));
    }
    if (_to != null) {
      q = q.where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(_to!));
    }

    // Must orderBy the same field used in range filters.
    q = q.orderBy('createdAt', descending: true);

    return q;
  }

  List<_ScanRow> _applyClientFilters(List<_ScanRow> rows) {
    return rows.where((r) {
      if (_role != "All" && r.role != _role) return false;
      if (_label != "All" && r.label != _label) return false;
      if (_userId != "All" && r.userId != _userId) return false;
      return true;
    }).toList();
  }

  Future<void> _exportPdf() async {
    if (_lastFiltered.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No data to export.")),
      );
      return;
    }

    final doc = pw.Document();
    final df = DateFormat('dd MMM yyyy');
    final dtf = DateFormat('dd MMM yyyy, HH:mm');

    final fromStr = _from == null ? "—" : df.format(_from!);
    final toStr = _to == null ? "—" : df.format(_to!);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          pw.Text(
            "AI Scan Report",
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text("Date range: $fromStr → $toStr"),
          pw.Text("Role: $_role   |   Label: $_label   |   User: ${_userId == 'All' ? 'All' : _userId}"),
          pw.SizedBox(height: 14),

          pw.Table.fromTextArray(
            headers: const ["Date/Time", "Email", "Role", "Label", "Confidence"],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 10),
            columnWidths: {
              0: const pw.FlexColumnWidth(2.2),
              1: const pw.FlexColumnWidth(2.8),
              2: const pw.FlexColumnWidth(1.2),
              3: const pw.FlexColumnWidth(1.4),
              4: const pw.FlexColumnWidth(1.2),
            },
            data: _lastFiltered.map((r) {
              final dt = r.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              return [
                dtf.format(dt),
                r.email,
                r.role,
                r.label,
                "${(r.confidence * 100).toStringAsFixed(1)}%",
              ];
            }).toList(),
          ),

          pw.SizedBox(height: 14),
          pw.Text("Total scans: ${_lastFiltered.length}"),
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: "ai_scan_report.pdf",
    );
  }

  Future<void> _exportCsv() async {
    if (_lastFiltered.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No data to export.")),
      );
      return;
    }

    final dtf = DateFormat('yyyy-MM-dd HH:mm:ss');

    final buffer = StringBuffer();
    buffer.writeln("date_time,email,role,label,confidence");

    for (final r in _lastFiltered) {
      final dt = r.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final date = dtf.format(dt);
      final email = _csvSafe(r.email);
      final role = _csvSafe(r.role);
      final label = _csvSafe(r.label);
      final conf = (r.confidence * 100).toStringAsFixed(1);

      buffer.writeln("$date,$email,$role,$label,$conf");
    }

    final dir = await getTemporaryDirectory();
    final file = File("${dir.path}/ai_scan_report.csv");
    await file.writeAsString(buffer.toString(), flush: true);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: "AI Scan Report (CSV)",
    );
  }

  static String _csvSafe(String s) {
    // Wrap in quotes if it contains comma or quotes
    if (s.contains(',') || s.contains('"') || s.contains('\n')) {
      final escaped = s.replaceAll('"', '""');
      return '"$escaped"';
    }
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Reports (Super Admin)"),
        actions: [
          IconButton(
            tooltip: "Export PDF",
            onPressed: _exportPdf,
            icon: const Icon(Icons.picture_as_pdf),
          ),
          IconButton(
            tooltip: "Export CSV",
            onPressed: _exportCsv,
            icon: const Icon(Icons.table_view),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters Panel
          Padding(
            padding: const EdgeInsets.all(12),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _dropdown<String>(
                            label: "Role",
                            value: _role,
                            items: const ["All", "SuperAdmin", "Admin", "Employee"],
                            onChanged: (v) => setState(() => _role = v ?? "All"),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _dropdown<String>(
                            label: "Label",
                            value: _label,
                            items: const ["All", "Healthy", "Unhealthy"],
                            onChanged: (v) => setState(() => _label = v ?? "All"),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: _loadingUsers
                              ? const _FieldSkeleton(label: "User")
                              : _dropdown<_UserItem>(
                                  label: "User",
                                  value: _users.firstWhere((u) => u.uid == _userId, orElse: () => _users.first),
                                  items: _users,
                                  itemLabel: (u) => u.display,
                                  onChanged: (u) => setState(() => _userId = u?.uid ?? "All"),
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: _dateButton(
                            label: "From",
                            text: _from == null ? "Any" : df.format(_from!),
                            onTap: _pickFromDate,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _dateButton(
                            label: "To",
                            text: _to == null ? "Any" : df.format(_to!),
                            onTap: _pickToDate,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _role = "All";
                                _label = "All";
                                _userId = "All";
                                _setDefaultRange();
                              });
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text("Reset Filters"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Results
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _baseQuery().snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snap.data!.docs;

                final rows = docs.map((doc) {
                  final d = doc.data() as Map<String, dynamic>;

                  final ts = d['createdAt'];
                  DateTime? dt;
                  if (ts is Timestamp) dt = ts.toDate();

                  return _ScanRow(
                    id: doc.id,
                    userId: (d['userId'] ?? '').toString(),
                    email: (d['email'] ?? '').toString(),
                    role: (d['role'] ?? '').toString(),
                    label: (d['label'] ?? '').toString(),
                    confidence: (d['confidence'] ?? 0.0) is num ? (d['confidence'] as num).toDouble() : 0.0,
                    createdAt: dt,
                  );
                }).toList();

                final filtered = _applyClientFilters(rows);
                _lastFiltered = filtered;

                if (filtered.isEmpty) {
                  return const Center(child: Text("No scans match the selected filters."));
                }

                final dtf = DateFormat('dd MMM yyyy, HH:mm');

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final r = filtered[i];
                    final dt = r.createdAt == null ? "—" : dtf.format(r.createdAt!);

                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.psychology),
                        title: Text("${r.label}  •  ${(r.confidence * 100).toStringAsFixed(1)}%"),
                        subtitle: Text("${r.email}\n${r.role} • $dt"),
                        isThreeLine: true,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateButton({
    required String label,
    required String text,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(
          children: [
            Expanded(child: Text(text)),
            const Icon(Icons.calendar_month),
          ],
        ),
      ),
    );
  }

  Widget _dropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    String Function(T item)? itemLabel,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: items.map((e) {
        final text = itemLabel != null ? itemLabel(e) : e.toString();
        return DropdownMenuItem<T>(
          value: e,
          child: Text(text, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}

class _UserItem {
  final String uid;
  final String display;
  const _UserItem({required this.uid, required this.display});

  @override
  String toString() => display;
}

class _ScanRow {
  final String id;
  final String userId;
  final String email;
  final String role;
  final String label;
  final double confidence;
  final DateTime? createdAt;

  _ScanRow({
    required this.id,
    required this.userId,
    required this.email,
    required this.role,
    required this.label,
    required this.confidence,
    required this.createdAt,
  });
}

class _FieldSkeleton extends StatelessWidget {
  final String label;
  const _FieldSkeleton({required this.label});

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: const SizedBox(
        height: 18,
        child: LinearProgressIndicator(),
      ),
    );
  }
}
