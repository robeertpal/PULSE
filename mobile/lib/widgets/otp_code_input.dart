import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'auth_shell.dart';

class OtpCodeInput extends StatefulWidget {
  const OtpCodeInput({
    super.key,
    required this.onChanged,
    this.length = 6,
    this.errorText,
    this.enabled = true,
    this.autofocus = false,
    this.onSubmitted,
  });

  final int length;
  final ValueChanged<String> onChanged;
  final String? errorText;
  final bool enabled;
  final bool autofocus;
  final ValueChanged<String>? onSubmitted;

  @override
  State<OtpCodeInput> createState() => OtpCodeInputState();
}

class OtpCodeInputState extends State<OtpCodeInput> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  bool get _hasError =>
      widget.errorText != null && widget.errorText!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _focusNodes = List.generate(widget.length, (_) => FocusNode());
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _focusNodes.isNotEmpty) {
          _focusNodes.first.requestFocus();
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant OtpCodeInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.length != widget.length) {
      _emitCode();
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void clear() {
    for (final controller in _controllers) {
      controller.clear();
    }
    _emitCode();
    if (_focusNodes.isNotEmpty) {
      _focusNodes.first.requestFocus();
    }
  }

  String get code => _controllers.map((controller) => controller.text).join();

  void _emitCode() {
    final currentCode = code;
    widget.onChanged(currentCode);
    if (currentCode.length == widget.length) {
      widget.onSubmitted?.call(currentCode);
    }
  }

  void _handleChanged(String value, int index) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      _controllers[index].clear();
      _emitCode();
      return;
    }

    if (digits.length > 1) {
      _applyDigits(
        digits,
        startIndex: digits.length == widget.length ? 0 : index,
      );
      return;
    }

    _controllers[index].value = TextEditingValue(
      text: digits,
      selection: const TextSelection.collapsed(offset: 1),
    );
    if (index < widget.length - 1) {
      _focusNodes[index + 1].requestFocus();
    } else {
      _focusNodes[index].unfocus();
    }
    _emitCode();
  }

  void _applyDigits(String digits, {required int startIndex}) {
    final cleanDigits = digits.replaceAll(RegExp(r'[^0-9]'), '');
    var targetIndex = startIndex;
    for (final digit in cleanDigits.split('')) {
      if (targetIndex >= widget.length) break;
      _controllers[targetIndex].value = TextEditingValue(
        text: digit,
        selection: const TextSelection.collapsed(offset: 1),
      );
      targetIndex += 1;
    }

    if (targetIndex < widget.length) {
      _focusNodes[targetIndex].requestFocus();
    } else {
      _focusNodes.last.unfocus();
    }
    _emitCode();
  }

  void _handleBackspace(int index) {
    if (_controllers[index].text.isNotEmpty) return;
    if (index == 0) return;
    _focusNodes[index - 1].requestFocus();
    _controllers[index - 1].selection = TextSelection.collapsed(
      offset: _controllers[index - 1].text.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = constraints.maxWidth < 360 ? 7.0 : 10.0;
        final availableWidth =
            constraints.maxWidth - (gap * (widget.length - 1));
        final boxSize = (availableWidth / widget.length).clamp(40.0, 54.0);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.length, (index) {
                return Padding(
                  padding: EdgeInsets.only(
                    right: index == widget.length - 1 ? 0 : gap,
                  ),
                  child: _OtpDigitBox(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    enabled: widget.enabled,
                    hasError: _hasError,
                    size: boxSize,
                    autofocus: widget.autofocus && index == 0,
                    onChanged: (value) => _handleChanged(value, index),
                    onBackspace: () => _handleBackspace(index),
                  ),
                );
              }),
            ),
            if (_hasError) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  widget.errorText!,
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontSize: 12,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _OtpDigitBox extends StatelessWidget {
  const _OtpDigitBox({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.hasError,
    required this.size,
    required this.autofocus,
    required this.onChanged,
    required this.onBackspace,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final bool hasError;
  final double size;
  final bool autofocus;
  final ValueChanged<String> onChanged;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.backspace) {
          onBackspace();
        }
        return KeyEventResult.ignored;
      },
      child: AnimatedBuilder(
        animation: focusNode,
        builder: (context, child) {
          final isFocused = focusNode.hasFocus;
          final borderColor = hasError
              ? Colors.red.shade400
              : isFocused
              ? AuthShell.pulsePurple
              : Colors.white.withValues(alpha: 0.14);

          return AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: enabled
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: borderColor,
                width: isFocused || hasError ? 1.6 : 1.1,
              ),
              boxShadow: isFocused
                  ? [
                      BoxShadow(
                        color: AuthShell.pulsePurple.withValues(alpha: 0.24),
                        blurRadius: 18,
                        offset: const Offset(0, 9),
                      ),
                    ]
                  : null,
            ),
            child: child,
          );
        },
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          autofocus: autofocus,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          textAlign: TextAlign.center,
          cursorColor: AuthShell.pulsePurple,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          style: const TextStyle(
            color: AuthShell.textPrimary,
            fontSize: 22,
            height: 1,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
          decoration: const InputDecoration(
            border: InputBorder.none,
            counterText: '',
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
