import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/firestore_repository.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/medication_provider.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.statsTitle),
      ),
      body: FutureBuilder<StatsData>(
        future: _loadStats(context),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('${snapshot.error}'));
          }
          final data = snapshot.data!;
          final theme = Theme.of(context);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.statsPastes7, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text('${data.prises7}', style: theme.textTheme.headlineMedium?.copyWith(color: theme.colorScheme.primary)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.statsPastes30, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text('${data.prises30}', style: theme.textTheme.headlineMedium?.copyWith(color: theme.colorScheme.primary)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(l10n.statsMostUsed, style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              if (data.mostUsed.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(l10n.shoppingEmpty, style: theme.textTheme.bodyMedium),
                  ),
                )
              else
                ...data.mostUsed.map((e) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(e.name),
                    trailing: Text('${e.count}', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary)),
                  ),
                )),
            ],
          );
        },
      ),
    );
  }

  Future<StatsData> _loadStats(BuildContext context) async {
    final provider = context.read<MedicationProvider>();
    final familyId = context.read<AuthProvider>().currentFamilyId;
    if (familyId == null) return StatsData(prises7: 0, prises30: 0, mostUsed: []);

    final now = DateTime.now();
    final start7 = now.subtract(const Duration(days: 7));
    final start30 = now.subtract(const Duration(days: 30));

    final prises7 = await FirestoreRepository.getPrisesInRange(familyId, start7, now);
    final prises30 = await FirestoreRepository.getPrisesInRange(familyId, start30, now);
    final total7 = prises7.fold<int>(0, (s, m) => s + m.quantite);
    final total30 = prises30.fold<int>(0, (s, m) => s + m.quantite);
    final byMed = <String, int>{};
    for (final m in prises30) {
      byMed[m.medicationId] = (byMed[m.medicationId] ?? 0) + m.quantite;
    }
    final sorted = byMed.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final mostUsed = <({String name, int count})>[];
    for (final e in sorted.take(10)) {
      final med = await provider.getById(e.key);
      mostUsed.add((name: med?.nom ?? '#${e.key}', count: e.value));
    }
    return StatsData(prises7: total7, prises30: total30, mostUsed: mostUsed);
  }
}

class StatsData {
  final int prises7;
  final int prises30;
  final List<({String name, int count})> mostUsed;

  StatsData({required this.prises7, required this.prises30, required this.mostUsed});
}
