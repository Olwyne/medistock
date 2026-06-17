import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/medication.dart';
import '../providers/auth_provider.dart';
import '../providers/family_provider.dart';
import '../providers/medication_provider.dart';
import '../theme/cocon_theme.dart';
import '../widgets/cocon/cocon.dart';
import 'medication_detail_screen.dart';
import 'settings_screen.dart';

/// Écran d'accueil — équivalent de l'écran « Accueil » du prototype Cocon :
/// tuiles "À surveiller", prochaines péremptions, regroupement par lieu.
class DashboardScreen extends StatelessWidget {
  final void Function(int tabIndex)? onNavigate;

  const DashboardScreen({super.key, this.onNavigate});

  String _greetingName(AuthProvider auth) {
    final email = auth.userEmail;
    if (email == null || email.isEmpty) return '';
    final local = email.split('@').first;
    if (local.isEmpty) return '';
    return local[0].toUpperCase() + local.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = context.watch<AuthProvider>();
    final family = context.watch<FamilyProvider>();
    final meds = context.watch<MedicationProvider>();

    final perimes = meds.perimes;
    final bientot = meds.bientotPerimes;
    final aRacheter = meds.stockFaible;
    final name = _greetingName(auth);

    final places = meds.medications
        .map((m) => m.lieu)
        .where((l) => l != null && l.isNotEmpty)
        .toSet()
        .cast<String>()
        .toList()
      ..sort();

    return Scaffold(
      backgroundColor: CoconColors.bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.household,
                            style: const TextStyle(color: CoconColors.muted, fontWeight: FontWeight.w800, fontSize: 12.5),
                          ),
                          Text(
                            name.isEmpty ? l10n.greeting : '${l10n.greeting} $name 👋',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 25, letterSpacing: -0.4, color: CoconColors.ink),
                          ),
                        ],
                      ),
                    ),
                    if (family.members.isNotEmpty)
                      SizedBox(
                        width: 36.0 + (family.members.length - 1) * 24.0,
                        height: 38,
                        child: Stack(
                          children: [
                            for (var i = 0; i < family.members.length; i++)
                              Positioned(
                                left: i * 24.0,
                                child: MemberAvatar(name: family.members[i].name, seed: family.members[i].id, size: 36),
                              ),
                          ],
                        ),
                      ),
                    const SizedBox(width: 10),
                    RoundIconButton(
                      icon: Icons.settings_outlined,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 26),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _SectionTitle(title: l10n.watchSection, hint: l10n.watchSectionHint),
                  const SizedBox(height: 11),
                  Row(
                    children: [
                      Expanded(child: _StatTile(status: MedStatus.perime, count: perimes.length, label: AppLocalizations.of(context).expired, onTap: () => onNavigate?.call(2))),
                      const SizedBox(width: 11),
                      Expanded(child: _StatTile(status: MedStatus.bientot, count: bientot.length, label: l10n.soonExpiry, onTap: () => onNavigate?.call(2))),
                      const SizedBox(width: 11),
                      Expanded(child: _StatTile(status: MedStatus.rupture, count: aRacheter.length, label: l10n.toReorder, onTap: () => onNavigate?.call(2))),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(child: _SectionTitle(title: l10n.upcomingExpiry)),
                      TextButton(
                        onPressed: () => onNavigate?.call(2),
                        child: Text(l10n.seeAll, style: const TextStyle(color: CoconColors.accent, fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                  if (bientot.isEmpty)
                    SoftCard(child: Text(l10n.noAlertsHint, style: const TextStyle(color: CoconColors.muted, fontWeight: FontWeight.w700)))
                  else
                    SoftCard(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      child: Column(
                        children: [
                          for (var i = 0; i < bientot.take(4).length; i++)
                            _UpcomingRow(medication: bientot[i], showDivider: i < bientot.take(4).length - 1),
                        ],
                      ),
                    ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(child: _SectionTitle(title: l10n.byPlace)),
                      TextButton(
                        onPressed: () => onNavigate?.call(0),
                        child: Text(l10n.seeAll, style: const TextStyle(color: CoconColors.accent, fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                  if (places.isEmpty)
                    SoftCard(child: Text(l10n.noMedicationHint, style: const TextStyle(color: CoconColors.muted, fontWeight: FontWeight.w700)))
                  else
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 11,
                      crossAxisSpacing: 11,
                      childAspectRatio: 2.6,
                      children: places.take(6).map((p) {
                        final n = meds.medications.where((m) => m.lieu == p).length;
                        return _PlaceTile(name: p, count: n, onTap: () => onNavigate?.call(0));
                      }).toList(),
                    ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? hint;
  const _SectionTitle({required this.title, this.hint});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: CoconColors.ink)),
        if (hint != null) ...[
          const SizedBox(width: 9),
          Text(hint!, style: const TextStyle(color: CoconColors.muted, fontWeight: FontWeight.w700, fontSize: 12.5)),
        ],
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final MedStatus status;
  final int count;
  final String label;
  final VoidCallback onTap;

  const _StatTile({required this.status, required this.count, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = CoconColors.status[status]!;
    return SoftCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(13, 13, 13, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: s.bg, borderRadius: BorderRadius.circular(11)),
            alignment: Alignment.center,
            child: Icon(s.icon, size: 19, color: s.fg),
          ),
          const SizedBox(height: 9),
          Text('$count', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 25, color: s.fg, height: 1)),
          const SizedBox(height: 3),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: CoconColors.muted), maxLines: 2),
        ],
      ),
    );
  }
}

class _UpcomingRow extends StatelessWidget {
  final Medication medication;
  final bool showDivider;

  const _UpcomingRow({required this.medication, required this.showDivider});

  @override
  Widget build(BuildContext context) {
    final m = medication;
    return Column(
      children: [
        InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => MedicationDetailScreen(medicationId: m.id)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 11),
            child: Row(
              children: [
                const CatAvatar(size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m.nom, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                      if (m.lieu != null && m.lieu!.isNotEmpty)
                        Text(m.lieu!, style: const TextStyle(color: CoconColors.muted, fontWeight: FontWeight.w700, fontSize: 12.5)),
                    ],
                  ),
                ),
                if (m.datePeremption != null)
                  Text(
                    '${m.datePeremption!.day.toString().padLeft(2, '0')}/${m.datePeremption!.month.toString().padLeft(2, '0')}/${m.datePeremption!.year}',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: CoconColors.status[MedStatus.bientot]!.fg),
                  ),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right, size: 17, color: CoconColors.muted),
              ],
            ),
          ),
        ),
        if (showDivider) const Divider(height: 1),
      ],
    );
  }
}

class _PlaceTile extends StatelessWidget {
  final String name;
  final int count;
  final VoidCallback onTap;

  const _PlaceTile({required this.name, required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
      child: Row(
        children: [
          const CatAvatar(icon: Icons.inventory_2_outlined, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('$count', style: const TextStyle(color: CoconColors.muted, fontWeight: FontWeight.w700, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
