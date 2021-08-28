import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';

class InlineSpanTextRange {
  final InlineSpan span;
  final TextRange textRange;
  InlineSpanTextRange(this.span, this.textRange);
}

extension InlineSpanPositions on InlineSpan {
  /// gets the [TextRange] for all the children inside this span
  /// helpfull for getting [TextBox] from the [Paragraph] renderbox.
  ///
  /// it accumulate all the lengths of the texts in the span.
  List<InlineSpanTextRange> getTextRanges({
    bool includePlaceholders = true,
    bool includeSemanticsLabels = true,
  }) {
    final result = <InlineSpanTextRange>[];

    var offset = Accumulator();
    visitChildren((span) {
      String? text;
      if (span is TextSpan) {
        text = span.text;
      }
      if (text != null) {
        result.add(
          InlineSpanTextRange(
            span,
            TextRange(
              start: offset.value,
              end: offset.value + text.length,
            ),
          ),
        );
        offset.increment(text.length);
      }
      return true;
    });

    return result;
  }
}

extension TextPainterPositions on TextPainter {
  /// checks for the [TextBox]es of this [TextPainter]
  /// and finds their positions in the renderbox.
  ///
  /// Becuase every span may paint two or more lines (multiple [TextBox]es)
  /// the function returns a list of lists of [TextBox],
  /// each list of [TextBox]es is an [InlineSpan] finding.
  ///
  List<List<TextBox>> getBoxesForSpan(
    InlineSpan span, {
    double minWidth = 0.0,
    double maxWidth = double.infinity,
    double minHeight = double.infinity,
    double maxHeight = double.infinity,
  }) {
    final List<List<TextBox>> result = [];

    var renderPar = RenderParagraph(
      this.text!,
      textAlign: textAlign,
      textDirection: textDirection!,
      locale: locale,
      maxLines: maxLines,
      strutStyle: strutStyle,
      textHeightBehavior: textHeightBehavior,
      textScaleFactor: textScaleFactor,
      textWidthBasis: textWidthBasis,
    );

    renderPar.layout(
      BoxConstraints(
        minWidth: minWidth,
        maxWidth: maxWidth,
        minHeight: minHeight,
        maxHeight: maxHeight,
      ),
    );

    var ranges = text!.getTextRanges();

    for (var spanRange in ranges) {
      if (spanRange.span == span) {
        result.add(
          renderPar.getBoxesForSelection(
            TextSelection(
              baseOffset: spanRange.textRange.start,
              extentOffset: spanRange.textRange.end,
            ),
          ),
        );
      }
    }

    return result;
  }
}
