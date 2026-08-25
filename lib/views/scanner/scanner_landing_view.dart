import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/ai/schedule_parser_service.dart';
import '../../core/constants/app_colors.dart';
import '../../models/schedule_entry.dart';
import '../../providers/schedule_provider.dart';
import 'review_scanned_schedules_view.dart';

class ScannerLandingView extends ConsumerStatefulWidget {
  const ScannerLandingView({super.key});

  @override
  ConsumerState<ScannerLandingView> createState() => _ScannerLandingViewState();
}

class _ScannerLandingViewState extends ConsumerState<ScannerLandingView> {
  final ImagePicker _picker = ImagePicker();
  final ScheduleParserService _parserService = ScheduleParserService();

  bool _isProcessing = false;
  String _statusMessage = '';

  Future<void> _pickAndProcessImage(ImageSource source) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: source,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 85,
      );

      if (photo == null) return;

      setState(() {
        _isProcessing = true;
        _statusMessage = 'Reading image and analyzing schedule layout...';
      });

      final bytes = await photo.readAsBytes();
      final mimeType = photo.mimeType ?? 'image/jpeg';
      final userApiKey = ref.read(geminiApiKeyProvider);

      setState(() {
        _statusMessage = 'AI is extracting classes, shifts, and times...';
      });

      final List<ScheduleEntry> results = await _parserService.parseImage(
        imageBytes: bytes,
        mimeType: mimeType,
        apiKey: userApiKey.isNotEmpty ? userApiKey : null,
      );

      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReviewScannedSchedulesView(parsedEntries: results),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Scanning Error'),
            content: Text(
              'Could not extract schedule: ${e.toString().replaceAll("Exception: ", "")}\n\nTip: You can use the built-in demo mode or ensure your Gemini API key is configured.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  void _showApiKeyDialog() {
    final currentKey = ref.read(geminiApiKeyProvider);
    final keyController = TextEditingController(text: currentKey);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Gemini API Key'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter your Google Gemini API Key for live AI schedule parsing. Leave blank to use realistic offline demo mode.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: keyController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'AIzaSy...',
                  prefixIcon: Icon(Icons.key_rounded),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                ref.read(geminiApiKeyProvider.notifier).state =
                    keyController.text.trim();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('API Key updated!')),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentKey = ref.watch(geminiApiKeyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Schedule'),
        actions: [
          IconButton(
            tooltip: 'Gemini API Key Settings',
            icon: Icon(
              currentKey.isNotEmpty ? Icons.vpn_key_rounded : Icons.vpn_key_outlined,
              color: currentKey.isNotEmpty ? AppColors.primary : null,
            ),
            onPressed: _showApiKeyDialog,
          ),
        ],
      ),
      body: _isProcessing
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(strokeWidth: 3),
                    const SizedBox(height: 24),
                    Text(
                      _statusMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Analyzing columns, days, and time blocks...',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Hero illustration / icon
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            // ignore: deprecated_member_use
                            color: AppColors.primary.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.document_scanner_rounded,
                            size: 48,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Import Schedule Screenshot',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Upload a photo or screenshot of your class timetable, work shift roster, or duty sheet.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondaryLight,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      // Camera
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _pickAndProcessImage(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt_rounded),
                          label: const Text('Take Photo'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Gallery
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickAndProcessImage(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library_rounded),
                          label: const Text('Choose Photo'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Supported formats tip
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.lightbulb_outline_rounded, color: AppColors.warning, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Supported Schedule Formats',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _buildTipItem('🎓 University Timetables (MWF, TTH, Saturday classes)'),
                        _buildTipItem('🍔 Fast-Food / Mall Rosters (Jollibee, McDo, SM Staff)'),
                        _buildTipItem('🏥 Hospital & Government Duty Sheets'),
                        _buildTipItem('🌙 Overnight & Graveyard Shifting Schedules'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
            ),
          ),
        ],
      ),
    );
  }
}
