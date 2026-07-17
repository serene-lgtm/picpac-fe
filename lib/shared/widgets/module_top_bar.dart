import 'package:flutter/material.dart';

const moduleTopBarHeight = 98.0;
const moduleTopBarTitleStyle = TextStyle(
  color: Colors.black,
  fontSize: 18,
  fontWeight: FontWeight.w700,
);
const moduleTopBarIconSize = 30.0;
const moduleTopBarHorizontalPadding = 22.0;
const moduleTopBarActionWidth = 48.0;

class ModuleTopBar extends StatelessWidget {
  const ModuleTopBar({
    super.key,
    required this.title,
    this.leading,
    this.trailing,
    this.trailingText,
    this.onLeadingTap,
    this.onTrailingTap,
    this.background,
    this.foregroundColor = Colors.black,
    this.trailingTextColor,
    this.height = moduleTopBarHeight,
  });

  final String title;
  final IconData? leading;
  final IconData? trailing;
  final String? trailingText;
  final VoidCallback? onLeadingTap;
  final VoidCallback? onTrailingTap;
  final Decoration? background;
  final Color foregroundColor;
  final Color? trailingTextColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: background,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: moduleTopBarHorizontalPadding,
          ),
          child: SizedBox(
            height: moduleTopBarActionWidth,
            child: Row(
              children: [
                SizedBox(
                  width: moduleTopBarActionWidth,
                  child: leading == null
                      ? null
                      : IconButton(
                          alignment: Alignment.centerLeft,
                          padding: EdgeInsets.zero,
                          onPressed: onLeadingTap,
                          icon: Icon(
                            leading,
                            color: foregroundColor,
                            size: moduleTopBarIconSize,
                          ),
                        ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: moduleTopBarTitleStyle.copyWith(
                        color: foregroundColor,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: moduleTopBarActionWidth,
                  child: trailing == null && trailingText == null
                      ? null
                      : trailingText != null
                      ? TextButton(
                          onPressed: onTrailingTap,
                          style: TextButton.styleFrom(
                            foregroundColor:
                                trailingTextColor ?? foregroundColor,
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            trailingText!,
                            maxLines: 1,
                            overflow: TextOverflow.visible,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      : IconButton(
                          alignment: Alignment.centerRight,
                          padding: EdgeInsets.zero,
                          onPressed: onTrailingTap,
                          icon: Icon(
                            trailing,
                            color: foregroundColor,
                            size: moduleTopBarIconSize,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
