import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:my_skates/api.dart';

class InvoiceWebViewPage extends StatefulWidget {
  final int orderId;

  const InvoiceWebViewPage({
    super.key,
    required this.orderId,
  });

  @override
  State<InvoiceWebViewPage> createState() => _InvoiceWebViewPageState();
}

class _InvoiceWebViewPageState extends State<InvoiceWebViewPage> {
  WebViewController? _controller;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInvoice();
  }

  Future<void> _loadInvoice() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    final invoiceUrl =
        '$api/api/myskates/invoice/generate/${widget.orderId}/';

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() {
              isLoading = true;
            });
          },
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() {
              isLoading = false;
            });
          },
          onWebResourceError: (error) {
            if (!mounted) return;

            setState(() {
              isLoading = false;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Failed to load invoice: ${error.description}',
                ),
                backgroundColor: Colors.red,
              ),
            );
          },
        ),
      )
      ..loadRequest(
        Uri.parse(invoiceUrl),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

    if (!mounted) return;

    setState(() {
      _controller = controller;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF003A36),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Invoice #${widget.orderId}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _controller == null
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.tealAccent,
              ),
            )
          : Stack(
              children: [
                WebViewWidget(controller: _controller!),
                if (isLoading)
                  Container(
                    color: Colors.black.withOpacity(0.4),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Colors.tealAccent,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}