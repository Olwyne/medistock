import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/family_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/medication_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/shopping_provider.dart';
import '../providers/theme_provider.dart';
import '../services/backup_service.dart';
import '../data/firestore_repository.dart';
import '../services/pdf_export_service.dart';
import '../theme/cocon_theme.dart';
import '../widgets/cocon/cocon.dart';
import 'stats_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: CoconColors.bg,
      body: Column(
        children: [
          CoconScreenHeader(title: l10n.settingsTitle, onBack: () => Navigator.of(context).pop()),
          Expanded(
            child: FutureBuilder<void>(
              future: context.read<SettingsProvider>().load(),
              builder: (context, _) {
                return Consumer6<AuthProvider, SettingsProvider, LocaleProvider, ThemeProvider, FamilyProvider, MedicationProvider>(
                  builder: (context, authProvider, settings, localeProvider, themeProvider, familyProvider, medicationProvider, _) {
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
                      children: [
                        _SectionLabel(l10n.signIn),
                        _GroupCard(children: [
                          _SettingsRow(
                            icon: Icons.account_circle_outlined,
                            title: authProvider.userName?.isNotEmpty == true ? authProvider.userName! : (authProvider.userEmail ?? 'Compte'),
                            subtitle: authProvider.userName?.isNotEmpty == true ? authProvider.userEmail : l10n.accountSynced,
                            onTap: () => _showEditNameDialog(context, authProvider),
                          ),
                          _SettingsRow(
                            icon: Icons.logout,
                            iconColor: CoconColors.status[MedStatus.perime]!.fg,
                            iconBg: CoconColors.status[MedStatus.perime]!.bg,
                            title: l10n.signOut,
                            danger: true,
                            onTap: () async => authProvider.signOut(),
                            last: true,
                          ),
                        ]),
                        const SizedBox(height: 20),
                        _SectionLabel(l10n.theme),
                        _GroupCard(children: [
                          _SettingsRow(
                            icon: Icons.language,
                            title: l10n.language,
                            subtitle: localeProvider.locale == null
                                ? '${l10n.french} / ${l10n.english}'
                                : localeProvider.locale!.languageCode == 'fr'
                                    ? l10n.french
                                    : l10n.english,
                            onTap: () => _showLanguagePicker(context, localeProvider),
                          ),
                          _SettingsRow(
                            icon: Icons.calendar_today_outlined,
                            title: l10n.firstDayOfWeek,
                            subtitle: settings.firstDayOfWeek == 0 ? l10n.sunday : l10n.monday,
                            onTap: () => _showFirstDayPicker(context, settings),
                          ),
                          _SettingsRow(
                            icon: Icons.volume_up_outlined,
                            title: l10n.scanSound,
                            trailing: Switch(value: settings.scanSound, onChanged: (v) => settings.setScanSound(v)),
                          ),
                          _SettingsRow(
                            icon: Icons.brightness_6_outlined,
                            title: l10n.theme,
                            subtitle: themeProvider.themeMode == ThemeMode.system
                                ? l10n.themeSystem
                                : themeProvider.themeMode == ThemeMode.light
                                    ? l10n.themeLight
                                    : l10n.themeDark,
                            onTap: () => _showThemePicker(context, themeProvider),
                            last: true,
                          ),
                        ]),
                        const SizedBox(height: 20),
                        _SectionLabel(l10n.household),
                        _GroupCard(children: [
                          _SettingsRow(icon: Icons.people_outline, title: l10n.family, onTap: () => _showFamilySection(context, familyProvider)),
                          _SettingsRow(icon: Icons.place_outlined, title: l10n.places, onTap: () => _showPlacesSection(context, familyProvider)),
                          _SettingsRow(icon: Icons.health_and_safety_outlined, title: l10n.health, subtitle: l10n.allergies, onTap: () => _showHealthSection(context, familyProvider)),
                          _SettingsRow(
                            icon: Icons.bar_chart_outlined,
                            title: l10n.statsTitle,
                            last: true,
                            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StatsScreen())),
                          ),
                        ]),
                        const SizedBox(height: 20),
                        _SectionLabel(l10n.backupRestore),
                        _GroupCard(children: [
                          _SettingsRow(icon: Icons.save_alt_outlined, title: l10n.backup, onTap: () => _doBackup(context, authProvider.currentFamilyId)),
                          _SettingsRow(icon: Icons.restore_outlined, title: l10n.restore, onTap: () => _doRestore(context, authProvider.currentFamilyId)),
                          _SettingsRow(icon: Icons.picture_as_pdf_outlined, title: l10n.exportPdfDoctor, last: true, onTap: () => _doExportPdf(context, medicationProvider, familyProvider)),
                        ]),
                        const SizedBox(height: 20),
                        Center(child: Text('Medistock · version 1.0.0', style: const TextStyle(color: CoconColors.muted, fontWeight: FontWeight.w600, fontSize: 12))),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditNameDialog(BuildContext context, AuthProvider authProvider) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: authProvider.userName ?? '');
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Prénom'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Prénom'),
          onSubmitted: (_) => Navigator.pop(ctx, controller.text.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: Text(l10n.save)),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      await authProvider.updateDisplayName(name);
    }
  }

  void _showHealthSection(BuildContext context, FamilyProvider familyProvider) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => _AllergiesScreen(familyProvider: familyProvider),
      ),
    );
  }

  void _showFamilySection(BuildContext context, FamilyProvider familyProvider) async {
    final l10n = AppLocalizations.of(context);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => Scaffold(
          appBar: AppBar(
            title: Text(l10n.family),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () async {
                  final name = await showDialog<String>(
                    context: ctx,
                    builder: (c) {
                      final controller = TextEditingController();
                      return AlertDialog(
                        title: Text(l10n.family),
                        content: TextField(
                          controller: controller,
                          decoration: InputDecoration(
                            labelText: l10n.medicationName,
                            hintText: 'Papa, Maman...',
                          ),
                          autofocus: true,
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(c),
                            child: Text(l10n.cancel),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(c, controller.text.trim()),
                            child: Text(l10n.add),
                          ),
                        ],
                      );
                    },
                  );
                  if (name != null && name.isNotEmpty) {
                    await familyProvider.addMember(name);
                  }
                },
              ),
            ],
          ),
          body: Consumer<FamilyProvider>(
            builder: (context, familyProvider, _) => ListView.builder(
              itemCount: familyProvider.members.length,
              itemBuilder: (context, i) {
                final m = familyProvider.members[i];
                return ListTile(
                  title: Text(m.name),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: Text(l10n.deleteConfirm),
                          content: Text('${m.name} ?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(c, false),
                              child: Text(l10n.cancel),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(c, true),
                              child: Text(l10n.delete),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) await familyProvider.deleteMember(m.id);
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _showPlacesSection(BuildContext context, FamilyProvider familyProvider) async {
    final l10n = AppLocalizations.of(context);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => Scaffold(
          appBar: AppBar(
            title: Text(l10n.places),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () async {
                  final name = await showDialog<String>(
                    context: ctx,
                    builder: (c) {
                      final controller = TextEditingController();
                      return AlertDialog(
                        title: Text(l10n.places),
                        content: TextField(
                          controller: controller,
                          decoration: InputDecoration(
                            labelText: l10n.placeStorage,
                            hintText: l10n.placeStorageHint,
                          ),
                          autofocus: true,
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(c),
                            child: Text(l10n.cancel),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(c, controller.text.trim()),
                            child: Text(l10n.add),
                          ),
                        ],
                      );
                    },
                  );
                  if (name != null && name.isNotEmpty) {
                    await familyProvider.addPlace(name);
                  }
                },
              ),
            ],
          ),
          body: Consumer<FamilyProvider>(
            builder: (context, familyProvider, _) => ListView.builder(
              itemCount: familyProvider.places.length,
              itemBuilder: (context, i) {
                final p = familyProvider.places[i];
                return ListTile(
                  title: Text(p.name),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: Text(l10n.deleteConfirm),
                          content: Text('${p.name} ?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(c, false),
                              child: Text(l10n.cancel),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(c, true),
                              child: Text(l10n.delete),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) await familyProvider.deletePlace(p.id);
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, LocaleProvider localeProvider) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(l10n.french),
              onTap: () {
                localeProvider.setLocale(const Locale('fr'));
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: Text(l10n.english),
              onTap: () {
                localeProvider.setLocale(const Locale('en'));
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('System'),
              onTap: () {
                localeProvider.setLocale(null);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showFirstDayPicker(BuildContext context, SettingsProvider settings) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(l10n.sunday),
              onTap: () {
                settings.setFirstDayOfWeek(0);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: Text(l10n.monday),
              onTap: () {
                settings.setFirstDayOfWeek(1);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showThemePicker(BuildContext context, ThemeProvider themeProvider) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(l10n.themeSystem),
              onTap: () {
                themeProvider.themeMode = ThemeMode.system;
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: Text(l10n.themeLight),
              onTap: () {
                themeProvider.themeMode = ThemeMode.light;
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: Text(l10n.themeDark),
              onTap: () {
                themeProvider.themeMode = ThemeMode.dark;
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _doExportPdf(BuildContext context, MedicationProvider medicationProvider, FamilyProvider familyProvider) async {
    final l10n = AppLocalizations.of(context);
    try {
      final memberNameById = {for (final m in familyProvider.members) m.id: m.name};
      final path = await PdfExportService.generateInventoryPdf(
        medicationProvider.medications,
        memberNameById: memberNameById,
        onlyInStock: true,
      );
      await Share.shareXFiles([XFile(path)], text: l10n.exportPdfDoctor);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.backupSuccess), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> _doBackup(BuildContext context, String? familyId) async {
    final l10n = AppLocalizations.of(context);
    if (familyId == null) return;
    try {
      final path = await BackupService.exportToFile(familyId);
      await Share.shareXFiles([XFile(path)], text: l10n.shoppingTitle);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.backupSuccess), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> _doRestore(BuildContext context, String? familyId) async {
    final l10n = AppLocalizations.of(context);
    if (familyId == null) return;
    final result = await FilePicker.platform.pickFiles(type: FileType.any, allowMultiple: false);
    if (result == null || result.files.single.path == null) return;
    if (!context.mounted) return;
    final path = result.files.single.path!;
    try {
      final bytes = await File(path).readAsBytes();
      if (!context.mounted) return;
      final data = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      final err = BackupService.validateBackup(data);
      if (err != null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(err), behavior: SnackBarBehavior.floating),
          );
        }
        return;
      }
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.restore),
          content: Text(l10n.restoreWarning),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.restore),
            ),
          ],
        ),
      );
      if (confirm != true || !context.mounted) return;
      final med = context.read<MedicationProvider>();
      final fam = context.read<FamilyProvider>();
      final shop = context.read<ShoppingProvider>();
      final settings = context.read<SettingsProvider>();
      final locale = context.read<LocaleProvider>();
      final messenger = ScaffoldMessenger.maybeOf(context);
      await BackupService.importFromMap(familyId, data);
      await med.load();
      await fam.load();
      await shop.load();
      await settings.load();
      await locale.load();
      messenger?.showSnackBar(
        SnackBar(content: Text(l10n.restoreSuccess), behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 9),
      child: Text(label.toUpperCase(), style: const TextStyle(color: CoconColors.muted, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.6)),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final List<Widget> children;
  const _GroupCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return SoftCard(padding: EdgeInsets.zero, child: Column(children: children));
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? iconColor;
  final Color? iconBg;
  final bool danger;
  final bool last;

  const _SettingsRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.iconColor,
    this.iconBg,
    this.danger = false,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(border: last ? null : const Border(bottom: BorderSide(color: CoconColors.line))),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(color: iconBg ?? CoconColors.sunk, borderRadius: BorderRadius.circular(10)),
                alignment: Alignment.center,
                child: Icon(icon, size: 19, color: iconColor ?? CoconColors.ink),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: danger ? CoconColors.status[MedStatus.perime]!.fg : CoconColors.ink)),
                    if (subtitle != null) Text(subtitle!, style: const TextStyle(color: CoconColors.muted, fontWeight: FontWeight.w600, fontSize: 12.5)),
                  ],
                ),
              ),
              trailing ?? (onTap != null ? const Icon(Icons.chevron_right, size: 18, color: CoconColors.muted) : const SizedBox.shrink()),
            ],
          ),
        ),
      ),
    );
  }
}

class _AllergiesScreen extends StatefulWidget {
  final FamilyProvider familyProvider;

  const _AllergiesScreen({required this.familyProvider});

  @override
  State<_AllergiesScreen> createState() => _AllergiesScreenState();
}

class _AllergiesScreenState extends State<_AllergiesScreen> {
  List<Map<String, dynamic>> _allergies = [];
  bool _loadStarted = false;

  Future<void> _load(String? familyId) async {
    if (familyId == null) return;
    final list = await FirestoreRepository.getAllergies(familyId);
    if (mounted) setState(() => _allergies = list);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loadStarted && mounted) {
      _loadStarted = true;
      final familyId = context.read<AuthProvider>().currentFamilyId;
      _load(familyId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.allergies),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final controller = TextEditingController();
              String? selectedMemberId;
              final result = await showDialog<bool>(
                context: context,
                builder: (ctx) => StatefulBuilder(
                  builder: (ctx, setDialogState) => AlertDialog(
                    title: Text(l10n.allergies),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: controller,
                          decoration: InputDecoration(
                            labelText: l10n.allergies,
                            hintText: 'Ex: Pénicilline',
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        if (widget.familyProvider.members.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String?>(
                            value: selectedMemberId,
                            decoration: InputDecoration(
                              labelText: l10n.family,
                            ),
                            items: [
                              const DropdownMenuItem<String?>(value: null, child: Text('–')),
                              ...widget.familyProvider.members.map(
                                (m) => DropdownMenuItem<String?>(value: m.id, child: Text(m.name)),
                              ),
                            ],
                            onChanged: (v) => setDialogState(() => selectedMemberId = v),
                          ),
                        ],
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(l10n.cancel),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(l10n.add),
                      ),
                    ],
                  ),
                ),
              );
              if (result == true && controller.text.trim().isNotEmpty) {
                final familyId = context.read<AuthProvider>().currentFamilyId;
                if (familyId != null) {
                  await FirestoreRepository.insertAllergy(
                    familyId,
                    memberId: selectedMemberId,
                    allergyText: controller.text.trim(),
                  );
                  if (context.mounted) await _load(familyId);
                }
              }
            },
          ),
        ],
      ),
      body: _allergies.isEmpty
          ? Center(child: Text(l10n.shoppingEmpty, style: theme.textTheme.bodyLarge))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _allergies.length,
              itemBuilder: (context, i) {
                final a = _allergies[i];
                final id = a['id'] as String;
                final text = a['allergy_text'] as String? ?? '';
                final memberId = a['member_id'] as String?;
                final memberName = memberId != null
                    ? widget.familyProvider.members.where((m) => m.id == memberId).map((m) => m.name).join(', ')
                    : '';
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(text),
                    subtitle: memberName.isNotEmpty ? Text(memberName) : null,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        final familyId = context.read<AuthProvider>().currentFamilyId;
                        if (familyId != null) {
                          await FirestoreRepository.deleteAllergy(familyId, id);
                          if (context.mounted) await _load(familyId);
                        }
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}
