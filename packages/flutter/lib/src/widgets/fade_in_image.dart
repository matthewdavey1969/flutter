// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'basic.dart';
import 'framework.dart';
import 'image.dart';
import 'ticker_provider.dart';

/// An image that shows a [placeholder] image while the target [image] is
/// loading, then fades in the new image when it loads.
///
/// Use this class to display long-loading images, such as [new NetworkImage],
/// so that the image appears on screen with a graceful animation rather than a
/// sudden jerk.
///
/// If the [image] emits an [ImageInfo] synchronously, such as when the image
/// has been loaded and cached, the [image] is displayed immediately and the
/// [placeholder] is never displayed.
///
/// [fadeOutDuration] and [fadeOutCurve] control the fade-out animation of the
/// placeholder.
///
/// [fadeInDuration] and [fadeInCurve] control the fade-in animation of the
/// target [image].
///
/// Prefer a [placeholder] that's already cached so that it is displayed in one
/// frame. This prevents it from appearing suddenly on the screen.
///
/// When [image] changes it is resolved to a new [ImageStream]. If the new
/// [ImageStream.key] is different this widget subscribes to the new stream and
/// replaces the displayed image to images emitted by the new stream.
///
/// When [placeholder] changes and the [image] has not yet emitted an
/// [ImageInfo], then [placeholder] is resolved to a new [ImageStream]. If the
/// new [ImageStream.key] is different this widget subscribes to the new stream
/// and replaces the displayed image to images emitted by the new stream.
///
/// ## Sample code:
///
/// ```dart
/// return new FadeInImage(
///   // here `bytes` is a Uint8List containing the bytes for the in-memory image
///   placeholder: new MemoryImage(bytes),
///   image: new NetworkImage('https://backend.example.com/image.png'),
/// );
/// ```
class FadeInImage extends StatefulWidget {
  /// Creates a widget that displays a [placeholder] while an [image] is loading
  /// then cross-fades to display the [image].
  ///
  /// The [placeholder], [image], [fadeOutDuration], [fadeOutCurve],
  /// [fadeInDuration] and [fadeInCurve] arguments must not be null.
  const FadeInImage({
    Key key,
    @required this.placeholder,
    @required this.image,
    this.fadeOutDuration: const Duration(milliseconds: 300),
    this.fadeOutCurve: Curves.easeOut,
    this.fadeInDuration: const Duration(milliseconds: 700),
    this.fadeInCurve: Curves.easeIn,
    this.width,
    this.height,
    this.fit,
    this.alignment,
    this.repeat: ImageRepeat.noRepeat,
  }) : assert(placeholder != null),
       assert(image != null),
       assert(fadeOutDuration != null),
       assert(fadeOutCurve != null),
       assert(fadeInDuration != null),
       assert(fadeInCurve != null),
       super(key: key);

  /// Creates a widget that uses a placeholder image stored in memory while
  /// loading the final image from the network.
  ///
  /// [placeholder] contains the bytes of the in-memory image.
  ///
  /// [image] is the URL of the final image.
  ///
  /// [placeholderScale] and [imageScale] are passed to their respective
  /// [ImageProvider]s (see also [ImageInfo.scale]).
  ///
  /// The [placeholder], [image], [fadeOutDuration], [fadeOutCurve],
  /// [fadeInDuration] and [fadeInCurve] arguments must not be null.
  ///
  /// See also:
  ///
  ///  * [new Image.memory], which has more details about loading images from
  ///    memory.
  ///  * [new Image.network], which has more details about loading images from
  ///    the network.
  FadeInImage.memoryNetwork({
    Key key,
    @required Uint8List placeholder,
    @required String image,
    double placeholderScale: 1.0,
    double imageScale: 1.0,
    this.fadeOutDuration: const Duration(milliseconds: 300),
    this.fadeOutCurve: Curves.easeOut,
    this.fadeInDuration: const Duration(milliseconds: 700),
    this.fadeInCurve: Curves.easeIn,
    this.width,
    this.height,
    this.fit,
    this.alignment,
    this.repeat: ImageRepeat.noRepeat,
  }) : assert(placeholder != null),
       assert(image != null),
       placeholder = new MemoryImage(placeholder, scale: placeholderScale),
       image = new NetworkImage(image, scale: imageScale),
       assert(fadeOutDuration != null),
       assert(fadeOutCurve != null),
       assert(fadeInDuration != null),
       assert(fadeInCurve != null),
       super(key: key);

  /// Creates a widget that uses a placeholder image stored in an asset bundle
  /// while loading the final image from the network.
  ///
  /// [placeholder] is the key of the image in the asset bundle.
  ///
  /// [image] is the URL of the final image.
  ///
  /// [placeholderScale] and [imageScale] are passed to their respective
  /// [ImageProvider]s (see also [ImageInfo.scale]).
  ///
  /// The [placeholder], [image], [fadeOutDuration], [fadeOutCurve],
  /// [fadeInDuration] and [fadeInCurve] arguments must not be null.
  ///
  /// See also:
  ///
  ///  * [new Image.asset], which has more details about loading images from
  ///    asset bundles.
  ///  * [new Image.network], which has more details about loading images from
  ///    the network.
  FadeInImage.assetNetwork({
    Key key,
    @required String placeholder,
    @required String image,
    AssetBundle bundle,
    double placeholderScale,
    double imageScale: 1.0,
    this.fadeOutDuration: const Duration(milliseconds: 300),
    this.fadeOutCurve: Curves.easeOut,
    this.fadeInDuration: const Duration(milliseconds: 700),
    this.fadeInCurve: Curves.easeIn,
    this.width,
    this.height,
    this.fit,
    this.alignment,
    this.repeat: ImageRepeat.noRepeat,
  }) : assert(placeholder != null),
       assert(image != null),
       placeholder = placeholderScale != null
         ? new ExactAssetImage(placeholder, bundle: bundle, scale: placeholderScale)
         : new AssetImage(placeholder, bundle: bundle),
       image = new NetworkImage(image, scale: imageScale),
       assert(fadeOutDuration != null),
       assert(fadeOutCurve != null),
       assert(fadeInDuration != null),
       assert(fadeInCurve != null),
       super(key: key);

  /// Image displayed while the target [image] is loading.
  final ImageProvider placeholder;

  /// The target image that is displayed.
  final ImageProvider image;

  /// The duration of the fade-out animation for the [placeholder].
  final Duration fadeOutDuration;

  /// The curve of the fade-out animation for the [placeholder].
  final Curve fadeOutCurve;

  /// The duration of the fade-in animation for the [image].
  final Duration fadeInDuration;

  /// The curve of the fade-in animation for the [image].
  final Curve fadeInCurve;

  /// If non-null, require the image to have this width.
  ///
  /// If null, the image will pick a size that best preserves its intrinsic
  /// aspect ratio. This may result in a sudden change if the size of the
  /// placeholder image does not match that of the target image. The size is
  /// also affected by the scale factor.
  final double width;

  /// If non-null, require the image to have this height.
  ///
  /// If null, the image will pick a size that best preserves its intrinsic
  /// aspect ratio. This may result in a sudden change if the size of the
  /// placeholder image does not match that of the target image. The size is
  /// also affected by the scale factor.
  final double height;

  /// How to inscribe the image into the space allocated during layout.
  ///
  /// The default varies based on the other fields. See the discussion at
  /// [paintImage].
  final BoxFit fit;

  /// How to align the image within its bounds.
  ///
  /// An alignment of (0.0, 0.0) aligns the image to the top-left corner of its
  /// layout bounds.  An alignment of (1.0, 0.5) aligns the image to the middle
  /// of the right edge of its layout bounds.
  final FractionalOffset alignment;

  /// How to paint any portions of the layout bounds not covered by the image.
  final ImageRepeat repeat;

  @override
  State<StatefulWidget> createState() => new _FadeInImageState();
}


/// The phases a [FadeInImage] goes through.
@visibleForTesting
enum FadeInImagePhase {
  /// The initial state.
  ///
  /// We do not yet know whether the target image is ready and therefore no
  /// animation is necessary, or whether we need to use the placeholder and
  /// wait for the image to load.
  start,

  /// Waiting for the target image to load.
  waiting,

  /// Fading out previous image.
  fadeOut,

  /// Fading in new image.
  fadeIn,

  /// Fade-in complete.
  completed,
}

typedef void _ImageProviderResolverListener();

class _ImageProviderResolver {
  _ImageProviderResolver({
    @required this.state,
    @required this.listener,
  });

  final _FadeInImageState state;
  final _ImageProviderResolverListener listener;

  FadeInImage get widget => state.widget;

  ImageStream _imageStream;
  ImageInfo _imageInfo;

  void resolve(ImageProvider provider) {
    final ImageStream oldImageStream = _imageStream;
    _imageStream = provider.resolve(createLocalImageConfiguration(
        state.context,
        size: widget.width != null && widget.height != null ? new Size(widget.width, widget.height) : null
    ));
    assert(_imageStream != null);

    if (_imageStream.key != oldImageStream?.key) {
      oldImageStream?.removeListener(_handleImageChanged);
      _imageStream.addListener(_handleImageChanged);
    }
  }

  void _handleImageChanged(ImageInfo imageInfo, bool synchronousCall) {
    _imageInfo = imageInfo;
    listener();
  }

  void stopListening() {
    _imageStream?.removeListener(_handleImageChanged);
  }
}

class _FadeInImageState extends State<FadeInImage> with TickerProviderStateMixin {
  _ImageProviderResolver _imageResolver;
  _ImageProviderResolver _placeholderResolver;

  AnimationController _controller;
  Animation<double> _animation;

  FadeInImagePhase _phase = FadeInImagePhase.start;
  FadeInImagePhase get phase => _phase;

  @override
  void initState() {
    _imageResolver = new _ImageProviderResolver(state: this, listener: _updatePhase);
    _placeholderResolver = new _ImageProviderResolver(state: this, listener: () {
      setState(() {
        // Trigger rebuild to display the placeholder image
      });
    });
    _controller = new AnimationController(
      value: 1.0,
      vsync: this,
    );
    _controller.addListener(() {
      setState(() {
        // Trigger rebuild to update opacity value.
      });
    });
    _controller.addStatusListener((AnimationStatus status) {
      _updatePhase();
    });
    super.initState();
  }

  @override
  void didChangeDependencies() {
    _resolveImage();
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(FadeInImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.image != oldWidget.image || widget.placeholder != widget.placeholder)
      _resolveImage();
  }

  @override
  void reassemble() {
    _resolveImage(); // in case the image cache was flushed
    super.reassemble();
  }

  void _resolveImage() {
    _imageResolver.resolve(widget.image);

    // No need to resolve the placeholder if we are past the placeholder stage.
    if (_isShowingPlaceholder)
      _placeholderResolver.resolve(widget.placeholder);

    if (_phase == FadeInImagePhase.start)
      _updatePhase();
  }

  void _updatePhase() {
    setState(() {
      switch(_phase) {
        case FadeInImagePhase.start:
          if (_imageResolver._imageInfo != null)
            _phase = FadeInImagePhase.completed;
          else
            _phase = FadeInImagePhase.waiting;
          break;
        case FadeInImagePhase.waiting:
          if (_imageResolver._imageInfo != null) {
            // Received image data. Begin placeholder fade-out.
            _controller.duration = widget.fadeOutDuration;
            _animation = new CurvedAnimation(
              parent: _controller,
              curve: widget.fadeOutCurve,
            );
            _phase = FadeInImagePhase.fadeOut;
            _controller.reverse(from: 1.0);
          }
          break;
        case FadeInImagePhase.fadeOut:
          if (_controller.status == AnimationStatus.dismissed) {
            // Done fading out placeholder. Begin target image fade-in.
            _controller.duration = widget.fadeInDuration;
            _animation = new CurvedAnimation(
              parent: _controller,
              curve: widget.fadeInCurve,
            );
            _phase = FadeInImagePhase.fadeIn;
            _placeholderResolver.stopListening();
            _controller.forward(from: 0.0);
          }
          break;
        case FadeInImagePhase.fadeIn:
          if (_controller.status == AnimationStatus.completed) {
            // Done finding in new image.
            _phase = FadeInImagePhase.completed;
          }
          break;
        case FadeInImagePhase.completed:
          // Nothing to do.
          break;
      }
    });
  }

  @override
  void dispose() {
    _imageResolver.stopListening();
    _placeholderResolver.stopListening();
    _controller.dispose();
    super.dispose();
  }

  bool get _isShowingPlaceholder {
    switch(_phase) {
      case FadeInImagePhase.start:
      case FadeInImagePhase.waiting:
      case FadeInImagePhase.fadeOut:
        return true;
      case FadeInImagePhase.fadeIn:
      case FadeInImagePhase.completed:
        return false;
    }

    throw new StateError('Unrecognized FadeInImage phase: $_phase');
  }

  ImageInfo get _imageInfo {
    return _isShowingPlaceholder
      ? _placeholderResolver._imageInfo
      : _imageResolver._imageInfo;
  }

  @override
  Widget build(BuildContext context) {
    assert(_phase != FadeInImagePhase.start);
    return new RawImage(
      image: _imageInfo?.image,
      width: widget.width,
      height: widget.height,
      scale: _imageInfo?.scale ?? 1.0,
      color: new Color.fromRGBO(255, 255, 255, _animation?.value ?? 1.0),
      colorBlendMode: BlendMode.modulate,
      fit: widget.fit,
      alignment: widget.alignment,
      repeat: widget.repeat,
    );
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('phase: $_phase');
    description.add('pixels: $_imageInfo');
    description.add('image stream: ${_imageResolver._imageStream}');
    description.add('placeholder stream: ${_placeholderResolver._imageStream}');
  }
}
