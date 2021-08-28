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
  final Function(InlineSpan span, int index)? onSpanCreation;

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
    this.enabled = true,
    this.onClicked,
    this.style,
    this.spanBuilder,
    this.onSpanCreation,
  });
  const ClickablePattern.email({
    required this.name,
    this.enabled = true,
    this.onClicked,
    this.style,
    this.spanBuilder,
    this.onSpanCreation,
  }) : pattern = r'(?<=[ ,.:=\a\e\f\n\r\t"'
            r"'"
            r']|^)'
            r'(?:[a-z0-9!#$%&'
            r"'"
            r'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'
            r"'"
            r'*+/=?^_`{|}~-]+)*|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:(2(5[0-5]|[0-4][0-9])|1[0-9][0-9]|[1-9]?[0-9]))\.){3}(?:(2(5[0-5]|[0-4][0-9])|1[0-9][0-9]|[1-9]?[0-9])|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])'
            r'(?=[ ,.\a\e\f\n\r\t"'
            r"'"
            r']|$)';

  ClickablePattern copyWith({
    String? name,
    String? pattern,
    bool? enabled,
    PatternClicked? onClicked,
    TextStyle? style,
    InlineSpan Function(String text, ClickablePattern pattern)? spanBuilder,
    Function(InlineSpan span, int index)? onSpanCreation,
  }) {
    return ClickablePattern(
      name: name ?? this.name,
      pattern: pattern ?? this.pattern,
      enabled: enabled ?? this.enabled,
      onClicked: onClicked ?? this.onClicked,
      style: style ?? this.style,
      onSpanCreation: onSpanCreation ?? this.onSpanCreation,
      spanBuilder: spanBuilder ?? this.spanBuilder,
    );
  }

  static final ClickablePattern error = ClickablePattern(
    name: 'error',
    pattern: r'$a',
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
