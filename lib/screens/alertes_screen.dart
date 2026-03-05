import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/medication.dart';
import '../providers/medication_provider.dart';
import '../providers/shopping_provider.dart';
import 'medication_detail_screen.dart';

class AlertesScreen extends StatelessWidget {
  const AlertesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alertes'),
      ),
      body: Consumer<MedicationProvider>(
        builder: (context, provider, _) {
          final bientotPerimes = provider.bientotPerimes;
          final perimes = provider.perimes;
          final stockFaible = provider.stockFaible;

          if (bientotPerimes.isEmpty && perimes.isEmpty && stockFaible.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 80, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune alerte',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Vos stocks et dates sont OK',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _Section(
                title: 'Périmés',
                icon: Icons.warning_amber_rounded,
                color: Theme.of(context).colorScheme.error,
                items: perimes,
              ),
              _Section(
                title: 'Bientôt périmés (30 j)',
                icon: Icons.schedule,
                color: Theme.of(context).colorScheme.tertiary,
                items: bientotPerimes,
              ),
              _Section(
                title: 'Stock faible',
                icon: Icons.inventory_2_outlined,
                color: Theme.of(context).colorScheme.secondary,
                items: stockFaible,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<Medication> items;

  const _Section({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 8),
            Text(title, style: theme.textTheme.titleMedium?.copyWith(color: color)),
          ],
        ),
        const SizedBox(height: 8),
        ...items.map((m) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.2),
                  child: Icon(Icons.medication, color: color),
                ),
                title: Text(m.nom),
                subtitle: Text(
                  m.datePeremption != null
                      ? 'Péremption : ${DateFormat.yMMMd('fr').format(m.datePeremption!)}'
                      : '${m.quantite} ${m.unite} - seuil ${m.seuilAlerte}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add_shopping_cart_outlined),
                      tooltip: AppLocalizations.of(context).addToShoppingList,
                      onPressed: () async {
                        await context.read<ShoppingProvider>().addItem(
                          label: m.nom,
                          medicationId: m.id,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(AppLocalizations.of(context).addToShoppingList),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MedicationDetailScreen(medicationId: kIsWeb ? m.serverId : m.id),
                  ),
                ),
              ),
            )),
      ],
    );
  }
}
