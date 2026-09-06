import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const String baseUrl = 'https://ashubaba02.app.n8n.cloud/webhook';
const String mizoChatUrl =
    '$baseUrl/20d821d7-ec90-45c2-b9a4-ebe12bcc7df1/chat';

const Color kBg = Color(0xFF05060F);
const Color kPanel = Color(0xFF141A30);
const Color kCard = Color(0xFF0A0E1E);
const Color kCyan = Color(0xFF22D3EE);
const Color kMagenta = Color(0xFFE879F9);
const Color kText = Color(0xFFE2E8F0);
const Color kMuted = Color(0xFF7D8AA5);
const Color kLine = Color(0x2E5EEAD4);

const LinearGradient kGrad = LinearGradient(colors: [kCyan, kMagenta]);

void main() {
  runApp(const PharmaIntelApp());
}

class PharmaIntelApp extends StatelessWidget {
  const PharmaIntelApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData.dark(useMaterial3: true);
    return MaterialApp(
      title: 'Pharma Intelligence',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        scaffoldBackgroundColor: kBg,
        colorScheme: const ColorScheme.dark(
          primary: kCyan,
          secondary: kMagenta,
          surface: kPanel,
          onSurface: kText,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: kBg,
          foregroundColor: kText,
          elevation: 0,
          centerTitle: true,
        ),
        cardTheme: CardThemeData(
          color: kCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: kLine),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF050814),
          hintStyle: const TextStyle(color: kMuted),
          labelStyle: const TextStyle(color: kMuted),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kLine),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kCyan, width: 1.5),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: kPanel,
          indicatorColor: kCyan.withOpacity(0.18),
          iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
              color: states.contains(WidgetState.selected) ? kCyan : kMuted)),
          labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
              color: states.contains(WidgetState.selected) ? kCyan : kMuted,
              fontSize: 12)),
        ),
        progressIndicatorTheme:
            const ProgressIndicatorThemeData(color: kCyan),
      ),
      home: const MainScreen(),
    );
  }
}

class GradientText extends StatelessWidget {
  final String text;
  final double size;
  final FontWeight weight;
  final double letterSpacing;
  const GradientText(this.text,
      {super.key,
      this.size = 20,
      this.weight = FontWeight.w800,
      this.letterSpacing = 2});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (rect) => kGrad.createShader(rect),
      child: Text(text,
          style: TextStyle(
              fontSize: size,
              fontWeight: weight,
              letterSpacing: letterSpacing,
              color: Colors.white)),
    );
  }
}

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
      appBar: AppBar(
        title: const GradientText('PHARMA INTELLIGENCE',
            size: 18, letterSpacing: 2.5),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.7, -1.0),
            radius: 1.2,
            colors: [Color(0x2622D3EE), Colors.transparent],
          ),
        ),
        child: screens[_tab],
      ),
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

Widget _sectionTitle(String title) => Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(title.toUpperCase(),
          style: const TextStyle(
              fontSize: 13,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w700,
              color: kCyan)),
    );

Widget _section(String title, List<dynamic> items, {String itemKey = 'finding'}) {
  if (items.isEmpty) return const SizedBox.shrink();
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionTitle(title),
      ...items.map((item) {
        final text = item is Map
            ? (item[itemKey] ?? item['signal'] ?? item['step'] ?? item.values.join(' — ')).toString()
            : item.toString();
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(text, style: const TextStyle(color: kText, fontSize: 14, height: 1.5)),
          ),
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
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: kLine),
                  ),
                  child: Column(
                    children: [
                      GradientText('${report.overallScore}', size: 30, letterSpacing: 0),
                      const SizedBox(height: 4),
                      const Text('OPPORTUNITY SCORE / 5',
                          style: TextStyle(color: kMuted, fontSize: 10, letterSpacing: 1)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: kLine),
                  ),
                  child: Column(
                    children: [
                      Text(report.runDate,
                          style: const TextStyle(
                              color: kText, fontSize: 14, fontWeight: FontWeight.w700),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 4),
                      const Text('RESEARCH RUN',
                          style: TextStyle(color: kMuted, fontSize: 10, letterSpacing: 1)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          _sectionTitle('Summary'),
          Text(report.summary, style: const TextStyle(color: kText, fontSize: 15, height: 1.7)),
          _section('Key Findings', report.keyFindings),
          _section('Market Signals', report.marketSignals, itemKey: 'signal'),
          _section('Next Steps', report.nextSteps, itemKey: 'step'),
          const SizedBox(height: 24),
          const Center(
            child: Text(
              'Owned and maintained by Ashutosh Tripathy\nResearch-support information only. Not medical advice.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF475569), fontSize: 11, height: 1.5),
            ),
          ),
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
          return const Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('Scanning global sources...', style: TextStyle(color: kMuted, fontSize: 13)),
            ]),
          );
        }
        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Could not load report.\n${snap.error}',
                  textAlign: TextAlign.center, style: const TextStyle(color: kMuted)),
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
          return Center(
              child: Text('Could not load history.\n${snap.error}',
                  style: const TextStyle(color: kMuted), textAlign: TextAlign.center));
        }
        final reports = snap.data!;
        if (reports.isEmpty) {
          return const Center(child: Text('No reports yet.', style: TextStyle(color: kMuted)));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: reports.length,
          itemBuilder: (context, i) {
            final r = reports[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(r.runDate, style: const TextStyle(color: kText, fontWeight: FontWeight.w600)),
                subtitle: Text(r.summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: kMuted, fontSize: 13)),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: kLine),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('${r.overallScore}/5', style: const TextStyle(color: kCyan, fontSize: 12)),
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => Scaffold(
                      appBar: AppBar(title: Text(r.runDate)),
                      body: Container(color: kBg, child: ReportView(report: r)),
                    ),
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

class MizoMessage {
  final String text;
  final bool fromUser;
  MizoMessage(this.text, this.fromUser);
}

class MizoAvatar extends StatelessWidget {
  final double size;
  const MizoAvatar({super.key, this.size = 34});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [kCyan, kCyan, Color(0xFFEEF2FF), Color(0xFFEEF2FF)],
          stops: [0, 0.5, 0.5, 1],
        ),
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: kCyan.withOpacity(0.5), blurRadius: 12)],
      ),
      child: const Icon(Icons.smart_toy, size: 18, color: Color(0xFF0F172A)),
    );
  }
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
      'Hi! I am Mizo, your little robot medicine friend. Ask me anything about medicines and the pharma world in simple words. Tip: type /new chat anytime to clear this chat and start fresh.',
      false,
    ),
  ];
  bool _sending = false;
  String _sessionId =
      'mizo-app-${DateTime.now().millisecondsSinceEpoch}';

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    _controller.clear();
    if (text == '/new chat' || text == '/new') {
      setState(() {
        _sessionId = 'mizo-app-${DateTime.now().millisecondsSinceEpoch}';
        _messages.clear();
        _messages.add(MizoMessage(
            'Fresh chat started! Mizo has forgotten our old conversation. What would you like to know?',
            false));
      });
      return;
    }
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: const BoxDecoration(
            color: kPanel,
            border: Border(bottom: BorderSide(color: kLine)),
          ),
          child: const Row(
            children: [
              MizoAvatar(),
              SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                GradientText('MIZO', size: 15, letterSpacing: 1.5),
                Text('Your friendly pharma guide',
                    style: TextStyle(color: kMuted, fontSize: 11)),
              ]),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.all(12),
            itemCount: _messages.length,
            itemBuilder: (context, i) {
              final m = _messages[i];
              return Align(
                alignment: m.fromUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.82,
                  ),
                  decoration: BoxDecoration(
                    gradient: m.fromUser
                        ? const LinearGradient(colors: [Color(0xFF0891B2), Color(0xFF0E7490)])
                        : null,
                    color: m.fromUser ? null : kPanel,
                    border: m.fromUser ? null : Border.all(color: kLine),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(14),
                      topRight: const Radius.circular(14),
                      bottomLeft: Radius.circular(m.fromUser ? 14 : 4),
                      bottomRight: Radius.circular(m.fromUser ? 4 : 14),
                    ),
                  ),
                  child: Text(m.text,
                      style: const TextStyle(color: kText, fontSize: 14.5, height: 1.5)),
                ),
              );
            },
          ),
        ),
        if (_sending)
          const Padding(
            padding: EdgeInsets.only(bottom: 6),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)),
              SizedBox(width: 8),
              Text('Mizo is thinking...',
                  style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12, color: kMuted)),
            ]),
          ),
        SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            decoration: const BoxDecoration(
              color: kPanel,
              border: Border(top: BorderSide(color: kLine)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    style: const TextStyle(color: kText),
                    decoration: const InputDecoration(
                      hintText: 'Ask Mizo anything...',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    gradient: kGrad,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: _sending ? null : _send,
                    icon: const Icon(Icons.send, color: Color(0xFF04121A)),
                  ),
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
  bool _ok = false;

  Future<void> _submit() async {
    final email = _controller.text.trim();
    if (!email.contains('@')) {
      setState(() {
        _ok = false;
        _message = 'Please enter a valid email address.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      await Api.subscribe(email);
      setState(() {
        _ok = true;
        _message = 'Subscribed! You will receive the next daily Pharma Intelligence email.';
      });
      _controller.clear();
    } catch (e) {
      setState(() {
        _ok = false;
        _message = 'Subscription failed: $e';
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: kPanel.withOpacity(0.55),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: kLine),
            ),
            child: Column(
              children: [
                const Icon(Icons.notifications_active_outlined, size: 56, color: kCyan),
                const SizedBox(height: 16),
                const GradientText('GET THE DAILY INTELLIGENCE EMAIL',
                    size: 13, letterSpacing: 1.5),
                const SizedBox(height: 8),
                const Text(
                  'Worldwide pharma news, market signals and AI research summaries — every day in your inbox.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: kMuted, fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _controller,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: kText),
                  decoration: const InputDecoration(
                    hintText: 'Enter your Gmail address',
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: kGrad,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextButton(
                      onPressed: _loading ? null : _submit,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        foregroundColor: const Color(0xFF04121A),
                      ),
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Color(0xFF04121A)))
                          : const Text('Subscribe',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    ),
                  ),
                ),
                if (_message != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    _message!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _ok ? const Color(0xFF6EE7B7) : const Color(0xFFFDA4AF),
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
