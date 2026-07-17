import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SearchEmptyState extends StatelessWidget {
  const SearchEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(28, 166, 28, 120),
      children: const [SearchEmptyIllustration()],
    );
  }
}

class SearchEmptyIllustration extends StatelessWidget {
  const SearchEmptyIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/common/no_result.svg',
      height: 270,
      semanticsLabel: '无搜索结果',
    );
  }
}
