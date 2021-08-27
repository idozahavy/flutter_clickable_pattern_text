import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';

const double _kDefaultFontSize = 14.0;

class InlineSpanTextRange {
  final InlineSpan span;
  final TextRange textRange;
  InlineSpanTextRange(this.span, this.textRange);
}

extension InlineSpanPositions on InlineSpan {
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
  List<List<TextBox>> getBoxesForSpan(
      InlineSpan parentSpan, InlineSpan specificSpan,
      {double minWidth = 0.0, double maxWidth = double.infinity}) {
    layout(minWidth: minWidth, maxWidth: maxWidth);
    final List<List<TextBox>> result = [];

    var ranges = text!.getTextRanges();

    final ui.ParagraphBuilder builder = ui.ParagraphBuilder(
      parentSpan.style?.getParagraphStyle(
            textAlign: textAlign,
            textDirection: textDirection,
            textScaleFactor: textScaleFactor,
            maxLines: maxLines,
            textHeightBehavior: textHeightBehavior,
            ellipsis: ellipsis,
            locale: locale,
            strutStyle: strutStyle,
          ) ??
          ui.ParagraphStyle(
            textAlign: textAlign,
            textDirection: textDirection,
            fontSize: _kDefaultFontSize * textScaleFactor,
            maxLines: maxLines,
            textHeightBehavior: textHeightBehavior,
            ellipsis: ellipsis,
            locale: locale,
          ),
    );
    parentSpan.build(builder,
        textScaleFactor: textScaleFactor, dimensions: null);
    var paragraph = builder.build();

    paragraph.layout(ui.ParagraphConstraints(width: maxWidth));
    if (minWidth != maxWidth) {
      double newWidth;
      switch (textWidthBasis) {
        case TextWidthBasis.longestLine:
          newWidth = _applyFloatingPointHack(paragraph.longestLine);
          break;
        case TextWidthBasis.parent:
          newWidth = maxIntrinsicWidth;
          break;
      }
      newWidth = newWidth.clamp(minWidth, maxWidth);
      if (newWidth != _applyFloatingPointHack(paragraph.width)) {
        paragraph.layout(ui.ParagraphConstraints(width: newWidth));
      }
    }

    for (var spanRange in ranges) {
      if (spanRange.span == specificSpan) {
        result.add(paragraph.getBoxesForRange(
            spanRange.textRange.start, spanRange.textRange.end));
      }
    }

    return result;
  }

  double _applyFloatingPointHack(double layoutValue) {
    return layoutValue.ceilToDouble();
  }
}

extension ScrollableExtension on Scrollable {
  static Future<void> ensureVisibleOffset(
    BuildContext context, {
    double alignment = 0.0,
    Duration duration = Duration.zero,
    Curve curve = Curves.ease,
    ScrollPositionAlignmentPolicy alignmentPolicy =
        ScrollPositionAlignmentPolicy.explicit,
    double offset = 0.0,
  }) {
    final List<Future<void>> futures = <Future<void>>[];
    RenderObject? targetRenderObject;
    ScrollableState? scrollable = Scrollable.of(context);
    while (scrollable != null) {
      futures.add(scrollable.position.ensureVisibleOffset(
        context.findRenderObject()!,
        alignment: alignment,
        duration: duration,
        curve: curve,
        alignmentPolicy: alignmentPolicy,
        targetRenderObject: targetRenderObject,
        offset: offset,
      ));

      targetRenderObject = targetRenderObject ?? context.findRenderObject();
      context = scrollable.context;
      scrollable = Scrollable.of(context);
    }

    if (futures.isEmpty || duration == Duration.zero)
      return Future<void>.value();
    if (futures.length == 1) return futures.single;
    return Future.wait<void>(futures).then<void>((List<void> _) => null);
  }
}

extension ScrollPositionExt on ScrollPosition {
  Future<void> ensureVisibleOffset(
    RenderObject object, {
    double alignment = 0.0,
    Duration duration = Duration.zero,
    Curve curve = Curves.ease,
    ScrollPositionAlignmentPolicy alignmentPolicy =
        ScrollPositionAlignmentPolicy.explicit,
    RenderObject? targetRenderObject,
    double offset = 0.0,
  }) {
    assert(object.attached);
    final RenderAbstractViewport viewport = RenderAbstractViewport.of(object)!;

    Rect? targetRect;
    if (targetRenderObject != null && targetRenderObject != object) {
      targetRect = MatrixUtils.transformRect(
        targetRenderObject.getTransformTo(object),
        object.paintBounds.intersect(targetRenderObject.paintBounds),
      );
    }

    double target;
    switch (alignmentPolicy) {
      case ScrollPositionAlignmentPolicy.explicit:
        target = (viewport
                    .getOffsetToReveal(object, alignment, rect: targetRect)
                    .offset +
                offset)
            .clamp(minScrollExtent, maxScrollExtent);
        break;
      case ScrollPositionAlignmentPolicy.keepVisibleAtEnd:
        target =
            (viewport.getOffsetToReveal(object, 1.0, rect: targetRect).offset +
                    offset)
                .clamp(minScrollExtent, maxScrollExtent);
        if (target < pixels) {
          target = pixels;
        }
        break;
      case ScrollPositionAlignmentPolicy.keepVisibleAtStart:
        target =
            (viewport.getOffsetToReveal(object, 0.0, rect: targetRect).offset +
                    offset)
                .clamp(minScrollExtent, maxScrollExtent);
        if (target > pixels) {
          target = pixels;
        }
        break;
    }

    if (target == pixels) return Future<void>.value();

    if (duration == Duration.zero) {
      jumpTo(target);
      return Future<void>.value();
    }

    return animateTo(target, duration: duration, curve: curve);
  }
}

class TextSpanHandler {
  TextSpanHandler({
    this.children,
    this.text,
    this.style,
    this.recognizer,
    this.semanticsLabel,
    this.onSpanPositioned,
  }) : assert(!(text == null && semanticsLabel != null));

  final String? text;

  final TextStyle? style;

  final List<TextSpanHandler>? children;

  final GestureRecognizer? recognizer;

  final String? semanticsLabel;

  final Function(
    TextSpanHandler span,
    List<TextBox> textBoxes,
    // List<TextBox> relativeTextBoxes,
  )? onSpanPositioned;

  List<TextBox>? lastTextBoxes;
  List<TextBox>? lastRelativeTextBoxes;

  void build(
    ui.ParagraphBuilder builder,
    Accumulator offset,
    Function(TextSpanHandler span, TextRange range) onTextPositioned, {
    List<PlaceholderDimensions>? dimensions,
    double textScaleFactor = 1.0,
  }) {
    final bool hasStyle = style != null;
    if (hasStyle)
      builder.pushStyle(style!.getTextStyle(textScaleFactor: textScaleFactor));

    if (text != null) {
      builder.addText(text!);
      onTextPositioned(
        this,
        TextRange(start: offset.value, end: offset.value + text!.length),
      );
      offset.increment(text!.length);
    }
    if (children != null) {
      for (final TextSpanHandler? child in children!) {
        assert(child != null);
        child!.build(
          builder,
          offset,
          onTextPositioned,
          textScaleFactor: textScaleFactor,
          dimensions: dimensions,
        );
      }
    }
    if (hasStyle) builder.pop();
  }

  void invokePositioned(
    ui.Paragraph par,
    Map<TextSpanHandler, TextRange> spanRangeMap,
    // Offset relativeOffset,
  ) {
    visitChildren((span) {
      if (spanRangeMap.containsKey(span)) {
        lastTextBoxes = par.getBoxesForRange(
            spanRangeMap[span]!.start, spanRangeMap[span]!.end);
        // lastRelativeTextBoxes = lastTextBoxes!.map((e) {
        //   return TextBox.fromLTRBD(
        //     e.left + relativeOffset.dx,
        //     e.top + relativeOffset.dy,
        //     e.right + relativeOffset.dx,
        //     e.bottom + relativeOffset.dy,
        //     e.direction,
        //   );
        // }).toList();
        Future.delayed(Duration.zero, () {
          span.onSpanPositioned?.call(
            this,
            lastTextBoxes!,
            // lastRelativeTextBoxes!,
          );
        });
      }
      return true;
    });
  }

  void handleEvent(PointerEvent event, HitTestEntry entry) {
    if (event is PointerDownEvent) recognizer?.addPointer(event);
  }

  /// Walks this [TextSpan] and its descendants in pre-order and calls [visitor]
  /// for each span that has text.
  ///
  /// When `visitor` returns true, the walk will continue. When `visitor`
  /// returns false, then the walk will end.
  bool visitChildren(bool Function(TextSpanHandler) visitor) {
    if (text != null) {
      if (!visitor(this)) return false;
    }
    if (children != null) {
      for (final TextSpanHandler child in children!) {
        if (!child.visitChildren(visitor)) return false;
      }
    }
    return true;
  }

  /// Returns the text span that contains the given position in the text.
  TextSpanHandler? getSpanForPositionVisitor(
      TextPosition position, Accumulator offset) {
    if (text == null) {
      return null;
    }
    final TextAffinity affinity = position.affinity;
    final int targetOffset = position.offset;
    final int endOffset = offset.value + text!.length;
    if (offset.value == targetOffset && affinity == TextAffinity.downstream ||
        offset.value < targetOffset && targetOffset < endOffset ||
        endOffset == targetOffset && affinity == TextAffinity.upstream) {
      return this;
    }
    offset.increment(text!.length);
    return null;
  }

  void computeToPlainText(
    StringBuffer buffer, {
    bool includeSemanticsLabels = false,
    bool includePlaceholders = false,
  }) {
    if (semanticsLabel != null && includeSemanticsLabels) {
      buffer.write(semanticsLabel);
    } else if (text != null) {
      buffer.write(text);
    }
    if (children != null) {
      for (final TextSpanHandler child in children!) {
        child.computeToPlainText(
          buffer,
          includeSemanticsLabels: includeSemanticsLabels,
          includePlaceholders: includePlaceholders,
        );
      }
    }
  }

  int? codeUnitAtVisitor(int index, Accumulator offset) {
    if (text == null) {
      return null;
    }
    if (index - offset.value < text!.length) {
      return text!.codeUnitAt(index - offset.value);
    }
    offset.increment(text!.length);
    return null;
  }

  /// Populates the `semanticsOffsets` and `semanticsElements` with the appropriate data
  /// to be able to construct a [SemanticsNode].
  ///
  /// If applicable, the beginning and end text offset are added to [semanticsOffsets].
  /// [PlaceholderSpan]s have a text length of 1, which corresponds to the object
  /// replacement character (0xFFFC) that is inserted to represent it.
  ///
  /// Any [GestureRecognizer]s are added to `semanticsElements`. Null is added to
  /// `semanticsElements` for [PlaceholderSpan]s.
  void describeSemantics(Accumulator offset, List<int> semanticsOffsets,
      List<dynamic> semanticsElements) {
    if (recognizer != null &&
        (recognizer is TapGestureRecognizer ||
            recognizer is LongPressGestureRecognizer)) {
      final int length = semanticsLabel?.length ?? text!.length;
      semanticsOffsets.add(offset.value);
      semanticsOffsets.add(offset.value + length);
      semanticsElements.add(recognizer);
    }
    offset.increment(text != null ? text!.length : 0);
  }

  String toPlainText(
      {bool includeSemanticsLabels = true, bool includePlaceholders = true}) {
    final StringBuffer buffer = StringBuffer();
    computeToPlainText(buffer,
        includeSemanticsLabels: includeSemanticsLabels,
        includePlaceholders: includePlaceholders);
    return buffer.toString();
  }

  RenderComparison compareTo(InlineSpan other) {
    if (identical(this, other)) return RenderComparison.identical;
    if (other.runtimeType != runtimeType) return RenderComparison.layout;
    final TextSpan textSpan = other as TextSpan;
    if (textSpan.text != text ||
        children?.length != textSpan.children?.length ||
        (style == null) != (textSpan.style == null))
      return RenderComparison.layout;
    RenderComparison result = recognizer == textSpan.recognizer
        ? RenderComparison.identical
        : RenderComparison.metadata;
    if (style != null) {
      final RenderComparison candidate = style!.compareTo(textSpan.style!);
      if (candidate.index > result.index) result = candidate;
      if (result == RenderComparison.layout) return result;
    }
    if (children != null) {
      for (int index = 0; index < children!.length; index += 1) {
        final RenderComparison candidate =
            children![index].compareTo(textSpan.children![index]);
        if (candidate.index > result.index) result = candidate;
        if (result == RenderComparison.layout) return result;
      }
    }
    return result;
  }

  int? codeUnitAt(int index) {
    if (index < 0) return null;
    final Accumulator offset = Accumulator();
    int? result;
    visitChildren((TextSpanHandler span) {
      result = span.codeUnitAtVisitor(index, offset);
      return result == null;
    });
    return result;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    if (super != other) return false;
    return other is TextSpanHandler &&
        other.text == text &&
        other.recognizer == recognizer &&
        other.semanticsLabel == semanticsLabel &&
        listEquals<TextSpanHandler>(other.children, children);
  }

  @override
  int get hashCode => hashValues(
        super.hashCode,
        text,
        recognizer,
        semanticsLabel,
        hashList(children),
      );

  String toStringShort() => objectRuntimeType(this, 'TextSpanHanlder');
}

// class TextHandlerPainter {
//   /// Creates a text painter that paints the given text.
//   ///
//   /// The `text` and `textDirection` arguments are optional but [text] and
//   /// [textDirection] must be non-null before calling [layout].
//   ///
//   /// The [textAlign] property must not be null.
//   ///
//   /// The [maxLines] property, if non-null, must be greater than zero.
//   TextHandlerPainter({
//     TextSpanHandler? text,
//     TextAlign textAlign = TextAlign.start,
//     TextDirection? textDirection,
//     double textScaleFactor = 1.0,
//     int? maxLines,
//     String? ellipsis,
//     Locale? locale,
//     StrutStyle? strutStyle,
//     TextWidthBasis textWidthBasis = TextWidthBasis.parent,
//     ui.TextHeightBehavior? textHeightBehavior,
//   })  : assert(maxLines == null || maxLines > 0),
//         _text = text,
//         _textAlign = textAlign,
//         _textDirection = textDirection,
//         _textScaleFactor = textScaleFactor,
//         _maxLines = maxLines,
//         _ellipsis = ellipsis,
//         _locale = locale,
//         _strutStyle = strutStyle,
//         _textWidthBasis = textWidthBasis,
//         _textHeightBehavior = textHeightBehavior;

//   ui.Paragraph? _paragraph;
//   bool _needsLayout = true;

//   /// Marks this text painter's layout information as dirty and removes cached
//   /// information.
//   ///
//   /// Uses this method to notify text painter to relayout in the case of
//   /// layout changes in engine. In most cases, updating text painter properties
//   /// in framework will automatically invoke this method.
//   void markNeedsLayout() {
//     _paragraph = null;
//     _needsLayout = true;
//     _previousCaretPosition = null;
//     _previousCaretPrototype = null;
//   }

//   /// The (potentially styled) text to paint.
//   ///
//   /// After this is set, you must call [layout] before the next call to [paint].
//   /// This and [textDirection] must be non-null before you call [layout].
//   ///
//   /// The [InlineSpan] this provides is in the form of a tree that may contain
//   /// multiple instances of [TextSpan]s and [WidgetSpan]s. To obtain a plain text
//   /// representation of the contents of this [TextPainter], use [InlineSpan.toPlainText]
//   /// to get the full contents of all nodes in the tree. [TextSpan.text] will
//   /// only provide the contents of the first node in the tree.
//   TextSpanHandler? get text => _text;
//   TextSpanHandler? _text;
//   set text(TextSpanHandler? value) {
//     assert(value == null);
//     if (_text == value) return;
//     if (_text?.style != value?.style) _layoutTemplate = null;
//     _text = value;
//     markNeedsLayout();
//   }

//   /// How the text should be aligned horizontally.
//   ///
//   /// After this is set, you must call [layout] before the next call to [paint].
//   ///
//   /// The [textAlign] property must not be null. It defaults to [TextAlign.start].
//   TextAlign get textAlign => _textAlign;
//   TextAlign _textAlign;
//   set textAlign(TextAlign value) {
//     if (_textAlign == value) return;
//     _textAlign = value;
//     markNeedsLayout();
//   }

//   /// The default directionality of the text.
//   ///
//   /// This controls how the [TextAlign.start], [TextAlign.end], and
//   /// [TextAlign.justify] values of [textAlign] are resolved.
//   ///
//   /// This is also used to disambiguate how to render bidirectional text. For
//   /// example, if the [text] is an English phrase followed by a Hebrew phrase,
//   /// in a [TextDirection.ltr] context the English phrase will be on the left
//   /// and the Hebrew phrase to its right, while in a [TextDirection.rtl]
//   /// context, the English phrase will be on the right and the Hebrew phrase on
//   /// its left.
//   ///
//   /// After this is set, you must call [layout] before the next call to [paint].
//   ///
//   /// This and [text] must be non-null before you call [layout].
//   TextDirection? get textDirection => _textDirection;
//   TextDirection? _textDirection;
//   set textDirection(TextDirection? value) {
//     if (_textDirection == value) return;
//     _textDirection = value;
//     markNeedsLayout();
//     _layoutTemplate =
//         null; // Shouldn't really matter, but for strict correctness...
//   }

//   /// The number of font pixels for each logical pixel.
//   ///
//   /// For example, if the text scale factor is 1.5, text will be 50% larger than
//   /// the specified font size.
//   ///
//   /// After this is set, you must call [layout] before the next call to [paint].
//   double get textScaleFactor => _textScaleFactor;
//   double _textScaleFactor;
//   set textScaleFactor(double value) {
//     if (_textScaleFactor == value) return;
//     _textScaleFactor = value;
//     markNeedsLayout();
//     _layoutTemplate = null;
//   }

//   /// The string used to ellipsize overflowing text. Setting this to a non-empty
//   /// string will cause this string to be substituted for the remaining text
//   /// if the text can not fit within the specified maximum width.
//   ///
//   /// Specifically, the ellipsis is applied to the last line before the line
//   /// truncated by [maxLines], if [maxLines] is non-null and that line overflows
//   /// the width constraint, or to the first line that is wider than the width
//   /// constraint, if [maxLines] is null. The width constraint is the `maxWidth`
//   /// passed to [layout].
//   ///
//   /// After this is set, you must call [layout] before the next call to [paint].
//   ///
//   /// The higher layers of the system, such as the [Text] widget, represent
//   /// overflow effects using the [TextOverflow] enum. The
//   /// [TextOverflow.ellipsis] value corresponds to setting this property to
//   /// U+2026 HORIZONTAL ELLIPSIS (…).
//   String? get ellipsis => _ellipsis;
//   String? _ellipsis;
//   set ellipsis(String? value) {
//     assert(value == null || value.isNotEmpty);
//     if (_ellipsis == value) return;
//     _ellipsis = value;
//     markNeedsLayout();
//   }

//   /// The locale used to select region-specific glyphs.
//   Locale? get locale => _locale;
//   Locale? _locale;
//   set locale(Locale? value) {
//     if (_locale == value) return;
//     _locale = value;
//     markNeedsLayout();
//   }

//   /// An optional maximum number of lines for the text to span, wrapping if
//   /// necessary.
//   ///
//   /// If the text exceeds the given number of lines, it is truncated such that
//   /// subsequent lines are dropped.
//   ///
//   /// After this is set, you must call [layout] before the next call to [paint].
//   int? get maxLines => _maxLines;
//   int? _maxLines;

//   /// The value may be null. If it is not null, then it must be greater than zero.
//   set maxLines(int? value) {
//     assert(value == null || value > 0);
//     if (_maxLines == value) return;
//     _maxLines = value;
//     markNeedsLayout();
//   }

//   /// {@template flutter.painting.textPainter.strutStyle}
//   /// The strut style to use. Strut style defines the strut, which sets minimum
//   /// vertical layout metrics.
//   ///
//   /// Omitting or providing null will disable strut.
//   ///
//   /// Omitting or providing null for any properties of [StrutStyle] will result in
//   /// default values being used. It is highly recommended to at least specify a
//   /// [StrutStyle.fontSize].
//   ///
//   /// See [StrutStyle] for details.
//   /// {@endtemplate}
//   StrutStyle? get strutStyle => _strutStyle;
//   StrutStyle? _strutStyle;
//   set strutStyle(StrutStyle? value) {
//     if (_strutStyle == value) return;
//     _strutStyle = value;
//     markNeedsLayout();
//   }

//   /// {@template flutter.painting.textPainter.textWidthBasis}
//   /// Defines how to measure the width of the rendered text.
//   /// {@endtemplate}
//   TextWidthBasis get textWidthBasis => _textWidthBasis;
//   TextWidthBasis _textWidthBasis;
//   set textWidthBasis(TextWidthBasis value) {
//     if (_textWidthBasis == value) return;
//     _textWidthBasis = value;
//     markNeedsLayout();
//   }

//   /// {@macro flutter.dart:ui.textHeightBehavior}
//   ui.TextHeightBehavior? get textHeightBehavior => _textHeightBehavior;
//   ui.TextHeightBehavior? _textHeightBehavior;
//   set textHeightBehavior(ui.TextHeightBehavior? value) {
//     if (_textHeightBehavior == value) return;
//     _textHeightBehavior = value;
//     markNeedsLayout();
//   }

//   ui.Paragraph? _layoutTemplate;

//   /// An ordered list of [TextBox]es that bound the positions of the placeholders
//   /// in the paragraph.
//   ///
//   /// Each box corresponds to a [PlaceholderSpan] in the order they were defined
//   /// in the [InlineSpan] tree.
//   List<TextBox>? get inlinePlaceholderBoxes => _inlinePlaceholderBoxes;
//   List<TextBox>? _inlinePlaceholderBoxes;

//   /// An ordered list of scales for each placeholder in the paragraph.
//   ///
//   /// The scale is used as a multiplier on the height, width and baselineOffset of
//   /// the placeholder. Scale is primarily used to handle accessibility scaling.
//   ///
//   /// Each scale corresponds to a [PlaceholderSpan] in the order they were defined
//   /// in the [InlineSpan] tree.
//   List<double>? get inlinePlaceholderScales => _inlinePlaceholderScales;
//   List<double>? _inlinePlaceholderScales;

//   /// Sets the dimensions of each placeholder in [text].
//   ///
//   /// The number of [PlaceholderDimensions] provided should be the same as the
//   /// number of [PlaceholderSpan]s in text. Passing in an empty or null `value`
//   /// will do nothing.
//   ///
//   /// If [layout] is attempted without setting the placeholder dimensions, the
//   /// placeholders will be ignored in the text layout and no valid
//   /// [inlinePlaceholderBoxes] will be returned.
//   void setPlaceholderDimensions(List<PlaceholderDimensions>? value) {
//     if (value == null ||
//         value.isEmpty ||
//         listEquals(value, _placeholderDimensions)) {
//       return;
//     }
//     assert(() {
//           int placeholderCount = 0;
//           text!.visitChildren((TextSpanHandler span) {
//             if (span is PlaceholderSpan) {
//               placeholderCount += 1;
//             }
//             return true;
//           });
//           return placeholderCount;
//         }() ==
//         value.length);
//     _placeholderDimensions = value;
//     markNeedsLayout();
//   }

//   List<PlaceholderDimensions>? _placeholderDimensions;

//   ui.ParagraphStyle _createParagraphStyle(
//       [TextDirection? defaultTextDirection]) {
//     // The defaultTextDirection argument is used for preferredLineHeight in case
//     // textDirection hasn't yet been set.
//     assert(textDirection != null || defaultTextDirection != null,
//         'TextPainter.textDirection must be set to a non-null value before using the TextPainter.');
//     return _text!.style?.getParagraphStyle(
//           textAlign: textAlign,
//           textDirection: textDirection ?? defaultTextDirection,
//           textScaleFactor: textScaleFactor,
//           maxLines: _maxLines,
//           textHeightBehavior: _textHeightBehavior,
//           ellipsis: _ellipsis,
//           locale: _locale,
//           strutStyle: _strutStyle,
//         ) ??
//         ui.ParagraphStyle(
//           textAlign: textAlign,
//           textDirection: textDirection ?? defaultTextDirection,
//           // Use the default font size to multiply by as RichText does not
//           // perform inheriting [TextStyle]s and would otherwise
//           // fail to apply textScaleFactor.
//           fontSize: _kDefaultFontSize * textScaleFactor,
//           maxLines: maxLines,
//           textHeightBehavior: _textHeightBehavior,
//           ellipsis: ellipsis,
//           locale: locale,
//         );
//   }

//   /// The height of a space in [text] in logical pixels.
//   ///
//   /// Not every line of text in [text] will have this height, but this height
//   /// is "typical" for text in [text] and useful for sizing other objects
//   /// relative a typical line of text.
//   ///
//   /// Obtaining this value does not require calling [layout].
//   ///
//   /// The style of the [text] property is used to determine the font settings
//   /// that contribute to the [preferredLineHeight]. If [text] is null or if it
//   /// specifies no styles, the default [TextStyle] values are used (a 10 pixel
//   /// sans-serif font).
//   double get preferredLineHeight {
//     if (_layoutTemplate == null) {
//       final ui.ParagraphBuilder builder = ui.ParagraphBuilder(
//         _createParagraphStyle(TextDirection.rtl),
//       ); // direction doesn't matter, text is just a space
//       if (text?.style != null)
//         builder.pushStyle(
//             text!.style!.getTextStyle(textScaleFactor: textScaleFactor));
//       builder.addText(' ');
//       _layoutTemplate = builder.build()
//         ..layout(const ui.ParagraphConstraints(width: double.infinity));
//     }
//     return _layoutTemplate!.height;
//   }

//   // Unfortunately, using full precision floating point here causes bad layouts
//   // because floating point math isn't associative. If we add and subtract
//   // padding, for example, we'll get different values when we estimate sizes and
//   // when we actually compute layout because the operations will end up associated
//   // differently. To work around this problem for now, we round fractional pixel
//   // values up to the nearest whole pixel value. The right long-term fix is to do
//   // layout using fixed precision arithmetic.
//   double _applyFloatingPointHack(double layoutValue) {
//     return layoutValue.ceilToDouble();
//   }

//   /// The width at which decreasing the width of the text would prevent it from
//   /// painting itself completely within its bounds.
//   ///
//   /// Valid only after [layout] has been called.
//   double get minIntrinsicWidth {
//     assert(!_needsLayout);
//     return _applyFloatingPointHack(_paragraph!.minIntrinsicWidth);
//   }

//   /// The width at which increasing the width of the text no longer decreases the height.
//   ///
//   /// Valid only after [layout] has been called.
//   double get maxIntrinsicWidth {
//     assert(!_needsLayout);
//     return _applyFloatingPointHack(_paragraph!.maxIntrinsicWidth);
//   }

//   /// The horizontal space required to paint this text.
//   ///
//   /// Valid only after [layout] has been called.
//   double get width {
//     assert(!_needsLayout);
//     return _applyFloatingPointHack(
//       textWidthBasis == TextWidthBasis.longestLine
//           ? _paragraph!.longestLine
//           : _paragraph!.width,
//     );
//   }

//   /// The vertical space required to paint this text.
//   ///
//   /// Valid only after [layout] has been called.
//   double get height {
//     assert(!_needsLayout);
//     return _applyFloatingPointHack(_paragraph!.height);
//   }

//   /// The amount of space required to paint this text.
//   ///
//   /// Valid only after [layout] has been called.
//   Size get size {
//     assert(!_needsLayout);
//     return Size(width, height);
//   }

//   /// Returns the distance from the top of the text to the first baseline of the
//   /// given type.
//   ///
//   /// Valid only after [layout] has been called.
//   double computeDistanceToActualBaseline(TextBaseline baseline) {
//     assert(!_needsLayout);
//     switch (baseline) {
//       case TextBaseline.alphabetic:
//         return _paragraph!.alphabeticBaseline;
//       case TextBaseline.ideographic:
//         return _paragraph!.ideographicBaseline;
//     }
//   }

//   /// Whether any text was truncated or ellipsized.
//   ///
//   /// If [maxLines] is not null, this is true if there were more lines to be
//   /// drawn than the given [maxLines], and thus at least one line was omitted in
//   /// the output; otherwise it is false.
//   ///
//   /// If [maxLines] is null, this is true if [ellipsis] is not the empty string
//   /// and there was a line that overflowed the `maxWidth` argument passed to
//   /// [layout]; otherwise it is false.
//   ///
//   /// Valid only after [layout] has been called.
//   bool get didExceedMaxLines {
//     assert(!_needsLayout);
//     return _paragraph!.didExceedMaxLines;
//   }

//   double? _lastMinWidth;
//   double? _lastMaxWidth;

//   /// Computes the visual position of the glyphs for painting the text.
//   ///
//   /// The text will layout with a width that's as close to its max intrinsic
//   /// width as possible while still being greater than or equal to `minWidth` and
//   /// less than or equal to `maxWidth`.
//   ///
//   /// The [text] and [textDirection] properties must be non-null before this is
//   /// called.
//   void layout({double minWidth = 0.0, double maxWidth = double.infinity}) {
//     assert(text != null,
//         'TextPainter.text must be set to a non-null value before using the TextPainter.');
//     assert(textDirection != null,
//         'TextPainter.textDirection must be set to a non-null value before using the TextPainter.');
//     if (!_needsLayout && minWidth == _lastMinWidth && maxWidth == _lastMaxWidth)
//       return;
//     _needsLayout = false;
//     if (_paragraph == null) {
//       final ui.ParagraphBuilder builder =
//           ui.ParagraphBuilder(_createParagraphStyle());
//       _text!.build(builder, Accumulator(), (_, __) {},
//           textScaleFactor: textScaleFactor, dimensions: _placeholderDimensions);
//       _inlinePlaceholderScales = builder.placeholderScales;
//       _paragraph = builder.build();
//     }
//     _lastMinWidth = minWidth;
//     _lastMaxWidth = maxWidth;
//     // A change in layout invalidates the cached caret metrics as well.
//     _previousCaretPosition = null;
//     _previousCaretPrototype = null;
//     _paragraph!.layout(ui.ParagraphConstraints(width: maxWidth));
//     if (minWidth != maxWidth) {
//       double newWidth;
//       switch (textWidthBasis) {
//         case TextWidthBasis.longestLine:
//           // The parent widget expects the paragraph to be exactly
//           // `TextPainter.width` wide, if that value satisfies the constraints
//           // it gave to the TextPainter. So when `textWidthBasis` is longestLine,
//           // the paragraph's width needs to be as close to the width of its
//           // longest line as possible.
//           newWidth = _applyFloatingPointHack(_paragraph!.longestLine);
//           break;
//         case TextWidthBasis.parent:
//           newWidth = maxIntrinsicWidth;
//           break;
//       }
//       newWidth = newWidth.clamp(minWidth, maxWidth);
//       if (newWidth != _applyFloatingPointHack(_paragraph!.width)) {
//         _paragraph!.layout(ui.ParagraphConstraints(width: newWidth));
//       }
//     }
//     _inlinePlaceholderBoxes = _paragraph!.getBoxesForPlaceholders();
//   }

//   /// Paints the text onto the given canvas at the given offset.
//   ///
//   /// Valid only after [layout] has been called.
//   ///
//   /// If you cannot see the text being painted, check that your text color does
//   /// not conflict with the background on which you are drawing. The default
//   /// text color is white (to contrast with the default black background color),
//   /// so if you are writing an application with a white background, the text
//   /// will not be visible by default.
//   ///
//   /// To set the text style, specify a [TextStyle] when creating the [TextSpan]
//   /// that you pass to the [TextPainter] constructor or to the [text] property.
//   void paint(Canvas canvas, Offset offset) {
//     assert(() {
//       if (_needsLayout) {
//         throw FlutterError(
//           'TextPainter.paint called when text geometry was not yet calculated.\n'
//           'Please call layout() before paint() to position the text before painting it.',
//         );
//       }
//       return true;
//     }());
//     canvas.drawParagraph(_paragraph!, offset);
//   }

//   // Returns true iff the given value is a valid UTF-16 surrogate. The value
//   // must be a UTF-16 code unit, meaning it must be in the range 0x0000-0xFFFF.
//   //
//   // See also:
//   //   * https://en.wikipedia.org/wiki/UTF-16#Code_points_from_U+010000_to_U+10FFFF
//   static bool _isUtf16Surrogate(int value) {
//     return value & 0xF800 == 0xD800;
//   }

//   // Checks if the glyph is either [Unicode.RLM] or [Unicode.LRM]. These values take
//   // up zero space and do not have valid bounding boxes around them.
//   //
//   // We do not directly use the [Unicode] constants since they are strings.
//   static bool _isUnicodeDirectionality(int value) {
//     return value == 0x200F || value == 0x200E;
//   }

//   /// Returns the closest offset after `offset` at which the input cursor can be
//   /// positioned.
//   int? getOffsetAfter(int offset) {
//     final int? nextCodeUnit = _text!.codeUnitAt(offset);
//     if (nextCodeUnit == null) return null;
//     return _isUtf16Surrogate(nextCodeUnit) ? offset + 2 : offset + 1;
//   }

//   /// Returns the closest offset before `offset` at which the input cursor can
//   /// be positioned.
//   int? getOffsetBefore(int offset) {
//     final int? prevCodeUnit = _text!.codeUnitAt(offset - 1);
//     if (prevCodeUnit == null) return null;
//     return _isUtf16Surrogate(prevCodeUnit) ? offset - 2 : offset - 1;
//   }

//   // Unicode value for a zero width joiner character.
//   static const int _zwjUtf16 = 0x200d;

//   // Get the Rect of the cursor (in logical pixels) based off the near edge
//   // of the character upstream from the given string offset.
//   Rect? _getRectFromUpstream(int offset, Rect caretPrototype) {
//     final String flattenedText = _text!.toPlainText(includePlaceholders: false);
//     final int? prevCodeUnit = _text!.codeUnitAt(max(0, offset - 1));
//     if (prevCodeUnit == null) return null;

//     // Check for multi-code-unit glyphs such as emojis or zero width joiner.
//     final bool needsSearch = _isUtf16Surrogate(prevCodeUnit) ||
//         _text!.codeUnitAt(offset) == _zwjUtf16 ||
//         _isUnicodeDirectionality(prevCodeUnit);
//     int graphemeClusterLength = needsSearch ? 2 : 1;
//     List<TextBox> boxes = <TextBox>[];
//     while (boxes.isEmpty) {
//       final int prevRuneOffset = offset - graphemeClusterLength;
//       // Use BoxHeightStyle.strut to ensure that the caret's height fits within
//       // the line's height and is consistent throughout the line.
//       boxes = _paragraph!.getBoxesForRange(prevRuneOffset, offset,
//           boxHeightStyle: ui.BoxHeightStyle.strut);
//       // When the range does not include a full cluster, no boxes will be returned.
//       if (boxes.isEmpty) {
//         // When we are at the beginning of the line, a non-surrogate position will
//         // return empty boxes. We break and try from downstream instead.
//         if (!needsSearch) {
//           break; // Only perform one iteration if no search is required.
//         }
//         if (prevRuneOffset < -flattenedText.length) {
//           break; // Stop iterating when beyond the max length of the text.
//         }
//         // Multiply by two to log(n) time cover the entire text span. This allows
//         // faster discovery of very long clusters and reduces the possibility
//         // of certain large clusters taking much longer than others, which can
//         // cause jank.
//         graphemeClusterLength *= 2;
//         continue;
//       }
//       final TextBox box = boxes.first;

//       // If the upstream character is a newline, cursor is at start of next line
//       const int NEWLINE_CODE_UNIT = 10;
//       if (prevCodeUnit == NEWLINE_CODE_UNIT) {
//         return Rect.fromLTRB(_emptyOffset.dx, box.bottom, _emptyOffset.dx,
//             box.bottom + box.bottom - box.top);
//       }

//       final double caretEnd = box.end;
//       final double dx = box.direction == TextDirection.rtl
//           ? caretEnd - caretPrototype.width
//           : caretEnd;
//       return Rect.fromLTRB(min(dx, _paragraph!.width), box.top,
//           min(dx, _paragraph!.width), box.bottom);
//     }
//     return null;
//   }

//   // Get the Rect of the cursor (in logical pixels) based off the near edge
//   // of the character downstream from the given string offset.
//   Rect? _getRectFromDownstream(int offset, Rect caretPrototype) {
//     final String flattenedText = _text!.toPlainText(includePlaceholders: false);
//     // We cap the offset at the final index of the _text.
//     final int? nextCodeUnit =
//         _text!.codeUnitAt(min(offset, flattenedText.length - 1));
//     if (nextCodeUnit == null) return null;
//     // Check for multi-code-unit glyphs such as emojis or zero width joiner
//     final bool needsSearch = _isUtf16Surrogate(nextCodeUnit) ||
//         nextCodeUnit == _zwjUtf16 ||
//         _isUnicodeDirectionality(nextCodeUnit);
//     int graphemeClusterLength = needsSearch ? 2 : 1;
//     List<TextBox> boxes = <TextBox>[];
//     while (boxes.isEmpty) {
//       final int nextRuneOffset = offset + graphemeClusterLength;
//       // Use BoxHeightStyle.strut to ensure that the caret's height fits within
//       // the line's height and is consistent throughout the line.
//       boxes = _paragraph!.getBoxesForRange(offset, nextRuneOffset,
//           boxHeightStyle: ui.BoxHeightStyle.strut);
//       // When the range does not include a full cluster, no boxes will be returned.
//       if (boxes.isEmpty) {
//         // When we are at the end of the line, a non-surrogate position will
//         // return empty boxes. We break and try from upstream instead.
//         if (!needsSearch) {
//           break; // Only perform one iteration if no search is required.
//         }
//         if (nextRuneOffset >= flattenedText.length << 1) {
//           break; // Stop iterating when beyond the max length of the text.
//         }
//         // Multiply by two to log(n) time cover the entire text span. This allows
//         // faster discovery of very long clusters and reduces the possibility
//         // of certain large clusters taking much longer than others, which can
//         // cause jank.
//         graphemeClusterLength *= 2;
//         continue;
//       }
//       final TextBox box = boxes.last;
//       final double caretStart = box.start;
//       final double dx = box.direction == TextDirection.rtl
//           ? caretStart - caretPrototype.width
//           : caretStart;
//       return Rect.fromLTRB(min(dx, _paragraph!.width), box.top,
//           min(dx, _paragraph!.width), box.bottom);
//     }
//     return null;
//   }

//   Offset get _emptyOffset {
//     assert(!_needsLayout); // implies textDirection is non-null
//     switch (textAlign) {
//       case TextAlign.left:
//         return Offset.zero;
//       case TextAlign.right:
//         return Offset(width, 0.0);
//       case TextAlign.center:
//         return Offset(width / 2.0, 0.0);
//       case TextAlign.justify:
//       case TextAlign.start:
//         assert(textDirection != null);
//         switch (textDirection!) {
//           case TextDirection.rtl:
//             return Offset(width, 0.0);
//           case TextDirection.ltr:
//             return Offset.zero;
//         }
//       case TextAlign.end:
//         assert(textDirection != null);
//         switch (textDirection!) {
//           case TextDirection.rtl:
//             return Offset.zero;
//           case TextDirection.ltr:
//             return Offset(width, 0.0);
//         }
//     }
//   }

//   /// Returns the offset at which to paint the caret.
//   ///
//   /// Valid only after [layout] has been called.
//   Offset getOffsetForCaret(TextPosition position, Rect caretPrototype) {
//     _computeCaretMetrics(position, caretPrototype);
//     return _caretMetrics.offset;
//   }

//   /// {@template flutter.painting.textPainter.getFullHeightForCaret}
//   /// Returns the strut bounded height of the glyph at the given `position`.
//   /// {@endtemplate}
//   ///
//   /// Valid only after [layout] has been called.
//   double? getFullHeightForCaret(TextPosition position, Rect caretPrototype) {
//     _computeCaretMetrics(position, caretPrototype);
//     return _caretMetrics.fullHeight;
//   }

//   // Cached caret metrics. This allows multiple invokes of [getOffsetForCaret] and
//   // [getFullHeightForCaret] in a row without performing redundant and expensive
//   // get rect calls to the paragraph.
//   late _CaretMetrics _caretMetrics;

//   // Holds the TextPosition and caretPrototype the last caret metrics were
//   // computed with. When new values are passed in, we recompute the caret metrics.
//   // only as necessary.
//   TextPosition? _previousCaretPosition;
//   Rect? _previousCaretPrototype;

//   // Checks if the [position] and [caretPrototype] have changed from the cached
//   // version and recomputes the metrics required to position the caret.
//   void _computeCaretMetrics(TextPosition position, Rect caretPrototype) {
//     assert(!_needsLayout);
//     if (position == _previousCaretPosition &&
//         caretPrototype == _previousCaretPrototype) return;
//     final int offset = position.offset;
//     Rect? rect;
//     switch (position.affinity) {
//       case TextAffinity.upstream:
//         {
//           rect = _getRectFromUpstream(offset, caretPrototype) ??
//               _getRectFromDownstream(offset, caretPrototype);
//           break;
//         }
//       case TextAffinity.downstream:
//         {
//           rect = _getRectFromDownstream(offset, caretPrototype) ??
//               _getRectFromUpstream(offset, caretPrototype);
//           break;
//         }
//     }
//     _caretMetrics = _CaretMetrics(
//       offset: rect != null ? Offset(rect.left, rect.top) : _emptyOffset,
//       fullHeight: rect != null ? rect.bottom - rect.top : null,
//     );

//     // Cache the input parameters to prevent repeat work later.
//     _previousCaretPosition = position;
//     _previousCaretPrototype = caretPrototype;
//   }

//   /// Returns a list of rects that bound the given selection.
//   ///
//   /// The [boxHeightStyle] and [boxWidthStyle] arguments may be used to select
//   /// the shape of the [TextBox]s. These properties default to
//   /// [ui.BoxHeightStyle.tight] and [ui.BoxWidthStyle.tight] respectively and
//   /// must not be null.
//   ///
//   /// A given selection might have more than one rect if this text painter
//   /// contains bidirectional text because logically contiguous text might not be
//   /// visually contiguous.
//   ///
//   /// Leading or trailing newline characters will be represented by zero-width
//   /// `Textbox`es.
//   ///
//   /// The method only returns `TextBox`es of glyphs that are entirely enclosed by
//   /// the given `selection`: a multi-code-unit glyph will be excluded if only
//   /// part of its code units are in `selection`.
//   List<TextBox> getBoxesForSelection(
//     TextSelection selection, {
//     ui.BoxHeightStyle boxHeightStyle = ui.BoxHeightStyle.tight,
//     ui.BoxWidthStyle boxWidthStyle = ui.BoxWidthStyle.tight,
//   }) {
//     assert(!_needsLayout);
//     return _paragraph!.getBoxesForRange(
//       selection.start,
//       selection.end,
//       boxHeightStyle: boxHeightStyle,
//       boxWidthStyle: boxWidthStyle,
//     );
//   }

//   /// Returns the position within the text for the given pixel offset.
//   TextPosition getPositionForOffset(Offset offset) {
//     assert(!_needsLayout);
//     return _paragraph!.getPositionForOffset(offset);
//   }

//   /// Returns the text range of the word at the given offset. Characters not
//   /// part of a word, such as spaces, symbols, and punctuation, have word breaks
//   /// on both sides. In such cases, this method will return a text range that
//   /// contains the given text position.
//   ///
//   /// Word boundaries are defined more precisely in Unicode Standard Annex #29
//   /// <http://www.unicode.org/reports/tr29/#Word_Boundaries>.
//   TextRange getWordBoundary(TextPosition position) {
//     assert(!_needsLayout);
//     return _paragraph!.getWordBoundary(position);
//   }

//   /// Returns the text range of the line at the given offset.
//   ///
//   /// The newline, if any, is included in the range.
//   TextRange getLineBoundary(TextPosition position) {
//     assert(!_needsLayout);
//     return _paragraph!.getLineBoundary(position);
//   }

//   /// Returns the full list of [LineMetrics] that describe in detail the various
//   /// metrics of each laid out line.
//   ///
//   /// The [LineMetrics] list is presented in the order of the lines they represent.
//   /// For example, the first line is in the zeroth index.
//   ///
//   /// [LineMetrics] contains measurements such as ascent, descent, baseline, and
//   /// width for the line as a whole, and may be useful for aligning additional
//   /// widgets to a particular line.
//   ///
//   /// Valid only after [layout] has been called.
//   ///
//   /// This can potentially return a large amount of data, so it is not recommended
//   /// to repeatedly call this. Instead, cache the results. The cached results
//   /// should be invalidated upon the next successful [layout].
//   List<ui.LineMetrics> computeLineMetrics() {
//     assert(!_needsLayout);
//     return _paragraph!.computeLineMetrics();
//   }
// }

// class _CaretMetrics {
//   const _CaretMetrics({required this.offset, this.fullHeight});

//   /// The offset of the top left corner of the caret from the top left
//   /// corner of the paragraph.
//   final Offset offset;

//   /// The full height of the glyph at the caret position.
//   final double? fullHeight;
// }
