import 'package:flutter/material.dart';
import '../../theme/cocon_theme.dart';

/// Pastille carrée arrondie sauge — icône représentant un médicament/lieu.
class CatAvatar extends StatelessWidget {
  final IconData icon;
  final double size;

  const CatAvatar({super.key, this.icon = Icons.medication_outlined, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: CoconColors.sageSoft,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: size * 0.5, color: CoconColors.sage),
    );
  }
}

/// Avatar rond coloré pour un membre du foyer (initiale).
class MemberAvatar extends StatelessWidget {
  final String name;
  final String seed;
  final double size;
  final Color borderColor;

  const MemberAvatar({super.key, required this.name, required this.seed, this.size = 34, this.borderColor = CoconColors.surface});

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: CoconColors.memberColor(seed.hashCode),
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2.5),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: size * 0.4),
      ),
    );
  }
}
