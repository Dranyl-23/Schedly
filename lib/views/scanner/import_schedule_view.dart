import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import 'image_preview_view.dart';

class ImportScheduleView extends StatefulWidget {
  const ImportScheduleView({super.key});

  @override
  State<ImportScheduleView> createState() => _ImportScheduleViewState();
}

class _ImportScheduleViewState extends State<ImportScheduleView> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 80,
      );

      if (file != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ImagePreviewView(imageFile: file),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _pickDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'webp', 'heic'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final pickedFile = result.files.first;
        final path = pickedFile.path;
        if (path != null && mounted) {
          final ext = pickedFile.extension?.toLowerCase() ?? 'jpg';
          final mimeType = switch (ext) {
            'pdf' => 'application/pdf',
            'png' => 'image/png',
            'webp' => 'image/webp',
            'heic' => 'image/heic',
            _ => 'image/jpeg',
          };
          final xFile = XFile(
            path,
            name: pickedFile.name,
            mimeType: mimeType,
          );

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ImagePreviewView(imageFile: xFile),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting document: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Schedule'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Select a file format to import your timetable (PDF, PNG, JPG, etc.)',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
            ),
          ),

          const SizedBox(height: 20),

          // PDF Document Card (Prominent)
          _buildImportOption(
            icon: Icons.picture_as_pdf_rounded,
            iconBg: const Color(0xFFFEE2E2),
            iconColor: const Color(0xFFDC2626),
            title: 'PDF Document',
            subtitle: 'Upload COR, study load, or timetable (.pdf)',
            badge: 'RECOMMENDED',
            badgeColor: const Color(0xFFDC2626),
            isDark: isDark,
            onTap: _pickDocument,
          ),

          const SizedBox(height: 14),

          // Gallery Option Card
          _buildImportOption(
            icon: Icons.photo_library_rounded,
            iconBg: const Color(0xFFF0FDF4),
            iconColor: const Color(0xFF16A34A),
            title: 'Photos & Gallery',
            subtitle: 'Choose PNG, JPG, or screenshot from gallery',
            isDark: isDark,
            onTap: () => _pickImage(ImageSource.gallery),
          ),

          const SizedBox(height: 14),

          // Camera Option Card
          _buildImportOption(
            icon: Icons.camera_alt_rounded,
            iconBg: const Color(0xFFEFF6FF),
            iconColor: const Color(0xFF2563EB),
            title: 'Camera Capture',
            subtitle: 'Snap a photo of printed schedule or screen',
            isDark: isDark,
            onTap: () => _pickImage(ImageSource.camera),
          ),

          const SizedBox(height: 30),

          // Supported Formats Info Box
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: Color(0xFF2563EB), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Supported File Formats',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '• PDF Files (.pdf) — Official University Registration Cards, Study Loads, Roster Sheets\n'
                  '• Images (.png, .jpg, .jpeg, .webp) — Screenshots, Camera Photos, Scans\n'
                  '• Multi-Day Timetables — MWF, TTh, Weekend Shifts, Graveyard Roster',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.5,
                    color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImportOption({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    String? badge,
    Color? badgeColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor?.withValues(alpha: 0.12) ?? Colors.blue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: badgeColor ?? Colors.blue,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            subtitle,
            style: TextStyle(
              fontSize: 12.5,
              color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
            ),
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: isDark ? AppColors.textSecondaryDark : const Color(0xFF94A3B8),
        ),
        onTap: onTap,
      ),
    );
  }
}
