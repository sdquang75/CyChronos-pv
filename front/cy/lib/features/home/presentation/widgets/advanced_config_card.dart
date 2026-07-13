import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cy/core/icons/app_icons.dart';
import 'package:cy/core/theme/app_colors.dart';
import 'dropdown_field.dart';

// 分数を "15 分" / "1 時間" / "1時間15分" のようなラベルに変換する
String _minutesLabel(int minutes) {
  if (minutes < 60) return '$minutes 分';
  final hours = minutes ~/ 60;
  final remainder = minutes % 60;
  return remainder == 0 ? '$hours 時間' : '$hours時間$remainder分';
}

List<DropdownOption> _minuteOptions(int stepMinutes, int maxMinutes) => [
  for (var m = stepMinutes; m <= maxMinutes; m += stepMinutes)
    DropdownOption(id: '$m', label: _minutesLabel(m)),
];

// 滞在時間: 目的地に着いてから過ごす時間。15分刻みで最大3時間
final _stayDurationOptions = _minuteOptions(15, 180);

// 余裕時間: 往復の移動+滞在をまかなう合計予算。30分刻みで最大5時間
final _spareTimeOptions = _minuteOptions(30, 300);

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

// "検索条件" card: stay duration / spare time / genre dropdowns used to
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
                  AppColors.greenDeep,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '検索条件',
                style: TextStyle(
                  fontFamily: 'HankenGrotesk',
                  fontFamilyFallback: ['NotoSansJP'],
                  fontWeight: FontWeight.w500,
                  fontSize: 24,
                  color: AppColors.greenDeep,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '滞在時間・余裕時間・ジャンルを設定',
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
