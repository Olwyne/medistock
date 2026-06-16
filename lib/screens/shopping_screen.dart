import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../l10n/app_localizations.dart';
import '../models/shopping_item.dart';
import '../providers/medication_provider.dart';
import '../providers/shopping_provider.dart';
import '../theme/cocon_theme.dart';
import '../widgets/cocon/cocon.dart';

class ShoppingScreen extends StatefulWidget {
  const ShoppingScreen({super.key});

  @override
  State<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends State<ShoppingScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: CoconColors.bg,
      body: Consumer<ShoppingProvider>(
        builder: (context, shopping, _) {
          final remaining = shopping.items.where((i) => !i.checked).length;
          return Column(
            children: [
              CoconScreenHeader(
                title: l10n.shoppingTitle,
                eyebrow: '$remaining ${l10n.toReorder.toLowerCase()}',
                trailing: shopping.items.isEmpty
                    ? null
                    : RoundIconButton(
                        icon: Icons.share_outlined,
                        onTap: () {
                          final text = shopping.shareableText();
                          if (text.isNotEmpty) Share.share(text, subject: l10n.shoppingTitle);
                        },
                      ),
              ),
              Expanded(
                child: shopping.items.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.shopping_basket_outlined, size: 72, color: CoconColors.muted),
                              const SizedBox(height: 16),
                              Text(l10n.shoppingEmpty, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: CoconColors.ink)),
                              const SizedBox(height: 22),
                              PrimaryButton(label: l10n.shoppingAddFromAlerts, icon: Icons.notifications_outlined, onPressed: () => _addFromAlerts(context), full: false),
                              const SizedBox(height: 11),
                              OutlinedButton.icon(onPressed: () => _addItem(context), icon: const Icon(Icons.add, size: 18), label: Text(l10n.shoppingAddItem)),
                            ],
                          ),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 26),
                        children: [
                          Row(
                            children: [
                              Expanded(child: PrimaryButton(label: l10n.shoppingAddFromAlerts, icon: Icons.notifications_outlined, onPressed: () => _addFromAlerts(context), full: false)),
                              const SizedBox(width: 11),
                              OutlinedButton.icon(onPressed: () => _addItem(context), icon: const Icon(Icons.add, size: 18), label: Text(l10n.shoppingAddItem)),
                            ],
                          ),
                          const SizedBox(height: 20),
                          SoftCard(
                            padding: EdgeInsets.zero,
                            child: Column(
                              children: [
                                for (var i = 0; i < shopping.items.length; i++)
                                  _ShoppingTile(
                                    item: shopping.items[i],
                                    showDivider: i < shopping.items.length - 1,
                                    onToggle: () => shopping.toggleChecked(shopping.items[i]),
                                    onDelete: shopping.items[i].id != null ? () => shopping.deleteItem(shopping.items[i].id!) : null,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _addFromAlerts(BuildContext context) async {
    final medicationProvider = context.read<MedicationProvider>();
    final shoppingProvider = context.read<ShoppingProvider>();
    final all = [
      ...medicationProvider.bientotPerimes,
      ...medicationProvider.perimes,
      ...medicationProvider.stockFaible,
    ];
    await shoppingProvider.addFromMedications(all);
    if (context.mounted) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.shoppingListUpdated), behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _addItem(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.shoppingAddItem),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: l10n.medicationName),
          autofocus: true,
          onSubmitted: (_) => Navigator.of(ctx).pop(true),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(l10n.add)),
        ],
      ),
    );
    if (result == true && controller.text.trim().isNotEmpty && context.mounted) {
      await context.read<ShoppingProvider>().addItem(label: controller.text.trim());
    }
  }
}

class _ShoppingTile extends StatelessWidget {
  final ShoppingItem item;
  final bool showDivider;
  final VoidCallback onToggle;
  final VoidCallback? onDelete;

  const _ShoppingTile({required this.item, required this.showDivider, required this.onToggle, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Opacity(
              opacity: item.checked ? 0.55 : 1,
              child: Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: item.checked ? CoconColors.sage : Colors.transparent,
                      border: Border.all(color: item.checked ? CoconColors.sage : CoconColors.line, width: 2),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    alignment: Alignment.center,
                    child: item.checked ? const Icon(Icons.check, size: 15, color: Colors.white) : null,
                  ),
                  const SizedBox(width: 13),
                  const CatAvatar(size: 40),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Text(
                      item.label,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                        decoration: item.checked ? TextDecoration.lineThrough : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (onDelete != null)
                    IconButton(icon: const Icon(Icons.close, size: 18, color: CoconColors.muted), onPressed: onDelete),
                ],
              ),
            ),
          ),
        ),
        if (showDivider) const Divider(height: 1),
      ],
    );
  }
}
