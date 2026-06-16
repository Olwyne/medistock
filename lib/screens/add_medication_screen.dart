import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/medication.dart';
import '../models/medication_units.dart';
import '../providers/auth_provider.dart';
import '../providers/family_provider.dart';
import '../providers/medication_provider.dart';
import '../services/interactions_service.dart';
import '../services/medication_api_service.dart';
import '../theme/cocon_theme.dart';
import '../widgets/cocon/cocon.dart';

class AddMedicationScreen extends StatefulWidget {
  final String? codeScanned;
  final String? suggestedName;
  final String? suggestedForme;
  final String? suggestedUnite;
  final int? suggestedQuantiteParUnite;
  final String? noticeUrl;
  final Medication? editing;

  const AddMedicationScreen({
    super.key,
    this.codeScanned,
    this.suggestedName,
    this.suggestedForme,
    this.suggestedUnite,
    this.suggestedQuantiteParUnite,
    this.noticeUrl,
    this.editing,
  });

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomController;
  late TextEditingController _quantiteController;
  late TextEditingController _lieuController;
  late TextEditingController _seuilController;
  late TextEditingController _quantiteParUniteController;
  DateTime? _datePeremption;
  bool _saving = false;
  late String _unite;
  List<String> _memberIds = [];
  String? _photoPath;
  Timer? _nameDebounce;
  List<MedicationApiResult> _suggestions = [];
  bool _searchingName = false;

  bool get isEditing => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    _nomController = TextEditingController(text: e?.nom ?? widget.suggestedName ?? '');
    _nomController.addListener(_onNameChanged);
    _quantiteController = TextEditingController(text: e?.quantite.toString() ?? '1');
    // Unité : édition > API (suggestedUnite) > forme pharmaceutique > défaut
    final uniteFromApi = widget.suggestedUnite != null && MedicationUnits.all.contains(widget.suggestedUnite)
        ? widget.suggestedUnite!
        : MedicationUnits.suggestFromForme(widget.suggestedForme);
    final suggestedUnite = e?.unite ?? uniteFromApi;
    _unite = MedicationUnits.all.contains(suggestedUnite) ? suggestedUnite : MedicationUnits.plaquette;
    _lieuController = TextEditingController(text: e?.lieu ?? '');
    _seuilController = TextEditingController(text: e?.seuilAlerte.toString() ?? '0');
    _memberIds = List.of(e?.memberIds ?? const []);
    // Quantité par unité : édition > API (suggestedQuantiteParUnite) > vide
    final qteParUnite = e?.quantiteParUnite ?? widget.suggestedQuantiteParUnite;
    _quantiteParUniteController = TextEditingController(
      text: qteParUnite != null ? qteParUnite.toString() : '',
    );
    _datePeremption = e?.datePeremption;
    _photoPath = e?.photoPath;
  }

  @override
  void dispose() {
    _nameDebounce?.cancel();
    _nomController.dispose();
    _quantiteController.dispose();
    _lieuController.dispose();
    _seuilController.dispose();
    _quantiteParUniteController.dispose();
    super.dispose();
  }

  void _onNameChanged() {
    _nameDebounce?.cancel();
    final query = _nomController.text;
    if (query.trim().length < 3) {
      setState(() => _suggestions = []);
      return;
    }
    _nameDebounce = Timer(const Duration(milliseconds: 400), () async {
      setState(() => _searchingName = true);
      final results = await MedicationApiService().searchByName(query);
      if (!mounted) return;
      setState(() {
        _suggestions = results;
        _searchingName = false;
      });
    });
  }

  void _applySuggestion(MedicationApiResult r) {
    _nameDebounce?.cancel();
    _nomController.removeListener(_onNameChanged);
    _nomController.text = r.nom;
    _nomController.addListener(_onNameChanged);
    if (r.suggestedUnite != null && MedicationUnits.all.contains(r.suggestedUnite)) {
      setState(() => _unite = r.suggestedUnite!);
    }
    if (r.suggestedQuantiteParUnite != null) {
      _quantiteParUniteController.text = r.suggestedQuantiteParUnite.toString();
    }
    setState(() => _suggestions = []);
    FocusScope.of(context).unfocus();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final provider = context.read<MedicationProvider>();
    final code = widget.editing?.codeScanned ?? widget.codeScanned ?? '';
    final nom = _nomController.text.trim();
    if (nom.isEmpty) {
      setState(() => _saving = false);
      return;
    }
    final quantite = int.tryParse(_quantiteController.text) ?? 1;
    final unite = _unite;
    final quantiteParUnite = int.tryParse(_quantiteParUniteController.text);
    final lieu = _lieuController.text.trim().isEmpty ? null : _lieuController.text.trim();
    final seuil = int.tryParse(_seuilController.text) ?? 0;

    final familyId = context.read<AuthProvider>().currentFamilyId;
    final hasInteraction = await InteractionsService.hasPossibleInteraction(nom, familyId: familyId);
    if (hasInteraction && mounted) {
      final l10n = AppLocalizations.of(context);
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.health),
          content: Text(l10n.checkWithDoctor),
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
      );
      if (proceed != true) {
        setState(() => _saving = false);
        return;
      }
    }

    if (isEditing) {
      await provider.update(widget.editing!.copyWith(
        nom: nom,
        quantite: quantite,
        unite: unite,
        quantiteParUnite: quantiteParUnite,
        lieu: lieu,
        memberIds: _memberIds,
        datePeremption: _datePeremption,
        seuilAlerte: seuil,
        photoPath: _photoPath,
      ));
    } else {
      final familyId = context.read<AuthProvider>().currentFamilyId;
      await provider.add(
        Medication(
          codeScanned: code,
          nom: nom,
          quantite: quantite,
          unite: unite,
          quantiteParUnite: quantiteParUnite,
          lieu: lieu,
          memberIds: _memberIds,
          datePeremption: _datePeremption,
          seuilAlerte: seuil,
          noticeUrl: widget.noticeUrl,
          photoPath: _photoPath,
        ),
        familyId: familyId,
      );
    }
    if (mounted) {
      setState(() => _saving = false);
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final familyProvider = context.watch<FamilyProvider>();
    return Scaffold(
      backgroundColor: CoconColors.bg,
      body: Column(
        children: [
          CoconScreenHeader(
            title: isEditing ? l10n.editMedicationTitle : l10n.addMedicationTitle,
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
            TextFormField(
              controller: _nomController,
              decoration: InputDecoration(
                labelText: l10n.medicationName,
                hintText: l10n.medicationNameHint,
                suffixIcon: _searchingName
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : null,
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) => v?.trim().isEmpty ?? true ? l10n.required : null,
            ),
            if (_suggestions.isNotEmpty)
              SoftCard(
                padding: EdgeInsets.zero,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < _suggestions.length; i++)
                      InkWell(
                        onTap: () => _applySuggestion(_suggestions[i]),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                          decoration: BoxDecoration(
                            border: i < _suggestions.length - 1 ? const Border(bottom: BorderSide(color: CoconColors.line)) : null,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_suggestions[i].nom, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    if (_suggestions[i].formePharmaceutique != null)
                                      Text(_suggestions[i].formePharmaceutique!, style: const TextStyle(color: CoconColors.muted, fontWeight: FontWeight.w600, fontSize: 12)),
                                  ],
                                ),
                              ),
                              const Icon(Icons.north_west, size: 16, color: CoconColors.muted),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            if (_photoPath != null) ...[
              Semantics(
                label: l10n.medicationName,
                image: true,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(_photoPath!),
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => setState(() => _photoPath = null),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Supprimer la photo'),
              ),
            ] else
              Semantics(
                label: l10n.addPhoto,
                button: true,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final picker = ImagePicker();
                    final x = await picker.pickImage(source: ImageSource.gallery);
                    if (x == null || !mounted) return;
                    final dir = await getApplicationDocumentsDirectory();
                    final name = 'med_${DateTime.now().millisecondsSinceEpoch}.jpg';
                    final file = File('${dir.path}/$name');
                    await file.writeAsBytes(await x.readAsBytes());
                    if (mounted) setState(() => _photoPath = file.path);
                  },
                  icon: const Icon(Icons.add_photo_alternate),
                  label: Text(l10n.addPhoto),
                  style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _quantiteController,
                    decoration: InputDecoration(
                      labelText: l10n.quantity,
                          ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null || n < 0) return l10n.numberMin;
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: _unite,
                    decoration: InputDecoration(
                      labelText: l10n.unit,
                          ),
                    items: MedicationUnits.all
                        .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _unite = v);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _quantiteParUniteController,
              decoration: InputDecoration(
                labelText: l10n.quantityPerUnit,
                hintText: l10n.quantityPerUnitHint,
              ),
              keyboardType: TextInputType.number,
            ),
            if (familyProvider.members.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(l10n.forWhom, style: const TextStyle(color: CoconColors.muted, fontWeight: FontWeight.w800, fontSize: 12.5)),
              const SizedBox(height: 7),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: familyProvider.members.map((m) {
                  final selected = _memberIds.contains(m.id);
                  return FilterChip(
                    label: Text(m.name),
                    selected: selected,
                    onSelected: (v) => setState(() {
                      if (v) {
                        _memberIds.add(m.id);
                      } else {
                        _memberIds.remove(m.id);
                      }
                    }),
                  );
                }).toList(),
              ),
            ],
            if (familyProvider.places.isNotEmpty) ...[
              const SizedBox(height: 8),
              DropdownButtonFormField<String?>(
                value: familyProvider.places.any((p) => p.name == _lieuController.text.trim())
                    ? _lieuController.text.trim()
                    : null,
                decoration: InputDecoration(
                  labelText: l10n.place,
                  ),
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text('—')),
                  ...familyProvider.places.map(
                    (p) => DropdownMenuItem<String?>(value: p.name, child: Text(p.name)),
                  ),
                ],
                onChanged: (v) {
                  _lieuController.text = v ?? '';
                  setState(() {});
                },
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _lieuController,
              decoration: InputDecoration(
                labelText: l10n.placeStorage,
                hintText: l10n.placeStorageHint,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _seuilController,
              decoration: InputDecoration(
                labelText: l10n.alertStockMin,
                hintText: l10n.alertStockHint,
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(
                _datePeremption == null
                    ? l10n.expiryDate
                    : '${l10n.expiryOptional} : ${_datePeremption!.day}/${_datePeremption!.month}/${_datePeremption!.year}',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _datePeremption ?? DateTime.now().add(const Duration(days: 365)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 3650)),
                );
                if (date != null) setState(() => _datePeremption = date);
              },
            ),
            if (_datePeremption != null)
              TextButton(
                onPressed: () => setState(() => _datePeremption = null),
                child: Text(l10n.removeDate),
              ),
            const SizedBox(height: 32),
            PrimaryButton(
              label: l10n.save,
              icon: _saving ? null : Icons.check,
              onPressed: _saving ? null : _save,
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
