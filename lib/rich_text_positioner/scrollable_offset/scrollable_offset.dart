import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

extension ScrollableOffset on ScrollableState {
  /// a copy of the regular [ensureVisible] but with an offset parameter
  /// for more hand precision scrolling.
  Future<void> ensureVisibleOffset({
    double alignment = 0.0,
    Duration duration = Duration.zero,
    Curve curve = Curves.ease,
    ScrollPositionAlignmentPolicy alignmentPolicy =
        ScrollPositionAlignmentPolicy.explicit,
    double offset = 0.0,
  }) {
    return ScrollableOffset.ensureVisibleContextOffset(context,
        alignment: alignment,
        duration: duration,
        curve: curve,
        alignmentPolicy: alignmentPolicy,
        offset: offset);
  }

  /// a copy of the regular [ensureVisible] but with an offset parameter
  /// for more hand precision scrolling.
  static Future<void> ensureVisibleContextOffset(
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

extension ScrollPositionOffset on ScrollPosition {
  /// Copy of the regular [ensureVisible] but with an offset parameter
  /// for more hand precision scrolling.
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
