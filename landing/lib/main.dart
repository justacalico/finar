import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'l10n/generated/landing_localizations.dart';

const _repoUrl = 'https://gitlab.com/openlyst/finar';
const _releasesApi =
    'https://gitlab.com/api/v4/projects/openlyst%2Ffinar/releases?per_page=5&order_by=released_at&sort=desc';
const _appPath = 'app/';

void main() {
  runApp(const LandingApp());
}

enum LandingTheme { system, light, dark, oled }

class LandingState extends ChangeNotifier {
  LandingTheme theme = LandingTheme.system;
  String? locale;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    theme = LandingTheme.values
            .where((t) => t.name == prefs.getString('landing.theme'))
            .firstOrNull ??
        LandingTheme.system;
    locale = prefs.getString('landing.locale');
    notifyListeners();
  }

  Future<void> setTheme(LandingTheme next) async {
    theme = next;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('landing.theme', next.name);
  }

  Future<void> setLocale(String? next) async {
    locale = next;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (next == null) {
      await prefs.remove('landing.locale');
    } else {
      await prefs.setString('landing.locale', next);
    }
  }
}

final landingState = LandingState();

class LandingApp extends StatefulWidget {
  const LandingApp({super.key});

  @override
  State<LandingApp> createState() => _LandingAppState();
}

class _LandingAppState extends State<LandingApp> {
  @override
  void initState() {
    super.initState();
    landingState.load().then((_) => mounted ? setState(() {}) : null);
  }

  Locale? _locale() => switch (landingState.locale) {
        'en_GB' => const Locale('en', 'GB'),
        'zh' => const Locale('zh'),
        'ru' => const Locale('ru'),
        'ga' => const Locale('ga'),
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: landingState,
      builder: (context, _) {
        final accent = const Color(0xFF8B5CF6);
        final light = ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
              seedColor: accent, brightness: Brightness.light),
        );
        final dark = ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
              seedColor: accent, brightness: Brightness.dark),
          scaffoldBackgroundColor: const Color(0xFF0D0F16),
        );
        final oled = dark.copyWith(
          scaffoldBackgroundColor: Colors.black,
          cardColor: const Color(0xFF070708),
        );
        return MaterialApp(
          title: 'Finar',
          debugShowCheckedModeBanner: false,
          theme: light,
          darkTheme: landingState.theme == LandingTheme.oled ? oled : dark,
          themeMode: switch (landingState.theme) {
            LandingTheme.system => ThemeMode.system,
            LandingTheme.light => ThemeMode.light,
            LandingTheme.dark || LandingTheme.oled => ThemeMode.dark,
          },
          locale: _locale(),
          supportedLocales: const [
            Locale('en', 'GB'),
            Locale('en'),
            Locale('zh'),
            Locale('ru'),
            Locale('ga'),
          ],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          home: const LandingPage(),
        );
      },
    );
  }
}

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final wide = MediaQuery.sizeOf(context).width > 860;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    scheme.primary.withValues(alpha: 0.25),
                    scheme.surface,
                  ],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 48),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1080),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                              width: 34,
                              height: 34,
                              child:
                                  SvgPicture.asset('assets/icon.svg')),
                          const SizedBox(width: 10),
                          Text(l10n.appTitle,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                      fontWeight: FontWeight.w800)),
                          const Spacer(),
                          const _ThemePicker(),
                          const SizedBox(width: 8),
                          const _LangPicker(),
                        ],
                      ),
                      SizedBox(height: wide ? 90 : 48),
                      Flex(
                        direction:
                            wide ? Axis.horizontal : Axis.vertical,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: wide ? 5 : 0,
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(l10n.tagline,
                                    style: Theme.of(context)
                                        .textTheme
                                        .displaySmall
                                        ?.copyWith(
                                            fontWeight:
                                                FontWeight.w800,
                                            height: 1.1)),
                                const SizedBox(height: 16),
                                Text(l10n.heroSubtitle,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                            color: scheme
                                                .onSurfaceVariant,
                                            height: 1.5)),
                                const SizedBox(height: 28),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: [
                                    FilledButton.icon(
                                      onPressed: () => launchUrl(
                                          Uri.parse(_appPath)),
                                      icon:
                                          const Icon(Icons.open_in_new),
                                      label: Text(l10n.openWebApp),
                                    ),
                                    OutlinedButton.icon(
                                      onPressed: () => launchUrl(
                                          Uri.parse(
                                              '$_repoUrl/-/releases'),
                                          mode: LaunchMode
                                              .externalApplication),
                                      icon: const Icon(
                                          Icons.download_outlined),
                                      label: Text(l10n.download),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                              width: wide ? 48 : 0,
                              height: wide ? 0 : 32),
                          Expanded(
                            flex: wide ? 4 : 0,
                            child: const _ShowcaseCard(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1080),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Features(l10n: l10n),
                      const SizedBox(height: 40),
                      Text(l10n.screenshots,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 16),
                      const _Screenshots(),
                      const SizedBox(height: 40),
                      Text(l10n.downloads,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 16),
                      const _Downloads(),
                      const SizedBox(height: 48),
                      const _Footer(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemePicker extends StatelessWidget {
  const _ThemePicker();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopupMenuButton<LandingTheme>(
      icon: const Icon(Icons.brightness_6_outlined),
      tooltip: l10n.themeSystem,
      onSelected: landingState.setTheme,
      itemBuilder: (context) => [
        _check(LandingTheme.system, l10n.themeSystem),
        _check(LandingTheme.light, l10n.themeLight),
        _check(LandingTheme.dark, l10n.themeDark),
        _check(LandingTheme.oled, l10n.themeOled),
      ],
    );
  }

  CheckedPopupMenuItem<LandingTheme> _check(
          LandingTheme v, String label) =>
      CheckedPopupMenuItem(
          value: v, checked: landingState.theme == v, child: Text(label));
}

class _LangPicker extends StatelessWidget {
  const _LangPicker();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const langs = <String?, String>{
      null: 'System',
      'en_GB': 'Traditional English',
      'zh': '简体中文',
      'ru': 'Русский',
      'ga': 'Gaeilge',
    };
    return PopupMenuButton<String?>(
      icon: const Icon(Icons.translate),
      tooltip: l10n.language,
      onSelected: landingState.setLocale,
      itemBuilder: (context) => [
        for (final e in langs.entries)
          CheckedPopupMenuItem(
              value: e.key,
              checked: landingState.locale == e.key,
              child: Text(e.value)),
      ],
    );
  }
}

class _ShowcaseCard extends StatelessWidget {
  const _ShowcaseCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF6366F1),
              const Color(0xFF8B5CF6),
              const Color(0xFFA855F7),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.35),
              blurRadius: 48,
              offset: const Offset(0, 24),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              left: 24,
              top: 24,
              right: 24,
              child: _MockBar(),
            ),
            Positioned(
              left: 24,
              top: 84,
              bottom: 24,
              child: Row(
                children: [
                  for (final hue in [260.0, 200.0, 320.0, 30.0])
                    Padding(
                      padding: const EdgeInsets.only(right: 14),
                      child: _PosterCard(hue: hue),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MockBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(width: 10),
        for (final w in [64.0, 48.0, 56.0])
          Container(
            width: w,
            height: 10,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(5),
            ),
          ),
      ],
    );
  }
}

class _PosterCard extends StatelessWidget {
  const _PosterCard({required this.hue});

  final double hue;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AspectRatio(
        aspectRatio: 2 / 3,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                HSLColor.fromAHSL(1, hue, 0.6, 0.5).toColor(),
                HSLColor.fromAHSL(1, hue + 40, 0.7, 0.3).toColor(),
              ],
            ),
          ),
          child: const Center(
            child: Icon(Icons.play_circle_fill,
                color: Colors.white70, size: 34),
          ),
        ),
      ),
    );
  }
}

class _Features extends StatelessWidget {
  const _Features({required this.l10n});

  final dynamic l10n;

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.video_library_outlined, l10n.featureMedia, l10n.featureMediaBody),
      (Icons.play_circle_outline, l10n.featurePlay, l10n.featurePlayBody),
      (Icons.devices_outlined, l10n.featureEverywhere,
          l10n.featureEverywhereBody),
    ];
    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth > 700 ? 3 : 1;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          for (final (icon, title, body) in items)
            SizedBox(
              width: cols == 3
                  ? (c.maxWidth - 32) / 3
                  : c.maxWidth,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(icon,
                          size: 30,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(height: 12),
                      Text(title,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Text(body,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }
}

class _Screenshots extends StatelessWidget {
  const _Screenshots();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final wide = c.maxWidth > 700;
      final shots = [
        'assets/shots/home_desktop.png',
        'assets/shots/detail_movie_desktop.png',
        'assets/shots/library_desktop.png',
      ];
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          for (final shot in shots)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                shot,
                width: wide ? (c.maxWidth - 32) / 3 : c.maxWidth,
                fit: BoxFit.cover,
              ),
            ),
        ],
      );
    });
  }
}

class _Downloads extends StatefulWidget {
  const _Downloads();

  @override
  State<_Downloads> createState() => _DownloadsState();
}

class _DownloadsState extends State<_Downloads> {
  List<dynamic>? _assets;
  String? _tag;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await http
          .get(Uri.parse(_releasesApi))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) throw StateError('bad status');
      final list = jsonDecode(res.body) as List<dynamic>;
      if (list.isEmpty) throw StateError('no releases');
      final latest = list.first as Map<String, dynamic>;
      setState(() {
        _tag = latest['tag_name'] as String?;
        _assets = (latest['assets']?['links'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .toList();
      });
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  static const _order = [
    ('Android', '.apk'),
    ('iOS', '.ipa'),
    ('Windows', 'setup.exe'),
    ('macOS', 'macos'),
    ('Linux AppImage', '.appimage'),
    ('Linux .deb', 'amd64'),
    ('Linux .rpm', '.rpm'),
    ('Linux zip', 'linux-x64'),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    if (_assets == null) {
      return _failed
          ? Row(children: [
              Text(l10n.releasesUnavailable,
                  style: TextStyle(color: scheme.onSurfaceVariant)),
              const SizedBox(width: 12),
              OutlinedButton(
                  onPressed: () => launchUrl(
                      Uri.parse('$_repoUrl/-/releases'),
                      mode: LaunchMode.externalApplication),
                  child: Text(l10n.releasesOnGitLab)),
            ])
          : Row(children: [
              const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2)),
              const SizedBox(width: 10),
              Text(l10n.loadingReleases,
                  style: TextStyle(color: scheme.onSurfaceVariant)),
            ]);
    }
    final links = _assets!
        .map((a) =>
            (name: a['name'] as String? ?? '', url: a['direct_asset_url'] as String? ?? a['url'] as String? ?? ''))
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_tag != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Chip(
              avatar: const Icon(Icons.new_releases_outlined, size: 16),
              label: Text('${l10n.latestVersion}  $_tag'),
            ),
          ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final (label, match) in _order)
              for (final link in links.where(
                  (l) => l.name.toLowerCase().contains(match.toLowerCase())))
                FilledButton.tonalIcon(
                  onPressed: () => launchUrl(Uri.parse(link.url),
                      mode: LaunchMode.externalApplication),
                  icon: const Icon(Icons.download_outlined, size: 18),
                  label: Text(label),
                ),
            OutlinedButton.icon(
              onPressed: () => launchUrl(
                  Uri.parse('$_repoUrl/-/releases'),
                  mode: LaunchMode.externalApplication),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: Text(l10n.releasesOnGitLab),
            ),
          ],
        ),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Text(l10n.builtWith,
            style: TextStyle(color: scheme.onSurfaceVariant)),
        const Spacer(),
        TextButton(
          onPressed: () => launchUrl(Uri.parse(_repoUrl),
              mode: LaunchMode.externalApplication),
          child: Text(l10n.sourceCode),
        ),
      ],
    );
  }
}
