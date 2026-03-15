import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const BrawlApp());

class BrawlApp extends StatelessWidget {
  const BrawlApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        primaryColor: Colors.redAccent,
      ),
      home: const DashboardScreen(),
    );
  }
}

// --- LOGIKA ANALISIS DURASI ---
String getFightStyle(int seconds) {
  if (seconds < 30) return "BLITZ (FAST KILL)";
  if (seconds < 120) return "TACTICAL BRAWL";
  return "ENDURANCE WARRIOR";
}

// --- SISTEM RANKING ---
class RankSystem {
  static const List<String> tiers = ["BRONZE", "SILVER", "GOLD", "PLATINUM", "DIAMOND", "SUPREME"];
  static const List<String> divisions = ["V", "IV", "III", "II", "I"];

  static String getRank(int points) {
    if (points >= 2500) return "SUPREME GOD";
    int tierIndex = (points ~/ 500); 
    int divIndex = (points % 500) ~/ 100; 
    if (tierIndex >= tiers.length) return tiers.last;
    return "${tiers[tierIndex]} ${divisions[divIndex.clamp(0, 4)]}";
  }

  static Color getRankColor(String rank) {
    if (rank.contains("BRONZE")) return Colors.brown;
    if (rank.contains("SILVER")) return Colors.grey;
    if (rank.contains("GOLD")) return Colors.amber;
    if (rank.contains("PLATINUM")) return Colors.cyan;
    if (rank.contains("DIAMOND")) return Colors.blueAccent;
    return Colors.redAccent;
  }
}

// --- 1. DASHBOARD SCREEN ---
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String userBrawlID = "LOADING...";
  int _totalPoints = 0;
  String _activeTitle = "THE BEAST";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _totalPoints = (prefs.getInt('points') ?? 100);
      userBrawlID = (prefs.getString('brawlID') ?? _generateAndSaveID(prefs));
      _activeTitle = (prefs.getString('activeTitle') ?? "THE BEAST");
    });
  }

  String _generateAndSaveID(SharedPreferences prefs) {
    var uuid = const Uuid();
    String newID = "BRAWL-${uuid.v4().substring(0, 8).toUpperCase()}";
    prefs.setString('brawlID', newID);
    return newID;
  }

  @override
  Widget build(BuildContext context) {
    String currentRank = RankSystem.getRank(_totalPoints);
    Color rankColor = RankSystem.getRankColor(currentRank);

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(currentRank, rankColor),
            _buildRankProgressBar(rankColor),
            _buildStatsSection(),
            _buildActionMenu(context),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String rank, Color color) {
    return Container(
      padding: const EdgeInsets.only(top: 60, bottom: 25, left: 20, right: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(35)),
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 40, backgroundColor: color, child: const Icon(Icons.person, size: 50, color: Colors.white)),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("YAZATA '$_activeTitle'", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(rank, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.5)),
                Text(userBrawlID, style: const TextStyle(color: Colors.grey, fontSize: 10, fontFamily: 'monospace')),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildRankProgressBar(Color color) {
    int pointsInCurrentLevel = _totalPoints % 100;
    return Padding(
      padding: const EdgeInsets.all(25),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("RANK PROGRESS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
              Text("$_totalPoints BP", style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(value: pointsInCurrentLevel / 100, backgroundColor: Colors.white10, color: color, minHeight: 8),
          const SizedBox(height: 5),
          Align(alignment: Alignment.centerRight, child: Text("${100 - pointsInCurrentLevel} BP to next Div", style: const TextStyle(color: Colors.grey, fontSize: 10))),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 25),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _StatItem(label: "WEIGHT", value: "50 KG"),
          _StatItem(label: "HEIGHT", value: "170 CM"),
          _StatItem(label: "STYLE", value: "BOXING"),
        ],
      ),
    );
  }

  Widget _buildActionMenu(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _actionButton(context, "BATTLE", "Cari lawan", Icons.radar, Colors.redAccent, const RadarMapScreen()),
          _actionButton(context, "HISTORY", "Catatan", Icons.history, Colors.white24, const FightHistoryScreen()),
          _actionButton(context, "ACHIEVEMENTS", "Gelar", Icons.emoji_events, Colors.amber, const AchievementsScreen()),
        ],
      ),
    );
  }

  Widget _actionButton(BuildContext context, String title, String sub, IconData icon, Color color, Widget target) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (context) => target));
        _loadUserData();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(15), border: Border.all(color: color.withOpacity(0.3))),
        child: Row(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(width: 20),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), Text(sub, style: const TextStyle(color: Colors.grey, fontSize: 12))]),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

// --- 2. RADAR MAP SCREEN ---
class RadarMapScreen extends StatefulWidget {
  const RadarMapScreen({super.key});
  @override
  State<RadarMapScreen> createState() => _RadarMapScreenState();
}

class _RadarMapScreenState extends State<RadarMapScreen> {
  final List<Map<String, dynamic>> _enemies = [
    {"name": "Heru Lohan", "x": 0.0, "y": -0.5, "rank": "SILVER I"},
    {"name": "Jefri Knalpot", "x": -0.3, "y": 0.4, "rank": "GOLD V"},
    {"name": "Cilok Mang Ujang", "x": 0.3, "y": -0.1, "rank": "PLATINUM III"},
    {"name": "Kiki Laundry", "x": 0.1, "y": -0.85, "rank": "BRONZE II"},
  ];

  int _selectedWager = 10;
  int _userCurrentPoints = 0;

  @override
  void initState() {
    super.initState();
    _loadPoints();
  }

  _loadPoints() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _userCurrentPoints = prefs.getInt('points') ?? 100);
  }

  void _showWagerDialog(String name, String rank) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("TENTUKAN TARUHAN (WAGER)", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [10, 50, 100, 500].map((val) {
                    bool isSelected = _selectedWager == val;
                    bool canAfford = _userCurrentPoints >= val;
                    return GestureDetector(
                      onTap: canAfford ? () => setModalState(() => _selectedWager = val) : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.redAccent : (canAfford ? Colors.white10 : Colors.black),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isSelected ? Colors.white : Colors.white10),
                        ),
                        child: Text("$val BP", style: TextStyle(color: canAfford ? Colors.white : Colors.white24, fontWeight: FontWeight.bold)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => BattleArenaScreen(enemyName: name, wager: _selectedWager)));
                    },
                    child: Text("KONFIRMASI DUEL vs $name", style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 10),
                Text("Saldo Anda: $_userCurrentPoints BP", style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("RADAR JAKARTA"), backgroundColor: Colors.black),
      body: Stack(
        children: [
          SizedBox.expand(
            child: Image.network(
              'https://api.mapbox.com/styles/v1/mapbox/dark-v10/static/106.8272,-6.1751,12,0/600x800?access_token=pk.eyJ1IjoiZmx1dHRlci1kZW1vIiwiYSI6ImNrZmxvY3B4bDAxbXoyc213ZzRndmZ3ZnEifQ==',
              fit: BoxFit.cover,
            ),
          ),
          ..._enemies.map((e) => Align(
            alignment: Alignment(e['x'], e['y']),
            child: GestureDetector(
              onTap: () => _showWagerDialog(e['name'], e['rank']),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.black.withOpacity(0.8), borderRadius: BorderRadius.circular(4)), child: Text(e['name'], style: const TextStyle(fontSize: 9, color: Colors.white))),
                  const Icon(Icons.location_on, color: Colors.redAccent, size: 35),
                ],
              ),
            ),
          )).toList(),
          const Center(child: Icon(Icons.my_location, color: Colors.blueAccent, size: 40)),
        ],
      ),
    );
  }
}

// --- 3. BATTLE ARENA (DENGAN FEEDBACK & REPORT) ---
class BattleArenaScreen extends StatefulWidget {
  final String enemyName;
  final int wager;
  const BattleArenaScreen({super.key, required this.enemyName, required this.wager});

  @override
  State<BattleArenaScreen> createState() => _BattleArenaScreenState();
}

class _BattleArenaScreenState extends State<BattleArenaScreen> {
  int _secondsElapsed = 0;
  Timer? _timer;
  bool _photoTaken = false;
  List<String> _injuries = [];
  bool _isSportif = true;
  final TextEditingController _reportController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _secondsElapsed++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _reportController.dispose();
    super.dispose();
  }

  void _showPostMatchReport(bool isWin) {
    _timer?.cancel(); 
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => Container(),
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: anim1.value,
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return AlertDialog(
                backgroundColor: const Color(0xFF1A1A1A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: Text(isWin ? "VICTORY REPORT" : "DEFEAT LOGGED", 
                  style: TextStyle(color: isWin ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(5)),
                        child: Text("STYLE: ${getFightStyle(_secondsElapsed)}", 
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber)),
                      ),
                      const SizedBox(height: 15),
                      const Text("📸 EVIDENCE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 5),
                      GestureDetector(
                        onTap: () => setModalState(() => _photoTaken = true),
                        child: Container(
                          height: 70, width: double.infinity,
                          decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8), border: Border.all(color: _photoTaken ? Colors.green : Colors.white24)),
                          child: _photoTaken 
                            ? const Icon(Icons.check_circle, color: Colors.green) 
                            : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.camera_alt, size: 20), Text("Ambil Foto Bukti", style: TextStyle(fontSize: 9))]),
                        ),
                      ),
                      const SizedBox(height: 15),
                      const Text("🩹 DAMAGE TAKEN", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                      Wrap(
                        spacing: 4,
                        children: ["HEAD", "TORSO", "ARMS", "LEGS"].map((part) {
                          bool selected = _injuries.contains(part);
                          return FilterChip(
                            label: Text(part, style: const TextStyle(fontSize: 9)),
                            selected: selected,
                            padding: EdgeInsets.zero,
                            onSelected: (val) {
                              setModalState(() {
                                val ? _injuries.add(part) : _injuries.remove(part);
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 15),
                      const Text("🛡️ FAIR PLAY", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                      CheckboxListTile(
                        title: const Text("Lawan bermain sportif", style: TextStyle(fontSize: 11)),
                        value: _isSportif,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (val) => setModalState(() => _isSportif = val!),
                      ),
                      TextField(
                        controller: _reportController,
                        style: const TextStyle(fontSize: 11),
                        decoration: const InputDecoration(
                          hintText: "Laporan kecurangan/feedback...",
                          hintStyle: TextStyle(fontSize: 10),
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  SizedBox(width: double.infinity, child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                    onPressed: _photoTaken ? () => _saveAndExit(isWin) : null,
                    child: const Text("SUBMIT FINAL DATA", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ))
                ],
              );
            }
          ),
        );
      },
    );
  }

  Future<void> _saveAndExit(bool isWin) async {
    final prefs = await SharedPreferences.getInstance();
    int currentPoints = (prefs.getInt('points') ?? 100);
    int amount = isWin ? widget.wager : -widget.wager;

    List<String> history = (prefs.getStringList('history') ?? []);
    Map<String, dynamic> entry = {
      'opponent': widget.enemyName,
      'result': isWin ? 'WIN' : 'LOSS',
      'points': amount.abs(),
      'duration': _secondsElapsed,
      'style': getFightStyle(_secondsElapsed),
      'injuries': _injuries,
      'sportif': _isSportif,
      'report': _reportController.text,
      'date': DateTime.now().toString(),
    };
    history.insert(0, jsonEncode(entry));
    
    await prefs.setInt('points', (currentPoints + amount).clamp(0, 50000));
    await prefs.setStringList('history', history);
    if (isWin) await prefs.setInt('totalWins', (prefs.getInt('totalWins') ?? 0) + 1);

    if (!mounted) return;
    Navigator.of(context).pop(); Navigator.of(context).pop(); Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    String timeFormatted = "${(_secondsElapsed ~/ 60).toString().padLeft(2, '0')}:${(_secondsElapsed % 60).toString().padLeft(2, '0')}";
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF300000), Colors.black], begin: Alignment.topCenter)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(20)),
              child: Text("STAKES: ${widget.wager} BP", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
            const SizedBox(height: 40),
            Text(timeFormatted, style: const TextStyle(fontSize: 70, fontWeight: FontWeight.w900, fontFamily: 'monospace', color: Colors.white)),
            const SizedBox(height: 10),
            Text("VS ${widget.enemyName}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 3)),
            const SizedBox(height: 80),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                children: [
                  Expanded(child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                    onPressed: () => _showPostMatchReport(true),
                    child: const Text("I WIN", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  )),
                  const SizedBox(width: 20),
                  Expanded(child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: const EdgeInsets.symmetric(vertical: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                    onPressed: () => _showPostMatchReport(false),
                    child: const Text("I LOSE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- 4. HISTORY SCREEN ---
class FightHistoryScreen extends StatefulWidget {
  const FightHistoryScreen({super.key});
  @override
  State<FightHistoryScreen> createState() => _FightHistoryScreenState();
}

class _FightHistoryScreenState extends State<FightHistoryScreen> {
  List<dynamic> _history = [];
  @override
  void initState() { super.initState(); _load(); }
  _load() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> raw = prefs.getStringList('history') ?? [];
    setState(() => _history = raw.map((e) => jsonDecode(e)).toList());
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("FIGHT LOGS & EVIDENCE")),
      body: _history.isEmpty 
        ? const Center(child: Text("No records found."))
        : ListView.builder(
            itemCount: _history.length,
            itemBuilder: (context, i) {
              final item = _history[i];
              bool isWin = item['result'] == 'WIN';
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                color: const Color(0xFF1A1A1A),
                child: ExpansionTile(
                  leading: Icon(isWin ? Icons.add_circle : Icons.remove_circle, color: isWin ? Colors.green : Colors.red),
                  title: Text("vs ${item['opponent']} (${item['result']})"),
                  subtitle: Text(item['style'] ?? "REGULAR FIGHT"),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("⏱ Duration: ${item['duration']} seconds"),
                          const SizedBox(height: 5),
                          Text("🩹 Damage Taken: ${item['injuries'] == null || item['injuries'].isEmpty ? 'None' : item['injuries'].join(', ')}"),
                          const SizedBox(height: 5),
                          Text("🛡️ Sportif: ${item['sportif'] ?? true ? 'Ya' : 'TIDAK'}"),
                          const SizedBox(height: 5),
                          Text("📝 Report: ${item['report'] ?? '-'}"),
                          const SizedBox(height: 5),
                          Text("💰 Payout: ${isWin ? '+' : '-'}${item['points']} BP"),
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          ),
    );
  }
}

// --- 5. ACHIEVEMENTS ---
class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});
  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  List<String> _unlocked = ["THE BEAST"];
  String _active = "THE BEAST";

  @override
  void initState() { super.initState(); _load(); }
  _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _unlocked = prefs.getStringList('titles') ?? ["THE BEAST"];
      _active = prefs.getString('activeTitle') ?? "THE BEAST";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("TITLES")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _badge("THE BEAST", "Starter Title", _unlocked.contains("THE BEAST")),
          _badge("HIGH ROLLER", "Menang Wager 500 BP", _unlocked.contains("HIGH ROLLER")),
        ],
      ),
    );
  }

  Widget _badge(String t, String d, bool unlocked) {
    bool isActive = _active == t;
    return ListTile(
      enabled: unlocked,
      leading: Icon(Icons.workspace_premium, color: unlocked ? (isActive ? Colors.redAccent : Colors.amber) : Colors.white10),
      title: Text(t, style: TextStyle(fontWeight: FontWeight.bold, color: unlocked ? Colors.white : Colors.grey)),
      subtitle: Text(d),
      trailing: isActive ? const Text("ACTIVE", style: TextStyle(color: Colors.redAccent)) : (unlocked ? const Icon(Icons.touch_app) : const Icon(Icons.lock)),
      onTap: unlocked ? () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('activeTitle', t);
        setState(() => _active = t);
      } : null,
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label, value;
  const _StatItem({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Column(children: [Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)), Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]);
}