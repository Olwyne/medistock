import 'package:flutter/material.dart';
import '../../theme/cocon_theme.dart';

/// Carte douce — fond surface, bordure ligne, ombre légère, coins arrondis 22.
class SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? borderColor;
  final double borderWidth;
  final Color? backgroundColor;

  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.borderColor,
    this.borderWidth = 1,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? CoconColors.surface,
        borderRadius: BorderRadius.circular(CoconRadii.card),
        border: Border.all(color: borderColor ?? CoconColors.line, width: borderWidth),
        boxShadow: const [
          BoxShadow(color: Color(0x0A3A352F), blurRadius: 12, offset: Offset(0, 2)),
        ],
      ),
      padding: padding,
      child: child,
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(CoconRadii.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(CoconRadii.card),
        child: card,
      ),
    );
  }
}
