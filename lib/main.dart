import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';

const String server = 'http://vod4k.cc:80';
const String defaultUsername = '3143771383105485';
const String defaultPassword = '5846751342';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DhiqarTVApp());
}

class DhiqarTVApp extends StatelessWidget {
  const DhiqarTVApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ذي قار TV 2028',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF070E17),
        fontFamily: 'sans',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00A3FF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}

class ApiService {
  static Future<Map<String, dynamic>> login(String user, String pass) async {
    final uri = Uri.parse(
      '$server/player_api.php?username=${Uri.encodeQueryComponent(user)}&password=${Uri.encodeQueryComponent(pass)}',
    );
    final response = await http.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }
    final data = jsonDecode(response.body);
    if (data is! Map<String, dynamic>) throw Exception('بيانات السيرفر غير صالحة');
    return data;
  }

  static Future<List<dynamic>> liveStreams(String user, String pass) async {
    final uri = Uri.parse(
      '$server/player_api.php?username=${Uri.encodeQueryComponent(user)}&password=${Uri.encodeQueryComponent(pass)}&action=get_live_streams',
    );
    final response = await http.get(uri).timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) throw Exception('تعذر جلب القنوات');
    final data = jsonDecode(response.body);
    return data is List ? data : [];
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final user = TextEditingController(text: defaultUsername);
  final pass = TextEditingController(text: defaultPassword);
  bool loading = false;
  String? error;

  Future<void> submit() async {
    setState(() { loading = true; error = null; });
    try {
      final info = await ApiService.login(user.text.trim(), pass.text.trim());
      if (!mounted) return;
      final exp = info['user_info']?['exp_date']?.toString();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => Dashboard(
            username: user.text.trim(),
            password: pass.text.trim(),
            expiry: exp,
          ),
        ),
      );
    } catch (e) {
      setState(() => error = 'تعذر الاتصال بالسيرفر. تأكد من البيانات والاتصال بالإنترنت.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.3,
            colors: [Color(0xFF063A60), Color(0xFF070E17), Color(0xFF03070C)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: GlassCard(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const LogoBadge(),
                  const SizedBox(height: 18),
                  const Text('ذي قار TV 2028',
                      style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
                  const Text('SAT-VIEW 4K PRO IPTV',
                      style: TextStyle(color: Color(0xFF00A3FF), letterSpacing: 2)),
                  const SizedBox(height: 28),
                  _field('اسم المستخدم', user, Icons.person),
                  const SizedBox(height: 14),
                  _field('كلمة المرور', pass, Icons.lock, obscure: true),
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    Text(error!, style: const TextStyle(color: Colors.redAccent)),
                  ],
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton.icon(
                      onPressed: loading ? null : submit,
                      icon: loading
                          ? const SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.login),
                      label: Text(loading ? 'جاري الاتصال...' : 'دخول'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController c, IconData icon, {bool obscure = false}) {
    return TextField(
      controller: c,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF00A3FF)),
        filled: true,
        fillColor: const Color(0xAA071521),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class Dashboard extends StatefulWidget {
  final String username, password;
  final String? expiry;
  const Dashboard({super.key, required this.username, required this.password, this.expiry});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  Timer? timer;
  DateTime now = DateTime.now();

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => now = DateTime.now());
    });
  }

  @override
  void dispose() { timer?.cancel(); super.dispose(); }

  String dateText() {
    const days = ['الاثنين','الثلاثاء','الأربعاء','الخميس','الجمعة','السبت','الأحد'];
    return '${now.hour.toString().padLeft(2,'0')}:${now.minute.toString().padLeft(2,'0')} ${days[now.weekday-1]} ${now.day}/${now.month}/${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    final cards = [
      ('LIVE TV', 'القنوات المباشرة', Icons.live_tv),
      ('SPORTS', 'مباريات اليوم', Icons.sports_soccer),
      ('MOVIES', 'الأفلام', Icons.movie),
      ('SERIES', 'المسلسلات', Icons.tv),
      ('FAVORITE', 'المفضلة', Icons.star),
      ('SETTINGS', 'الإعدادات', Icons.settings),
    ];
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft, radius: 1.4,
            colors: [Color(0xFF063A60), Color(0xFF070E17), Color(0xFF03070C)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
                child: Row(
                  children: [
                    const LogoBadge(size: 50),
                    const SizedBox(width: 12),
                    Expanded(child: Center(child: Text(dateText(),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)))),
                    GlassCard(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(children: [
                        const Icon(Icons.wifi, color: Colors.greenAccent, size: 18),
                        const SizedBox(width: 6),
                        Text('الاشتراك نشط\nEXP: ${widget.expiry ?? "غير متاح"}',
                          style: const TextStyle(fontSize: 11)),
                      ]),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(18),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 300,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 1.18,
                  ),
                  itemCount: cards.length,
                  itemBuilder: (_, i) {
                    final c = cards[i];
                    return InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () {
                        if (i == 0) {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => ChannelScreen(username: widget.username, password: widget.password)));
                        }
                      },
                      child: GlassCard(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(c.$3, size: 52, color: i == 4 ? const Color(0xFFFFD700) : const Color(0xFF00A3FF)),
                            const SizedBox(height: 12),
                            Text(c.$1, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                            Text(c.$2, style: const TextStyle(color: Colors.white70)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(
                height: 94,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  children: ['beIN SPORTS','SSC','OSN','MBC'].map((x) =>
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: GlassCard(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                        child: Center(child: Text(x, style: const TextStyle(fontWeight: FontWeight.bold))),
                      ),
                    )).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF08121D),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'الرئيسية'),
          NavigationDestination(icon: Icon(Icons.live_tv), label: 'القنوات'),
          NavigationDestination(icon: Icon(Icons.sports_soccer), label: 'الرياضة'),
          NavigationDestination(icon: Icon(Icons.movie), label: 'أفلام/مسلسلات'),
          NavigationDestination(icon: Icon(Icons.star), label: 'المفضلة'),
        ],
      ),
    );
  }
}

class ChannelScreen extends StatefulWidget {
  final String username, password;
  const ChannelScreen({super.key, required this.username, required this.password});
  @override
  State<ChannelScreen> createState() => _ChannelScreenState();
}

class _ChannelScreenState extends State<ChannelScreen> {
  List<dynamic> channels = [];
  List<dynamic> filtered = [];
  bool loading = true;
  String search = '';
  final favorites = <int>{};

  @override
  void initState() { super.initState(); load(); }

  Future<void> load() async {
    try {
      final data = await ApiService.liveStreams(widget.username, widget.password);
      if (mounted) setState(() { channels = data; filtered = data; loading = false; });
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  void filter(String value) {
    final q = value.toLowerCase();
    setState(() {
      search = value;
      filtered = channels.where((c) =>
        (c['name'] ?? '').toString().toLowerCase().contains(q)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('القنوات المباشرة')),
      body: loading
        ? const Center(child: CircularProgressIndicator())
        : Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: TextField(
                onChanged: filter,
                decoration: InputDecoration(
                  hintText: 'بحث عن قناة...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: const Color(0xAA071521),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                ? const Center(child: Text('لا توجد قنوات مطابقة'))
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final c = filtered[i] as Map<String, dynamic>;
                      final id = int.tryParse('${c['stream_id']}') ?? i;
                      final name = '${c['name'] ?? 'قناة'}';
                      final icon = '${c['stream_icon'] ?? ''}';
                      final url = '$server/live/${widget.username}/${widget.password}/${c['stream_id']}.ts';
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        child: GlassCard(
                          padding: const EdgeInsets.all(10),
                          child: ListTile(
                            leading: ChannelLogo(url: icon),
                            title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: const Text('بث مباشر'),
                            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withOpacity(.18),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.redAccent),
                                ),
                                child: const Text('LIVE', style: TextStyle(color: Colors.redAccent, fontSize: 11)),
                              ),
                              IconButton(
                                icon: Icon(favorites.contains(id) ? Icons.star : Icons.star_border,
                                  color: const Color(0xFFFFD700)),
                                onPressed: () => setState(() {
                                  favorites.contains(id) ? favorites.remove(id) : favorites.add(id);
                                }),
                              ),
                            ]),
                            onTap: () => Navigator.push(context, MaterialPageRoute(
                              builder: (_) => PlayerScreen(title: name, url: url))),
                          ),
                        ),
                      );
                    },
                  ),
            ),
          ],
        ),
    );
  }
}

class PlayerScreen extends StatefulWidget {
  final String title, url;
  const PlayerScreen({super.key, required this.title, required this.url});
  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late VideoPlayerController controller;
  bool ready = false;

  @override
  void initState() {
    super.initState();
    controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (mounted) setState(() => ready = true);
        controller.play();
      });
  }

  @override
  void dispose() { controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: ready
                ? AspectRatio(aspectRatio: controller.value.aspectRatio, child: VideoPlayer(controller))
                : const CircularProgressIndicator(),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            color: const Color(0xFF07111C),
            child: Row(
              children: [
                IconButton(onPressed: () => controller.value.isPlaying ? controller.pause() : controller.play(),
                  icon: Icon(controller.value.isPlaying ? Icons.pause : Icons.play_arrow)),
                const Spacer(),
                const Text('4K', style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
                const SizedBox(width: 18),
                const Icon(Icons.hd),
                const SizedBox(width: 18),
                const Icon(Icons.star_border, color: Color(0xFFFFD700)),
                const SizedBox(width: 18),
                const Icon(Icons.fullscreen),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChannelLogo extends StatelessWidget {
  final String url;
  const ChannelLogo({super.key, required this.url});
  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return const CircleAvatar(child: Icon(Icons.tv));
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(url, width: 54, height: 54, fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const SizedBox(width: 54, height: 54, child: Icon(Icons.tv))),
    );
  }
}

class LogoBadge extends StatelessWidget {
  final double size;
  const LogoBadge({super.key, this.size = 82});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFF8F6B00)]),
        boxShadow: const [BoxShadow(color: Color(0x66FFD700), blurRadius: 22)],
      ),
      child: Center(child: Icon(Icons.satellite_alt, size: size * .55, color: const Color(0xFF070E17))),
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const GlassCard({super.key, required this.child, this.padding = const EdgeInsets.all(18)});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xAA0B1A29),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x9900A3FF), width: 1.2),
        boxShadow: const [
          BoxShadow(color: Color(0x3300A3FF), blurRadius: 18, spreadRadius: 1),
          BoxShadow(color: Color(0x66000000), blurRadius: 12),
        ],
      ),
      child: child,
    );
  }
}
