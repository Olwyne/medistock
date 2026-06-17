import 'package:flutter/material.dart';
import '../../theme/cocon_theme.dart';

/// Chip de filtre pill — actif = fond ink, avec compteur optionnel.
class CoconChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final int? count;

  const CoconChip({super.key, required this.label, required this.active, required this.onTap, this.count});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(CoconRadii.pill),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
          decoration: BoxDecoration(
            color: active ? CoconColors.ink : CoconColors.surface,
            borderRadius: BorderRadius.circular(CoconRadii.pill),
            border: Border.all(color: active ? CoconColors.ink : CoconColors.line, width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                  color: active ? Colors.white : CoconColors.muted,
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: 7),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                  decoration: BoxDecoration(
                    color: active ? Colors.white.withValues(alpha: 0.22) : CoconColors.sunk,
                    borderRadius: BorderRadius.circular(CoconRadii.pill),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 11.5,
                      color: active ? Colors.white : CoconColors.muted,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
