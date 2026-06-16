import 'package:flutter/material.dart';
import '../../theme/cocon_theme.dart';

/// Bouton pill corail avec ombre accent — action principale d'un écran.
class PrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool full;
  final Color? background;

  const PrimaryButton({super.key, required this.label, this.icon, this.onPressed, this.full = true, this.background});

  @override
  Widget build(BuildContext context) {
    final bg = background ?? CoconColors.accent;
    final button = FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: bg,
        disabledBackgroundColor: bg.withValues(alpha: 0.45),
        elevation: 0,
        shadowColor: Colors.transparent,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 9)],
          Text(label),
        ],
      ),
    );
    final wrapped = Container(
      decoration: onPressed == null
          ? null
          : BoxDecoration(
              borderRadius: BorderRadius.circular(CoconRadii.pill),
              boxShadow: [BoxShadow(color: bg.withValues(alpha: 0.32), blurRadius: 18, offset: const Offset(0, 8))],
            ),
      child: button,
    );
    return full ? SizedBox(width: double.infinity, child: wrapped) : wrapped;
  }
}
