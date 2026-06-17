import 'package:flutter/material.dart';
import '../../theme/cocon_theme.dart';

/// Pastille de statut (péremption / stock) — ronde colorée + libellé.
class StatusBadge extends StatelessWidget {
  final MedStatus status;
  final bool big;

  const StatusBadge({super.key, required this.status, this.big = false});

  @override
  Widget build(BuildContext context) {
    final s = CoconColors.status[status]!;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: big ? 13 : 10, vertical: big ? 7 : 5),
      decoration: BoxDecoration(color: s.bg, borderRadius: BorderRadius.circular(CoconRadii.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: s.fg, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(
            s.label,
            style: TextStyle(color: s.fg, fontWeight: FontWeight.w800, fontSize: big ? 13 : 11.5),
          ),
        ],
      ),
    );
  }
}
