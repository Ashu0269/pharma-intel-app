import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const String baseUrl = 'https://ashubaba02.app.n8n.cloud/webhook';
const String mizoChatUrl =
    '$baseUrl/20d821d7-ec90-45c2-b9a4-ebe12bcc7df1/chat';

void main() {
  runApp(const PharmaIntelApp());
}

class PharmaIntelApp extends StatelessWidget {
  const PharmaIntelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pharma Intelligence',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

// ---------------- Data layer ----------------

class Report {
  final String runDate;
  final String summary;
  final num overallScore;
  final List<dynamic> keyFindings;
  final List<dynamic> marketSignals;
  final List<dynamic> nextSteps;

  Report({
    required this.runDate,
    required this.summary,
    required this.overallScore,
    required this.keyFindings,
    required this.marketSignals,
    required this.nextSteps,
  });

  static List<dynamic> _parseJsonList(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) return raw;
    try {
      final decoded = jsonDecode(raw.toString());
      return decoded is List ? decoded : [];
    } catch (_) {
      return [];
    }
  }

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      runDate: json['run_date']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
      overallScore: json['overall_score'] is num ? json['overall_score'] : 0,
      keyFindings: _parseJsonList(json['key_findings_json']),
      marketSignals: _parseJsonList(json['market_signals_json']),
      nextSteps: _parseJsonList(json['next_steps_json']),
    );
  }
}

class Api {
  static Future<Report> fetchLatest() async {
    final res = await http.get(Uri.parse('$baseUrl/pharma/latest-report'));
    if (res.statusCode != 200) throw Exception('Server error ${res.statusCode}');
    return Report.fromJson(jsonDecode(res.body));
  }

  static Future<List<Report>> fetchReports() async {
    final res = await http.get(Uri.parse('$baseUrl/pharma/reports'));
    if (res.statusCode != 200) throw Exception('Server error ${res.statusCode}');
    final body = jsonDecode(res.body);
    final list = (body['reports'] as List? ?? []);
    return list.map((e) => Report.fromJson(e)).toList();
  }

  static Future<void> subscribe(String email) async {
    final res = await http.post(
      Uri.parse('$baseUrl/pharma/subscribe'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    if (res.statusCode != 200) throw Exception('Server error ${res.statusCode}');
  }
}

// ---------------- UI ----------------

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      const HomeScreen(),
      const HistoryScreen(),
      const SubscribeScreen(),
      const MizoChatScreen(),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Pharma Intelligence'), centerTitle: true),
      body: screens[_tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.today), label: 'Today'),
          NavigationDestination(icon: Icon(Icons.history), label: 'History'),
          NavigationDestination(icon: Icon(Icons.mail_outline), label: 'Subscribe'),
          NavigationDestination(icon: Icon(Icons.smart_toy_outlined), label: 'Mizo'),
        ],
      ),
    );
  }
}

Widget _section(String title, List<dynamic> items, {String itemKey = 'finding'}) {
  if (items.isEmpty) return const SizedBox.shrink();
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 16),
      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      ...items.map((item) {
        final text = item is Map
            ? (item[itemKey] ?? item['signal'] ?? item['step'] ?? item.values.join(' — ')).toString()
            : item.toString();
        return Card(
          child: Padding(padding: const EdgeInsets.all(12), child: Text(text)),
        );
      }),
    ],
  );
}

class ReportView extends StatelessWidget {
  final Report report;
  const ReportView({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(report.runDate, style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Overall Score: ', style: TextStyle(fontSize: 16)),
              Chip(
                label: Text('${report.overallScore} / 5',
                    style: const TextStyle(color: Colors.white)),
                backgroundColor: report.overallScore >= 4
                    ? Colors.green
                    : report.overallScore >= 3
                        ? Colors.orange
                        : Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(report.summary, style: const TextStyle(fontSize: 16)),
          _section('Key Findings', report.keyFindings),
          _section('Market Signals', report.marketSignals, itemKey: 'signal'),
          _section('Next Steps', report.nextSteps, itemKey: 'step'),
        ],
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Report>(
      future: Api.fetchLatest(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Could not load report.\n${snap.error}', textAlign: TextAlign.center),
            ),
          );
        }
        return ReportView(report: snap.data!);
      },
    );
  }
}

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Report>>(
      future: Api.fetchReports(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Could not load history.\n${snap.error}'));
        }
        final reports = snap.data!;
        if (reports.isEmpty) return const Center(child: Text('No reports yet.'));
        return ListView.builder(
          itemCount: reports.length,
          itemBuilder: (context, i) {
            final r = reports[i];
            return ListTile(
              title: Text(r.runDate),
              subtitle: Text(r.summary, maxLines: 2, overflow: TextOverflow.ellipsis),
              trailing: Chip(label: Text('${r.overallScore}/5')),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(title: Text(r.runDate)),
                    body: ReportView(report: r),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ---------------- Mizo chatbot ----------------

class MizoMessage {
  final String text;
  final bool fromUser;
  MizoMessage(this.text, this.fromUser);
}

class MizoChatScreen extends StatefulWidget {
  const MizoChatScreen({super.key});

  @override
  State<MizoChatScreen> createState() => _MizoChatScreenState();
}

class _MizoChatScreenState extends State<MizoChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final List<MizoMessage> _messages = [
    MizoMessage(
      'Hi! I am Mizo, your little robot medicine friend. Ask me anything about medicines and the pharma world in simple words.',
      false,
    ),
  ];
  bool _sending = false;
  final String _sessionId =
      'mizo-app-${DateTime.now().millisecondsSinceEpoch}';

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    _controller.clear();
    setState(() {
      _messages.add(MizoMessage(text, true));
      _sending = true;
    });
    _scrollToBottom();
    try {
      final res = await http
          .post(
            Uri.parse(mizoChatUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'action': 'sendMessage',
              'sessionId': _sessionId,
              'chatInput': text,
            }),
          )
          .timeout(const Duration(seconds: 120));
      String reply = 'Sorry, I could not think of an answer. Please try again.';
      if (res.statusCode == 200) {
        try {
          final d = jsonDecode(res.body);
          reply = (d['output'] ?? d['text'] ?? d['message'] ?? d['response'] ?? reply)
              .toString()
              .replaceAll('*', '')
              .trim();
        } catch (_) {
          if (res.body.trim().isNotEmpty) reply = res.body.trim();
        }
      } else {
        reply = 'Mizo server error ${res.statusCode}. Please try again.';
      }
      setState(() => _messages.add(MizoMessage(reply, false)));
    } catch (e) {
      setState(() => _messages
          .add(MizoMessage('Could not reach Mizo. Check your connection.', false)));
    } finally {
      setState(() => _sending = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.all(12),
            itemCount: _messages.length,
            itemBuilder: (context, i) {
              final m = _messages[i];
              return Align(
                alignment:
                    m.fromUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.8,
                  ),
                  decoration: BoxDecoration(
                    color: m.fromUser
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    m.text,
                    style: TextStyle(
                      color: m.fromUser ? Colors.white : null,
                      fontSize: 15,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (_sending)
          const Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: Text('Mizo is thinking...',
                style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),
          ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: const InputDecoration(
                      hintText: 'Ask Mizo anything...',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _sending ? null : _send,
                  child: const Text('Send'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class SubscribeScreen extends StatefulWidget {
  const SubscribeScreen({super.key});

  @override
  State<SubscribeScreen> createState() => _SubscribeScreenState();
}

class _SubscribeScreenState extends State<SubscribeScreen> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _message;

  Future<void> _submit() async {
    final email = _controller.text.trim();
    if (!email.contains('@')) {
      setState(() => _message = 'Please enter a valid email address.');
      return;
    }
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      await Api.subscribe(email);
      setState(() => _message = 'Subscribed! You will receive daily reports.');
      _controller.clear();
    } catch (e) {
      setState(() => _message = 'Subscription failed: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.notifications_active_outlined, size: 64),
          const SizedBox(height: 16),
          const Text('Get daily pharma intelligence by email',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email address',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Subscribe'),
            ),
          ),
          if (_message != null) ...[
            const SizedBox(height: 16),
            Text(_message!, textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }
}
