import 'dart:math';
import 'dart:ui' as ui;
import 'package:clickable_pattern_text/text_canvas/span_handler.dart';
import 'package:flutter/painting.dart' as paint;

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

// class TextCanvas extends StatefulWidget {
//   final TextSpanHandler? span;
//   final TextDirection? textDirection;
//   final GlobalKey? relativePositionAncestorKey;
//   final GlobalKey? relativePositionKey;
//   TextCanvas({
//     this.span,
//     Key? key,
//     this.textDirection,
//     this.relativePositionAncestorKey,
//     this.relativePositionKey,
//   }) : super(key: key);

//   @override
//   TextCanvasState createState() => TextCanvasState();
// }

// class TextCanvasState extends State<TextCanvas> {
//   final _canvasKey = GlobalKey<TextCanvasState>();

//   @override
//   Widget build(BuildContext context) {
//     // var searchSpan = TextSpanHandler(
//     //   text: 'bbb',
//     //   onSpanPositioned: (textBoxes) {
//     //     print(textBoxes);
//     //   },
//     // );
//     return Container(
//       decoration: BoxDecoration(
//           border: Border.all(
//         width: 1,
//         color: Colors.black,
//       )),
//       child: LayoutBuilder(builder: (context, box) {
//         var textPainter = TextHandlerPainter(
//             text: widget.span,
//             textDirection: widget.textDirection ?? Directionality.of(context));
//         textPainter.layout(maxWidth: box.maxWidth, minWidth: box.minWidth);
//         return CustomPaint(
//           key: _canvasKey,
//           willChange: true,
//           child: SizedBox(
//             height: textPainter.height,
//             width: textPainter.width,
//           ),
//           size: textPainter.size,
//           painter: SpanCanvasPainter(
//             widget.span,
//             canvasKey: _canvasKey,
//             relativePositionAncestorKey: widget.relativePositionAncestorKey,
//             relativePositionKey: widget.relativePositionKey,
//             paragraphBuilded: (par, spans) {
//               // if (spans.containsKey(searchSpan)) {
//               //   print(par.getBoxesForRange(
//               //       spans[searchSpan]!.start, spans[searchSpan]!.end));
//               // }
//               // for (var spanRange in spans) {
//               //   if (spanRange.span == searchSpan) {
//               //     print(par.getBoxesForRange(
//               //         spanRange.textRange.start, spanRange.textRange.end));
//               //   }
//               // }
//             },
//           ),
//         );
//       }),
//     );
//   }

//   Future<void> ensureVisible(
//     TextSpanHandler span, {
//     double alignment = 0.0,
//     Duration duration = Duration.zero,
//     Curve curve = Curves.ease,
//     ScrollPositionAlignmentPolicy alignmentPolicy =
//         ScrollPositionAlignmentPolicy.explicit,
//     double offset = 0,
//   }) {
//     return Scrollable.ensureVisible(
//       _canvasKey.currentContext!,
//       alignment: alignment,
//       alignmentPolicy: alignmentPolicy,
//       curve: curve,
//       duration: duration,
//       offset: span.lastTextBoxes!.first.top + offset,
//     );
//   }
// }

// class SpanCanvasPainter extends CustomPainter {
//   final TextSpanHandler? span;
//   final GlobalKey canvasKey;
//   final GlobalKey? relativePositionAncestorKey;
//   final GlobalKey? relativePositionKey;
//   final Function(
//           ui.Paragraph, Map<TextSpanHandler, TextRange> spanTextPositions)?
//       paragraphBuilded;
//   SpanCanvasPainter(
//     this.span, {
//     required this.canvasKey,
//     this.relativePositionAncestorKey,
//     this.relativePositionKey,
//     this.paragraphBuilded,
//   });

//   @override
//   void paint(Canvas canvas, Size size) {
//     if (span != null) {
//       var parBuilder = ui.ParagraphBuilder(ui.ParagraphStyle());
//       Accumulator offset = Accumulator();
//       Map<TextSpanHandler, TextRange> spanTextRangeMap = {};
//       onTextBuilded(TextSpanHandler span, TextRange range) {
//         spanTextRangeMap[span] = range;
//       }

//       span!.build(parBuilder, offset, onTextBuilded);
//       var par = parBuilder.build();
//       par.layout(ui.ParagraphConstraints(width: size.width));
//       paragraphBuilded?.call(par, spanTextRangeMap);
//       // Offset canvasRelativeOffset = Offset(0, 0);
//       // if (canvasKey.currentContext != null) {
//       //   var canvasRenderBox =
//       //       canvasKey.currentContext!.findRenderObject() as RenderBox?;
//       //   if (canvasRenderBox != null) {
//       //     if (relativePositionAncestorKey?.currentContext != null) {
//       //       canvasRelativeOffset = canvasRenderBox.localToGlobal(Offset.zero,
//       //           ancestor: relativePositionAncestorKey!.currentContext!
//       //               .findRenderObject());
//       //     } else if (relativePositionKey?.currentContext != null) {
//       //       var relativeRenderBox = relativePositionKey!.currentContext!
//       //           .findRenderObject() as RenderBox?;
//       //       if (relativeRenderBox != null) {
//       //         var relativeOffset = relativeRenderBox.localToGlobal(Offset.zero);
//       //         canvasRelativeOffset = canvasRenderBox
//       //             .localToGlobal(Offset.zero)
//       //             .translate(-relativeOffset.dx, -relativeOffset.dy);
//       //       }
//       //     }
//       //   }
//       // }
//       span!.invokePositioned(
//         par,
//         spanTextRangeMap,
//         // canvasRelativeOffset,
//       );
//       canvas.drawParagraph(par, Offset.zero);
//     }
//     // double fontSize = 20;
//     // var texts = ['a b c', 'def', 'ghi'];
//     // var index = 0;
//     // var styles = [
//     //   ui.TextStyle(color: Colors.black, fontSize: fontSize, height: 1),
//     //   ui.TextStyle(color: Colors.red, fontSize: fontSize, height: 1),
//     //   ui.TextStyle(color: Colors.blue, fontSize: fontSize, height: 1)
//     // ];
//     // Offset lastOffsetEnd = Offset(0, 0);
//     // double lastHeight = 0;
//     // for (var text in texts) {
//     //   var parBuilder = ui.ParagraphBuilder(ui.ParagraphStyle());

//     //   // parBuilder.addPlaceholder(
//     //   //     0, lastHeight * 0.5, PlaceholderAlignment.middle);
//     //   for (var i = 0; i < text.characters.length; i++) {
//     //     var char = text.characters.characterAt(i);
//     //     // parBuilder.pushStyle(styles[i % 3]);
//     //     // parBuilder.addText(char.toString());
//     //   }
//     //   parBuilder.pushStyle(styles[0]);
//     //   parBuilder.addText(text);
//     //   var par = parBuilder.build();
//     //   par.layout(ui.ParagraphConstraints(width: size.width));
//     //   // print(par.computeLineMetrics());
//     //   print(par.getPositionForOffset(Offset(10, 20)));
//     //   // print(par.getLineBoundary(TextPosition(offset: 1)));
//     //   var textBoxes = par.getBoxesForRange(0, 9223372036854775807);
//     //   // print(textBoxes);
//     //   // print(par.getLineBoundary(TextPosition(offset: 2)));
//     //   var lastBox = textBoxes.last;
//     //   canvas.drawParagraph(par, lastOffsetEnd);
//     //   lastOffsetEnd = lastOffsetEnd.translate(
//     //       lastBox.right,
//     //       lastBox.top +
//     //           (-0.00001 * fontSize * fontSize + 0.1385 * fontSize - 0.02));
//     //   lastHeight = lastBox.bottom / textBoxes.length;
//     // }
//   }

//   void drawSpanParagraph(InlineSpan span, ui.ParagraphBuilder parBuilder,
//       Accumulator offset, ui.TextStyle defaultStyle) {
//     if (span.style != null) {
//       parBuilder.pushStyle(span.style!.toUi());
//     } else {
//       parBuilder.pushStyle(defaultStyle);
//     }
//     var text = span.toPlainText();
//     span.build(parBuilder);
//     parBuilder.addText(text);
//     offset.increment(text.length);
//   }

//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) {
//     return true;
//   }
// }

class RichTextPositioner extends StatefulWidget {
  /// The text to display in this widget.
  final InlineSpan text;

  /// How the text should be aligned horizontally.
  final TextAlign textAlign;

  /// The directionality of the text.
  ///
  /// This decides how [textAlign] values like [TextAlign.start] and
  /// [TextAlign.end] are interpreted.
  ///
  /// This is also used to disambiguate how to render bidirectional text. For
  /// example, if the [text] is an English phrase followed by a Hebrew phrase,
  /// in a [TextDirection.ltr] context the English phrase will be on the left
  /// and the Hebrew phrase to its right, while in a [TextDirection.rtl]
  /// context, the English phrase will be on the right and the Hebrew phrase on
  /// its left.
  ///
  /// Defaults to the ambient [Directionality], if any. If there is no ambient
  /// [Directionality], then this must not be null.
  final TextDirection? textDirection;

  /// Whether the text should break at soft line breaks.
  ///
  /// If false, the glyphs in the text will be positioned as if there was unlimited horizontal space.
  final bool softWrap;

  /// How visual overflow should be handled.
  final TextOverflow overflow;

  /// The number of font pixels for each logical pixel.
  ///
  /// For example, if the text scale factor is 1.5, text will be 50% larger than
  /// the specified font size.
  final double textScaleFactor;

  /// An optional maximum number of lines for the text to span, wrapping if necessary.
  /// If the text exceeds the given number of lines, it will be truncated according
  /// to [overflow].
  ///
  /// If this is 1, text will not wrap. Otherwise, text will be wrapped at the
  /// edge of the box.
  final int? maxLines;

  /// Used to select a font when the same Unicode character can
  /// be rendered differently, depending on the locale.
  ///
  /// It's rarely necessary to set this property. By default its value
  /// is inherited from the enclosing app with `Localizations.localeOf(context)`.
  ///
  /// See [RenderParagraph.locale] for more information.
  final Locale? locale;

  /// {@macro flutter.painting.textPainter.strutStyle}
  final StrutStyle? strutStyle;

  /// {@macro flutter.painting.textPainter.textWidthBasis}
  final TextWidthBasis textWidthBasis;

  /// {@macro flutter.dart:ui.textHeightBehavior}
  final ui.TextHeightBehavior? textHeightBehavior;

  const RichTextPositioner({
    Key? key,
    required this.text,
    this.textAlign = TextAlign.start,
    this.textDirection,
    this.softWrap = true,
    this.overflow = TextOverflow.clip,
    this.textScaleFactor = 1.0,
    this.maxLines,
    this.locale,
    this.strutStyle,
    this.textWidthBasis = TextWidthBasis.parent,
    this.textHeightBehavior,
  }) : super(key: key);

  @override
  RichTextPositionerState createState() => RichTextPositionerState();
}

class RichTextPositionerState extends State<RichTextPositioner> {
  final _containerKey = GlobalKey();
  BoxConstraints? _boxConstraints;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      _boxConstraints = box;
      return Container(
        key: _containerKey,
        child: RichText(
          text: widget.text,
        ),
      );
    });
  }

  Future<void> ensureVisible(
    InlineSpan span, {
    double alignment = 0.0,
    Duration duration = Duration.zero,
    Curve curve = Curves.ease,
    ScrollPositionAlignmentPolicy alignmentPolicy =
        ScrollPositionAlignmentPolicy.explicit,
    double offset = 0,
  }) {
    var textPainter = TextPainter(
      text: widget.text,
      textDirection: widget.textDirection ?? Directionality.of(context),
    );
    List<List<TextBox>> textBoxes = textPainter.getBoxesForSpan(
        widget.text, span,
        maxWidth: _boxConstraints!.maxWidth, minWidth: 0);
    if (textBoxes.isEmpty || textBoxes.first.isEmpty) return Future.value();
    return ScrollableExtension.ensureVisibleOffset(
      _containerKey.currentContext!,
      alignment: alignment,
      alignmentPolicy: alignmentPolicy,
      curve: curve,
      duration: duration,
      offset: textBoxes.last.first.top + offset,
    );
  }
}

class TextCanvas2 extends StatefulWidget {
  final InlineSpan? text;
  final TextDirection? textDirection;
  final GlobalKey? relativePositionAncestorKey;
  final GlobalKey? relativePositionKey;
  TextCanvas2({
    this.text,
    Key? key,
    this.textDirection,
    this.relativePositionAncestorKey,
    this.relativePositionKey,
  }) : super(key: key);

  @override
  TextCanvas2State createState() => TextCanvas2State();
}

class TextCanvas2State extends State<TextCanvas2> {
  final _canvasKey = GlobalKey<TextCanvas2State>();

  BoxConstraints? constraints;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      constraints = box;
      var textPainter = TextPainter(
          text: widget.text,
          textDirection: widget.textDirection ?? Directionality.of(context));
      textPainter.layout(maxWidth: box.maxWidth, minWidth: box.minWidth);
      return CustomPaint(
        key: _canvasKey,
        willChange: true,
        child: SizedBox(
          height: textPainter.height,
          width: textPainter.width,
        ),
        size: textPainter.size,
        painter: SpanCanvasPainter2(
          widget.text,
          canvasKey: _canvasKey,
          relativePositionAncestorKey: widget.relativePositionAncestorKey,
          relativePositionKey: widget.relativePositionKey,
          paragraphBuilded: (par, spans) {
            // if (spans.containsKey(searchSpan)) {
            //   print(par.getBoxesForRange(
            //       spans[searchSpan]!.start, spans[searchSpan]!.end));
            // }
            // for (var spanRange in spans) {
            //   if (spanRange.span == searchSpan) {
            //     print(par.getBoxesForRange(
            //         spanRange.textRange.start, spanRange.textRange.end));
            //   }
            // }
          },
        ),
      );
    });
  }

  Future<void> ensureVisible(
    InlineSpan span, {
    double alignment = 0.0,
    Duration duration = Duration.zero,
    Curve curve = Curves.ease,
    ScrollPositionAlignmentPolicy alignmentPolicy =
        ScrollPositionAlignmentPolicy.explicit,
    double offset = 0,
  }) {
    var textPainter = TextPainter(
        text: widget.text,
        textDirection: widget.textDirection ?? Directionality.of(context));
    List<List<TextBox>> textBoxes = textPainter.getBoxesForSpan(
        widget.text!, span,
        maxWidth: constraints!.maxWidth, minWidth: constraints!.minWidth);
    if (textBoxes.isEmpty || textBoxes.first.isEmpty) return Future.value();
    return ScrollableExtension.ensureVisibleOffset(
      _canvasKey.currentContext!,
      alignment: alignment,
      alignmentPolicy: alignmentPolicy,
      curve: curve,
      duration: duration,
      offset: textBoxes.first.first.top + offset,
    );
  }
}

class SpanCanvasPainter2 extends CustomPainter {
  final InlineSpan? text;
  final GlobalKey canvasKey;
  final GlobalKey? relativePositionAncestorKey;
  final GlobalKey? relativePositionKey;
  final Function(
          ui.Paragraph, Map<TextSpanHandler, TextRange> spanTextPositions)?
      paragraphBuilded;
  SpanCanvasPainter2(
    this.text, {
    required this.canvasKey,
    this.relativePositionAncestorKey,
    this.relativePositionKey,
    this.paragraphBuilded,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (text != null) {
      var parBuilder = ui.ParagraphBuilder(ui.ParagraphStyle());

      text!.build(parBuilder);
      var par = parBuilder.build();
      par.layout(ui.ParagraphConstraints(width: size.width));
      canvas.drawParagraph(par, Offset.zero);
    }
  }

  void drawSpanParagraph(InlineSpan span, ui.ParagraphBuilder parBuilder,
      Accumulator offset, ui.TextStyle defaultStyle) {
    if (span.style != null) {
      parBuilder.pushStyle(span.style!.toUi());
    } else {
      parBuilder.pushStyle(defaultStyle);
    }
    var text = span.toPlainText();
    span.build(parBuilder);
    parBuilder.addText(text);
    offset.increment(text.length);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

extension TextStyleUIMethods on paint.TextStyle {
  ui.TextStyle toUi() {
    return ui.TextStyle(
      background: background,
      color: color,
      decoration: decoration,
      decorationColor: decorationColor,
      decorationThickness: decorationThickness,
      decorationStyle: decorationStyle,
      fontFamily: fontFamily,
      fontFamilyFallback: fontFamilyFallback,
      fontFeatures: fontFeatures,
      fontSize: fontSize,
      fontStyle: fontStyle,
      fontWeight: fontWeight,
      foreground: foreground,
      height: height,
      leadingDistribution: leadingDistribution,
      letterSpacing: letterSpacing,
      locale: locale,
      shadows: shadows,
      textBaseline: textBaseline,
      wordSpacing: wordSpacing,
    );
  }
}
