import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';

class PinDots extends StatelessWidget {
  const PinDots({required this.filled, this.onDark = false, super.key});

  final int filled;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final active = onDark ? Colors.white : scheme.onSurface;
    final border = onDark ? Colors.white38 : scheme.outlineVariant;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(AppConfig.pinLength, (index) {
        final isFilled = index < filled;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 7),
          height: 44,
          width: 34,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isFilled ? active : border),
          ),
          alignment: Alignment.center,
          child: isFilled
              ? Container(
                  height: 10,
                  width: 10,
                  decoration: BoxDecoration(color: active, shape: BoxShape.circle),
                )
              : null,
        );
      }),
    );
  }
}

class PinKeypad extends StatelessWidget {
  const PinKeypad({
    required this.onDigit,
    required this.onBackspace,
    this.enabled = true,
    this.onDark = false,
    super.key,
  });

  final ValueChanged<int> onDigit;
  final VoidCallback onBackspace;
  final bool enabled;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final row in const [
          [1, 2, 3],
          [4, 5, 6],
          [7, 8, 9],
        ])
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [for (final digit in row) _key(context, digit: digit)],
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const Expanded(child: SizedBox(height: 66)),
            _key(context, digit: 0),
            Expanded(
              child: _Tappable(
                enabled: enabled,
                onTap: onBackspace,
                child: Icon(
                  Icons.backspace_outlined,
                  size: 22,
                  color: onDark ? Colors.white : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _key(BuildContext context, {required int digit}) {
    final color = onDark ? Colors.white : Theme.of(context).colorScheme.onSurface;

    return Expanded(
      child: _Tappable(
        enabled: enabled,
        onTap: () => onDigit(digit),
        child: Text(
          '$digit',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600, color: color),
        ),
      ),
    );
  }
}

class _Tappable extends StatelessWidget {
  const _Tappable({required this.child, required this.onTap, required this.enabled});

  final Widget child;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: InkResponse(
        onTap: enabled ? onTap : null,
        radius: 42,
        child: SizedBox(height: 66, child: Center(child: child)),
      ),
    );
  }
}
