import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const url = 'https://gnhwmxjmzybqxcgghcbo.supabase.co';
  const key = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  if (url.isEmpty || key.isEmpty) {
    runApp(const MaterialApp(
        home: Scaffold(
            body: Center(
                child: Text(
                    'Configure SUPABASE_PUBLISHABLE_KEY com --dart-define.')))));
    return;
  }
  try {
    await Supabase.initialize(url: url, anonKey: key);
    runApp(const ChampionsApp());
  } catch (error) {
    runApp(MaterialApp(
        home: Scaffold(
            body: Center(
                child: Padding(
      padding: const EdgeInsets.all(24),
      child: SelectableText('Falha ao iniciar o Supabase: $error'),
    )))));
  }
}

final db = Supabase.instance.client;

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) => StreamBuilder<AuthState>(
        stream: db.auth.onAuthStateChange,
        builder: (context, snapshot) =>
            db.auth.currentUser == null ? const LoginPage() : const Home(),
      );
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController(), password = TextEditingController();
  bool busy = false;
  String message = '';
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit(bool signup) async {
    if (email.text.trim().isEmpty || password.text.length < 6) {
      setState(() => message =
          'Informe um e-mail e uma senha com pelo menos 6 caracteres.');
      return;
    }
    setState(() {
      busy = true;
      message = '';
    });
    try {
      if (signup) {
        final result = await db.auth
            .signUp(email: email.text.trim(), password: password.text);
        if (result.session == null)
          setState(
              () => message = 'Confira seu e-mail para confirmar o cadastro.');
      } else {
        await db.auth.signInWithPassword(
            email: email.text.trim(), password: password.text);
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      final friendly = e.code == 'anonymous_provider_disabled'
          ? 'O Supabase tentou usar login anônimo. Use Entrar ou Criar conta com e-mail e senha; se persistir, confira o provedor Email no painel Authentication.'
          : e.message;
      setState(() => message = 'Não foi possível autenticar: $friendly');
    } catch (e) {
      if (mounted) setState(() => message = 'Erro de autenticação: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      body: Center(
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.sports_soccer,
                        size: 64, color: Color(0xFFB4F34A)),
                    const SizedBox(height: 14),
                    const Text('CARTOLA CHAMPIONS',
                        style: TextStyle(
                            fontSize: 26, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 25),
                    TextField(
                        controller: email,
                        decoration: const InputDecoration(labelText: 'E-mail')),
                    const SizedBox(height: 12),
                    TextField(
                        controller: password,
                        obscureText: true,
                        decoration: const InputDecoration(
                            labelText: 'Senha (mínimo 6 caracteres)')),
                    const SizedBox(height: 20),
                    FilledButton(
                        onPressed: busy ? null : () => submit(false),
                        child: const Text('Entrar')),
                    TextButton(
                        onPressed: busy ? null : () => submit(true),
                        child: const Text('Criar conta')),
                    if (message.isNotEmpty)
                      Text(message, textAlign: TextAlign.center)
                  ])))));
}

class Player {
  final int id;
  final String name, club, role;
  final double price;
  const Player(this.id, this.name, this.club, this.role, this.price);
}

// Dados de demonstração. Substituir por API licenciada antes de usar em produção.
const players = <Player>[
  Player(1, 'Courtois', 'Real Madrid', 'GOL', 12),
  Player(2, 'Donnarumma', 'Manchester City', 'GOL', 11),
  Player(3, 'Raya', 'Arsenal', 'GOL', 10),
  Player(4, 'Hakimi', 'PSG', 'DEF', 12),
  Player(5, 'Saliba', 'Arsenal', 'DEF', 11),
  Player(6, 'Van Dijk', 'Liverpool', 'DEF', 12),
  Player(7, 'Rüdiger', 'Real Madrid', 'DEF', 10),
  Player(8, 'Bastoni', 'Inter', 'DEF', 9),
  Player(9, 'Koundé', 'Barcelona', 'DEF', 9),
  Player(10, 'Gvardiol', 'Manchester City', 'DEF', 10),
  Player(11, 'Bellingham', 'Real Madrid', 'MEI', 14),
  Player(12, 'Pedri', 'Barcelona', 'MEI', 12),
  Player(13, 'Vitinha', 'PSG', 'MEI', 11),
  Player(14, 'Musiala', 'Bayern', 'MEI', 13),
  Player(15, 'Ødegaard', 'Arsenal', 'MEI', 12),
  Player(16, 'Valverde', 'Real Madrid', 'MEI', 11),
  Player(17, 'Barella', 'Inter', 'MEI', 10),
  Player(18, 'Haaland', 'Manchester City', 'ATA', 17),
  Player(19, 'Mbappé', 'Real Madrid', 'ATA', 18),
  Player(20, 'Vinícius Jr.', 'Real Madrid', 'ATA', 16),
  Player(21, 'Salah', 'Liverpool', 'ATA', 16),
  Player(22, 'Yamal', 'Barcelona', 'ATA', 15),
  Player(23, 'Kane', 'Bayern', 'ATA', 16),
  Player(24, 'Dembélé', 'PSG', 'ATA', 15),
];

class ChampionsApp extends StatelessWidget {
  const ChampionsApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
      title: 'Cartola Champions',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          brightness: Brightness.dark,
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFB4F34A), brightness: Brightness.dark),
          scaffoldBackgroundColor: const Color(0xFF0B1020),
          cardTheme: CardThemeData(
              color: const Color(0xFF172139),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)))),
      home: const AuthGate());
}

class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int tab = 0, round = 1, captain = -1;
  String formation = '4-3-3', teamName = 'Meu Esquadrão';
  final selected = <int>[];
  final leagues = <Map<String, dynamic>>[];
  final nameController = TextEditingController();
  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> fixtures = [];
  List<Map<String, dynamic>> rankings = [];
  final layouts = {
    '4-3-3': {'GOL': 1, 'DEF': 4, 'MEI': 3, 'ATA': 3},
    '4-4-2': {'GOL': 1, 'DEF': 4, 'MEI': 4, 'ATA': 2},
    '3-5-2': {'GOL': 1, 'DEF': 3, 'MEI': 5, 'ATA': 2}
  };
  @override
  void initState() {
    super.initState();
    _load();
    _loadRemote();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      teamName = p.getString('teamName') ?? teamName;
      formation = p.getString('formation') ?? formation;
      captain = p.getInt('captain') ?? -1;
      selected.addAll((p.getStringList('selected') ?? [])
          .map(int.parse)
          .where((id) => players.any((x) => x.id == id)));
      try {
        leagues.addAll((jsonDecode(p.getString('leagues') ?? '[]') as List)
            .map((e) => Map<String, dynamic>.from(e)));
      } catch (_) {}
    });
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('teamName', teamName);
    await p.setString('formation', formation);
    await p.setInt('captain', captain);
    await p.setStringList('selected', selected.map((x) => '$x').toList());
    await p.setString('leagues', jsonEncode(leagues));
  }

  Future<void> _loadRemote() async {
    try {
      final uid = db.auth.currentUser!.id;
      final team = await db
          .from('fantasy_teams')
          .select()
          .eq('user_id', uid)
          .maybeSingle();
      final memberships = await db
          .from('fantasy_league_members')
          .select('league_id, fantasy_leagues(id,name,invite_code,owner_id)')
          .eq('user_id', uid);
      final matches = await db
          .from('fantasy_fixtures')
          .select()
          .order('kickoff', ascending: true)
          .limit(100);
      if (!mounted) return;
      setState(() {
        if (team != null) {
          teamName = team['name'] as String;
          formation = team['formation'] as String;
          captain = team['captain_id'] as int? ?? -1;
          selected
            ..clear()
            ..addAll((team['player_ids'] as List).cast<int>());
        }
        leagues
          ..clear()
          ..addAll((memberships as List).map((row) {
            final l = Map<String, dynamic>.from(row['fantasy_leagues'] as Map);
            return {
              'id': l['id'],
              'name': l['name'],
              'code': l['invite_code'],
              'owner': l['owner_id'] == uid
            };
          }));
        fixtures = List<Map<String, dynamic>>.from(matches);
      });
    } catch (e) {
      if (mounted) notice('Não foi possível carregar dados online: $e');
    }
  }

  Future<void> saveRemote() async {
    try {
      await db.from('fantasy_teams').upsert({
        'user_id': db.auth.currentUser!.id,
        'name': teamName,
        'formation': formation,
        'player_ids': selected,
        'captain_id': captain < 0 ? null : captain,
        'updated_at': DateTime.now().toUtc().toIso8601String()
      });
      if (mounted) notice('Time salvo na sua conta!');
    } catch (e) {
      if (mounted) notice('Erro ao salvar online: $e');
    }
  }

  Future<void> loadRanking(String leagueId) async {
    try {
      final members = await db
          .from('fantasy_league_members')
          .select('user_id')
          .eq('league_id', leagueId);
      final scores = await db
          .from('fantasy_player_scores')
          .select('round_id,player_id,points');
      final lineups = await db
          .from('fantasy_round_lineups')
          .select('user_id,round_id,player_ids,captain_id');
      final teams = await db.from('fantasy_teams').select('user_id,name');
      final names = {for (final t in teams) t['user_id']: t['name']};
      final points = <String, double>{
        for (final m in members) m['user_id'] as String: 0
      };
      for (final lineup in lineups) {
        final uid = lineup['user_id'] as String;
        if (!points.containsKey(uid)) continue;
        for (final score in scores) {
          if (score['round_id'] != lineup['round_id']) continue;
          final pid = score['player_id'] as int;
          if ((lineup['player_ids'] as List).contains(pid)) {
            final value = (score['points'] as num).toDouble();
            points[uid] =
                points[uid]! + value * (lineup['captain_id'] == pid ? 2 : 1);
          }
        }
      }
      if (!mounted) return;
      showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
                  title: const Text('Classificação da liga'),
                  content: SizedBox(
                      width: 400,
                      child: ListView(
                          shrinkWrap: true,
                          children: (points.entries.toList()
                                ..sort((a, b) => b.value.compareTo(a.value)))
                              .asMap()
                              .entries
                              .map((e) => ListTile(
                                  title: Text(
                                      '${e.key + 1}º ${names[e.value.key] ?? 'Jogador'}'),
                                  trailing: Text('${e.value.value.toStringAsFixed(1)} pts')))
                              .toList())),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Fechar'))
                  ]));
    } catch (e) {
      if (mounted) notice('Erro ao carregar ranking: $e');
    }
  }

  double get spent => players
      .where((p) => selected.contains(p.id))
      .fold(0.0, (s, p) => s + p.price);
  int count(String role) =>
      players.where((p) => selected.contains(p.id) && p.role == role).length;
  void notice(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));
  void toggle(Player p) {
    final max = layouts[formation]![p.role]!;
    setState(() {
      if (selected.contains(p.id)) {
        selected.remove(p.id);
        if (captain == p.id) captain = -1;
      } else if (count(p.role) >= max) {
        notice('Limite de ${p.role} para a formação $formation');
      } else if (spent + p.price > 150) {
        notice('Saldo insuficiente! Orçamento: C\$ 150');
      } else {
        selected.add(p.id);
      }
    });
    _save();
  }

  void changeFormation(String value) {
    setState(() {
      formation = value;
      for (final role in ['ATA', 'MEI', 'DEF', 'GOL']) {
        final ids = players
            .where((p) => selected.contains(p.id) && p.role == role)
            .map((p) => p.id)
            .toList();
        for (final id in ids.skip(layouts[value]![role]!)) {
          selected.remove(id);
          if (captain == id) captain = -1;
        }
      }
    });
    _save();
  }

  Widget section(String title, String subtitle) => Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Text(subtitle, style: const TextStyle(color: Colors.white60))
      ]));
  Widget tile(Player p, {bool market = false}) => Card(
      child: ListTile(
          leading: CircleAvatar(
              backgroundColor: const Color(0xFF273C57),
              child: Text(p.role.substring(0, 1))),
          title:
              Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text('${p.club} • ${p.role}'),
          trailing: market
              ? FilledButton.tonal(
                  onPressed: () => toggle(p),
                  child: Text(selected.contains(p.id)
                      ? 'Vender'
                      : 'C\$ ${p.price.toStringAsFixed(0)}'))
              : IconButton(
                  tooltip: 'Escolher capitão',
                  onPressed: () {
                    setState(() => captain = p.id);
                    _save();
                  },
                  icon: Icon(captain == p.id ? Icons.star : Icons.star_border,
                      color:
                          captain == p.id ? Colors.amber : Colors.white70))));
  Widget squad() {
    return ListView(padding: const EdgeInsets.all(18), children: [
      section('Meu time', 'Monte seu elenco para a Champions League'),
      TextFormField(
          initialValue: teamName,
          decoration: const InputDecoration(
              labelText: 'Nome do time', prefixIcon: Icon(Icons.shield)),
          onFieldSubmitted: (v) {
            setState(
                () => teamName = v.trim().isEmpty ? 'Meu Esquadrão' : v.trim());
            _save();
          }),
      const SizedBox(height: 14),
      Wrap(spacing: 12, runSpacing: 12, children: [
        Chip(label: Text('Saldo: C\$ ${(150 - spent).toStringAsFixed(0)}')),
        Chip(label: Text('Jogadores: ${selected.length}/11')),
        Chip(label: Text('Rodada $round'))
      ]),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
          initialValue: formation,
          decoration: const InputDecoration(labelText: 'Formação tática'),
          items: layouts.keys
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (v) {
            if (v != null) changeFormation(v);
          }),
      const SizedBox(height: 20),
      for (final role in ['GOL', 'DEF', 'MEI', 'ATA']) ...[
        Text('$role  ${count(role)}/${layouts[formation]![role]}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        ...players
            .where((p) => selected.contains(p.id) && p.role == role)
            .map((p) => tile(p)),
        if (count(role) == 0)
          const Padding(
              padding: EdgeInsets.all(12),
              child: Text('Nenhum jogador escalado',
                  style: TextStyle(color: Colors.white54))),
        const SizedBox(height: 15)
      ],
      FilledButton.icon(
          onPressed: () => setState(() => tab = 1),
          icon: const Icon(Icons.add),
          label: const Text('Abrir mercado')),
      const SizedBox(height: 8),
      FilledButton.tonalIcon(
          onPressed: () {
            _save();
            if (selected.length == 11 && captain != -1) {
              saveRemote();
            } else {
              notice(
                  'Complete 11 atletas e escolha um capitão antes de salvar online.');
            }
          },
          icon: const Icon(Icons.save),
          label: const Text('Salvar escalação'))
    ]);
  }

  Widget market() {
    String filter = 'TODOS';
    return StatefulBuilder(
        builder: (context, refresh) => Column(children: [
              Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        section('Mercado de atletas',
                            'Valores e elenco ilustrativos'),
                        Text(
                            'C\$ ${(150 - spent).toStringAsFixed(0)} disponíveis',
                            style: const TextStyle(
                                color: Color(0xFFB4F34A),
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                                children: ['TODOS', 'GOL', 'DEF', 'MEI', 'ATA']
                                    .map((r) => Padding(
                                        padding:
                                            const EdgeInsets.only(right: 8),
                                        child: ChoiceChip(
                                            label: Text(r),
                                            selected: filter == r,
                                            onSelected: (_) =>
                                                refresh(() => filter = r))))
                                    .toList()))
                      ])),
              Expanded(
                  child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      children: players
                          .where((p) => filter == 'TODOS' || p.role == filter)
                          .map((p) => tile(p, market: true))
                          .toList()))
            ]));
  }

  String makeCode() => DateTime.now()
      .microsecondsSinceEpoch
      .toRadixString(36)
      .toUpperCase()
      .substring(0, 6);
  Future<void> createLeague() async {
    final c = TextEditingController();
    final result = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
                title: const Text('Criar liga'),
                content: TextField(
                    controller: c,
                    decoration:
                        const InputDecoration(labelText: 'Nome da liga'),
                    autofocus: true),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancelar')),
                  FilledButton(
                      onPressed: () => Navigator.pop(ctx, c.text.trim()),
                      child: const Text('Criar'))
                ]));
    if (result == null || result.isEmpty) return;
    try {
      await db.from('fantasy_leagues').insert({
        'name': result,
        'invite_code': makeCode(),
        'owner_id': db.auth.currentUser!.id
      });
      await _loadRemote();
    } catch (e) {
      notice('Erro ao criar liga: $e');
    }
  }

  Future<void> joinLeague() async {
    final c = TextEditingController();
    final result = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
                title: const Text('Entrar em liga'),
                content: TextField(
                    controller: c,
                    textCapitalization: TextCapitalization.characters,
                    decoration:
                        const InputDecoration(labelText: 'Código de convite')),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancelar')),
                  FilledButton(
                      onPressed: () =>
                          Navigator.pop(ctx, c.text.trim().toUpperCase()),
                      child: const Text('Entrar'))
                ]));
    if (result == null || result.isEmpty) return;
    try {
      await db.rpc('join_fantasy_league', params: {'p_code': result});
      await _loadRemote();
      notice('Você entrou na liga!');
    } catch (e) {
      notice('Não foi possível entrar: $e');
    }
  }

  Widget leaguePage() => ListView(padding: const EdgeInsets.all(18), children: [
        section('Minhas ligas', 'Crie campeonatos e compartilhe códigos'),
        Row(children: [
          Expanded(
              child: FilledButton.icon(
                  onPressed: createLeague,
                  icon: const Icon(Icons.add),
                  label: const Text('Criar liga'))),
          const SizedBox(width: 8),
          Expanded(
              child: OutlinedButton.icon(
                  onPressed: joinLeague,
                  icon: const Icon(Icons.group_add),
                  label: const Text('Entrar')))
        ]),
        const SizedBox(height: 18),
        if (leagues.isEmpty)
          const Card(
              child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Nenhuma liga ainda. Crie sua primeira liga!'))),
        ...leagues.map((l) => Card(
            child: ListTile(
                leading: const Icon(Icons.emoji_events, color: Colors.amber),
                title: Text('${l['name']}'),
                subtitle: Text('Código: ${l['code']} • Liga online'),
                onTap: () => loadRanking(l['id'] as String),
                trailing: const Icon(Icons.leaderboard))))
      ]);
  Widget rounds() => ListView(padding: const EdgeInsets.all(18), children: [
        section('Rodadas da Champions', 'Partidas importadas para o Supabase'),
        if (fixtures.isEmpty)
          const Card(
              child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                      'Ainda não há jogos importados. Configure a integração de resultados no servidor.'))),
        ...fixtures.map((game) => Card(
            child: ListTile(
                title: Text('${game['home_team']} x ${game['away_team']}'),
                subtitle: Text(
                    'Rodada ${game['round_id'] ?? '?'} • ${game['kickoff'] ?? 'Data pendente'}'),
                trailing: Text(game['home_score'] == null
                    ? 'A jogar'
                    : '${game['home_score']} - ${game['away_score']}')))),
        FilledButton.tonal(
            onPressed: _loadRemote, child: const Text('Atualizar rodadas'))
      ]);
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
          backgroundColor: const Color(0xFF111B30),
          title: const Row(children: [
            Icon(Icons.sports_soccer, color: Color(0xFFB4F34A)),
            SizedBox(width: 10),
            Expanded(
                child: Text('CARTOLA CHAMPIONS',
                    style:
                        TextStyle(fontWeight: FontWeight.w900, fontSize: 18)))
          ]),
          actions: [
            IconButton(
                tooltip: 'Sair',
                onPressed: () => db.auth.signOut(),
                icon: const Icon(Icons.logout))
          ]),
      body: IndexedStack(
          index: tab, children: [squad(), market(), leaguePage(), rounds()]),
      bottomNavigationBar: NavigationBar(
          selectedIndex: tab,
          onDestinationSelected: (i) => setState(() => tab = i),
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.shield_outlined), label: 'Meu time'),
            NavigationDestination(
                icon: Icon(Icons.storefront), label: 'Mercado'),
            NavigationDestination(
                icon: Icon(Icons.emoji_events_outlined), label: 'Ligas'),
            NavigationDestination(
                icon: Icon(Icons.calendar_month), label: 'Rodadas')
          ]));
}
