import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';
import '../models/medication.dart';
import '../models/stock_movement.dart';
import '../providers/medication_provider.dart';
import '../services/reminder_service.dart';
import '../theme/cocon_theme.dart';
import '../widgets/cocon/cocon.dart';
import 'add_medication_screen.dart';

class MedicationDetailScreen extends StatefulWidget {
  /// Id du document Firestore.
  final dynamic medicationId;

  const MedicationDetailScreen({super.key, required this.medicationId});

  @override
  State<MedicationDetailScreen> createState() => _MedicationDetailScreenState();
}

class _MedicationDetailScreenState extends State<MedicationDetailScreen> {
  Medication? _medication;
  List<StockMovement> _movements = [];
  String? _reminderTime;
  int _takeQty = 1;

  Future<void> _load([MedicationProvider? provider]) async {
    final p = provider ?? context.read<MedicationProvider>();
    final m = await p.getById(widget.medicationId);
    final movements = await p.getMovements(widget.medicationId, limit: 20);
    final reminder = await ReminderService.getReminderTime(widget.medicationId);
    if (mounted) {
      setState(() {
        _medication = m;
        _movements = movements;
        _reminderTime = reminder;
        _takeQty = 1;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  static String _uniteWithPlural(Medication m) {
    if (m.quantite <= 1) return m.unite;
    if (m.unite == 'ML') return m.unite;
    return '${m.unite}s';
  }

  MedStatus _statusOf(Medication m) {
    if (m.estPerime) return MedStatus.perime;
    if (m.estBientotPerime) return MedStatus.bientot;
    if (m.stockFaible) return m.quantite <= 0 ? MedStatus.rupture : MedStatus.bas;
    return MedStatus.ok;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_medication == null) {
      return Scaffold(
        backgroundColor: CoconColors.bg,
        body: Column(
          children: [
            CoconScreenHeader(title: l10n.detail, onBack: () => Navigator.of(context).pop()),
            const Expanded(child: Center(child: CircularProgressIndicator())),
          ],
        ),
      );
    }
    final m = _medication!;
    final status = _statusOf(m);
    final s = CoconColors.status[status]!;

    return Scaffold(
      backgroundColor: CoconColors.bg,
      body: Column(
        children: [
          CoconScreenHeader(
            title: l10n.detail,
            onBack: () => Navigator.of(context).pop(),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                RoundIconButton(
                  icon: Icons.edit_outlined,
                  onTap: () async {
                    final provider = context.read<MedicationProvider>();
                    final updated = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(builder: (_) => AddMedicationScreen(editing: m)),
                    );
                    if (updated == true && mounted) await _load(provider);
                  },
                ),
                const SizedBox(width: 8),
                RoundIconButton(
                  icon: Icons.delete_outline,
                  color: CoconColors.status[MedStatus.perime]!.fg,
                  onTap: () async {
                    final provider = context.read<MedicationProvider>();
                    final navigator = Navigator.of(context);
                    final medicationId = m.id;
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(l10n.deleteConfirm),
                        content: Text(l10n.deleteMedicationConfirm),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: FilledButton.styleFrom(backgroundColor: CoconColors.status[MedStatus.perime]!.fg),
                            child: Text(l10n.delete),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true && mounted) {
                      if (medicationId != null) await provider.delete(medicationId);
                      if (mounted) navigator.pop();
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 30),
              child: Column(
                children: [
                  // héros
                  m.photoPath != null && File(m.photoPath!).existsSync()
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: Image.file(File(m.photoPath!), width: 96, height: 96, fit: BoxFit.cover),
                        )
                      : const CatAvatar(size: 96),
                  const SizedBox(height: 12),
                  Text(
                    m.nom,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontFamily: 'Quicksand', fontWeight: FontWeight.w700, fontSize: 25, letterSpacing: -0.4, color: CoconColors.ink),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${m.quantite} ${_uniteWithPlural(m)}${m.quantiteParUnite != null ? ' (× ${m.quantiteParUnite})' : ''}',
                    style: const TextStyle(color: CoconColors.muted, fontWeight: FontWeight.w700, fontSize: 14.5),
                  ),
                  const SizedBox(height: 12),
                  StatusBadge(status: status, big: true),
                  const SizedBox(height: 18),

                  if (status == MedStatus.perime || status == MedStatus.bientot)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(color: s.bg, borderRadius: BorderRadius.circular(CoconRadii.tile)),
                      child: Row(
                        children: [
                          Icon(s.icon, size: 22, color: s.fg),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              status == MedStatus.perime
                                  ? '${l10n.expired} — pensez à le rapporter en pharmacie.'
                                  : m.datePeremption != null
                                      ? '${l10n.expiry} : ${DateFormat.yMMMd('fr').format(m.datePeremption!)}.'
                                      : l10n.expiresIn,
                              style: TextStyle(color: s.fg, fontWeight: FontWeight.w700, fontSize: 13.5),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // grille infos
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 11,
                    crossAxisSpacing: 11,
                    childAspectRatio: 2.6,
                    children: [
                      _InfoCell(label: l10n.quantity, value: '${m.quantite} ${_uniteWithPlural(m)}'),
                      _InfoCell(label: l10n.expiry, value: m.datePeremption != null ? DateFormat.yMMMd('fr').format(m.datePeremption!) : l10n.notSet),
                      if (m.lieu != null && m.lieu!.isNotEmpty) _InfoCell(label: l10n.place, value: m.lieu!),
                      _InfoCell(label: l10n.unit, value: m.unite),
                      if (m.dci != null && m.dci!.isNotEmpty) _InfoCell(label: 'Substance (DCI)', value: m.dci!),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (m.indication != null || m.posologie != null || m.precautions != null) ...[
                    SoftCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (m.indication != null && m.indication!.isNotEmpty) ...[
                            const Text('À quoi ça sert', style: TextStyle(fontFamily: 'Quicksand', fontWeight: FontWeight.w700, fontSize: 14, color: CoconColors.ink)),
                            const SizedBox(height: 4),
                            Text(m.indication!, style: const TextStyle(color: CoconColors.muted, fontWeight: FontWeight.w600, fontSize: 13.5, height: 1.4)),
                          ],
                          if (m.posologie != null && m.posologie!.isNotEmpty) ...[
                            if (m.indication != null && m.indication!.isNotEmpty) const SizedBox(height: 12),
                            const Text('Posologie', style: TextStyle(fontFamily: 'Quicksand', fontWeight: FontWeight.w700, fontSize: 14, color: CoconColors.ink)),
                            const SizedBox(height: 4),
                            Text(m.posologie!, style: const TextStyle(color: CoconColors.muted, fontWeight: FontWeight.w600, fontSize: 13.5, height: 1.4)),
                          ],
                          if (m.precautions != null && m.precautions!.isNotEmpty) ...[
                            if (m.indication != null || m.posologie != null) const SizedBox(height: 12),
                            const Text('Effets secondaires / précautions', style: TextStyle(fontFamily: 'Quicksand', fontWeight: FontWeight.w700, fontSize: 14, color: CoconColors.ink)),
                            const SizedBox(height: 4),
                            Text(m.precautions!, style: const TextStyle(color: CoconColors.muted, fontWeight: FontWeight.w600, fontSize: 13.5, height: 1.4)),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  SoftCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.eco_outlined, size: 19, color: CoconColors.sage),
                            const SizedBox(width: 9),
                            Text(l10n.goodToKnow, style: const TextStyle(fontFamily: 'Quicksand', fontWeight: FontWeight.w700, fontSize: 15, color: CoconColors.ink)),
                          ],
                        ),
                        const SizedBox(height: 7),
                        Text(l10n.goodToKnowHint, style: const TextStyle(color: CoconColors.muted, fontWeight: FontWeight.w600, fontSize: 13.5, height: 1.45)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // actions stock
                  Row(
                    children: [
                      SizedBox(
                        width: 76,
                        child: TextFormField(
                          key: ValueKey('qty_${m.id}'),
                          initialValue: '1',
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(labelText: l10n.quantity, contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12)),
                          onChanged: (v) {
                            final n = int.tryParse(v);
                            if (n != null && n >= 1) setState(() => _takeQty = n.clamp(1, m.quantite));
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: PrimaryButton(
                          label: '${l10n.removeQuantity} $_takeQty',
                          icon: Icons.remove_circle_outline,
                          onPressed: m.quantite <= 0
                              ? null
                              : () async {
                                  final qty = _takeQty.clamp(1, m.quantite);
                                  final provider = context.read<MedicationProvider>();
                                  final messenger = ScaffoldMessenger.maybeOf(context);
                                  final unite = m.unite;
                                  await provider.takeStock(m.id, qty);
                                  await _load();
                                  if (mounted && messenger != null) {
                                    messenger.showSnackBar(SnackBar(content: Text('$qty $unite'), behavior: SnackBarBehavior.floating));
                                  }
                                },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 11),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final provider = context.read<MedicationProvider>();
                      final messenger = ScaffoldMessenger.maybeOf(context);
                      final unite = m.unite;
                      await provider.addStock(m.id, 1);
                      await _load();
                      if (mounted && messenger != null) {
                        messenger.showSnackBar(SnackBar(content: Text('+1 $unite ajouté'), behavior: SnackBarBehavior.floating));
                      }
                    },
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    label: Text(l10n.addStock),
                    style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                  ),

                  if (m.noticeUrl != null && m.noticeUrl!.isNotEmpty) ...[
                    const SizedBox(height: 11),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final uri = Uri.parse(m.noticeUrl!);
                        if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
                      },
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: Text(l10n.viewNotice),
                      style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                    ),
                  ],

                  const SizedBox(height: 18),
                  SoftCard(
                    padding: EdgeInsets.zero,
                    child: ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CoconRadii.card)),
                      leading: const Icon(Icons.notifications_outlined, color: CoconColors.muted),
                      title: Text(l10n.dailyReminder, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                      subtitle: Text(_reminderTime != null ? '${l10n.at} $_reminderTime' : l10n.notSet, style: const TextStyle(color: CoconColors.muted, fontWeight: FontWeight.w600)),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: _reminderTime != null
                              ? TimeOfDay(hour: int.parse(_reminderTime!.split(':')[0]), minute: int.parse(_reminderTime!.split(':')[1]))
                              : TimeOfDay.now(),
                        );
                        if (time != null && mounted) {
                          final s = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                          await ReminderService.setReminderTime(m.id!, s);
                          await ReminderService.scheduleReminder(m.id!, s, m.nom);
                          setState(() => _reminderTime = s);
                        }
                      },
                      trailing: _reminderTime != null
                          ? IconButton(
                              icon: const Icon(Icons.close, color: CoconColors.muted),
                              onPressed: () async {
                                await ReminderService.clearReminder(m.id!);
                                if (mounted) setState(() => _reminderTime = null);
                              },
                            )
                          : null,
                    ),
                  ),

                  if (_movements.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(l10n.movementHistory, style: const TextStyle(fontFamily: 'Quicksand', fontWeight: FontWeight.w700, fontSize: 15, color: CoconColors.ink)),
                    ),
                    const SizedBox(height: 8),
                    SoftCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: _movements.take(15).map((mov) {
                          final isPrise = mov.type == StockMovementType.prise;
                          final color = isPrise ? CoconColors.status[MedStatus.perime]!.fg : CoconColors.sage;
                          return ListTile(
                            dense: true,
                            leading: Icon(isPrise ? Icons.remove_circle_outline : Icons.add_circle_outline, color: color),
                            title: Text(isPrise ? '${l10n.taken} : ${mov.quantite}' : '${l10n.added} : +${mov.quantite}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                            subtitle: Text(DateFormat('dd/MM/yyyy HH:mm', 'fr').format(mov.date), style: const TextStyle(color: CoconColors.muted)),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCell extends StatelessWidget {
  final String label;
  final String value;

  const _InfoCell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: CoconColors.bg, border: Border.all(color: CoconColors.line), borderRadius: BorderRadius.circular(CoconRadii.tile)),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label.toUpperCase(), style: const TextStyle(color: CoconColors.muted, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 0.4)),
          const SizedBox(height: 3),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: CoconColors.ink), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
