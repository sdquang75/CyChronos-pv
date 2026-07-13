import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cy/core/icons/app_icons.dart';
import 'package:cy/core/theme/app_colors.dart';
import 'package:cy/core/widgets/app_screen_frame.dart';

// A single dropdown option shown in a DropdownField's picker sheet.
class DropdownOption {
  const DropdownOption({required this.id, required this.label});

  final String? id;
  final String label;
}

// Label + tappable "options" row that opens a single-select bottom sheet.
// Used by AdvancedConfigCard for stay-duration / spare-time / genre fields.
class DropdownField extends StatelessWidget {
  const DropdownField({
    super.key,
    required this.label,
    required this.options,
    required this.selectedId,
    required this.onChanged,
  });

  final String label;
  final List<DropdownOption> options;
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  String get _selectedLabel => options
      .firstWhere((o) => o.id == selectedId, orElse: () => options.first)
      .label;

  Future<void> _openPicker(BuildContext context) async {
    // Longer option lists (e.g. genre, 11 entries) can otherwise grow
    // taller than the screen and overflow — cap the sheet's height (and
    // let its internal ListView scroll instead) and its width, so it never
    // stretches past the app's own phone-frame width on a wide viewport.
    final picked = await showModalBottomSheet<String?>(
      context: context,
      // ExploreFlow が独自の(ネストした)Navigatorを持つため、指定しないと
      // その中のOverlayにしか描画されず、HomeScreenのStack内で後ろに置かれた
      // HomeBottomNavBarの下に隠れてしまう。ルートのNavigator/Overlayに
      // 出すことで、ボトムナビより確実に手前に表示する
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
        maxWidth: AppScreenFrame.width,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'HankenGrotesk',
                      fontFamilyFallback: ['NotoSansJP'],
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: AppColors.greenDeep,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options[index];
                    final isSelected = option.id == selectedId;
                    return ListTile(
                      onTap: () => Navigator.of(context).pop(option.id),
                      title: Text(
                        option.label,
                        style: TextStyle(
                          fontFamily: 'HankenGrotesk',
                          fontFamilyFallback: const ['NotoSansJP'],
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w400,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check_rounded,
                              color: AppColors.greenPrimary,
                            )
                          : null,
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );

    if (picked != selectedId) {
      onChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'JetBrainsMono',
            fontWeight: FontWeight.w500,
            fontSize: 12,
            letterSpacing: 0.6,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => _openPicker(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.surfaceHover,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.textPrimary.withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedLabel,
                      style: const TextStyle(
                        fontFamily: 'HankenGrotesk',
                        fontFamilyFallback: ['NotoSansJP'],
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  SvgPicture.string(
                    AppIcons.chevronDown,
                    width: 12,
                    height: 8,
                    colorFilter: const ColorFilter.mode(
                      AppColors.textSecondary,
                      BlendMode.srcIn,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
