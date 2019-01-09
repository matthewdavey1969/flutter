// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show timeDilation;
import 'package:flutter_gallery/demo/shrine/model/app_state_model.dart';
import 'package:flutter_gallery/welcome/home.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../demo/playground_demo.dart';

import 'demos.dart';
import 'home.dart';
import 'options.dart';
import 'scales.dart';
import 'themes.dart';
import 'updater.dart';

const String _kPrefsHasSeenWelcome = 'hasSeenWelcome';

class GalleryApp extends StatefulWidget {
  const GalleryApp({
    Key key,
    this.updateUrlFetcher,
    this.enablePerformanceOverlay = true,
    this.enableRasterCacheImagesCheckerboard = true,
    this.enableOffscreenLayersCheckerboard = true,
    this.onSendFeedback,
    this.testMode = false,
  }) : super(key: key);

  final UpdateUrlFetcher updateUrlFetcher;
  final bool enablePerformanceOverlay;
  final bool enableRasterCacheImagesCheckerboard;
  final bool enableOffscreenLayersCheckerboard;
  final VoidCallback onSendFeedback;
  final bool testMode;

  @override
  _GalleryAppState createState() => _GalleryAppState();
}

class _GalleryAppState extends State<GalleryApp>
    with SingleTickerProviderStateMixin {
  GalleryOptions _options;
  Timer _timeDilationTimer;
  AppStateModel model;
  SharedPreferences _prefs;
  Future<bool> _checkWelcomeFuture;
  bool _showWelcome;
  AnimationController _welcomeContentAnimationController;
  Animation<Offset> _welcomeContentAnimation;

  Map<String, WidgetBuilder> _buildRoutes() {
    // For a different example of how to set up an application routing table
    // using named routes, consider the example in the Navigator class documentation:
    // https://docs.flutter.io/flutter/widgets/Navigator-class.html
    final Map<String, WidgetBuilder> routes = Map<String, WidgetBuilder>.fromIterable(
      kAllGalleryDemos,
      key: (dynamic demo) => '${demo.routeName}',
      value: (dynamic demo) => demo.buildRoute,
    );

    // Add special playground demo cases directly to router
    routes[MaterialPlaygroundDemo.routeName] = MaterialPlaygroundDemo.buildRoute();
    routes[CupertinoPlaygroundDemo.routeName] = CupertinoPlaygroundDemo.buildRoute();

    return routes;
  }

  @override
  void initState() {
    super.initState();
    _options = GalleryOptions(
      theme: kLightGalleryTheme,
      textScaleFactor: kAllGalleryTextScaleValues[0],
      timeDilation: timeDilation,
      platform: defaultTargetPlatform,
    );
    model = AppStateModel()..loadProducts();
    _checkWelcomeFuture = _getWelcomePrefsValue();
    _welcomeContentAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  void dispose() {
    _timeDilationTimer?.cancel();
    _timeDilationTimer = null;
    _checkWelcomeFuture = null;
    _welcomeContentAnimationController.dispose();
    super.dispose();
  }

  void _handleOptionsChanged(GalleryOptions newOptions) {
    setState(() {
      if (_options.timeDilation != newOptions.timeDilation) {
        _timeDilationTimer?.cancel();
        _timeDilationTimer = null;
        if (newOptions.timeDilation > 1.0) {
          // We delay the time dilation change long enough that the user can see
          // that UI has started reacting and then we slam on the brakes so that
          // they see that the time is in fact now dilated.
          _timeDilationTimer = Timer(const Duration(milliseconds: 150), () {
            timeDilation = newOptions.timeDilation;
          });
        } else {
          timeDilation = newOptions.timeDilation;
        }
      }
      _options = newOptions;
    });
  }

  Widget _applyTextScaleFactor(Widget child) {
    return Builder(
      builder: (BuildContext context) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaleFactor: _options.textScaleFactor.scale,
          ),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScopedModel<AppStateModel>(
      model: model,
      child: MaterialApp(
        theme: _options.theme.data.copyWith(platform: _options.platform),
        title: 'Flutter Design Lab',
        color: Colors.grey,
        showPerformanceOverlay: _options.showPerformanceOverlay,
        checkerboardOffscreenLayers: _options.showOffscreenLayersCheckerboard,
        checkerboardRasterCacheImages: _options.showRasterCacheImagesCheckerboard,
        routes: _buildRoutes(),
        builder: (BuildContext context, Widget child) {
          return Directionality(
            textDirection: _options.textDirection,
            child: _applyTextScaleFactor(
              // Specifically use a blank Cupertino theme here and do not transfer
              // over the Material primary color etc except the brightness to
              // showcase standard iOS looks.
              CupertinoTheme(
                data: CupertinoThemeData(
                  brightness: _options.theme.data.brightness,
                ),
                child: child,
              ),
            ),
          );
        },
        home: _buildHomeWidget(context),
      ),
    );
  }

  Future<bool> _getWelcomePrefsValue() async {
    _prefs = await SharedPreferences.getInstance();
    final bool hasSeenWelcome = _prefs.getBool(_kPrefsHasSeenWelcome) ?? false;
    return !hasSeenWelcome;
  }

  Widget _buildHomeWidget(BuildContext context) {

    Widget home = GalleryHome(
      testMode: widget.testMode,
      optionsPage: GalleryOptionsPage(
        options: _options,
        onOptionsChanged: _handleOptionsChanged,
        onSendFeedback: widget.onSendFeedback ?? () {
          launch('https://github.com/flutter/flutter/issues/new/choose', forceSafariVC: false);
        },
      ),
    );
    if (widget.updateUrlFetcher != null) {
      home = Updater(
        updateUrlFetcher: widget.updateUrlFetcher,
        child: home,
      );
    }
    // We want to avoid showing the welcome flow if we're doing tests
    // because the welcome requires an async check that will cause all of the
    // tests to fail and the app will be stuck showing the welcome screen.
    if (widget.testMode != null && widget.testMode == true) {
      return home;
    } else {
      return FutureBuilder<bool>(
        future: _checkWelcomeFuture,
        builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            _showWelcome ??= snapshot.data;
            return _buildContentWidget(home, _showWelcome);
          } else {
            return Container();
          }
        },
      );
    }
  }

  Widget _buildContentWidget(Widget homeWidget, bool showWelcome) {
    Widget contentWidget = homeWidget;
    if (showWelcome == true) {
      final Widget welcome = Welcome(
        onDismissed: () {
          _welcomeContentAnimationController.forward();
          _prefs.setBool(_kPrefsHasSeenWelcome, true);
        },
      );
      _welcomeContentAnimation = Tween<Offset>(
        begin: const Offset(0.0, 1.0),
        end: const Offset(0.0, 0.0),
      ).animate(_welcomeContentAnimationController);
      contentWidget = Stack(
        children: <Widget>[
          welcome,
          SlideTransition(
            position: _welcomeContentAnimation,
            child: homeWidget,
          )
        ],
      );
    }
    return contentWidget;
  }
}
