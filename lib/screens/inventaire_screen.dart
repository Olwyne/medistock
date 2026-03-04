import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/medication.dart';
import '../providers/family_provider.dart';
import '../providers/medication_provider.dart';
import 'medication_detail_screen.dart';
import 'add_medication_screen.dart';

String _uniteLabel(Medication m) {
  if (m.quantite <= 1) return m.unite;
  if (m.unite == 'ML') return m.unite;
  return '${m.unite}s';
}

enum InventaireSort { nom, quantite, peremption }
enum InventaireFilter { tous, bientotPerime, stockFaible }

class InventaireScreen extends StatefulWidget {
  const InventaireScreen({super.key});

  @override
  State<InventaireScreen> createState() => _InventaireScreenState();
}

class _InventaireScreenState extends State<InventaireScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  InventaireSort _sort = InventaireSort.nom;
  InventaireFilter _filter = InventaireFilter.tous;
  String? _lieuFilter;
  int? _memberFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  static void _exportCsv(BuildContext context, List<Medication> medications) {
    const sep = ';';
    final sb = StringBuffer();
    sb.writeln('Nom${sep}Quantité${sep}Unité${sep}Lieu${sep}Péremption${sep}Seuil alerte');
    for (final m in medications) {
      sb.writeln([
        '"${m.nom.replaceAll('"', '""')}"',
        m.quantite,
        m.unite,
        m.lieu ?? '',
        m.datePeremption != null ? DateFormat('yyyy-MM-dd').format(m.datePeremption!) : '',
        m.seuilAlerte,
      ].join(sep));
    }
    final csv = sb.toString();
    Clipboard.setData(ClipboardData(text: csv));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).exportCsvCopied),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  List<Medication> _applyFilterSort(List<Medication> list) {
    var result = list.where((m) {
      if (_searchQuery.isNotEmpty &&
          !m.nom.toLowerCase().contains(_searchQuery.toLowerCase()) &&
          (m.lieu == null || !m.lieu!.toLowerCase().contains(_searchQuery.toLowerCase()))) {
        return false;
      }
      if (_filter == InventaireFilter.bientotPerime && !m.estBientotPerime) return false;
      if (_filter == InventaireFilter.stockFaible && !m.stockFaible) return false;
      if (_lieuFilter != null && m.lieu != _lieuFilter) return false;
      if (_memberFilter != null && m.memberId != _memberFilter) return false;
      return true;
    }).toList();

    result.sort((a, b) {
      switch (_sort) {
        case InventaireSort.nom:
          return a.nom.compareTo(b.nom);
        case InventaireSort.quantite:
          return a.quantite.compareTo(b.quantite);
        case InventaireSort.peremption:
          final da = a.datePeremption ?? DateTime(9999);
          final db = b.datePeremption ?? DateTime(9999);
          return da.compareTo(db);
      }
    });
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.inventaireTitle),
        actions: [
          PopupMenuButton<InventaireSort>(
            icon: const Icon(Icons.sort),
            tooltip: l10n.sort,
            onSelected: (s) => setState(() => _sort = s),
            itemBuilder: (_) => [
              PopupMenuItem(value: InventaireSort.nom, child: Text(l10n.sortByName)),
              PopupMenuItem(value: InventaireSort.quantite, child: Text(l10n.sortByQuantity)),
              PopupMenuItem(value: InventaireSort.peremption, child: Text(l10n.sortByExpiry)),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: l10n.exportCsv,
            onPressed: () => _exportCsv(context, context.read<MedicationProvider>().medications),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const AddMedicationScreen(),
              ),
            ),
          ),
        ],
      ),
      body: Consumer<MedicationProvider>(
        builder: (context, provider, _) {
          if (provider.loading && provider.medications.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(provider.error!, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => provider.load(),
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            );
          }
          if (provider.medications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.medication_liquid_outlined, size: 80, color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noMedication,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.noMedicationHint,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.outline),
                  ),
                  const SizedBox(height: 24),
                  Semantics(
                    label: l10n.addMedication,
                    button: true,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AddMedicationScreen()),
                      ),
                      icon: const Icon(Icons.add),
                      label: Text(l10n.addMedication),
                      style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
                    ),
                  ),
                ],
              ),
            );
          }

          final filtered = _applyFilterSort(provider.medications);
          final lieux = provider.medications
              .map((m) => m.lieu)
              .where((l) => l != null && l.isNotEmpty)
              .toSet()
              .cast<String>()
              .toList()
            ..sort();
          final familyProvider = context.watch<FamilyProvider>();
          final memberIdsInUse = provider.medications.map((m) => m.memberId).whereType<int>().toSet();
          final membersInUse = familyProvider.members.where((m) => memberIdsInUse.contains(m.id)).toList();

          return RefreshIndicator(
            onRefresh: () => provider.load(),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: _DashboardSummary(provider: provider),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: l10n.searchHint,
                        prefixIcon: const Icon(Icons.search),
                        border: const OutlineInputBorder(),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                      ),
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _FilterChip(
                          label: l10n.filterAll,
                          selected: _filter == InventaireFilter.tous && _lieuFilter == null,
                          onSelected: () => setState(() {
                            _filter = InventaireFilter.tous;
                            _lieuFilter = null;
                          }),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: l10n.filterSoonExpiry,
                          selected: _filter == InventaireFilter.bientotPerime,
                          onSelected: () => setState(() {
                            _filter = InventaireFilter.bientotPerime;
                            _lieuFilter = null;
                          }),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: l10n.filterLowStock,
                          selected: _filter == InventaireFilter.stockFaible,
                          onSelected: () => setState(() {
                            _filter = InventaireFilter.stockFaible;
                            _lieuFilter = null;
                          }),
                        ),
                        if (lieux.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          PopupMenuButton<String?>(
                            tooltip: l10n.place,
                            offset: const Offset(0, 40),
                            child: Chip(
                              label: Text(_lieuFilter ?? l10n.place),
                              deleteIcon: _lieuFilter != null ? const Icon(Icons.close, size: 18) : null,
                              onDeleted: _lieuFilter != null ? () => setState(() => _lieuFilter = null) : null,
                            ),
                            itemBuilder: (_) => [
                              ...lieux.map((l) => PopupMenuItem(value: l, child: Text(l))),
                            ],
                            onSelected: (v) => setState(() => _lieuFilter = v),
                          ),
                        ],
                        if (membersInUse.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          PopupMenuButton<int?>(
                            tooltip: l10n.family,
                            offset: const Offset(0, 40),
                            child: Chip(
                              label: Text(
                                _memberFilter == null
                                    ? l10n.family
                                    : () {
                                        final list = familyProvider.members.where((m) => m.id == _memberFilter).toList();
                                        return list.isEmpty ? l10n.family : list.first.name;
                                      }(),
                              ),
                              deleteIcon: _memberFilter != null ? const Icon(Icons.close, size: 18) : null,
                              onDeleted: _memberFilter != null ? () => setState(() => _memberFilter = null) : null,
                            ),
                            itemBuilder: (_) => [
                              PopupMenuItem<int?>(value: null, child: Text(l10n.filterAll)),
                              ...membersInUse.map((m) => PopupMenuItem<int?>(value: m.id, child: Text(m.name))),
                            ],
                            onSelected: (v) => setState(() => _memberFilter = v),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final m = filtered[index];
                        final memberName = m.memberId == null
                            ? null
                            : (() {
                                final list = familyProvider.members.where((x) => x.id == m.memberId).toList();
                                return list.isEmpty ? null : list.first.name;
                              })();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _MedicationCard(medication: m, memberName: memberName),
                        );
                      },
                      childCount: filtered.length,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DashboardSummary extends StatelessWidget {
  final MedicationProvider provider;

  const _DashboardSummary({required this.provider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = provider.medications.length;
    final bientot = provider.bientotPerimes.length;
    final faible = provider.stockFaible.length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  Text('$total', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  Text(AppLocalizations.of(context).medications, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            Expanded(
              child: Builder(
                builder: (ctx) {
                  final l10n = AppLocalizations.of(ctx);
                  return Column(
                    children: [
                      Text('$bientot', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.tertiary)),
                      Text(l10n.soonExpiry, style: theme.textTheme.bodySmall),
                    ],
                  );
                },
              ),
            ),
            Expanded(
              child: Builder(
                builder: (ctx) {
                  final l10n = AppLocalizations.of(ctx);
                  return Column(
                    children: [
                      Text('$faible', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.secondary)),
                      Text(l10n.lowStock, style: theme.textTheme.bodySmall),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChip({required this.label, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }
}

class _MedicationCard extends StatelessWidget {
  final Medication medication;
  final String? memberName;

  const _MedicationCard({required this.medication, this.memberName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MedicationDetailScreen(medicationId: medication.id!),
          ),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              medication.photoPath != null && File(medication.photoPath!).existsSync()
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.file(
                        File(medication.photoPath!),
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      ),
                    )
                  : CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Icon(Icons.medication, color: theme.colorScheme.onPrimaryContainer),
                    ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medication.nom,
                      style: theme.textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${medication.quantite} ${_uniteLabel(medication)}${medication.quantiteParUnite != null ? ' (× ${medication.quantiteParUnite})' : ''}',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                    ),
                    if (medication.lieu != null && medication.lieu!.isNotEmpty)
                      Text(
                        medication.lieu!,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                      ),
                    if (memberName != null)
                      Text(
                        memberName!,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                      ),
                    if (medication.estBientotPerime || medication.stockFaible) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        children: [
                          if (medication.estPerime)
                            Chip(
                              label: Text(AppLocalizations.of(context).expired),
                              backgroundColor: theme.colorScheme.errorContainer,
                              labelStyle: TextStyle(color: theme.colorScheme.onErrorContainer, fontSize: 12),
                            ),
                          if (medication.estBientotPerime && !medication.estPerime)
                            Chip(
                              label: Text('${AppLocalizations.of(context).expiresIn} ${medication.joursAvantPeremption} ${AppLocalizations.of(context).days}'),
                              backgroundColor: theme.colorScheme.tertiaryContainer,
                              labelStyle: TextStyle(color: theme.colorScheme.onTertiaryContainer, fontSize: 12),
                            ),
                          if (medication.stockFaible)
                            Chip(
                              label: Text(AppLocalizations.of(context).lowStock),
                              backgroundColor: theme.colorScheme.secondaryContainer,
                              labelStyle: TextStyle(color: theme.colorScheme.onSecondaryContainer, fontSize: 12),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: theme.colorScheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}
