import 'package:flutter/material.dart';
// flutter_svg not required here; removed to avoid unused import
import 'dart:math' as math;
import 'package:flutter/scheduler.dart';

import '../services/api_service.dart';
import '../services/auth_storage.dart';
import '../widgets/auth_shell.dart';
import 'email_verification_screen.dart';
import 'login_screen.dart';

// Sunset palette (warmer, soft gradient)
class _Sunset {
  static const Color left = Color(0xFFFF8A65); // coral
  static const Color right = Color(0xFFFFC371); // light orange
  static const Color accent = Color(0xFFFF6B97); // warm pink
  static const Color soft = Color(0xFFFFE6D6);
}

class _InterestOption {
  const _InterestOption({required this.id, required this.name});

  final int id;
  final String name;

  factory _InterestOption.fromJson(Map<String, dynamic> json) {
    return _InterestOption(
      id: (json['id'] as num).toInt(),
      name: (json['name'] ?? '').toString().trim(),
    );
  }
}

// Clasa extinsă pentru a gestiona fizica poziționării direct în ecran
class _BubbleNode {
  _BubbleNode({
    required this.option,
    required this.radius,
    required double initialX,
    required double initialY,
  }) : x = initialX,
       y = initialY;

  final _InterestOption option;
  final double radius;
  double x;
  double y;
}

class InterestsSelectionScreen extends StatefulWidget {
  const InterestsSelectionScreen({
    super.key,
    required this.email,
    required this.password,
    required this.verificationRequired,
  });

  final String email;
  final String password;
  final bool verificationRequired;

  @override
  State<InterestsSelectionScreen> createState() =>
      _InterestsSelectionScreenState();
}

class _InterestsSelectionScreenState extends State<InterestsSelectionScreen>
  with SingleTickerProviderStateMixin {

  final _apiService = ApiService();
  final _authStorage = AuthStorage();

  final Set<int> _selectedInterestIds = {};
  List<_InterestOption> _interests = const [];
  List<_BubbleNode> _bubbleNodes = [];

  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _hasTemporarySession = false;
  String? _errorMessage;

  late Ticker _ticker;
  Size? _lastLayoutSize;

  @override
  void initState() {
    super.initState();
    _loadInterests();

    // Ticker-ul rulează fizica la fiecare cadru pentru a așeza bulele lin
    _ticker = createTicker((_) {
      if (_bubbleNodes.isNotEmpty && _lastLayoutSize != null) {
        _applyPhysics(_lastLayoutSize!);
      }
    });
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
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
            .map(_InterestOption.fromJson)
            .where((item) => item.name.isNotEmpty)
            .toList();
        _lastLayoutSize = null; // Forțează re-inițializarea nodurilor
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Inițializează bulele dispersate în centrul ecranului
  void _initBubbleNodes(Size size) {
    // Radial / spiral placement for more aesthetic distribution
    final random = math.Random();
    _bubbleNodes = [];
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final maxRadius = math.min(size.width, size.height) * 0.38;

    for (int i = 0; i < _interests.length; i++) {
      final double angle = (i / math.max(1, _interests.length)) * math.pi * 2 + (random.nextDouble() - 0.5) * 0.25;
      final double spiral = (i / math.max(1, _interests.length)) * 0.75; // 0..0.75

      final double r = 40 + spiral * maxRadius * (0.45 + random.nextDouble() * 0.55);

      final double initialX = centerX + math.cos(angle) * r;
      final double initialY = centerY + math.sin(angle) * r;

      // Slight size variation for visual rhythm
      final double baseSize = 52.0 + (i % 6) * 4.0 + (random.nextDouble() - 0.5) * 6.0;

      _bubbleNodes.add(_BubbleNode(
        option: _interests[i],
        radius: baseSize.abs(),
        initialX: initialX,
        initialY: initialY,
      ));
    }
  }

  // Algoritmul de respingere (Spring / Force-directed layout)
  void _applyPhysics(Size size) {
    bool movements = false;
    final double padding = 16.0;

    // 1. Respingere între bule dacă se suprapun
    for (int i = 0; i < _bubbleNodes.length; i++) {
      for (int j = i + 1; j < _bubbleNodes.length; j++) {
        final b1 = _bubbleNodes[i];
        final b2 = _bubbleNodes[j];

        final double dx = b2.x - b1.x;
        final double dy = b2.y - b1.y;
        final double distance = math.sqrt(dx * dx + dy * dy);
        // Adăugăm 12 pixeli extra spațiu gol (padding) între bule pentru lizibilitate
        final double minDistance = b1.radius + b2.radius + 12.0;

        if (distance < minDistance) {
          final double overlap = minDistance - (distance == 0 ? 1 : distance);
          final double nx = distance == 0 ? 1.0 : dx / distance;
          final double ny = distance == 0 ? 0.0 : dy / distance;

          // Stronger but still smooth repulsion
          final double push = 0.28;
          b1.x -= nx * overlap * push;
          b1.y -= ny * overlap * push;
          b2.x += nx * overlap * push;
          b2.y += ny * overlap * push;
          movements = true;
        }
      }
    }

    // 2. Constrângeri margini ecran (să nu iasă din zona alocată)
    for (var b in _bubbleNodes) {
      if (b.x - b.radius < padding) {
        b.x = b.radius + padding;
        movements = true;
      }
      if (b.x + b.radius > size.width - padding) {
        b.x = size.width - b.radius - padding;
        movements = true;
      }
      if (b.y - b.radius < padding) {
        b.y = b.radius + padding;
        movements = true;
      }
      if (b.y + b.radius > size.height - padding) {
        b.y = size.height - b.radius - padding;
        movements = true;
      }
    }

    // 3. Gentle attraction to center to keep composition cohesive
    final cx = size.width / 2;
    final cy = size.height / 2;
    for (var b in _bubbleNodes) {
      final dx = cx - b.x;
      final dy = cy - b.y;
      b.x += dx * 0.02; // small pull
      b.y += dy * 0.02;
    }

    // Actualizăm interfața doar dacă bulele încă se mișcă spre poziția stabilă
    if (movements) {
      setState(() {});
    }
  }

  Future<void> _persistSelection() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final loginData = await _apiService.login(
        email: widget.email,
        password: widget.password,
      );
      final userId = loginData['user_id'];
      final sessionToken = loginData['session_token'] as String? ?? '';
      await _authStorage.saveSession(
        userId: userId is int ? userId : int.parse(userId.toString()),
        sessionToken: sessionToken,
        email: widget.email,
      );
      _hasTemporarySession = true;

      await _apiService.updateMyInterests(
        interestIds: _selectedInterestIds.toList(),
      );

      if (!mounted) return;
      if (widget.verificationRequired) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => EmailVerificationScreen(email: widget.email),
          ),
          (route) => false,
        );
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (_hasTemporarySession) {
        await _authStorage.clearSession();
        _hasTemporarySession = false;
      }
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Widget _header() {
    return const AuthHeaderText(
      title: 'Alege-ți interesele',
      subtitle:
          'Atinge bulele care te reprezintă. Poți selecta mai multe și poți modifica alegerea ulterior.',
      light: true,
      align: TextAlign.left,
    );
  }

  Widget _selectionSummary() {
    final selectedCount = _selectedInterestIds.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _Sunset.left.withValues(alpha: 0.14),
            _Sunset.right.withValues(alpha: 0.12),
          ],
        ),
        border: Border.all(
          color: _Sunset.accent.withValues(alpha: 0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AuthShell.pulseGradient,
              boxShadow: [
                BoxShadow(
                  color: AuthShell.pulsePurple.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    selectedCount == 0
                      ? 'Alege ce te definește'
                      : '$selectedCount interese selectate',
                  style: TextStyle(
                    decoration: TextDecoration.none,
                    color: AuthShell.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  selectedCount == 0
                      ? 'Apasă pe bule pentru a construi profilul tău.'
                      : 'Poți ajusta selecția înainte să continui.',
                  style: TextStyle(
                    decoration: TextDecoration.none,
                    color: AuthShell.textSecondary,
                    fontSize: 13.5,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: const Color(0xFFFFB5CA).withValues(alpha: 0.8),
              ),
            ),
            child: Text(
              '$selectedCount',
              style: const TextStyle(
                color: AuthShell.pulsePurple,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Desenarea stilizată a bulei (Modernă, semi-transparentă și asortată cu fundalul)
  Widget _buildBubbleWidget(_BubbleNode node) {
    final isSelected = _selectedInterestIds.contains(node.option.id);

    return Positioned(
      left: node.x - node.radius,
      top: node.y - node.radius,
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedInterestIds.remove(node.option.id);
            } else {
              _selectedInterestIds.add(node.option.id);
            }
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          width: node.radius * 2,
          height: node.radius * 2,
          padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
            shape: BoxShape.circle,
            // Culorile de fundal din imaginea ta (Roz-Violet pastelat)
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isSelected
                  ? [
                      _Sunset.left,
                      _Sunset.accent,
                    ]
                  : [
                      _Sunset.soft.withValues(alpha: 0.6),
                      _Sunset.right.withValues(alpha: 0.45),
                    ],
            ),
            border: Border.all(
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.9)
                  : const Color(0xFFD4BFFF).withValues(alpha: 0.6),
              width: isSelected ? 2.5 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? const Color(0xFF9C47FF).withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.03),
                blurRadius: isSelected ? 14 : 6,
                offset: isSelected ? const Offset(0, 6) : const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Text(
              node.option.name,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                decoration: TextDecoration.none,
                color: isSelected ? Colors.white : const Color(0xFF4A3565),
                fontSize: node.radius < 54 ? 12 : 13.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                height: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell.background(
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: FrostedAuthCard(
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_errorMessage != null) ...[
                          Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 8),
                        ],
                        _header(),
                        const SizedBox(height: 20),
                        _selectionSummary(),
                        const SizedBox(height: 16),
                        // Zona interactivă cu bule
                        SizedBox(
                          height: 420,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final size = Size(constraints.maxWidth, constraints.maxHeight);
                              if (_lastLayoutSize != size) {
                                _lastLayoutSize = size;
                                _initBubbleNodes(size);
                              }
                              return Stack(
                                clipBehavior: Clip.none,
                                children: _bubbleNodes.map(_buildBubbleWidget).toList(),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Butonul de continuare
                        ElevatedButton(
                          onPressed: _selectedInterestIds.isEmpty ? null : _persistSelection,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: const Color(0xFF9C47FF), // Mov asortat
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey.shade300,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 2,
                          ),
                          child: _isSubmitting
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text(
                                  'Continuă',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ],
                    ),
                    if (_isLoading)
                      Positioned.fill(
                        child: Container(
                          color: Colors.white.withValues(alpha: 0.6),
                          child: const Center(child: CircularProgressIndicator()),
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
