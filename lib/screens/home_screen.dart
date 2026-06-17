import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/family_provider.dart';
import '../providers/medication_provider.dart';
import '../providers/shopping_provider.dart';
import '../services/reminder_service.dart';
import '../theme/cocon_theme.dart';
import '../widgets/cocon/cocon.dart';
import 'add_medication_screen.dart';
import 'alertes_screen.dart';
import 'dashboard_screen.dart';
import 'inventaire_screen.dart';
import 'scan_screen.dart';
import 'settings_screen.dart';
import 'shopping_screen.dart';

const _desktopBreakpoint = 760.0;

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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _rescheduleReminders();
      final auth = context.read<AuthProvider>();
      final medicationProvider = context.read<MedicationProvider>();
      final familyProvider = context.read<FamilyProvider>();
      final shoppingProvider = context.read<ShoppingProvider>();
      final familyId = auth.currentFamilyId;
      if (familyId != null) {
        await medicationProvider.loadWithSync(familyId);
        if (!mounted) return;
        await familyProvider.load();
        if (!mounted) return;
        await shoppingProvider.load();
      }
    });
  }

  Future<void> _rescheduleReminders() async {
    final context = this.context;
    if (!context.mounted) return;
    final provider = context.read<MedicationProvider>();
    final reminders = await ReminderService.getAllReminders();
    if (reminders.isEmpty) return;
    final items = <({String id, String name, String time})>[];
    for (final e in reminders.entries) {
      final med = await provider.getById(e.key);
      if (med != null) items.add((id: e.key, name: med.nom, time: e.value));
    }
    if (items.isNotEmpty) await ReminderService.rescheduleAll(items);
  }

  void _goTo(int i) => setState(() => _index = i);

  void _openScan() {
    // Le scan caméra repose sur l'API navigateur BarcodeDetector, non supportée sur
    // le web (PWA) -> on saute direct à la saisie manuelle plutôt que sur un écran
    // de scan qui ne détectera jamais rien.
    final screen = kIsWeb ? const AddMedicationScreen() : const ScanScreen();
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  List<Widget> _screens() => [
        DashboardScreen(onNavigate: _goTo),
        const InventaireScreen(),
        const AlertesScreen(),
        const ShoppingScreen(),
      ];

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= _desktopBreakpoint;
    final screens = _screens();
    if (wide) {
      return Scaffold(
        backgroundColor: CoconColors.bg,
        body: Row(
          children: [
            _Sidebar(index: _index, onSelect: _goTo, onAdd: _openScan),
            Expanded(child: screens[_index]),
          ],
        ),
      );
    }
    return Scaffold(
      backgroundColor: CoconColors.bg,
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: _MobileTabBar(index: _index, onSelect: _goTo, onAdd: _openScan),
    );
  }
}

class _MobileTabBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onSelect;
  final VoidCallback onAdd;

  const _MobileTabBar({required this.index, required this.onSelect, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final alertCount = context.watch<MedicationProvider>().perimes.length + context.watch<MedicationProvider>().bientotPerimes.length;
    final items = [
      (Icons.home_outlined, Icons.home, l10n.homeTitle),
      (Icons.medication_outlined, Icons.medication, l10n.inventaireTitle),
      (Icons.notifications_outlined, Icons.notifications, l10n.alertesTitle),
      (Icons.shopping_cart_outlined, Icons.shopping_cart, l10n.shoppingTitle),
    ];
    return Container(
      decoration: const BoxDecoration(
        color: CoconColors.surface,
        border: Border(top: BorderSide(color: CoconColors.line)),
      ),
      padding: EdgeInsets.fromLTRB(8, 11, 8, 8 + MediaQuery.of(context).padding.bottom),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < 2; i++) _TabItem(item: items[i], selected: index == i, onTap: () => onSelect(i), badge: i == 2 ? alertCount : null),
          _CenterAddButton(onTap: onAdd),
          for (var i = 2; i < items.length; i++) _TabItem(item: items[i], selected: index == i, onTap: () => onSelect(i), badge: i == 2 ? alertCount : null),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final (IconData, IconData, String) item;
  final bool selected;
  final VoidCallback onTap;
  final int? badge;

  const _TabItem({required this.item, required this.selected, required this.onTap, this.badge});

  @override
  Widget build(BuildContext context) {
    final color = selected ? CoconColors.accent : CoconColors.muted;
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 64,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(selected ? item.$2 : item.$1, size: 23, color: color),
                const SizedBox(height: 4),
                Text(item.$3, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10.5, color: color), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
            if (badge != null && badge! > 0)
              Positioned(
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  decoration: BoxDecoration(
                    color: CoconColors.status[MedStatus.perime]!.fg,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: CoconColors.surface, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Text('$badge', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 10)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CenterAddButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CenterAddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 0),
      child: Material(
        color: CoconColors.accent,
        shape: const CircleBorder(side: BorderSide(color: CoconColors.surface, width: 4)),
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: const SizedBox(width: 54, height: 54, child: Icon(Icons.add, color: Colors.white, size: 26)),
        ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onSelect;
  final VoidCallback onAdd;

  const _Sidebar({required this.index, required this.onSelect, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final family = context.watch<FamilyProvider>();
    final items = [
      (Icons.home_outlined, l10n.homeTitle),
      (Icons.medication_outlined, l10n.inventaireTitle),
      (Icons.notifications_outlined, l10n.alertesTitle),
      (Icons.shopping_cart_outlined, l10n.shoppingTitle),
    ];
    return Container(
      width: 232,
      decoration: const BoxDecoration(
        color: CoconColors.surface,
        border: Border(right: BorderSide(color: CoconColors.line)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: CoconColors.accent,
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [BoxShadow(color: CoconColors.accent.withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 6))],
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.medication_liquid, color: Colors.white, size: 21),
              ),
              const SizedBox(width: 11),
              const Text('Medistock', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 21, letterSpacing: -0.3, color: CoconColors.ink)),
            ],
          ),
          const SizedBox(height: 28),
          for (var i = 0; i < items.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: _SidebarItem(icon: items[i].$1, label: items[i].$2, active: index == i, onTap: () => onSelect(i)),
            ),
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: _SidebarItem(icon: Icons.add_circle_outline, label: l10n.add, active: false, onTap: onAdd),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
            child: Container(
              decoration: BoxDecoration(color: CoconColors.sunk, borderRadius: BorderRadius.circular(18)),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.household.toUpperCase(), style: const TextStyle(color: CoconColors.muted, fontWeight: FontWeight.w700, fontSize: 12.5, letterSpacing: 0.6)),
                  const SizedBox(height: 10),
                  if (family.members.isEmpty)
                    Row(
                      children: [
                        const Icon(Icons.settings_outlined, size: 18, color: CoconColors.muted),
                        const SizedBox(width: 8),
                        Text(l10n.settingsTitle, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: CoconColors.muted)),
                      ],
                    )
                  else
                    SizedBox(
                      width: 30.0 + (family.members.length - 1) * 22.0,
                      height: 30,
                      child: Stack(
                        children: [
                          for (var i = 0; i < family.members.length; i++)
                            Positioned(left: i * 22.0, child: MemberAvatar(name: family.members[i].name, seed: family.members[i].id, size: 30, borderColor: CoconColors.sunk)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _SidebarItem({required this.icon, required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? CoconColors.accentSoft : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            children: [
              Icon(icon, size: 20, color: active ? CoconColors.accent : CoconColors.muted),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(fontWeight: active ? FontWeight.w700 : FontWeight.w600, fontSize: 15.5, color: active ? CoconColors.accent : CoconColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
