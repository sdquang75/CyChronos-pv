import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cy/core/icons/app_icons.dart';
import 'package:cy/core/theme/app_colors.dart';
import 'dropdown_field.dart';

const _stayDurationOptions = [
  DropdownOption(id: '30', label: '30 分'),
  DropdownOption(id: '60', label: '1 時間'),
  DropdownOption(id: '90', label: '1.5 時間'),
  DropdownOption(id: '120', label: '2 時間'),
  DropdownOption(id: '180', label: '3 時間+'),
];

const _spareTimeOptions = [
  DropdownOption(id: '15', label: '15 分'),
  DropdownOption(id: '30', label: '30 分'),
  DropdownOption(id: '45', label: '45 分'),
  DropdownOption(id: '60', label: '60 分'),
  DropdownOption(id: '90', label: '90 分'),
];

const _genreOptions = [
  DropdownOption(id: null, label: 'すべて'),
  DropdownOption(id: 'Cafe', label: 'カフェ'),
  DropdownOption(id: 'Nature', label: '自然'),
  DropdownOption(id: 'Food', label: 'グルメ'),
  DropdownOption(id: 'Temple', label: '寺院'),
  DropdownOption(id: 'Art', label: 'アート'),
  DropdownOption(id: 'Viewpoint', label: '絶景'),
  DropdownOption(id: 'Shop', label: 'ショッピング'),
  DropdownOption(id: 'Landmark', label: 'ランドマーク'),
  DropdownOption(id: 'Hill', label: 'ヒルクライム'),
  DropdownOption(id: 'Park', label: '公園'),
];

// "カスタマイズ" card: stay duration / spare time / genre dropdowns used to
// tailor the destination search.
class AdvancedConfigCard extends StatelessWidget {
  const AdvancedConfigCard({
    super.key,
    required this.stayDurationMinutes,
    required this.onStayDurationChanged,
    required this.spareTimeMinutes,
    required this.onSpareTimeChanged,
    required this.selectedGenreId,
    required this.onGenreChanged,
  });

  final String stayDurationMinutes;
  final ValueChanged<String?> onStayDurationChanged;
  final String spareTimeMinutes;
  final ValueChanged<String?> onSpareTimeChanged;
  final String? selectedGenreId;
  final ValueChanged<String?> onGenreChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.borderLight),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SvgPicture.string(
                AppIcons.settings,
                width: 18,
                height: 18,
                colorFilter: const ColorFilter.mode(
                  AppColors.terracottaDeep,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'カスタマイズ',
                style: TextStyle(
                  fontFamily: 'HankenGrotesk',
                  fontFamilyFallback: ['NotoSansJP'],
                  fontWeight: FontWeight.w500,
                  fontSize: 24,
                  color: AppColors.terracottaDeep,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '速度・休憩時間の設定',
            style: TextStyle(
              fontFamily: 'HankenGrotesk',
              fontFamilyFallback: ['NotoSansJP'],
              fontWeight: FontWeight.w400,
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          DropdownField(
            label: '滞在時間',
            options: _stayDurationOptions,
            selectedId: stayDurationMinutes,
            onChanged: onStayDurationChanged,
          ),
          const SizedBox(height: 24),
          DropdownField(
            label: '余裕時間',
            options: _spareTimeOptions,
            selectedId: spareTimeMinutes,
            onChanged: onSpareTimeChanged,
          ),
          const SizedBox(height: 24),
          DropdownField(
            label: 'ジャンル',
            options: _genreOptions,
            selectedId: selectedGenreId,
            onChanged: onGenreChanged,
          ),
        ],
      ),
    );
  }
}
