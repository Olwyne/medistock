import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/medication.dart';
import '../providers/medication_provider.dart';
import '../providers/shopping_provider.dart';
import '../theme/cocon_theme.dart';
import '../widgets/cocon/cocon.dart';
import 'medication_detail_screen.dart';

class AlertesScreen extends StatelessWidget {
  const AlertesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: CoconColors.bg,
      body: Consumer<MedicationProvider>(
        builder: (context, provider, _) {
          final bientotPerimes = provider.bientotPerimes;
          final perimes = provider.perimes;
          final stockFaible = provider.stockFaible;
          final total = bientotPerimes.length + perimes.length + stockFaible.length;

          return Column(
            children: [
              CoconScreenHeader(title: l10n.alertesTitle, eyebrow: '$total points d\'attention'),
              Expanded(
                child: total == 0
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_outline, size: 72, color: CoconColors.sage),
                            const SizedBox(height: 16),
                            Text(l10n.noAlerts, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: CoconColors.ink)),
                            const SizedBox(height: 8),
                            Text(l10n.noAlertsHint, style: const TextStyle(color: CoconColors.muted, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 26),
                        children: [
                          _Section(status: MedStatus.perime, title: 'Périmés', sub: 'À retirer de l\'armoire', items: perimes),
                          _Section(status: MedStatus.bientot, title: l10n.soonExpiry, sub: 'Sous 30 jours', items: bientotPerimes),
                          _Section(status: MedStatus.rupture, title: l10n.lowStock, sub: l10n.toReorder, items: stockFaible),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final MedStatus status;
  final String title;
  final String sub;
  final List<Medication> items;

  const _Section({required this.status, required this.title, required this.sub, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final s = CoconColors.status[status]!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: s.bg, borderRadius: BorderRadius.circular(10)),
                alignment: Alignment.center,
                child: Icon(s.icon, size: 18, color: s.fg),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: CoconColors.ink)),
                    Text(sub, style: const TextStyle(color: CoconColors.muted, fontWeight: FontWeight.w700, fontSize: 12)),
                  ],
                ),
              ),
              Text('${items.length}', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20, color: s.fg)),
            ],
          ),
          const SizedBox(height: 11),
          for (final m in items) Padding(padding: const EdgeInsets.only(bottom: 10), child: _AlertCard(status: status, medication: m)),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final MedStatus status;
  final Medication medication;

  const _AlertCard({required this.status, required this.medication});

  @override
  Widget build(BuildContext context) {
    final m = medication;
    final s = CoconColors.status[status]!;
    return SoftCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => MedicationDetailScreen(medicationId: m.id)),
              ),
              child: Row(
                children: [
                  const CatAvatar(size: 42),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.nom, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(
                          m.datePeremption != null
                              ? 'exp ${DateFormat.yMMMd('fr').format(m.datePeremption!)}'
                              : '${m.quantite} ${m.unite}',
                          style: const TextStyle(color: CoconColors.muted, fontWeight: FontWeight.w700, fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (status == MedStatus.perime)
            _MiniButton(
              label: AppLocalizations.of(context).detail,
              fg: s.fg,
              bg: s.bg,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => MedicationDetailScreen(medicationId: m.id))),
            )
          else
            Consumer<ShoppingProvider>(
              builder: (context, shopping, _) {
                final inCart = shopping.items.any((i) => i.medicationId == m.id && !i.checked);
                return _MiniButton(
                  label: inCart ? AppLocalizations.of(context).added : AppLocalizations.of(context).addToShoppingList,
                  icon: inCart ? Icons.check : Icons.shopping_cart_outlined,
                  fg: inCart ? CoconColors.sage : CoconColors.accent,
                  bg: inCart ? CoconColors.sageSoft : CoconColors.accentSoft,
                  onTap: inCart ? null : () => context.read<ShoppingProvider>().addItem(label: m.nom, medicationId: m.id),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _MiniButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color fg;
  final Color bg;
  final VoidCallback? onTap;

  const _MiniButton({required this.label, this.icon, required this.fg, required this.bg, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 15, color: fg), const SizedBox(width: 6)],
              Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 12.5)),
            ],
          ),
        ),
      ),
    );
  }
}
