import 'dart:math';
import 'dart:ui' as ui;
import 'package:clickable_pattern_text/rich_text_positioner/scrollable_offset/scrollable_offset.dart';
import 'package:clickable_pattern_text/rich_text_positioner/text_span_positions.dart';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

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

  /// wrapper for [RichText] that can scroll to a specified [TextSpan]
  /// inside it.
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
  RichText? richRenderObject;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      _boxConstraints = box;
      return Container(
        key: _containerKey,
        child: richRenderObject = RichText(
          text: widget.text,
        ),
      );
    });
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
    var textPainter = TextPainter(
      text: widget.text,
      textDirection: widget.textDirection ?? Directionality.maybeOf(context),
      textAlign: widget.textAlign,
      textScaleFactor: widget.textScaleFactor,
      maxLines: widget.maxLines,
      ellipsis: widget.overflow == TextOverflow.ellipsis ? '\u2026' : null,
      locale: widget.locale,
      strutStyle: widget.strutStyle,
      textWidthBasis: widget.textWidthBasis,
      textHeightBehavior: widget.textHeightBehavior,
    );
    List<List<TextBox>> spanBoxesList = textPainter.getBoxesForSpan(
      span,
      maxWidth: _boxConstraints!.maxWidth,
      minWidth: _boxConstraints!.minWidth,
      minHeight: _boxConstraints!.minHeight,
      maxHeight: _boxConstraints!.maxHeight,
    );
    if (spanBoxesList.isEmpty || spanBoxesList.first.isEmpty)
      return Future.value();
    var selectedSpanBoxesIndex =
        min(max(spanIndex, 0), spanBoxesList.length - 1);
    if (spanSelector != null) {
      for (var i = 0; i < spanBoxesList.length; i++) {
        if (spanSelector(spanBoxesList[i], i, spanBoxesList.length)) {
          selectedSpanBoxesIndex = i;
          break;
        }
      }
    }
    var selectedSpanBoxes = spanBoxesList[selectedSpanBoxesIndex];
    var selectedTextBoxIndex =
        min(max(textBoxIndex, 0), selectedSpanBoxes.length - 1);
    if (textBoxSelector != null) {
      for (var i = 0; i < selectedSpanBoxes.length; i++) {
        if (textBoxSelector(
            selectedSpanBoxes[i], i, selectedSpanBoxes.length)) {
          selectedTextBoxIndex = i;
          break;
        }
      }
    }
    var selectedTextBox = selectedSpanBoxes[selectedTextBoxIndex];
    if (offsetSelector != null) {
      offset = offsetSelector(selectedTextBox, alignment);
    }
    var scrollerSize = Scrollable.of(context)?.context.size;
    return ScrollableOffset.ensureVisibleContextOffset(
      _containerKey.currentContext!,
      alignment: 0.0,
      alignmentPolicy: alignmentPolicy,
      curve: curve,
      duration: duration,
      offset: selectedTextBox.top +
          offset -
          (scrollerSize?.height ?? 0) * alignment +
          ((selectedTextBox.top - selectedTextBox.bottom) * -alignment),
    );
  }
}
