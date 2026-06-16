import 'package:flutter/material.dart';
import '../../theme/cocon_theme.dart';

/// En-tête d'écran Cocon — eyebrow + titre Quicksand + retour optionnel + action.
class CoconScreenHeader extends StatelessWidget implements PreferredSizeWidget {
  final String? eyebrow;
  final String title;
  final VoidCallback? onBack;
  final Widget? trailing;
  final bool large;

  const CoconScreenHeader({super.key, this.eyebrow, required this.title, this.onBack, this.trailing, this.large = false});

  @override
  Size get preferredSize => Size.fromHeight(large ? 86 : 72);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: CoconColors.surface,
        border: Border(bottom: BorderSide(color: CoconColors.line)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: SafeArea(
        bottom: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (onBack != null) ...[
              _RoundIconButton(icon: Icons.arrow_back_rounded, onTap: onBack!),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (eyebrow != null)
                    Text(eyebrow!, style: const TextStyle(color: CoconColors.muted, fontWeight: FontWeight.w800, fontSize: 12.5)),
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: large ? 25 : 20,
                      color: CoconColors.ink,
                      letterSpacing: -0.4,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? background;
  final Color? color;

  const _RoundIconButton({required this.icon, required this.onTap, this.background, this.color});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background ?? CoconColors.sunk,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, size: 21, color: color ?? CoconColors.ink),
        ),
      ),
    );
  }
}

/// Petit bouton rond utilitaire (engrenage, plus...) réutilisé hors header.
class RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? background;
  final Color? color;
  final double size;

  const RoundIconButton({super.key, required this.icon, required this.onTap, this.background, this.color, this.size = 42});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background ?? CoconColors.sunk,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: SizedBox(width: size, height: size, child: Icon(icon, size: size * 0.5, color: color ?? CoconColors.ink)),
      ),
    );
  }
}
