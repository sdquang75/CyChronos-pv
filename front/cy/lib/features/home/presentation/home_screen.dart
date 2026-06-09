import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../auth/domain/auth_state.dart';
import '../../auth/presentation/providers/auth_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // Scroll Controller for Auto-Scrolling in Home Tab
  final ScrollController _scrollController = ScrollController();

  // Interactive States
  int _selectedDuration = 45; // default 45 mins
  final Set<String> _selectedGenres = {'Cafe'}; // default Cafe selected
  int _currentTab = 0; // 0: HOME, 1: ROUTE, 2: HISTORY, 3: PROFILE
  bool _advancedExpanded = false;

  // Advanced Config state variables (3 sliders)
  double _speedKmh = 18.0;     // Cruising Speed
  double _restMinutes = 15.0;  // Rest Duration
  double _restFreqMin = 30.0;  // Rest Frequency (every X minutes)

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleAdvanced() {
    setState(() {
      _advancedExpanded = !_advancedExpanded;
    });

    if (_advancedExpanded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          final double targetOffset = _scrollController.offset + 230.0;
          _scrollController.animateTo(
            targetOffset,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOutCubic,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isLargeScreen = size.width > 390 || size.height > 1115;

    Widget content = Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Stack(
        children: [
          // Main Dynamic Body based on Selected Tab
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: IndexedStack(
                index: _currentTab,
                children: [
                  _buildHomeTab(),
                  _buildRouteTab(),
                  _buildHistoryTab(),
                  _buildProfileTab(),
                ],
              ),
            ),
          ),

          // Floating CTA (Only visible on Home Tab)
          if (_currentTab == 0)
            Positioned(
              left: 0,
              right: 0,
              bottom: 88.92 + 16,
              child: _buildFloatingCTA(),
            ),

          // Custom Bottom Navigation Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 88.92,
            child: _buildBottomNavBar(),
          ),
        ],
      ),
    );

    if (isLargeScreen) {
      return Scaffold(
        backgroundColor: const Color(0xFF191C1F),
        body: Center(
          child: Container(
            width: 390,
            height: 1115,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: content,
          ),
        ),
      );
    }

    return content;
  }

  // ================= TAB CONTENT BUILDERS =================

  // TAB 0: HOME PLANNER SCREEN
  Widget _buildHomeTab() {
    return SingleChildScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: 180, // Space for floating CTA & Bottom Bar
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroHeader(),
          const SizedBox(height: 36),
          _buildDurationSection(),
          const SizedBox(height: 36),
          _buildGenreSection(),
          const SizedBox(height: 32),
          _buildAdvancedConfigCard(),
        ],
      ),
    );
  }

  // TAB 1: ROUTE SEARCH/EXPLORE SCREEN (MOCKUP)
  Widget _buildRouteTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTabHeader(title: 'ルート探索', subtitle: '最適なサイクリングパス'),
          const SizedBox(height: 24),
          // Suggested Route Cards
          _buildRouteCard(
            title: '海沿いカフェ巡りコース',
            distance: '18.5 km',
            duration: '1時間15分',
            difficulty: '初級',
            tags: ['カフェ', '絶景'],
          ),
          const SizedBox(height: 16),
          _buildRouteCard(
            title: '歴史ある寺院と緑の丘ルート',
            distance: '34.2 km',
            duration: '2時間30分',
            difficulty: '中級',
            tags: ['寺院', '自然', 'ヒルクライム'],
          ),
        ],
      ),
    );
  }

  // TAB 2: HISTORY ACTIVITIES SCREEN (MOCKUP)
  Widget _buildHistoryTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTabHeader(title: 'アクティビティ履歴', subtitle: 'これまでの走行記録'),
          const SizedBox(height: 24),
          // History items
          _buildHistoryItem(
            title: '週末のモーニングライド',
            date: '2026/05/24',
            distance: '22.4 km',
            time: '1:12:05',
            calories: '420 kcal',
          ),
          const SizedBox(height: 16),
          _buildHistoryItem(
            title: '鎌倉寺院巡りサイクリング',
            date: '2026/05/17',
            distance: '15.8 km',
            time: '0:58:30',
            calories: '310 kcal',
          ),
          const SizedBox(height: 16),
          _buildHistoryItem(
            title: '荒川サイクリングロード往復',
            date: '2026/05/10',
            distance: '45.0 km',
            time: '2:15:18',
            calories: '890 kcal',
          ),
        ],
      ),
    );
  }

  // TAB 3: USER PROFILE SCREEN WITH LOGOUT BUTTON
  Widget _buildProfileTab() {
    final authState = ref.watch(authProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTabHeader(title: 'プロフィール', subtitle: 'ユーザーアカウント設定'),
          const SizedBox(height: 32),

          // User Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFC9C4D5).withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2E0094).withValues(alpha: 0.03),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                // Avatar: Google photo or fallback SVG
                CircleAvatar(
                  radius: 48,
                  backgroundColor: const Color(0xFFF1EBFF),
                  backgroundImage: (user?.photoUrl != null)
                      ? NetworkImage(user!.photoUrl!)
                      : null,
                  child: (user?.photoUrl == null)
                      ? SvgPicture.string(
                          _kProfileTabSvg,
                          width: 44,
                          height: 44,
                          colorFilter: const ColorFilter.mode(
                            Color(0xFF19005C),
                            BlendMode.srcIn,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  user?.name.isNotEmpty == true ? user!.name : 'CyChronos ライダー',
                  style: const TextStyle(
                    fontFamily: 'HankenGrotesk',
                    fontFamilyFallback: ['NotoSansJP'],
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                    color: Color(0xFF19005C),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: const Color(0xFF484553).withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Statistics Grid
          const Text(
            'STATISTICS',
            style: TextStyle(
              fontFamily: 'JetBrainsMono',
              fontWeight: FontWeight.w500,
              fontSize: 13,
              letterSpacing: 0.7,
              color: Color(0xFF484553),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  label: '総走行距離',
                  value: '83.2 km',
                  icon: Icons.directions_bike_rounded,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  label: '総走行時間',
                  value: '4.5 hrs',
                  icon: Icons.timer_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),

          // Logout Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => ref.read(authProvider.notifier).signOut(),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEA4335).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFEA4335).withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.logout_rounded,
                      color: Color(0xFFEA4335),
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'ログアウト',
                      style: TextStyle(
                        fontFamily: 'HankenGrotesk',
                        fontFamilyFallback: ['NotoSansJP'],
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Color(0xFFEA4335),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= UI ELEMENT BUILDERS =================

  // Header for Home Screen (Without Logout icon)
  Widget _buildHeroHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CyChronos',
              style: TextStyle(
                fontFamily: 'HankenGrotesk',
                fontFamilyFallback: ['NotoSansJP'],
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF19005C),
                letterSpacing: -0.4,
              ),
            ),
            Text(
              'RIDE PLANNER',
              style: TextStyle(
                fontFamily: 'JetBrainsMono',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF19005C).withValues(alpha: 0.6),
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        const Text(
          '今日はどのくらい走る？',
          style: TextStyle(
            fontFamily: 'HankenGrotesk',
            fontFamilyFallback: ['NotoSansJP'],
            fontWeight: FontWeight.w700,
            fontSize: 28,
            color: Color(0xFF19005C),
            height: 1.29,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          '目標時間を設定して、最適なルートを見つけましょう。',
          style: TextStyle(
            fontFamily: 'Inter',
            fontFamilyFallback: ['NotoSansJP'],
            fontWeight: FontWeight.w400,
            fontSize: 16,
            color: Color(0xFF484553),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // General Header for Sub-Tabs
  Widget _buildTabHeader({required String title, required String subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'HankenGrotesk',
            fontFamilyFallback: ['NotoSansJP'],
            fontWeight: FontWeight.w700,
            fontSize: 28,
            color: Color(0xFF19005C),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontFamilyFallback: ['NotoSansJP'],
            fontWeight: FontWeight.w400,
            fontSize: 14,
            color: Color(0xFF484553),
          ),
        ),
      ],
    );
  }

  // Duration Picker
  Widget _buildDurationSection() {
    final durations = [15, 30, 45, 60, 90, 120, 150, 180];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'DURATION',
          style: TextStyle(
            fontFamily: 'JetBrainsMono',
            fontWeight: FontWeight.w500,
            fontSize: 14,
            letterSpacing: 0.7,
            color: Color(0xFF484553),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 74,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: durations.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final dur = durations[index];
              final isSelected = _selectedDuration == dur;

              return Center(
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 200),
                  tween: Tween(begin: 0.0, end: isSelected ? 1.0 : 0.0),
                  builder: (context, value, child) {
                    final color = Color.lerp(
                      const Color(0xFFFFFFFF).withValues(alpha: 0.8),
                      const Color(0xFF19005C).withValues(alpha: 0.85),
                      value,
                    )!;
                    final textColor = Color.lerp(
                      const Color(0xFF191C1F),
                      const Color(0xFFFFFFFF),
                      value,
                    )!;
                    final borderColor = Color.lerp(
                      const Color(0xFFC9C4D5).withValues(alpha: 0.5),
                      const Color(0xFF19005C).withValues(alpha: 0.8),
                      value,
                    )!;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedDuration = dur;
                        });
                      },
                      child: Container(
                        height: 66,
                        constraints: BoxConstraints(
                          minWidth: dur >= 100 ? 120 : 100,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: borderColor, width: 1.5),
                        ),
                        child: Center(
                          child: Text(
                            dur >= 60 ? '${dur ~/ 60}時間' : '$dur分',
                            style: TextStyle(
                              fontFamily: 'HankenGrotesk',
                              fontFamilyFallback: ['NotoSansJP'],
                              fontWeight: FontWeight.w600,
                              fontSize: 22,
                              color: textColor,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Genre Selector (Expanded list of interests)
  Widget _buildGenreSection() {
    final genres = [
      {'id': 'Cafe', 'label': 'カフェ', 'svg': _kCafeSvg},
      {'id': 'Nature', 'label': '自然', 'svg': _kNatureSvg},
      {'id': 'Food', 'label': 'グルメ', 'svg': _kFoodSvg},
      {'id': 'Temple', 'label': '寺院', 'svg': _kTempleSvg},
      {'id': 'Art', 'label': 'アート', 'svg': _kArtSvg},
      {'id': 'Viewpoint', 'label': '絶景', 'svg': _kViewpointSvg},
      {'id': 'Shop', 'label': 'ショッピング', 'svg': _kShopSvg},
      {'id': 'Landmark', 'label': 'ランドマーク', 'svg': _kLandmarkSvg},
      {'id': 'Hill', 'label': 'ヒルクライム', 'svg': _kHillSvg},
      {'id': 'Park', 'label': '公園', 'svg': _kParkSvg},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'INTEREST',
          style: TextStyle(
            fontFamily: 'JetBrainsMono',
            fontWeight: FontWeight.w500,
            fontSize: 14,
            letterSpacing: 0.7,
            color: Color(0xFF484553),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: genres.map((genre) {
            final id = genre['id'] as String;
            final label = genre['label'] as String;
            final svgStr = genre['svg'] as String;
            final isSelected = _selectedGenres.contains(id);

            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedGenres.remove(id);
                  } else {
                    _selectedGenres.add(id);
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFF1EBFF) : const Color(0xFFF2F3F8),
                  borderRadius: BorderRadius.circular(9999),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF19005C).withValues(alpha: 0.3)
                        : const Color(0xFFC9C4D5),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.string(
                      svgStr,
                      width: 20,
                      height: 20,
                      colorFilter: ColorFilter.mode(
                        isSelected ? const Color(0xFF19005C) : const Color(0xFF484553),
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: TextStyle(
                        fontFamily: 'HankenGrotesk',
                        fontFamilyFallback: ['NotoSansJP'],
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        fontSize: 16,
                        color: isSelected ? const Color(0xFF19005C) : const Color(0xFF484553),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // Advanced Config Card (Expandable with 3 sliders)
  Widget _buildAdvancedConfigCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        border: Border.all(color: Colors.white),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E0094).withValues(alpha: 0.05),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _toggleAdvanced,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          SvgPicture.string(
                            _kSettingsSvg,
                            width: 20,
                            height: 20,
                            colorFilter: const ColorFilter.mode(
                              Color(0xFF19005C),
                              BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            '詳細設定',
                            style: TextStyle(
                              fontFamily: 'HankenGrotesk',
                              fontFamilyFallback: ['NotoSansJP'],
                              fontWeight: FontWeight.w700,
                              fontSize: 24,
                              color: Color(0xFF19005C),
                            ),
                          ),
                        ],
                      ),
                      AnimatedRotation(
                        turns: _advancedExpanded ? 0.25 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFF484553),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '速度・休憩時間の設定',
                    style: TextStyle(
                      fontFamily: 'HankenGrotesk',
                      fontFamilyFallback: ['NotoSansJP'],
                      fontWeight: FontWeight.w400,
                      fontSize: 16,
                      color: Color(0xFF484553),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expanding sliders area
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            clipBehavior: Clip.antiAlias,
            child: !_advancedExpanded
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(left: 24, right: 24, bottom: 32),
                    child: Column(
                      children: [
                        const Divider(height: 1, color: Color(0x33C9C4D5)),
                        const SizedBox(height: 24),

                        // Slider 1: 巡航速度 (Cruising Speed)
                        _buildSliderRow(
                          label: '巡航速度',
                          valueText: '${_speedKmh.toStringAsFixed(1)} km/h',
                          value: _speedKmh,
                          min: 10.0,
                          max: 30.0,
                          divisions: 20,
                          onChanged: (val) {
                            setState(() {
                              _speedKmh = val;
                            });
                          },
                        ),
                        const SizedBox(height: 24),

                        // Slider 2: 休憩時間 (Rest Duration)
                        _buildSliderRow(
                          label: '休憩時間',
                          valueText: '${_restMinutes.toInt()} 分',
                          value: _restMinutes,
                          min: 5.0,
                          max: 45.0,
                          divisions: 8,
                          onChanged: (val) {
                            setState(() {
                              _restMinutes = val;
                            });
                          },
                        ),
                        const SizedBox(height: 24),

                        // Slider 3: 休憩頻度 (Rest Frequency)
                        _buildSliderRow(
                          label: '休憩頻度',
                          valueText: '毎 ${_restFreqMin.toInt()} 分',
                          value: _restFreqMin,
                          min: 15.0,
                          max: 120.0,
                          divisions: 7,
                          onChanged: (val) {
                            setState(() {
                              _restFreqMin = val;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderRow({
    required String label,
    required String valueText,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'HankenGrotesk',
                fontFamilyFallback: ['NotoSansJP'],
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Color(0xFF191C1F),
              ),
            ),
            Text(
              valueText,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: Color(0xFF19005C),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFF2A0088),
            inactiveTrackColor: const Color(0xFFE7E8ED),
            thumbColor: const Color(0xFF19005C),
            overlayColor: const Color(0xFF2A0088).withValues(alpha: 0.1),
            trackHeight: 6,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  // Floating CTA Button
  Widget _buildFloatingCTA() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).clearSnackBars();
            final genreText = _selectedGenres.isEmpty ? 'おまかせ' : _selectedGenres.join(", ");
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _selectedDuration >= 60 
                      ? '${_selectedDuration ~/ 60}時間、$genreTextの最適ルートを検索しています...'
                      : '$_selectedDuration分、$genreTextの最適ルートを検索しています...',
                  style: const TextStyle(
                    fontFamily: 'HankenGrotesk',
                    fontFamilyFallback: ['NotoSansJP'],
                  ),
                ),
                backgroundColor: const Color(0xFF2A0088),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          },
          borderRadius: BorderRadius.circular(9999),
          child: Container(
            height: 64,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF19005C),
              borderRadius: BorderRadius.circular(9999),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF19005C).withValues(alpha: 0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'ルートを検索',
                  style: TextStyle(
                    fontFamily: 'HankenGrotesk',
                    fontFamilyFallback: ['NotoSansJP'],
                    fontWeight: FontWeight.w600,
                    fontSize: 22,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                SvgPicture.string(
                  _kArrowRightSvg,
                  width: 20,
                  height: 20,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Custom Bottom Navigation Bar
  Widget _buildBottomNavBar() {
    final tabs = [
      {'label': 'HOME', 'svg': _kHomeTabSvg},
      {'label': 'ROUTE', 'svg': _kRouteTabSvg},
      {'label': 'HISTORY', 'svg': _kHistoryTabSvg},
      {'label': 'PROFILE', 'svg': _kProfileTabSvg},
    ];

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FE).withValues(alpha: 0.8),
            border: Border(
              top: BorderSide(
                color: const Color(0xFFC9C4D5).withValues(alpha: 0.3),
                width: 1,
              ),
            ),
          ),
          padding: const EdgeInsets.only(top: 12, bottom: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(tabs.length, (index) {
              final tab = tabs[index];
              final isSelected = _currentTab == index;
              final color = isSelected ? const Color(0xFF19005C) : const Color(0xFF484553);

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  setState(() {
                    _currentTab = index;
                  });
                },
                child: SizedBox(
                  width: 70,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        height: 24,
                        width: 28,
                        child: SvgPicture.string(
                          tab['svg']!,
                          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tab['label']!,
                        style: TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 11,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  // MOCKUP SUB-WIDGETS FOR TABS

  Widget _buildRouteCard({
    required String title,
    required String distance,
    required String duration,
    required String difficulty,
    required List<String> tags,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFC9C4D5).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'HankenGrotesk',
              fontFamilyFallback: ['NotoSansJP'],
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: Color(0xFF19005C),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildRouteStat(Icons.directions_bike_rounded, distance),
              const SizedBox(width: 16),
              _buildRouteStat(Icons.timer_rounded, duration),
              const SizedBox(width: 16),
              _buildRouteStat(Icons.trending_up_rounded, difficulty),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: tags.map((t) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1EBFF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  t,
                  style: const TextStyle(
                    fontFamily: 'HankenGrotesk',
                    fontFamilyFallback: ['NotoSansJP'],
                    fontSize: 12,
                    color: Color(0xFF19005C),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteStat(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF484553)),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontFamilyFallback: ['NotoSansJP'],
            fontSize: 13,
            color: Color(0xFF484553),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryItem({
    required String title,
    required String date,
    required String distance,
    required String time,
    required String calories,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFC9C4D5).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'HankenGrotesk',
                  fontFamilyFallback: ['NotoSansJP'],
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Color(0xFF19005C),
                ),
              ),
              Text(
                date,
                style: TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 12,
                  color: const Color(0xFF484553).withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildHistoryStat('距離', distance),
              _buildHistoryStat('時間', time),
              _buildHistoryStat('消費カロリー', calories),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'HankenGrotesk',
            fontFamilyFallback: ['NotoSansJP'],
            fontSize: 12,
            color: const Color(0xFF484553).withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'JetBrainsMono',
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: Color(0xFF191C1F),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({required String label, required String value, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFC9C4D5).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF2A0088), size: 24),
          const SizedBox(height: 16),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'HankenGrotesk',
              fontFamilyFallback: ['NotoSansJP'],
              fontSize: 12,
              color: const Color(0xFF484553).withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'JetBrainsMono',
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: Color(0xFF19005C),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom SVGs (Inline)
const _kCafeSvg = '''<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M18.5 7.5H19.5C20.6 7.5 21.5 8.4 21.5 9.5V11.5C21.5 12.6 20.6 13.5 19.5 13.5H18.5V7.5ZM18.5 15.5V17.5C18.5 18.6 17.6 19.5 16.5 19.5H5.5C4.4 19.5 3.5 18.6 3.5 17.5V7.5C3.5 6.4 4.4 5.5 5.5 5.5H16.5C17.6 5.5 18.5 6.4 18.5 7.5V15.5Z" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M7.5 2.5V4.5" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M11.5 2.5V4.5" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M15.5 2.5V4.5" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
</svg>''';

const _kNatureSvg = '''<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M12 2L2 22H22L12 2Z" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M12 8L7 17H17L12 8Z" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M12 14V22" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
</svg>''';

const _kFoodSvg = '''<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M12 2C6.48 2 2 6.48 2 12C2 17.52 6.48 22 12 22C17.52 22 22 17.52 22 12C22 6.48 17.52 2 12 2ZM12 18.5C8.41 18.5 5.5 15.59 5.5 12C5.5 8.41 8.41 5.5 12 5.5C15.59 5.5 18.5 8.41 18.5 12C18.5 15.59 15.59 18.5 12 18.5Z" stroke="currentColor" stroke-width="2"/>
  <path d="M9 12H15" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
</svg>''';

const _kTempleSvg = '''<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M2 19.5H22" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
  <path d="M4 19.5V11.5H20V19.5" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M1 9.5L12 3.5L23 9.5" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M8 19.5V14.5H16V19.5" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
</svg>''';

const _kArtSvg = '''<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M12 22C17.5228 22 22 17.5228 22 12C22 6.47715 17.5228 2 12 2C6.47715 2 2 6.47715 2 12C2 14.7255 3.09032 17.1962 4.85857 19C5.03457 19.176 5.28143 19.243 5.51857 19.18C6.39857 18.94 7.62571 18.5 8.5 18.5C9.5 18.5 10.5 19.5 10.5 20.5C10.5 21.3743 11.06 21.84 12 22Z" stroke="currentColor" stroke-width="2" stroke-linejoin="round"/>
  <circle cx="7.5" cy="10.5" r="1.5" fill="currentColor"/>
  <circle cx="11.5" cy="7.5" r="1.5" fill="currentColor"/>
  <circle cx="16.5" cy="9.5" r="1.5" fill="currentColor"/>
  <circle cx="15.5" cy="14.5" r="1.5" fill="currentColor"/>
</svg>''';

const _kViewpointSvg = '''<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
  <circle cx="12" cy="12" r="3" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
</svg>''';

const _kShopSvg = '''<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M6 2L3 6v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V6l-3-4H6z" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
  <line x1="3" y1="6" x2="21" y2="6" stroke="currentColor" stroke-width="2"/>
  <path d="M16 10a4 4 0 0 1-8 0" stroke="currentColor" stroke-width="2"/>
</svg>''';

const _kLandmarkSvg = '''<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M12 2L15.09 8.26L22 9.27L17 14.14L18.18 21.02L12 17.77L5.82 21.02L7 14.14L2 9.27L8.91 8.26L12 2Z" stroke="currentColor" stroke-width="2" stroke-linejoin="round"/>
</svg>''';

const _kHillSvg = '''<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M4 22L12 8L16 15L20 10L23 15" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M2 22H22" stroke="currentColor" stroke-width="2"/>
</svg>''';

const _kParkSvg = '''<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M12 2a5 5 0 0 0-5 5c0 4 5 9 5 9s5-5 5-5a5 5 0 0 0-5-5z" stroke="currentColor" stroke-width="2"/>
  <path d="M3 22h18" stroke="currentColor" stroke-width="2"/>
  <path d="M12 16v6" stroke="currentColor" stroke-width="2"/>
</svg>''';

const _kSettingsSvg = '''<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <circle cx="12" cy="12" r="3" stroke="currentColor" stroke-width="2"/>
  <path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 1 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 1 1-2.83-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 1 1 2.83-2.83l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 1 1 2.83 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z" stroke="currentColor" stroke-width="2" stroke-linejoin="round"/>
</svg>''';

const _kArrowRightSvg = '''<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M5 12H19" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M12 5L19 12L12 5.5" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M19 12L12 19" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
</svg>''';

const _kHomeTabSvg = '''<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2Z" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M9 22V12h6v10" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
</svg>''';

const _kRouteTabSvg = '''<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M9 20L3 17V4L9 7L15 4L21 7V20L15 17L9 20Z" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M9 7V20" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M15 4V17" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
</svg>''';

const _kHistoryTabSvg = '''<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <circle cx="12" cy="12" r="10" stroke="currentColor" stroke-width="2"/>
  <path d="M12 6V12L16 14" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
</svg>''';

const _kProfileTabSvg = '''<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
  <circle cx="12" cy="7" r="4" stroke="currentColor" stroke-width="2"/>
</svg>''';
