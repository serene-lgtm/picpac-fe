import 'package:flutter/material.dart';

const checklistGradientColors = [Color(0xFF48B3AF), Color(0xFFA7E399)];
const checklistCardColor = Color(0xDDF1FFFB);
const checklistPrimary = Color(0xFF48B8B4);
const checklistMutedText = Color(0xFF8D9A9C);
const checklistGiftAsset = 'assets/common/gift_box.png';
const checklistCoverAsset = 'assets/common/checklist_tile_cover.png';

BoxDecoration checklistGradientDecoration() {
  return const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: checklistGradientColors,
    ),
  );
}

String checklistDisplayDate(String value) {
  final date = DateTime.tryParse(value);
  if (date == null) return value;
  return '${date.year}年${date.month}月${date.day}日';
}

String checklistApiDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}
