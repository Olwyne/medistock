import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/medication_provider.dart';
import '../services/reminder_service.dart';
import 'inventaire_screen.dart';
import 'scan_screen.dart';
import 'alertes_screen.dart';
import 'settings_screen.dart';
import 'shopping_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _rescheduleReminders());
  }

  Future<void> _rescheduleReminders() async {
    final context = this.context;
    if (!context.mounted) return;
    final provider = context.read<MedicationProvider>();
    final reminders = await ReminderService.getAllReminders();
    if (reminders.isEmpty) return;
    final items = <({int id, String name, String time})>[];
    for (final e in reminders.entries) {
      final id = int.tryParse(e.key);
      if (id == null) continue;
      final med = await provider.getById(id);
      if (med != null) items.add((id: id, name: med.nom, time: e.value));
    }
    if (items.isNotEmpty) await ReminderService.rescheduleAll(items);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final screens = [
      const InventaireScreen(),
      const ScanScreen(),
      const AlertesScreen(),
      const ShoppingScreen(),
      const SettingsScreen(),
    ];
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.medication_liquid_outlined),
            selectedIcon: const Icon(Icons.medication_liquid),
            label: l10n.inventaireTitle,
          ),
          NavigationDestination(
            icon: const Icon(Icons.qr_code_scanner_outlined),
            selectedIcon: const Icon(Icons.qr_code_scanner),
            label: l10n.scannerTitle,
          ),
          NavigationDestination(
            icon: const Icon(Icons.notifications_outlined),
            selectedIcon: const Icon(Icons.notifications),
            label: l10n.alertesTitle,
          ),
          NavigationDestination(
            icon: const Icon(Icons.shopping_cart_outlined),
            selectedIcon: const Icon(Icons.shopping_cart),
            label: l10n.shoppingTitle,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l10n.settingsTitle,
          ),
        ],
      ),
    );
  }
}
