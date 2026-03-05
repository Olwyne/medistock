import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
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
import '../data/database.dart';
import '../services/pdf_export_service.dart';
import 'stats_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
      ),
      body: FutureBuilder<void>(
        future: context.read<SettingsProvider>().load(),
        builder: (context, _) {
          return Consumer6<AuthProvider, SettingsProvider, LocaleProvider, ThemeProvider, FamilyProvider, MedicationProvider>(
            builder: (context, authProvider, settings, localeProvider, themeProvider, familyProvider, medicationProvider, _) {
              return ListView(
                children: [
                  if (authProvider.isConfigured && authProvider.isSignedIn) ...[
                    ListTile(
                      leading: const Icon(Icons.account_circle),
                      title: Text(authProvider.userEmail ?? 'Compte'),
                      subtitle: const Text('Foyer synchronisé'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.logout),
                      title: const Text('Déconnexion'),
                      onTap: () async {
                        await authProvider.signOut();
                      },
                    ),
                    const Divider(),
                  ],
                  ListTile(
                    leading: const Icon(Icons.language),
                    title: Text(l10n.language),
                    subtitle: Text(
                      localeProvider.locale == null
                          ? '${l10n.french} / ${l10n.english}'
                          : localeProvider.locale!.languageCode == 'fr'
                              ? l10n.french
                              : l10n.english,
                    ),
                    onTap: () => _showLanguagePicker(context, localeProvider),
                  ),
                  ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: Text(l10n.firstDayOfWeek),
                    subtitle: Text(
                      settings.firstDayOfWeek == 0 ? l10n.sunday : l10n.monday,
                    ),
                    onTap: () => _showFirstDayPicker(context, settings),
                  ),
                  SwitchListTile(
                    secondary: const Icon(Icons.volume_up),
                    title: Text(l10n.scanSound),
                    value: settings.scanSound,
                    onChanged: (v) => settings.setScanSound(v),
                  ),
                  ListTile(
                    leading: const Icon(Icons.brightness_6),
                    title: Text(l10n.theme),
                    subtitle: Text(
                      themeProvider.themeMode == ThemeMode.system
                          ? l10n.themeSystem
                          : themeProvider.themeMode == ThemeMode.light
                              ? l10n.themeLight
                              : l10n.themeDark,
                    ),
                    onTap: () => _showThemePicker(context, themeProvider),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.people),
                    title: Text(l10n.family),
                    onTap: () => _showFamilySection(context, familyProvider),
                  ),
                  ListTile(
                    leading: const Icon(Icons.place),
                    title: Text(l10n.places),
                    onTap: () => _showPlacesSection(context, familyProvider),
                  ),
                  if (!kIsWeb) ...[
                    ListTile(
                      leading: const Icon(Icons.health_and_safety_outlined),
                      title: Text(l10n.health),
                      subtitle: Text(l10n.allergies),
                      onTap: () => _showHealthSection(context, familyProvider),
                    ),
                  ],
                  ListTile(
                    leading: const Icon(Icons.bar_chart),
                    title: Text(l10n.statsTitle),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const StatsScreen()),
                    ),
                  ),
                  if (!kIsWeb) ...[
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.save_alt),
                      title: Text(l10n.backup),
                      onTap: () => _doBackup(context),
                    ),
                    ListTile(
                      leading: const Icon(Icons.restore),
                      title: Text(l10n.restore),
                      onTap: () => _doRestore(context),
                    ),
                    ListTile(
                      leading: const Icon(Icons.picture_as_pdf),
                      title: Text(l10n.exportPdfDoctor),
                      onTap: () => _doExportPdf(context, medicationProvider, familyProvider),
                    ),
                  ],
                ],
              );
            },
          );
        },
      ),
    );
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
          body: ListView.builder(
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
    );
    familyProvider.load();
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
          body: ListView.builder(
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
    );
    familyProvider.load();
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

  Future<void> _doBackup(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    try {
      final path = await BackupService.exportToFile();
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

  Future<void> _doRestore(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
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
      await BackupService.importFromMap(data);
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
    final list = await AppDatabase.getAllergies(familyId: familyId);
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
              int? selectedMemberId;
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
                          DropdownButtonFormField<int?>(
                            value: selectedMemberId,
                            decoration: InputDecoration(
                              labelText: l10n.family,
                              border: const OutlineInputBorder(),
                            ),
                            items: [
                              const DropdownMenuItem<int?>(value: null, child: Text('–')),
                              ...widget.familyProvider.members.map(
                                (m) => DropdownMenuItem<int?>(value: m.id, child: Text(m.name)),
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
                await AppDatabase.insertAllergy(
                  memberId: selectedMemberId,
                  allergyText: controller.text.trim(),
                  familyId: familyId,
                );
                if (context.mounted) await _load(familyId);
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
                final id = a['id'] as int;
                final text = a['allergy_text'] as String? ?? '';
                final memberId = a['member_id'] as int?;
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
                        await AppDatabase.deleteAllergy(id);
                        if (context.mounted) await _load(familyId);
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}
