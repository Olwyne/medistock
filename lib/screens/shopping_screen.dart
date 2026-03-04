import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../l10n/app_localizations.dart';
import '../models/shopping_item.dart';
import '../providers/medication_provider.dart';
import '../providers/shopping_provider.dart';

class ShoppingScreen extends StatefulWidget {
  const ShoppingScreen({super.key});

  @override
  State<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends State<ShoppingScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.shoppingTitle),
        actions: [
          Consumer<ShoppingProvider>(
            builder: (context, shopping, _) {
              if (shopping.items.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.share),
                onPressed: () {
                  final text = shopping.shareableText();
                  if (text.isNotEmpty) Share.share(text, subject: l10n.shoppingTitle);
                },
              );
            },
          ),
        ],
      ),
      body: Consumer<ShoppingProvider>(
        builder: (context, shopping, _) {
          if (shopping.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 80, color: theme.colorScheme.outline),
                  const SizedBox(height: 16),
                  Text(l10n.shoppingEmpty, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 24),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: () => _addFromAlerts(context),
                        icon: const Icon(Icons.notifications_outlined),
                        label: Text(l10n.shoppingAddFromAlerts),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _addItem(context),
                        icon: const Icon(Icons.add),
                        label: Text(l10n.shoppingAddItem),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _addFromAlerts(context),
                        icon: const Icon(Icons.notifications_outlined, size: 20),
                        label: Text(l10n.shoppingAddFromAlerts),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _addItem(context),
                        icon: const Icon(Icons.add, size: 20),
                        label: Text(l10n.shoppingAddItem),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: shopping.items.length,
                  itemBuilder: (context, i) {
                    final item = shopping.items[i];
                    return _ShoppingTile(
                      item: item,
                      onToggle: () => shopping.toggleChecked(item),
                      onDelete: item.id != null ? () => shopping.deleteItem(item.id!) : null,
                    );
                  },
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
        SnackBar(
          content: Text(l10n.shoppingListUpdated),
          behavior: SnackBarBehavior.floating,
        ),
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
          decoration: InputDecoration(
            labelText: l10n.medicationName,
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
          onSubmitted: (_) => Navigator.of(ctx).pop(true),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.add),
          ),
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
  final VoidCallback onToggle;
  final VoidCallback? onDelete;

  const _ShoppingTile({
    required this.item,
    required this.onToggle,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Checkbox(
          value: item.checked,
          onChanged: (_) => onToggle(),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        title: Text(
          item.label,
          style: item.checked
              ? theme.textTheme.bodyLarge?.copyWith(
                  decoration: TextDecoration.lineThrough,
                  color: theme.colorScheme.outline,
                )
              : null,
        ),
        trailing: onDelete != null
            ? IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: onDelete,
              )
            : null,
        onTap: onToggle,
      ),
    );
  }
}
