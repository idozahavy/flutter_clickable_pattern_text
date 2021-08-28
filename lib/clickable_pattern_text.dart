import 'package:clickable_pattern_text/index.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:clickable_pattern_text/clickable_pattern.dart';

export 'clickable_pattern.dart';
export 'rich_text_positioner/rich_text_positioner.dart';

class ClickablePatternText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final TextStyle? clickableDefaultStyle;
  final List<ClickablePattern> _patterns;
  final bool softWrap;
  final int? maxLines;
  final TextOverflow overflow;
  ClickablePatternText(
    this.text, {
    List<ClickablePattern> patterns = const [],
    Key? key,
    this.style,
    this.softWrap = true,
    this.maxLines,
    this.overflow = TextOverflow.clip,
    this.clickableDefaultStyle,
  })  : _patterns = patterns,
        super(key: key);

  @override
  ClickablePatternTextState createState() => ClickablePatternTextState();

  static List<InlineSpan> _clickableTypeTextsToTextSpans(
    List<_ClickableTypeText> ctts, [
    TextStyle? defaultClickableStyle,
  ]) {
    var spans = <InlineSpan>[];
    int clickableIndex = 0;
    for (var i = 0; i < ctts.length; i++) {
      var ctt = ctts[i];
      InlineSpan span;
      if (ctt.clickable) {
        span = _createClickableTextSpan(ctt, defaultClickableStyle);
        ctt.clickablePattern?.onSpanCreation?.call(span, clickableIndex++);
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
            ctt.clickablePattern?.onClicked?.call(
              ctt.text,
              ctt.clickablePattern ?? ClickablePattern.error,
            );
          },
        style: ctt.clickablePattern?.style ?? defaultStyle,
        text: ctt.text,
      );
    }
  }

  // TODO extract to other class that constructs this type and converts it to spans
  static List<_ClickableTypeText> _getClickableTexts(
    String text,
    List<ClickablePattern> patterns,
  ) {
    List<_ClickableTypeText> typeTexts = [_ClickableTypeText(text)];
    for (var pIndex = 0; pIndex < patterns.length; pIndex++) {
      var clickablePattern = patterns[pIndex];
      if (!clickablePattern.enabled) continue;
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

class ClickablePatternTextState extends State<ClickablePatternText> {
  final _richTextPositionerKey = GlobalKey<RichTextPositionerState>();
  @override
  Widget build(BuildContext context) {
    List<_ClickableTypeText> ctts =
        ClickablePatternText._getClickableTexts(widget.text, widget._patterns);

    return RichTextPositioner(
      key: _richTextPositionerKey,
      softWrap: widget.softWrap,
      maxLines: widget.maxLines,
      overflow: widget.overflow,
      text: TextSpan(
        style: widget.style,
        children: ClickablePatternText._clickableTypeTextsToTextSpans(
            ctts, widget.clickableDefaultStyle),
      ),
    );
  }

  Future<void> ensureVisible(
    TextSpan span, {
    double alignment = 0.0,
    Duration duration = Duration.zero,
    Curve curve = Curves.ease,
    ScrollPositionAlignmentPolicy alignmentPolicy =
        ScrollPositionAlignmentPolicy.explicit,
    double offset = 0,
    int spanIndex = 0,
    int textBoxIndex = 0,
    bool Function(List<TextBox> spanBoxes, int index, int length)? spanSelector,
    bool Function(TextBox textBox, int index, int length)? textBoxSelector,
    double Function(TextBox textBox, double alignment)? offsetSelector,
  }) {
    return _richTextPositionerKey.currentState!.ensureVisible(
      span,
      alignment: alignment,
      alignmentPolicy: alignmentPolicy,
      curve: curve,
      duration: duration,
      offset: offset,
      offsetSelector: offsetSelector,
      spanIndex: spanIndex,
      spanSelector: spanSelector,
      textBoxIndex: textBoxIndex,
      textBoxSelector: textBoxSelector,
    );
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
