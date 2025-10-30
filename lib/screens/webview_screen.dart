import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../utils/app_theme.dart';
import '../providers/app_providers.dart';

class WebViewScreen extends StatefulWidget {
  final String url;
  final String title;
  final Function(String)? onUrlChanged;
  final Function(String)? onPageFinished;

  const WebViewScreen({
    super.key,
    required this.url,
    required this.title,
    this.onUrlChanged,
    this.onPageFinished,
  });

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _currentUrl;
  bool _canGoBack = false;
  bool _canGoForward = false;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading progress
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _currentUrl = url;
            });
            widget.onUrlChanged?.call(url);
            // Check for checkout success in URL
            _checkForCheckoutSuccess(url);
          },
          onUrlChange: (UrlChange change) {
            if (change.url != null) {
              print('URL changed to: ${change.url}');
              _checkForCheckoutSuccess(change.url!);
              // Auto-fill email on URL change (for navigation within checkout)
              _autoFillEmail(change.url!);
            }
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
              _currentUrl = url;
            });
            widget.onPageFinished?.call(url);
            _updateNavigationState();
            // Check for checkout success after page loads
            _checkForCheckoutSuccess(url);
            // Auto-fill email field if on checkout page
            _autoFillEmail(url);
          },
          onNavigationRequest: (NavigationRequest request) {
            // Handle navigation requests
            return NavigationDecision.navigate;
          },
          onWebResourceError: (WebResourceError error) {
            // Handle web resource errors
            print('WebView error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  Future<void> _updateNavigationState() async {
    final canGoBack = await _controller.canGoBack();
    final canGoForward = await _controller.canGoForward();
    
    if (mounted) {
      setState(() {
        _canGoBack = canGoBack;
        _canGoForward = canGoForward;
      });
    }
  }

  void _goBack() {
    if (_canGoBack) {
      _controller.goBack();
    }
  }

  void _goForward() {
    if (_canGoForward) {
      _controller.goForward();
    }
  }

  void _reload() {
    _controller.reload();
  }

  bool _successHandled = false; // Flag to prevent multiple success calls

  void _checkForCheckoutSuccess(String url) {
    if (_successHandled) return; // Prevent multiple calls
    
    print('Checking checkout success for URL: $url');
    
    // Check for various Shopify checkout success URL patterns
    final successPatterns = [
      'checkout/success',
      'thank_you',
      'order-confirmation',
      'orders/',
      '/thank',
      'thank-you',
      'order/success',
      'checkouts/thank_you',
      'order-status',
      'thankyou',
      'confirmation',
      'order/thank',
    ];
    
    final urlLower = url.toLowerCase();
    
    // Check if URL contains any success pattern
    final isSuccess = successPatterns.any((pattern) => urlLower.contains(pattern.toLowerCase()));
    
    // Also check for query parameters that indicate success
    final uri = Uri.tryParse(url);
    if (uri != null) {
      final queryParams = uri.queryParameters;
      // Check for common success indicators in query params
      if (queryParams.containsKey('checkout') && queryParams['checkout']?.contains('success') == true) {
        print('Success detected via query parameter: checkout');
        _handleCheckoutSuccess();
        return;
      }
      if (queryParams.containsKey('order') && queryParams.containsKey('key')) {
        // Shopify order confirmation usually has order ID and key
        print('Success detected via query parameters: order and key');
        _handleCheckoutSuccess();
        return;
      }
      if (queryParams.containsKey('status') && queryParams['status']?.toLowerCase() == 'success') {
        print('Success detected via query parameter: status=success');
        _handleCheckoutSuccess();
        return;
      }
    }
    
    // Check for Shopify-specific success patterns
    if (urlLower.contains('checkout.shopify.com') && 
        (urlLower.contains('thank') || urlLower.contains('success') || urlLower.contains('confirmation'))) {
      print('Success detected: Shopify checkout success URL');
      _handleCheckoutSuccess();
      return;
    }
    
    if (isSuccess) {
      print('Success detected: URL pattern match');
      _handleCheckoutSuccess();
    }
  }

  void _handleCheckoutSuccess() {
    if (_successHandled) return; // Prevent duplicate calls
    _successHandled = true;
    
    print('Handling checkout success - closing WebView and returning true');
    
    // Wait a brief moment to ensure the page has fully loaded
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        // Return true to indicate successful checkout
        Navigator.pop(context, true);
      }
    });
  }

  void _autoFillEmail(String url) {
    // Check if we're on a checkout page
    final urlLower = url.toLowerCase();
    if (!urlLower.contains('checkout')) {
      return; // Not a checkout page, skip
    }

    // Get user email from provider
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.user == null || userProvider.user!.email.isEmpty) {
        print('No logged-in user found, skipping email auto-fill');
        return;
      }

      final email = userProvider.user!.email;
      print('Attempting to auto-fill email: $email');

      // Try multiple times with delays to catch form when it's ready
      _tryAutoFillEmail(email, attempt: 1);
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          _tryAutoFillEmail(email, attempt: 2);
        }
      });
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (mounted) {
          _tryAutoFillEmail(email, attempt: 3);
        }
      });
    } catch (e) {
      print('Error getting user email for auto-fill: $e');
    }
  }

  void _tryAutoFillEmail(String email, {int attempt = 1}) {
    if (!mounted) return;

    // JavaScript to auto-fill email field
    // Try multiple common selectors for Shopify checkout email fields
    final jsCode = '''
      (function() {
        var email = '$email';
        
        // Common Shopify checkout email field selectors
        var selectors = [
          '#checkout_email',
          'input[name="checkout[email]"]',
          'input[name="checkout[contact][email]"]',
          'input[type="email"]',
          'input[id*="email"]',
          'input[name*="email"]',
          '#email',
          '.email-input',
          '[data-email-input]'
        ];
        
        var filled = false;
        
        for (var i = 0; i < selectors.length; i++) {
          try {
            var field = document.querySelector(selectors[i]);
            if (field) {
              // Fill only if empty to avoid overwriting user input
              if (!field.value || field.value.trim() === '') {
                field.value = email;
                
                // Trigger input events to ensure form validation
                field.dispatchEvent(new Event('input', { bubbles: true }));
                field.dispatchEvent(new Event('change', { bubbles: true }));
                field.dispatchEvent(new Event('blur', { bubbles: true }));
                
                filled = true;
                console.log('Email auto-filled using selector: ' + selectors[i]);
                break;
              } else {
                console.log('Email field already has value: ' + field.value);
              }
            }
          } catch (e) {
            console.log('Error trying selector ' + selectors[i] + ': ' + e);
          }
        }
        
        if (!filled) {
          console.log('Email field not found or already filled (attempt ${attempt.toString()})');
        }
        return filled;
      })();
    ''';

    _controller.runJavaScript(jsCode).then((_) {
      print('Email auto-fill JavaScript executed (attempt $attempt)');
    }).catchError((error) {
      print('Error injecting email auto-fill JavaScript (attempt $attempt): $error');
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _reload,
          ),
        ],
        bottom: _isLoading
            ? PreferredSize(
                preferredSize: const Size.fromHeight(4),
                child: LinearProgressIndicator(
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : null,
      ),
      body: Column(
        children: [
          // Navigation Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: Colors.grey[100],
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _canGoBack ? _goBack : null,
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: _canGoForward ? _goForward : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _currentUrl ?? widget.url,
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          
          // WebView
          Expanded(
            child: Stack(
              children: [
                WebViewWidget(controller: _controller),
                
                // Loading indicator
                if (_isLoading)
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
