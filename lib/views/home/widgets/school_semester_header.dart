import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/institution_directory.dart';
import '../../../providers/profile_provider.dart';
import '../../../providers/user_setup_provider.dart';
import '../../onboarding/widgets/institution_logo.dart';
import '../../profile/user_profile_detail_view.dart';

class SchoolSemesterHeader extends ConsumerWidget {
  const SchoolSemesterHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userSetup = ref.watch(userSetupProvider);
    final activeProfile = ref.watch(activeProfileProvider);

    final schoolName = userSetup.organizationName.isNotEmpty
        ? userSetup.organizationName
        : 'Cor Jesu College, Inc. (CJC)';

    final detectedTerm = AcademicTermDetector.computeCurrentTerm(
      role: userSetup.role,
      orgName: schoolName,
    );

    final termName = activeProfile != null && activeProfile.name.contains('AY')
        ? activeProfile.name
        : detectedTerm;

    final institutionItem = InstitutionItem.findByDetails(
      name: schoolName,
      role: userSetup.role,
    );

    String roleLabel;
    IconData roleIcon;
    Color roleColor;

    switch (userSetup.role.toLowerCase()) {
      case 'duty':
      case 'medic':
      case 'nurs':
        roleLabel = 'Clinical Duty';
        roleIcon = Icons.medical_services_rounded;
        roleColor = const Color(0xFF0EA5E9);
        break;
      case 'work':
      case 'job':
      case 'part':
        roleLabel = 'Workplace';
        roleIcon = Icons.work_rounded;
        roleColor = const Color(0xFFF59E0B);
        break;
      case 'personal':
      case 'custom':
        roleLabel = 'Personal';
        roleIcon = Icons.person_rounded;
        roleColor = const Color(0xFF8B5CF6);
        break;
      default:
        roleLabel = 'Student';
        roleIcon = Icons.school_rounded;
        roleColor = const Color(0xFF2563EB);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const UserProfileDetailView()),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Genuine Institution Logo / Emblem
              InstitutionLogo(
                item: institutionItem,
                size: 44,
              ),

              const SizedBox(width: 12),

              // School / Organization Name & Dynamic Term
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            schoolName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: roleColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: roleColor.withValues(alpha: 0.3), width: 0.8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(roleIcon, size: 11, color: roleColor),
                              const SizedBox(width: 3.5),
                              Text(
                                roleLabel,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: roleColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_month_rounded,
                          size: 13,
                          color: roleColor,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            termName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.textSecondaryDark : const Color(0xFF475569),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
