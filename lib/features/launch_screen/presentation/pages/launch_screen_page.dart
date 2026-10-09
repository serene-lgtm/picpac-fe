import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../data/launch_screen.dart';
import '../../data/launch_screen_repository.dart';

class LaunchScreenPage extends StatefulWidget {
  const LaunchScreenPage({
    super.key,
    required this.repository,
    required this.onFinished,
  });

  final LaunchScreenRepository repository;
  final VoidCallback onFinished;

  @override
  State<LaunchScreenPage> createState() => _LaunchScreenPageState();
}

class _LaunchScreenPageState extends State<LaunchScreenPage> {
  static const _configTimeout = Duration(seconds: 3);
  static const _imageTimeout = Duration(seconds: 10);
  LaunchScreen? _config;
  ImageProvider? _image;
  bool _loading = true;
  Timer? _timer;
  bool _started = false;
  bool _finished = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    unawaited(_load());
  }

  Future<void> _load() async {
    LaunchScreen config;
    try {
      config = await widget.repository.getLaunchScreen().timeout(
        _configTimeout,
      );
      _log(
        'config enabled=${config.enabled} type=${config.type} '
        'duration_ms=${config.durationMs} skip_enabled=${config.skipEnabled}',
      );
    } catch (error) {
      _log('config failed (${error.runtimeType}); using bundled image');
      config = const LaunchScreen();
    }
    if (!mounted || _finished) return;
    // Allow skipping a slow download as soon as the server permits it.
    setState(() => _config = config);
    ImageProvider? image;
    if (config.imageUrl.isNotEmpty) {
      final candidate = NetworkImage(config.imageUrl);
      var failed = false;
      try {
        await precacheImage(
          candidate,
          context,
          onError: (error, _) {
            failed = true;
            _log('image failed (${error.runtimeType}); using bundled image');
          },
        ).timeout(_imageTimeout);
        if (!failed) image = candidate;
      } catch (error) {
        _log('image load failed (${error.runtimeType}); using bundled image');
        // Keep the bundled image when downloading or decoding fails.
      }
    }
    if (!mounted || _finished) return;
    setState(() {
      _config = config;
      _image = image;
      _loading = false;
    });
    _log('displaying ${image == null ? 'bundled' : 'remote'} image');
    // Count display time only after the image has loaded (or fallback is ready).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _finished) return;
      _timer = Timer(config.duration, _finish);
    });
  }

  void _finish() {
    if (!mounted || _finished) return;
    _finished = true;
    _timer?.cancel();
    _log('finished');
    widget.onFinished();
  }

  void _log(String message) {
    if (kDebugMode) debugPrint('[picpac.launch] $message');
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    child: Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (!_loading && _image == null)
            _defaultImage()
          else if (_image != null)
            Image(
              image: _image!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _defaultImage(),
            ),
          if (_config?.skipEnabled == true)
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextButton(
                    onPressed: _finish,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.black54,
                      minimumSize: const Size(64, 48),
                      shape: const StadiumBorder(),
                    ),
                    child: const Text('跳过'),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );

  Widget _defaultImage() => SvgPicture.asset(
    'assets/common/launch_default.svg',
    fit: BoxFit.fill,
    excludeFromSemantics: true,
  );
}
