import 'package:flutter/widgets.dart';

typedef PatternClicked = void Function(
    String text, ClickablePattern clickablePattern);

class ClickablePattern {
  final String name;
  final String pattern;
  final bool enabled;
  final TextStyle? style;
  final PatternClicked? onClicked;
  final InlineSpan Function(String text, ClickablePattern pattern)? spanBuilder;

  /// Pattern class used by ClickableText widget for pattern finding,
  /// and click function bindings.
  ///
  /// **pattern** =
  /// regex string to search on text and convert them
  /// to different InlineSpan.
  ///
  /// **name** =
  /// easy way to tell which pattern is activated.
  ///
  /// **onClicked** =
  /// function that is called when InlineSpan is clicked.
  ///
  /// **style** =
  /// style for the InlineSpan created.
  ///
  /// **spanBuilder** =
  /// for more specific widget building,
  /// will not include the onClicked and style attributes,
  /// you need to add them yourself.
  const ClickablePattern({
    required this.name,
    required this.pattern,
    this.onClicked,
    this.enabled = true,
    this.style,
    this.spanBuilder,
  });

  ClickablePattern copyWith({
    String? name,
    String? pattern,
    PatternClicked? onClicked,
    TextStyle? style,
  }) {
    return ClickablePattern(
      name: name ?? this.name,
      pattern: pattern ?? this.pattern,
      onClicked: onClicked ?? this.onClicked,
      style: style ?? this.style,
    );
  }

  static final ClickablePattern error = ClickablePattern(
    name: 'error',
    pattern: 'error',
    style: TextStyle(
      fontSize: 16,
      color: Color(0xFFFF0000),
      decoration: TextDecoration.lineThrough,
    ),
    onClicked: (text, clickablePattern) {
      throw Exception('Error: got to undefined ClickablePattern');
    },
  );
}
