import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/cocon_theme.dart';

class FamilyChoiceScreen extends StatefulWidget {
  const FamilyChoiceScreen({super.key});

  @override
  State<FamilyChoiceScreen> createState() => _FamilyChoiceScreenState();
}

class _FamilyChoiceScreenState extends State<FamilyChoiceScreen> {
  bool _isCreate = true;
  final _nameController = TextEditingController();
  final _joinIdController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _joinIdController.dispose();
    super.dispose();
  }

  Future<void> _createFamily() async {
    _error = null;
    setState(() => _loading = true);
    try {
      await context.read<AuthProvider>().createFamily(
            name: _nameController.text.trim().isEmpty
                ? null
                : _nameController.text.trim(),
          );
      if (!mounted) return;
    } catch (e) {
      setState(() => _error = e.toString());
      return;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _joinFamily() async {
    final id = _joinIdController.text.trim();
    if (id.isEmpty) {
      setState(() => _error = 'Indiquez l\'ID de la famille');
      return;
    }
    _error = null;
    setState(() => _loading = true);
    try {
      await context.read<AuthProvider>().joinFamily(id);
      if (!mounted) return;
    } catch (e) {
      setState(() => _error = e.toString());
      return;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: CoconColors.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Choisissez un foyer',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Créez un nouveau foyer ou rejoignez-en un avec l\'ID partagé.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: true, label: Text('Créer')),
                    ButtonSegment(value: false, label: Text('Rejoindre')),
                  ],
                  selected: {_isCreate},
                  onSelectionChanged: (s) => setState(() {
                    _isCreate = s.first;
                    _error = null;
                  }),
                ),
                const SizedBox(height: 24),
                if (_isCreate) ...[
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nom du foyer (optionnel)',
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _loading ? null : _createFamily,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Créer le foyer'),
                  ),
                ] else ...[
                  TextField(
                    controller: _joinIdController,
                    decoration: const InputDecoration(
                      labelText: 'ID du foyer (UUID)',
                      hintText: 'Ex: 123e4567-e89b-12d3-a456-426614174000',
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _loading ? null : _joinFamily,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Rejoindre le foyer'),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
