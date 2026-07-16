import 'package:besh24_sdk/besh24_sdk.dart';
import 'package:flutter/material.dart';

/// Point this at your Besh24 API (must include the `/api/v1` prefix).
const _baseUrl = 'https://besh24.example.com/api/v1';

void main() => runApp(const Besh24ExampleApp());

/// Root widget of the example app.
class Besh24ExampleApp extends StatelessWidget {
  /// Creates the app.
  const Besh24ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Besh24 SDK example',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      home: const _HomePage(),
    );
  }
}

class _HomePage extends StatefulWidget {
  const _HomePage();

  @override
  State<_HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage> {
  // In production create one client for the app lifetime.
  final Besh24Client _client = Besh24Client();
  final List<String> _log = [];
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _client.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    // 1) init → GET /identity → persisted anon/session id.
    final identity = await _client.init(
      Besh24Config(baseUrl: _baseUrl, siteKey: 'bsk_demo_9f3c1a2b', source: 'app'),
    );
    _append(
        'init → anon=${identity.anonymousId} session=${identity.sessionId}');
    setState(() => _ready = true);
  }

  void _append(String line) {
    setState(() => _log.insert(0, line));
  }

  Future<void> _trackView() async {
    final res = await _client.trackView('SKU-123', available: true);
    _append('trackView → ${res.isOk ? 'accepted' : res.errorOrNull}');
  }

  Future<void> _recommend() async {
    final res = await _client.recommend('popular', limit: 8);
    final value = res.valueOrNull;
    _append(
        'recommend → ${value?.itemIds ?? const []} (req ${value?.requestId})');
  }

  Future<void> _search() async {
    final res = await _client.search('телефон');
    final value = res.valueOrNull;
    _append(
        'search → ${value?.total ?? 0} total, ${value?.items.length ?? 0} items');
  }

  Future<void> _instant() async {
    final res = await _client.searchInstant('теле');
    _append('instant → ${res.valueOrNull?.length ?? 0} suggestions');
  }

  Future<void> _subscribe() async {
    final res = await _client.subscribeRestock(
      const RestockInput(itemId: 'SKU-123', email: 'demo@besh24.test'),
    );
    _append('subscribeRestock → ${res.isOk ? 'created' : res.errorOrNull}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Besh24 SDK example')),
      body: Column(
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _btn('Track view', _trackView),
              _btn('Recommend', _recommend),
              _btn('Search', _search),
              _btn('Instant', _instant),
              _btn('Subscribe restock', _subscribe),
            ],
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: _log.length,
              itemBuilder: (_, i) => ListTile(
                dense: true,
                title: Text(_log[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _btn(String label, Future<void> Function() onTap) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: FilledButton(
        onPressed: _ready ? () => onTap() : null,
        child: Text(label),
      ),
    );
  }
}
