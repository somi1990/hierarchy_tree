import 'package:flutter/material.dart';

enum HierarchyDensity { compact, comfortable }

/// Visual theme for [HierarchyTreeView]'s default node card and details
/// panel. Pass a custom instance to restyle without writing a full
/// `cardBuilder`/`detailsBuilder`.
///
/// The row-height fields (`cardPaddingVertical`, `headerRowHeight`,
/// `headlineRowHeight`, `progressRowHeight`, `rowSpacing`) are what drive
/// automatic card sizing when `HierarchyTreeView.cardHeight` is left unset
/// — see `resolveCardSize` in `card_metrics.dart`.
class HierarchyTheme {
  const HierarchyTheme({
    this.cardBackground = Colors.white,
    this.lockedCardBackground = const Color(0xfff8fafc),
    this.cardBorderRadius = 13.0,
    this.cardShadow = const [
      BoxShadow(color: Color(0x0e000000), blurRadius: 7, offset: Offset(0, 3)),
    ],
    this.selectedBorderWidth = 2.0,
    this.unselectedBorderWidth = 1.2,
    this.lockedBorderColor = const Color(0xffcbd5e1),
    this.nameTextStyle = const TextStyle(
      fontSize: 13,
      height: 1.05,
      fontWeight: FontWeight.w700,
      color: Color(0xff0f172a),
    ),
    this.lockedNameTextColor = const Color(0xff64748b),
    this.levelLabelTextStyle = const TextStyle(
      fontSize: 9,
      height: 1,
      color: Color(0xff64748b),
    ),
    this.lockedIconColor = const Color(0xff94a3b8),
    this.metricLabelTextStyle = const TextStyle(
      fontSize: 8.5,
      height: 1,
      color: Color(0xff64748b),
    ),
    this.metricValueFontSize = 14.0,
    this.progressBarHeight = 4.0,
    this.progressBarBackground = const Color(0xffe2e8f0),
    this.searchMatchBorderColor = const Color(0xfff59e0b),
    this.density = HierarchyDensity.comfortable,
    this.cardPaddingVertical = 18.0,
    this.headerRowHeight = 34.0,
    this.headlineRowHeight = 35.0,
    this.progressRowHeight = 25.0,
    this.rowSpacing = 7.0,
  });

  final Color cardBackground;
  final Color lockedCardBackground;
  final double cardBorderRadius;
  final List<BoxShadow> cardShadow;
  final double selectedBorderWidth;
  final double unselectedBorderWidth;
  final Color lockedBorderColor;
  final TextStyle nameTextStyle;
  final Color lockedNameTextColor;
  final TextStyle levelLabelTextStyle;
  final Color lockedIconColor;
  final TextStyle metricLabelTextStyle;
  final double metricValueFontSize;
  final double progressBarHeight;
  final Color progressBarBackground;

  /// Border color used to highlight nodes matching an active search query.
  final Color searchMatchBorderColor;

  final HierarchyDensity density;

  /// Total top+bottom padding inside the card.
  final double cardPaddingVertical;

  /// Height reserved for the icon/name/level-label header row. Always
  /// present, regardless of how many metrics are configured.
  final double headerRowHeight;

  /// Height reserved for the up-to-two headline numbers row. Only counted
  /// toward the card's auto-computed height when at least one headline
  /// metric is actually shown.
  final double headlineRowHeight;

  /// Height reserved for the up-to-two progress-bar row. Only counted
  /// toward the card's auto-computed height when at least one progress
  /// metric is actually shown.
  final double progressRowHeight;

  /// Vertical gap inserted between whichever rows are actually present.
  final double rowSpacing;

  /// A tighter preset for trees with many nodes on screen at once.
  factory HierarchyTheme.dense() => const HierarchyTheme(
        cardBorderRadius: 10,
        nameTextStyle: TextStyle(
          fontSize: 11.5,
          height: 1.0,
          fontWeight: FontWeight.w700,
          color: Color(0xff0f172a),
        ),
        levelLabelTextStyle: TextStyle(fontSize: 8, height: 1, color: Color(0xff64748b)),
        metricLabelTextStyle: TextStyle(fontSize: 7.5, height: 1, color: Color(0xff64748b)),
        metricValueFontSize: 12.0,
        progressBarHeight: 3.0,
        density: HierarchyDensity.compact,
        cardPaddingVertical: 12.0,
        headerRowHeight: 28.0,
        headlineRowHeight: 28.0,
        progressRowHeight: 20.0,
        rowSpacing: 5.0,
      );

  HierarchyTheme copyWith({
    Color? cardBackground,
    Color? lockedCardBackground,
    double? cardBorderRadius,
    List<BoxShadow>? cardShadow,
    double? selectedBorderWidth,
    double? unselectedBorderWidth,
    Color? lockedBorderColor,
    TextStyle? nameTextStyle,
    Color? lockedNameTextColor,
    TextStyle? levelLabelTextStyle,
    Color? lockedIconColor,
    TextStyle? metricLabelTextStyle,
    double? metricValueFontSize,
    double? progressBarHeight,
    Color? progressBarBackground,
    Color? searchMatchBorderColor,
    HierarchyDensity? density,
    double? cardPaddingVertical,
    double? headerRowHeight,
    double? headlineRowHeight,
    double? progressRowHeight,
    double? rowSpacing,
  }) {
    return HierarchyTheme(
      cardBackground: cardBackground ?? this.cardBackground,
      lockedCardBackground: lockedCardBackground ?? this.lockedCardBackground,
      cardBorderRadius: cardBorderRadius ?? this.cardBorderRadius,
      cardShadow: cardShadow ?? this.cardShadow,
      selectedBorderWidth: selectedBorderWidth ?? this.selectedBorderWidth,
      unselectedBorderWidth: unselectedBorderWidth ?? this.unselectedBorderWidth,
      lockedBorderColor: lockedBorderColor ?? this.lockedBorderColor,
      nameTextStyle: nameTextStyle ?? this.nameTextStyle,
      lockedNameTextColor: lockedNameTextColor ?? this.lockedNameTextColor,
      levelLabelTextStyle: levelLabelTextStyle ?? this.levelLabelTextStyle,
      lockedIconColor: lockedIconColor ?? this.lockedIconColor,
      metricLabelTextStyle: metricLabelTextStyle ?? this.metricLabelTextStyle,
      metricValueFontSize: metricValueFontSize ?? this.metricValueFontSize,
      progressBarHeight: progressBarHeight ?? this.progressBarHeight,
      progressBarBackground: progressBarBackground ?? this.progressBarBackground,
      searchMatchBorderColor: searchMatchBorderColor ?? this.searchMatchBorderColor,
      density: density ?? this.density,
      cardPaddingVertical: cardPaddingVertical ?? this.cardPaddingVertical,
      headerRowHeight: headerRowHeight ?? this.headerRowHeight,
      headlineRowHeight: headlineRowHeight ?? this.headlineRowHeight,
      progressRowHeight: progressRowHeight ?? this.progressRowHeight,
      rowSpacing: rowSpacing ?? this.rowSpacing,
    );
  }
}
