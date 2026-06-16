import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/medication.dart';
import '../providers/family_provider.dart';
import '../providers/medication_provider.dart';
import '../theme/cocon_theme.dart';
import '../widgets/cocon/cocon.dart';
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
  String? _memberFilter;

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
    Clipboard.setData(ClipboardData(text: sb.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).exportCsvCopied), behavior: SnackBarBehavior.floating),
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
      if (_memberFilter != null && !m.memberIds.contains(_memberFilter)) return false;
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
      backgroundColor: CoconColors.bg,
      body: Consumer<MedicationProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              CoconScreenHeader(
                title: l10n.inventaireTitle,
                eyebrow: '${provider.medications.length} ${l10n.medications.toLowerCase()}',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RoundIconButton(
                      icon: Icons.sort,
                      onTap: () => _showSortMenu(context),
                    ),
                    const SizedBox(width: 8),
                    RoundIconButton(
                      icon: Icons.upload_file_outlined,
                      onTap: () => _exportCsv(context, provider.medications),
                    ),
                    const SizedBox(width: 8),
                    RoundIconButton(
                      icon: Icons.add,
                      background: CoconColors.accent,
                      color: Colors.white,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddMedicationScreen())),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Builder(builder: (context) {
                  if (provider.loading && provider.medications.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (provider.error != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(provider.error!, textAlign: TextAlign.center, style: const TextStyle(color: CoconColors.muted)),
                          const SizedBox(height: 16),
                          PrimaryButton(label: l10n.retry, onPressed: () => provider.load(), full: false),
                        ],
                      ),
                    );
                  }
                  if (provider.medications.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CatAvatar(icon: Icons.medication_liquid_outlined, size: 80),
                            const SizedBox(height: 16),
                            Text(l10n.noMedication, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: CoconColors.ink)),
                            const SizedBox(height: 8),
                            Text(l10n.noMedicationHint, style: const TextStyle(color: CoconColors.muted, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                            const SizedBox(height: 24),
                            PrimaryButton(
                              label: l10n.addMedication,
                              icon: Icons.add,
                              full: false,
                              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddMedicationScreen())),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final filtered = _applyFilterSort(provider.medications);
                  final lieux = provider.medications.map((m) => m.lieu).where((l) => l != null && l.isNotEmpty).toSet().cast<String>().toList()..sort();
                  final familyProvider = context.watch<FamilyProvider>();
                  final memberIdsInUse = provider.medications.expand((m) => m.memberIds).toSet();
                  final membersInUse = familyProvider.members.where((m) => memberIdsInUse.contains(m.id)).toList();

                  return RefreshIndicator(
                    onRefresh: () => provider.load(),
                    child: CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: l10n.searchHint,
                                prefixIcon: const Icon(Icons.search, color: CoconColors.muted),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(icon: const Icon(Icons.clear), onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                      })
                                    : null,
                              ),
                              onChanged: (v) => setState(() => _searchQuery = v),
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.fromLTRB(18, 14, 18, 4),
                            child: Row(
                              children: [
                                CoconChip(
                                  label: l10n.filterAll,
                                  active: _filter == InventaireFilter.tous && _lieuFilter == null && _memberFilter == null,
                                  onTap: () => setState(() {
                                    _filter = InventaireFilter.tous;
                                    _lieuFilter = null;
                                    _memberFilter = null;
                                  }),
                                ),
                                const SizedBox(width: 8),
                                CoconChip(
                                  label: l10n.filterSoonExpiry,
                                  active: _filter == InventaireFilter.bientotPerime,
                                  onTap: () => setState(() => _filter = InventaireFilter.bientotPerime),
                                ),
                                const SizedBox(width: 8),
                                CoconChip(
                                  label: l10n.filterLowStock,
                                  active: _filter == InventaireFilter.stockFaible,
                                  onTap: () => setState(() => _filter = InventaireFilter.stockFaible),
                                ),
                                if (lieux.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  PopupMenuButton<String?>(
                                    tooltip: l10n.place,
                                    itemBuilder: (_) => lieux.map((l) => PopupMenuItem(value: l, child: Text(l))).toList(),
                                    onSelected: (v) => setState(() => _lieuFilter = v),
                                    child: CoconChip(label: _lieuFilter ?? l10n.place, active: _lieuFilter != null, onTap: () {}),
                                  ),
                                ],
                                if (membersInUse.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  PopupMenuButton<String?>(
                                    tooltip: l10n.family,
                                    itemBuilder: (_) => [
                                      PopupMenuItem<String?>(value: null, child: Text(l10n.filterAll)),
                                      ...membersInUse.map((m) => PopupMenuItem<String?>(value: m.id, child: Text(m.name))),
                                    ],
                                    onSelected: (v) => setState(() => _memberFilter = v),
                                    child: CoconChip(
                                      label: _memberFilter == null ? l10n.family : (membersInUse.where((m) => m.id == _memberFilter).firstOrNull?.name ?? l10n.family),
                                      active: _memberFilter != null,
                                      onTap: () {},
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(18, 10, 18, 26),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final m = filtered[index];
                                final names = familyProvider.members.where((x) => m.memberIds.contains(x.id)).map((x) => x.name).join(', ');
                                final memberName = names.isEmpty ? null : names;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
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
                }),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showSortMenu(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: CoconColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: Text(l10n.sortByName), onTap: () { setState(() => _sort = InventaireSort.nom); Navigator.pop(ctx); }),
            ListTile(title: Text(l10n.sortByQuantity), onTap: () { setState(() => _sort = InventaireSort.quantite); Navigator.pop(ctx); }),
            ListTile(title: Text(l10n.sortByExpiry), onTap: () { setState(() => _sort = InventaireSort.peremption); Navigator.pop(ctx); }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _MedicationCard extends StatelessWidget {
  final Medication medication;
  final String? memberName;

  const _MedicationCard({required this.medication, this.memberName});

  @override
  Widget build(BuildContext context) {
    final m = medication;
    MedStatus status = MedStatus.ok;
    if (m.estPerime) {
      status = MedStatus.perime;
    } else if (m.estBientotPerime) {
      status = MedStatus.bientot;
    } else if (m.stockFaible) {
      status = MedStatus.bas;
    }
    final s = CoconColors.status[status]!;

    return SoftCard(
      borderColor: CoconColors.line,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => MedicationDetailScreen(medicationId: m.id)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(width: 4, height: 44, decoration: BoxDecoration(color: s.fg, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 10),
          m.photoPath != null && File(m.photoPath!).existsSync()
              ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(File(m.photoPath!), width: 44, height: 44, fit: BoxFit.cover))
              : const CatAvatar(size: 44),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.nom, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  [
                    '${m.quantite} ${_uniteLabel(m)}',
                    if (m.lieu != null && m.lieu!.isNotEmpty) m.lieu!,
                    if (memberName != null) memberName!,
                  ].join(' · '),
                  style: const TextStyle(color: CoconColors.muted, fontWeight: FontWeight.w700, fontSize: 12.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          StatusBadge(status: status),
        ],
      ),
    );
  }
}
