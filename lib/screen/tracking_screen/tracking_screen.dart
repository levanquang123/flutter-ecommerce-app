import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../utility/app_color.dart';
import '../coming_soon_screen.dart';

class TrackingScreen extends StatefulWidget {
  final String? url;

  const TrackingScreen({super.key, required this.url});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  WebViewController? _webViewController;
  bool _hasLoadError = false;
  bool _isLoading = true;

  Uri? get _trackingUri {
    final rawUrl = widget.url?.trim() ?? '';
    final uri = Uri.tryParse(rawUrl);
    if (uri == null) return null;
    if (uri.scheme != 'http' && uri.scheme != 'https') return null;
    if ((uri.host).trim().isEmpty) return null;
    return uri;
  }

  @override
  void initState() {
    super.initState();
    final uri = _trackingUri;
    if (uri == null) return;

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() {
              _isLoading = true;
              _hasLoadError = false;
            });
          },
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (_) {
            if (!mounted) return;
            setState(() {
              _isLoading = false;
              _hasLoadError = true;
            });
          },
          onNavigationRequest: (_) => NavigationDecision.navigate,
        ),
      )
      ..loadRequest(uri);
  }

  @override
  Widget build(BuildContext context) {
    final controller = _webViewController;
    if (controller == null || _hasLoadError) {
      return const ComingSoonScreen(
        title: 'Tracking coming soon',
        message:
            'Shipment tracking is not available yet. Please check your order again later.',
        icon: Icons.local_shipping_outlined,
        primaryActionText: 'Back to order',
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Track Order",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColor.darkOrange,
          ),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
