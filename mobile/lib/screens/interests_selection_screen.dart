import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../services/api_service.dart';
import '../services/auth_storage.dart';
import '../widgets/auth_shell.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class InterestOption {
  const InterestOption({required this.id, required this.name});

  final int id;
  final String name;

  factory InterestOption.fromJson(Map<String, dynamic> json) {
    return InterestOption(
      id: (json['id'] as num).toInt(),
      name: (json['name'] ?? '').toString().trim(),
    );
  }
}

class _BubbleLayoutItem {
  _BubbleLayoutItem({
    required this.interest,
    required this.baseRadius,
    required this.x,
    required this.y,
    required this.anchorX,
    required this.anchorY,
    required this.phase,
  });

  final InterestOption interest;
  final double baseRadius;
  final double anchorX;
  final double anchorY;
  final double phase;
  double x;
  double y;
  double vx = 0;
  double vy = 0;
  double selectionProgress = 0;
}

class InterestsSelectionScreen extends StatefulWidget {
  const InterestsSelectionScreen({
    super.key,
    required this.email,
    this.password,
  });

  final String email;
  final String? password;

  @override
  State<InterestsSelectionScreen> createState() =>
      _InterestsSelectionScreenState();
}

class _InterestsSelectionScreenState extends State<InterestsSelectionScreen>
    with SingleTickerProviderStateMixin {
  final _apiService = ApiService();
  final _authStorage = AuthStorage();
  final _bubbleScrollController = ScrollController();
  final Set<int> _selectedInterestIds = {};

  List<InterestOption> _interests = const [];
  List<_BubbleLayoutItem> _bubbleItems = [];
  Ticker? _bubbleTicker;
  Duration _lastBubbleTick = Duration.zero;
  double _lastCanvasWidth = 0;
  double _lastCanvasHeight = 0;
  bool _shouldCenterBubbleScroll = false;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadInterests();
    _bubbleTicker = createTicker(_tickBubblePhysics)..start();
  }

  @override
  void dispose() {
    _bubbleTicker?.dispose();
    _bubbleScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInterests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await _apiService.getInterests();
      if (!mounted) return;
      setState(() {
        _interests = items
            .map(InterestOption.fromJson)
            .where((item) => item.name.isNotEmpty)
            .toList();
        _bubbleItems = [];
        _shouldCenterBubbleScroll = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = pulseDisplayErrorMessage(e);
      });
      await showPulseErrorDialog(context, e);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _goToLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _persistSelection() async {
    if (_selectedInterestIds.isEmpty) {
      setState(() {
        _errorMessage = 'Selectează cel puțin un interes sau sari peste pas.';
      });
      return;
    }

    final password = widget.password;
    if (password == null || password.isEmpty) {
      setState(() {
        _errorMessage =
            'Pentru a salva interesele, autentifică-te după confirmarea emailului.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final loginData = await _apiService.login(
        email: widget.email,
        password: password,
      );
      final userId = loginData['user_id'];
      final sessionToken = loginData['session_token'] as String? ?? '';
      await _authStorage.saveSession(
        userId: userId is int ? userId : int.parse(userId.toString()),
        sessionToken: sessionToken,
        email: widget.email,
      );

      await _apiService.updateMyInterests(
        interestIds: _selectedInterestIds.toList(),
      );

      try {
        final profileData = await _apiService.getMyProfile();
        final name = profileData['display_name'] as String?;
        if (name != null && name.trim().isNotEmpty) {
          await _authStorage.saveUserName(name.trim());
        }
      } catch (e) {
        debugPrint('Failed to pre-fetch profile name after onboarding: $e');
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Interesele au fost salvate.')),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const HomeScreen(showOnboardingWelcome: true),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = pulseDisplayErrorMessage(e);
      });
      await showPulseErrorDialog(context, e);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Widget _summaryPill() {
    final selectedCount = _selectedInterestIds.length;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Text(
          selectedCount == 1
              ? '1 interes selectat'
              : '$selectedCount interese selectate',
          style: const TextStyle(
            color: AuthShell.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  void _ensureBubbleLayout(double viewportWidth) {
    final canvasWidth = _bubbleCanvasWidth(viewportWidth);
    final canvasHeight = _bubbleFieldHeight(viewportWidth);
    final sidePadding = _bubbleSidePadding(viewportWidth);
    final clusterWidth = canvasWidth - sidePadding * 2;
    if (_bubbleItems.length == _interests.length &&
        (canvasWidth - _lastCanvasWidth).abs() < 1 &&
        (canvasHeight - _lastCanvasHeight).abs() < 1) {
      return;
    }

    final baseSize = viewportWidth < 380
        ? 76.0
        : viewportWidth < 520
        ? 86.0
        : 96.0;
    const sizeFactors = [1.08, 0.92, 1.17, 0.86, 1.0, 1.11, 0.95, 1.04];
    const goldenAngle = 2.399963229728653;
    final clusterHeight = math.max(160.0, canvasHeight - 132);
    final centerX = canvasWidth / 2;
    final centerY = canvasHeight / 2 + 4;

    final previousById = {
      for (final item in _bubbleItems) item.interest.id: item,
    };
    _lastCanvasWidth = canvasWidth;
    _lastCanvasHeight = canvasHeight;
    _bubbleItems = [
      for (var i = 0; i < _interests.length; i++)
        () {
          final interest = _interests[i];
          final radius = baseSize * sizeFactors[i % sizeFactors.length] / 2;
          final spread = math.sqrt((i + 0.55) / math.max(1, _interests.length));
          final angle =
              i * goldenAngle + _stableUnit(interest.id * 17 + 3) * 1.2;
          final jitterX =
              (_stableUnit(interest.id * 31 + 7) - 0.5) * baseSize * 0.74;
          final jitterY =
              (_stableUnit(interest.id * 43 + 11) - 0.5) * baseSize * 0.8;
          final anchorX =
              (centerX +
                      math.cos(angle) * clusterWidth * 0.43 * spread +
                      jitterX)
                  .clamp(
                    sidePadding + radius,
                    canvasWidth - sidePadding - radius,
                  );
          final anchorY =
              (centerY +
                      math.sin(angle) * clusterHeight * 0.43 * spread +
                      jitterY)
                  .clamp(radius + 12, canvasHeight - radius - 12);
          final previous = previousById[interest.id];
          return _BubbleLayoutItem(
            interest: interest,
            baseRadius: radius,
            x: previous?.x ?? anchorX,
            y: previous?.y ?? anchorY,
            anchorX: anchorX,
            anchorY: anchorY,
            phase: i * 0.73,
          );
        }(),
    ];
    _relaxBubbleCollisions(iterations: 28, correction: 0.88);
    _shouldCenterBubbleScroll = true;
  }

  double _stableUnit(int seed) {
    final value = math.sin(seed * 12.9898) * 43758.5453123;
    return value - value.floorToDouble();
  }

  double _bubbleSidePadding(double viewportWidth) {
    return viewportWidth < 380 ? 72.0 : 96.0;
  }

  double _bubbleCanvasWidth(double viewportWidth) {
    final sidePadding = _bubbleSidePadding(viewportWidth);
    final clusterWidth = math.max(viewportWidth * 1.22, viewportWidth + 170);
    return clusterWidth + sidePadding * 2;
  }

  double _bubbleFieldHeight(double viewportWidth) {
    if (_interests.isEmpty) return 120;
    final baseSize = viewportWidth < 380
        ? 76.0
        : viewportWidth < 520
        ? 86.0
        : 96.0;
    final approximateRows = math.max(3, (_interests.length / 5.2).ceil());
    return 132 + approximateRows * baseSize * 0.72;
  }

  void _tickBubblePhysics(Duration elapsed) {
    if (_bubbleItems.isEmpty) return;
    if (_lastBubbleTick != Duration.zero &&
        elapsed - _lastBubbleTick < const Duration(milliseconds: 32)) {
      return;
    }
    final deltaSeconds = _lastBubbleTick == Duration.zero
        ? 1 / 30
        : (elapsed - _lastBubbleTick).inMilliseconds / 1000.0;
    _lastBubbleTick = elapsed;

    final seconds = elapsed.inMilliseconds / 1000.0;
    const padding = 8.0;

    for (final item in _bubbleItems) {
      final selected = _selectedInterestIds.contains(item.interest.id);
      final targetSelection = selected ? 1.0 : 0.0;
      final selectionStep = (deltaSeconds * 3.2).clamp(0.0, 0.16);
      item.selectionProgress +=
          (targetSelection - item.selectionProgress) * selectionStep;

      final anchorPull = selected ? 0.008 : 0.011;
      final driftX = math.sin(seconds * 0.36 + item.phase) * 10;
      final driftY = math.cos(seconds * 0.32 + item.phase) * 7;
      item.vx += (item.anchorX + driftX - item.x) * anchorPull;
      item.vy += (item.anchorY + driftY - item.y) * anchorPull;
    }

    for (var i = 0; i < _bubbleItems.length; i++) {
      for (var j = i + 1; j < _bubbleItems.length; j++) {
        final a = _bubbleItems[i];
        final b = _bubbleItems[j];
        final aRadius = _effectiveBubbleRadius(a);
        final bRadius = _effectiveBubbleRadius(b);
        final dx = b.x - a.x;
        final dy = b.y - a.y;
        final distance = math.sqrt(dx * dx + dy * dy).clamp(1.0, 10000.0);
        final minDistance = aRadius + bRadius + _bubbleGap(a, b);
        if (distance < minDistance) {
          final overlap = minDistance - distance;
          final nx = dx / distance;
          final ny = dy / distance;
          final push = overlap * 0.015;
          a.vx -= nx * push;
          a.vy -= ny * push;
          b.vx += nx * push;
          b.vy += ny * push;
        }
      }
    }

    for (final item in _bubbleItems) {
      final radius = _effectiveBubbleRadius(item);
      item.vx *= 0.9;
      item.vy *= 0.9;
      final nextDx = item.vx.clamp(-2.2, 2.2);
      final nextDy = item.vy.clamp(-2.2, 2.2);
      item.x += nextDx;
      item.y += nextDy;
      item.x = item.x.clamp(radius + 4, _lastCanvasWidth - radius - 4);
      item.y = item.y.clamp(
        radius + padding,
        _lastCanvasHeight - radius - padding,
      );
    }
    _relaxBubbleCollisions(
      iterations: 2,
      correction: 0.22,
      maxPushPerPair: 1.15,
    );

    if (mounted) setState(() {});
  }

  double _effectiveBubbleRadius(_BubbleLayoutItem item) {
    return item.baseRadius * (1 + item.selectionProgress * 0.15);
  }

  double _bubbleGap(_BubbleLayoutItem a, _BubbleLayoutItem b) {
    final selected =
        _selectedInterestIds.contains(a.interest.id) ||
        _selectedInterestIds.contains(b.interest.id);
    return selected ? 11.0 : 6.0;
  }

  void _relaxBubbleCollisions({
    required int iterations,
    required double correction,
    double? maxPushPerPair,
  }) {
    if (_bubbleItems.length < 2) return;
    for (var pass = 0; pass < iterations; pass++) {
      for (var i = 0; i < _bubbleItems.length; i++) {
        for (var j = i + 1; j < _bubbleItems.length; j++) {
          final a = _bubbleItems[i];
          final b = _bubbleItems[j];
          final dx = b.x - a.x;
          final dy = b.y - a.y;
          final distance = math.sqrt(dx * dx + dy * dy);
          final safeDistance = distance < 0.001 ? 0.001 : distance;
          final minDistance =
              _effectiveBubbleRadius(a) +
              _effectiveBubbleRadius(b) +
              _bubbleGap(a, b);
          if (safeDistance >= minDistance) continue;

          final angle = safeDistance < 0.01
              ? a.phase + pass
              : math.atan2(dy, dx);
          final nx = math.cos(angle);
          final ny = math.sin(angle);
          var push = (minDistance - safeDistance) * 0.5 * correction;
          if (maxPushPerPair != null) {
            push = push.clamp(0.0, maxPushPerPair);
          }
          a.x -= nx * push;
          a.y -= ny * push;
          b.x += nx * push;
          b.y += ny * push;
        }
      }
      _clampBubblesToCanvas();
    }
  }

  void _clampBubblesToCanvas() {
    if (_lastCanvasWidth <= 0 || _lastCanvasHeight <= 0) return;
    for (final item in _bubbleItems) {
      final radius = _effectiveBubbleRadius(item);
      item.x = item.x.clamp(radius + 4, _lastCanvasWidth - radius - 4);
      item.y = item.y.clamp(radius + 8, _lastCanvasHeight - radius - 8);
    }
  }

  void _centerBubbleScroll(double viewportWidth, double canvasWidth) {
    if (!_shouldCenterBubbleScroll || !_bubbleScrollController.hasClients) {
      return;
    }
    final maxScrollExtent = _bubbleScrollController.position.maxScrollExtent;
    final centeredOffset = ((canvasWidth - viewportWidth) / 2).clamp(
      0.0,
      maxScrollExtent,
    );
    _bubbleScrollController.jumpTo(centeredOffset);
    _shouldCenterBubbleScroll = false;
  }

  Widget _buildInterestBubble(_BubbleLayoutItem item, int index) {
    final interest = item.interest;
    final isSelected = _selectedInterestIds.contains(interest.id);
    final size = item.baseRadius * 2;
    return Positioned(
      left: item.x - item.baseRadius,
      top: item.y - item.baseRadius,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 260 + (index % 8) * 45),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.scale(scale: 0.9 + value * 0.1, child: child),
          );
        },
        child: GestureDetector(
          onTap: _isSubmitting
              ? null
              : () {
                  setState(() {
                    if (isSelected) {
                      _selectedInterestIds.remove(interest.id);
                    } else {
                      _selectedInterestIds.add(interest.id);
                    }
                    _errorMessage = null;
                  });
                },
          child: Transform.scale(
            scale: 1 + item.selectionProgress * 0.12,
            child: Builder(
              builder: (context) {
                final selectedProgress = item.selectionProgress;
                final unselectedBorder = index.isEven
                    ? AuthShell.pulsePurple.withValues(alpha: 0.26)
                    : AuthShell.pulseOrange.withValues(alpha: 0.2);
                final fill = Colors.white.withValues(alpha: 0.075);
                final gradientStart = Color.lerp(
                  fill,
                  AuthShell.deepPurple,
                  selectedProgress,
                )!;
                final gradientMiddle = Color.lerp(
                  fill,
                  AuthShell.pulsePurple,
                  selectedProgress,
                )!;
                final gradientEnd = Color.lerp(
                  fill,
                  AuthShell.pulseOrange,
                  selectedProgress,
                )!;
                final textColor = Color.lerp(
                  AuthShell.textPrimary,
                  Colors.white,
                  selectedProgress,
                )!;
                final borderColor = Color.lerp(
                  unselectedBorder,
                  Colors.white.withValues(alpha: 0.58),
                  selectedProgress,
                )!;

                return Container(
                  width: size,
                  height: size,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [gradientStart, gradientMiddle, gradientEnd],
                    ),
                    border: Border.all(
                      color: borderColor,
                      width: 1 + selectedProgress * 0.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.22),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                        spreadRadius: -8,
                      ),
                      BoxShadow(
                        color: AuthShell.pulsePurple.withValues(
                          alpha: 0.26 * selectedProgress,
                        ),
                        blurRadius: 14 + selectedProgress * 10,
                        offset: const Offset(0, 10),
                        spreadRadius: -5,
                      ),
                      BoxShadow(
                        color: AuthShell.pulseOrange.withValues(
                          alpha: 0.2 * selectedProgress,
                        ),
                        blurRadius: 12 + selectedProgress * 10,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      interest.name,
                      textAlign: TextAlign.center,
                      maxLines: size < 78 ? 2 : 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textColor,
                        fontSize: size < 82 ? 11.5 : 12.8,
                        fontWeight: FontWeight.lerp(
                          FontWeight.w800,
                          FontWeight.w900,
                          selectedProgress,
                        ),
                        height: 1.12,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _interestsContent() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 42),
        child: Center(
          child: CircularProgressIndicator(color: AuthShell.pulseOrange),
        ),
      );
    }

    if (_interests.isEmpty && _errorMessage == null) {
      return const AuthErrorBox(
        message: 'Nu există interese disponibile momentan.',
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportWidth = constraints.maxWidth;
        _ensureBubbleLayout(viewportWidth);
        final canvasWidth = _bubbleCanvasWidth(viewportWidth);
        final canvasHeight = _bubbleFieldHeight(viewportWidth);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _centerBubbleScroll(viewportWidth, canvasWidth);
        });
        return SizedBox(
          height: canvasHeight,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragUpdate: (details) {
              if (!_bubbleScrollController.hasClients) return;
              final nextOffset =
                  _bubbleScrollController.offset - details.delta.dx;
              _bubbleScrollController.jumpTo(
                nextOffset.clamp(
                  0.0,
                  _bubbleScrollController.position.maxScrollExtent,
                ),
              );
            },
            child: SingleChildScrollView(
              controller: _bubbleScrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: SizedBox(
                width: canvasWidth,
                height: canvasHeight,
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    for (var i = 0; i < _bubbleItems.length; i++)
                      _buildInterestBubble(_bubbleItems[i], i),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthAnimatedGradientBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const AuthHeaderText(
                      title: 'Alege-ți interesele',
                      subtitle:
                          'Selectează domeniile care te interesează. Vom personaliza conținutul pentru tine.',
                      light: true,
                      align: TextAlign.left,
                    ),
                    const SizedBox(height: 22),
                    FrostedAuthCard(
                      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_errorMessage != null) ...[
                            AuthErrorBox(message: _errorMessage!),
                            const SizedBox(height: 16),
                          ],
                          _summaryPill(),
                          const SizedBox(height: 20),
                          _interestsContent(),
                          const SizedBox(height: 26),
                          AuthPrimaryButton(
                            label: 'Continuă',
                            isLoading: _isSubmitting,
                            onPressed: _isSubmitting ? null : _persistSelection,
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: _isSubmitting ? null : _goToLogin,
                            child: const Text(
                              'Sari peste momentan',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
