import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/widgets/link_preview/link_view.dart';
import 'package:hacki/screens/widgets/link_preview/web_analyzer.dart';
import 'package:url_launcher/url_launcher.dart';

class LinkPreview extends StatefulWidget {
  const LinkPreview({
    super.key,
    required this.link,
    required this.story,
    required this.showMetadata,
    this.cache = const Duration(days: 30),
    this.titleStyle,
    this.bodyStyle,
    this.showMultimedia = true,
    this.backgroundColor = const Color.fromRGBO(235, 235, 235, 1),
    this.bodyMaxLines = 3,
    this.bodyTextOverflow = TextOverflow.ellipsis,
    this.placeholderWidget,
    this.errorWidget,
    this.errorBody,
    this.errorImage,
    this.errorTitle,
    this.borderRadius,
    this.boxShadow,
    this.removeElevation = false,
  });

  final Story story;

  /// Web address (Url that need to be parsed)
  /// For IOS & Web, only HTTP and HTTPS are support
  /// For Android, all urls are supported
  final String link;

  /// Customize background colour
  /// Defaults to `Color.fromRGBO(235, 235, 235, 1)`
  final Color? backgroundColor;

  /// Widget that need to be shown when
  /// plugin is trying to fetch metadata
  /// If not given anything then default one will be shown
  final Widget? placeholderWidget;

  /// Widget that need to be shown if something goes wrong
  /// Defaults to plain container with given background colour
  /// If the issue is know then we will show customized UI
  /// Other options of error params are used
  final Widget? errorWidget;

  /// Title that need to be shown if something goes wrong
  /// Defaults to `Something went wrong!`
  final String? errorTitle;

  /// Body that need to be shown if something goes wrong
  /// Defaults to `Oops! Unable to parse the url.
  /// We have sent feedback to our developers & we will
  /// try to fix this in our next release. Thanks!`
  final String? errorBody;

  /// Image that will be shown if something goes wrong
  /// & when multimedia enabled & no meta data is available
  /// Defaults to `A semi-soccer ball image that looks like crying`
  final String? errorImage;

  /// Give the overflow type for body text (Description)
  /// Defaults to `TextOverflow.ellipsis`
  final TextOverflow bodyTextOverflow;

  /// Give the limit to body text (Description)
  /// Defaults to `3`
  final int bodyMaxLines;

  /// Cache result time, default cache `30 days`
  /// Works only for IOS & not for android
  final Duration cache;

  /// Customize body `TextStyle`
  final TextStyle? titleStyle;

  /// Customize body `TextStyle`
  final TextStyle? bodyStyle;

  /// Show or Hide image if available defaults to `true`
  final bool showMultimedia;

  /// BorderRadius for the card. Defaults to `12`
  final double? borderRadius;

  /// To remove the card elevation set it to `true`
  /// Default value is `false`
  final bool removeElevation;

  /// Box shadow for the card. Defaults to
  /// `[BoxShadow(blurRadius: 3, color: Colors.grey)]`
  final List<BoxShadow>? boxShadow;

  final bool showMetadata;

  @override
  _LinkPreviewState createState() => _LinkPreviewState();
}

class _LinkPreviewState extends State<LinkPreview> {
  InfoBase? _info;
  String? _errorTitle, _errorBody, _url;
  bool _loading = false;

  @override
  void initState() {
    _errorTitle = widget.errorTitle ?? 'Something went wrong!';
    _errorBody = widget.errorBody ??
        'Oops! Unable to parse the url. We have '
            'sent feedback to our developers & '
            'we will try to fix this in our next release. Thanks!';
    _url = widget.link.trim();

    if (_url?.isNotEmpty ?? false) {
      _info = WebAnalyzer.getInfoFromCache(_url);
    } else {
      _info = WebAnalyzer.getInfoFromCache(widget.story.id.toString());
    }

    if (_info == null) {
      _loading = true;
      _getInfo();
    }
    super.initState();
  }

  Future<void> _getInfo() async {
    if (_url!.startsWith('http') || _url!.startsWith('https')) {
      _info = await WebAnalyzer.getInfo(
        _url,
        story: widget.story,
        cache: widget.cache,
      );
    } else {
      _info = await WebAnalyzer.getInfo(
        widget.story.id.toString(),
        story: widget.story,
        cache: widget.cache,
      );
    }

    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      try {
        await launchUrl(uri);
      } catch (err) {
        throw Exception('Could not launch $url. Error: $err');
      }
    }
  }

  Widget _buildLinkContainer(
    double _height, {
    String? title = '',
    String? desc = '',
    String? imageUri = '',
    bool isIcon = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(widget.borderRadius ?? 12),
        boxShadow: widget.removeElevation
            ? <BoxShadow>[]
            : widget.boxShadow ??
                <BoxShadow>[const BoxShadow(blurRadius: 3, color: Colors.grey)],
      ),
      height: _height,
      child: LinkView(
        key: widget.key ?? Key(widget.link),
        metadata: widget.story.simpleMetadata,
        url: widget.link,
        title: title!,
        description: desc!,
        imageUri: imageUri,
        imagePath: Constants.hackerNewsLogoPath,
        onTap: _launchURL,
        titleTextStyle: widget.titleStyle,
        bodyTextStyle: widget.bodyStyle,
        bodyTextOverflow: widget.bodyTextOverflow,
        bodyMaxLines: widget.bodyMaxLines,
        showMultiMedia: widget.showMultimedia,
        isIcon: isIcon,
        bgColor: widget.backgroundColor,
        radius: widget.borderRadius ?? 12,
        showMetadata: widget.showMetadata,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool showSmallerPreviewPic = screenWidth > 428.0 && screenWidth < 850;
    final double _height = showSmallerPreviewPic
        ? 100.0
        : (MediaQuery.of(context).size.height * 0.14).clamp(118.0, 140.0);

    final Widget loadingWidget = widget.placeholderWidget ??
        Container(
          height: _height,
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius ?? 12),
            color: Colors.grey[200],
          ),
          alignment: Alignment.center,
          child: const Text('Fetching data...'),
        );

    Widget loadedWidget;

    if (_info is WebImageInfo) {
      final String img = (_info as WebImageInfo?)?.image ?? '';
      loadedWidget = _buildLinkContainer(
        _height,
        title: _errorTitle,
        desc: _errorBody,
        imageUri:
            widget.showMultimedia ? (img.trim() == '' ? null : img) : null,
      );
    } else {
      final WebInfo? info = _info as WebInfo?;
      loadedWidget = _info == null
          ? _buildLinkContainer(
              _height,
              title: _errorTitle,
              desc: _errorBody,
              imageUri: null,
            )
          : _buildLinkContainer(
              _height,
              title: _errorTitle,
              desc: WebAnalyzer.isNotEmpty(info!.description)
                  ? info.description
                  : _errorBody,
              imageUri: widget.showMultimedia
                  ? (WebAnalyzer.isNotEmpty(info.image)
                      ? info.image
                      : WebAnalyzer.isNotEmpty(info.icon)
                          ? info.icon
                          : null)
                  : null,
              isIcon: !WebAnalyzer.isNotEmpty(info.image),
            );
    }

    return AnimatedCrossFade(
      firstChild: loadingWidget,
      secondChild: loadedWidget,
      crossFadeState:
          _loading ? CrossFadeState.showFirst : CrossFadeState.showSecond,
      duration: const Duration(milliseconds: 500),
    );
  }
}
