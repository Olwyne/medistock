import 'package:flutter/material.dart';
import 'package:flutter_beep/flutter_beep.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';
import '../l10n/app_localizations.dart';
import '../providers/medication_provider.dart';
import '../providers/settings_provider.dart';
import '../services/medication_api_service.dart';
import '../services/scan_service.dart';
import 'add_medication_screen.dart';

/// Mode du scan: ajout au stock ou déduction (prise).
enum ScanMode { add, take }

class ScanScreen extends StatefulWidget {
  final ScanMode mode;

  const ScanScreen({super.key, this.mode = ScanMode.add});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );
  bool _hasScanned = false;
  late ScanMode _mode;

  @override
  void initState() {
    super.initState();
    _mode = widget.mode;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_hasScanned) return;
    final barcode = capture.barcodes.isNotEmpty ? capture.barcodes.first : null;
    final raw = barcode?.rawValue;
    if (raw == null || raw.isEmpty) return;

    _hasScanned = true;
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      Vibration.vibrate(duration: 100);
    }

    if (!mounted) return;
    final settings = context.read<SettingsProvider>();
    if (settings.scanSound) {
      FlutterBeep.beep();
    }
    final provider = context.read<MedicationProvider>();

    if (_mode == ScanMode.take) {
      final existing = await provider.getByCode(raw);
      if (existing != null) {
        await provider.takeStock(existing.id!, 1);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('1 ${existing.unite} retiré : ${existing.nom}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() => _hasScanned = false);
        return;
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Médicament non trouvé dans l\'inventaire. Ajoutez-le d\'abord.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() => _hasScanned = false);
        return;
      }
    }

    // Mode add
    final existing = await provider.getByCode(raw);
    if (existing != null) {
      if (!mounted) return;
      final add = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(existing.nom),
          content: const Text(
            'Ce médicament est déjà dans l\'inventaire. Voulez-vous ajouter une quantité au stock ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Non'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Oui, ajouter au stock'),
            ),
          ],
        ),
      );
      if (add == true && mounted) {
        await provider.addStock(existing.id!, 1);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('+1 ${existing.unite} : ${existing.nom}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      setState(() => _hasScanned = false);
      return;
    }

    final result = ScanService.parse(raw);
    if (!mounted) return;
    String? nameToSuggest = result.suggestedName;
    String? suggestedForme;
    String? suggestedUnite;
    int? suggestedQuantiteParUnite;
    bool apiFailed = false;
    if (result.cip != null || RegExp(r'^\d{7,13}$').hasMatch(raw.trim())) {
      final lookup = await MedicationApiService().lookupByCip(raw);
      if (!mounted) return;
      if (lookup.error != null) {
        apiFailed = true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).apiErrorHint),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      } else if (lookup.data != null) {
        nameToSuggest = lookup.data!.nom;
        suggestedForme = lookup.data!.formePharmaceutique;
        suggestedUnite = lookup.data!.suggestedUnite;
        suggestedQuantiteParUnite = lookup.data!.suggestedQuantiteParUnite;
      }
    }
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    final displayName = nameToSuggest?.trim().isNotEmpty == true ? nameToSuggest! : raw;
    if (!apiFailed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.medicationRecognized} : $displayName'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
    final navigator = Navigator.of(context);
    final added = await navigator.push<bool>(
      MaterialPageRoute(
        builder: (_) => AddMedicationScreen(
          codeScanned: raw,
          suggestedName: nameToSuggest,
          suggestedForme: suggestedForme,
          suggestedUnite: suggestedUnite,
          suggestedQuantiteParUnite: suggestedQuantiteParUnite,
          noticeUrl: result.noticeUrl,
        ),
      ),
    );
    if (mounted && added == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Médicament ajouté à l\'inventaire'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    if (mounted) setState(() => _hasScanned = false);
  }

  @override
  Widget build(BuildContext context) {
    final isTakeMode = _mode == ScanMode.take;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text('Ajouter au stock'),
                  selected: _mode == ScanMode.add,
                  onSelected: (_) => setState(() => _mode = ScanMode.add),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Retirer du stock'),
                  selected: _mode == ScanMode.take,
                  onSelected: (_) => setState(() => _mode = ScanMode.take),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 32,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  isTakeMode
                      ? 'Scannez le code du médicament à retirer'
                      : 'Scannez le code sur la boîte ou la plaquette',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
