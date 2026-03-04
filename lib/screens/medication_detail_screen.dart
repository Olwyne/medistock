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
import 'add_medication_screen.dart';

class MedicationDetailScreen extends StatefulWidget {
  final int medicationId;

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_medication == null) {
      final l10n = AppLocalizations.of(context);
      return Scaffold(
        appBar: AppBar(title: Text(l10n.detail)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final m = _medication!;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(m.nom),
        actions: [
          Semantics(
            label: l10n.edit,
            child: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
              final provider = context.read<MedicationProvider>();
              final updated = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => AddMedicationScreen(editing: m),
                ),
              );
              if (updated == true && mounted) await _load(provider);
            },
          ),
          ),
          Semantics(
            label: l10n.delete,
            child: IconButton(
              icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final provider = context.read<MedicationProvider>();
              final navigator = Navigator.of(context);
              final medicationId = m.id!;
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(l10n.deleteConfirm),
                  content: Text(l10n.deleteMedicationConfirm),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.error),
                      child: Text(l10n.delete),
                    ),
                  ],
                ),
              );
              if (confirm == true && mounted) {
                await provider.delete(medicationId);
                if (mounted) navigator.pop();
              }
            },
          ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    if (m.photoPath != null && File(m.photoPath!).existsSync())
                      Semantics(
                        label: l10n.medicationName,
                        image: true,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(m.photoPath!),
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                    else
                      Semantics(
                        label: l10n.medicationName,
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Icon(Icons.medication, size: 48, color: theme.colorScheme.onPrimaryContainer),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      '${m.quantite} ${_uniteWithPlural(m)}${m.quantiteParUnite != null ? ' (× ${m.quantiteParUnite})' : ''}',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (m.datePeremption != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Péremption : ${DateFormat.yMMMd('fr').format(m.datePeremption!)}',
                        style: theme.textTheme.bodyMedium,
                      ),
                      if (m.joursAvantPeremption != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          m.estPerime
                              ? 'Périmé'
                              : 'Dans ${m.joursAvantPeremption} jour${m.joursAvantPeremption! > 1 ? 's' : ''}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: m.estPerime ? theme.colorScheme.error : theme.colorScheme.tertiary,
                          ),
                        ),
                      ],
                    ],
                    if (m.lieu != null && m.lieu!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.place, size: 18, color: theme.colorScheme.outline),
                          const SizedBox(width: 4),
                          Text(m.lieu!, style: theme.textTheme.bodyMedium),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                SizedBox(
                  width: 72,
                  child: TextFormField(
                    key: ValueKey('qty_${m.id}'),
                    initialValue: '1',
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l10n.quantity,
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onChanged: (v) {
                      final n = int.tryParse(v);
                      if (n != null && n >= 1) setState(() => _takeQty = n.clamp(1, m.quantite));
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Semantics(
                    label: '${l10n.removeQuantity} $_takeQty',
                    button: true,
                    child: FilledButton.icon(
                      onPressed: m.quantite <= 0
                          ? null
                          : () async {
                              final qty = _takeQty.clamp(1, m.quantite);
                              final provider = context.read<MedicationProvider>();
                              final messenger = ScaffoldMessenger.maybeOf(context);
                              final unite = m.unite;
                              await provider.takeStock(m.id!, qty);
                              await _load();
                              if (mounted && messenger != null) {
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text('$qty $unite'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                      icon: const Icon(Icons.remove_circle_outline),
                      label: Text('${l10n.removeQuantity} $_takeQty'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        minimumSize: const Size(48, 48),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Semantics(
              label: l10n.addStock,
              button: true,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final provider = context.read<MedicationProvider>();
                  final messenger = ScaffoldMessenger.maybeOf(context);
                  final unite = m.unite;
                  await provider.addStock(m.id!, 1);
                  await _load();
                  if (mounted && messenger != null) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('+1 $unite ajouté'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.add_circle_outline),
                label: Text(l10n.addStock),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(48, 48),
                ),
              ),
            ),
            if (m.noticeUrl != null && m.noticeUrl!.isNotEmpty) ...[
              const SizedBox(height: 24),
              Semantics(
                label: l10n.viewNotice,
                button: true,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final uri = Uri.parse(m.noticeUrl!);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  icon: const Icon(Icons.open_in_new),
                  label: Text(l10n.viewNotice),
                  style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
                ),
              ),
            ],
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: Text(l10n.dailyReminder),
              subtitle: Text(_reminderTime != null ? '${l10n.at} $_reminderTime' : l10n.notSet),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: _reminderTime != null
                      ? TimeOfDay(
                          hour: int.parse(_reminderTime!.split(':')[0]),
                          minute: int.parse(_reminderTime!.split(':')[1]))
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
                      icon: const Icon(Icons.close),
                      onPressed: () async {
                        await ReminderService.clearReminder(m.id!);
                        if (mounted) setState(() => _reminderTime = null);
                      },
                    )
                  : null,
            ),
            if (_movements.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(l10n.movementHistory, style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              ..._movements.take(15).map((mov) {
                final isPrise = mov.type == StockMovementType.prise;
                return ListTile(
                  dense: true,
                  leading: Icon(
                    isPrise ? Icons.remove_circle_outline : Icons.add_circle_outline,
                    color: isPrise ? theme.colorScheme.error : theme.colorScheme.primary,
                  ),
                  title: Text(isPrise ? '${l10n.taken} : ${mov.quantite}' : '${l10n.added} : +${mov.quantite}'),
                  subtitle: Text(DateFormat('dd/MM/yyyy HH:mm', 'fr').format(mov.date)),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}
