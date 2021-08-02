import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:clickable_text/clickable_pattern.dart';

export 'clickable_pattern.dart';

class ClickableText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextStyle? clickableDefaultStyle;
  final List<ClickablePattern> patterns;
  final bool softWrap;
  final int? maxLines;
  final TextOverflow overflow;
  ClickableText(
    this.text, {
    Key? key,
    List<ClickablePattern>? patterns,
    this.style,
    this.softWrap = true,
    this.maxLines,
    this.overflow = TextOverflow.clip,
    this.clickableDefaultStyle,
  })  : patterns = patterns ?? patternDefaults,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    List<_ClickableTypeText> ctts = getClickableTexts(text, patterns);

    return RichText(
      softWrap: softWrap,
      maxLines: maxLines,
      overflow: overflow,
      text: TextSpan(
        style: style,
        children: _clickableTypeTextsToTextSpans(ctts, clickableDefaultStyle),
      ),
    );
  }

  static List<ClickablePattern> patternDefaults = [
    const ClickablePattern(
      name: 'cellphone_1',
      pattern: r'(?<=[ ,.:=\a\e\f\n\r\t"'
          r"'"
          r']|^)'
          r'\d{3}-?\d{3}-?\d{4}'
          r'(?=[ ,.\a\e\f\n\r\t"'
          r"'"
          r']|$)',
      onClicked: _nothingOnClicked,
    ),
    const ClickablePattern(
      name: 'email_1',
      pattern: r'(?<=[ ,.:=\a\e\f\n\r\t"'
          r"'"
          r']|^)'
          r'(?:[a-z0-9!#$%&'
          r"'"
          r'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'
          r"'"
          r'*+/=?^_`{|}~-]+)*|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:(2(5[0-5]|[0-4][0-9])|1[0-9][0-9]|[1-9]?[0-9]))\.){3}(?:(2(5[0-5]|[0-4][0-9])|1[0-9][0-9]|[1-9]?[0-9])|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])'
          r'(?=[ ,.\a\e\f\n\r\t"'
          r"'"
          r']|$)',
      onClicked: _nothingOnClicked,
    ),
  ];

  static void _nothingOnClicked(
      String text, ClickablePattern clickablePattern) {}

  static List<InlineSpan> _clickableTypeTextsToTextSpans(
    List<_ClickableTypeText> ctts, [
    TextStyle? defaultClickableStyle,
  ]) {
    var spans = <InlineSpan>[];
    for (var i = 0; i < ctts.length; i++) {
      var ctt = ctts[i];
      InlineSpan span;
      if (ctt.clickable) {
        span = _createClickableTextSpan(ctt, defaultClickableStyle);
      } else {
        span = TextSpan(text: ctt.text);
      }
      spans.add(span);
    }
    return spans;
  }

  static InlineSpan _createClickableTextSpan(
      _ClickableTypeText ctt, TextStyle? defaultStyle) {
    if (ctt.clickablePattern!.spanBuilder != null) {
      return ctt.clickablePattern!.spanBuilder!(
        ctt.text,
        ctt.clickablePattern!,
      );
    } else {
      return TextSpan(
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            ctt.clickablePattern?.onClicked(
              ctt.text,
              ctt.clickablePattern ?? ClickablePattern.error,
            );
          },
        style: ctt.clickablePattern?.style ?? defaultStyle,
        text: ctt.text,
      );
    }
  }

  static List<_ClickableTypeText> getClickableTexts(
    String text,
    List<ClickablePattern> patterns,
  ) {
    List<_ClickableTypeText> typeTexts = [_ClickableTypeText(text)];
    for (var pIndex = 0; pIndex < patterns.length; pIndex++) {
      var clickablePattern = patterns[pIndex];
      var regPattern = RegExp(clickablePattern.pattern);
      for (var ttIndex = 0; ttIndex < typeTexts.length; ttIndex++) {
        var typeText = typeTexts[ttIndex];
        if (typeText.clickable) continue;
        var matches = regPattern.allMatches(typeText.text);
        if (matches.isNotEmpty) {
          var matchesIterator = matches.iterator;
          var newTypeTexts = <_ClickableTypeText>[];
          var lastMatchIndex = 0;
          while (matchesIterator.moveNext()) {
            var match = matchesIterator.current;
            if (lastMatchIndex < match.start) {
              newTypeTexts.add(_ClickableTypeText(
                  typeText.text.substring(lastMatchIndex, match.start)));
            }
            newTypeTexts.add(
              _ClickableTypeText(match.input.substring(match.start, match.end),
                  clickablePattern),
            );
            lastMatchIndex = match.end;
          }
          if (lastMatchIndex < typeText.text.length) {
            newTypeTexts.add(_ClickableTypeText(
                typeText.text.substring(lastMatchIndex, typeText.text.length)));
          }
          typeTexts.removeAt(ttIndex);
          typeTexts.insertAll(ttIndex, newTypeTexts);
          ttIndex += newTypeTexts.length - 1;
        }
      }
    }
    return typeTexts;
  }
}

class _ClickableTypeText {
  final String text;
  final ClickablePattern? clickablePattern;
  bool get clickable {
    return clickablePattern != null;
  }

  const _ClickableTypeText(this.text, [this.clickablePattern]);
}
