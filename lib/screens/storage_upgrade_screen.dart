import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../utils/constants.dart';
import '../services/language_service.dart';
import '../services/storage_quota_service.dart';
import '../services/vnpay_service.dart';

class StorageUpgradeScreen extends StatefulWidget {
  const StorageUpgradeScreen({Key? key}) : super(key: key);

  @override
  State<StorageUpgradeScreen> createState() => _StorageUpgradeScreenState();
}

class _StorageUpgradeScreenState extends State<StorageUpgradeScreen> {
  late StorageInfo _storageInfo;
  bool _isLoading = true;
  
  bool get _isEnglish => context.read<LanguageService>().isEnglish;

  @override
  void initState() {
    super.initState();
    _loadStorageInfo();
  }

  Future<void> _loadStorageInfo() async {
    try {
      final info = await StorageQuotaService().getStorageInfo();
      if (mounted) {
        setState(() {
          _storageInfo = info;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToPayment() {
    // Navigate directly to VNPAY payment
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VNPayWebView(
          onReturn: _handlePaymentResult,
        ),
      ),
    );
  }
  
  void _handlePaymentResult(bool success) {
    if (success) {
      // Force clear cache and reload storage info
      StorageQuotaService().clearStorageCache().then((_) {
        _loadStorageInfo();
      });
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEnglish 
                ? '✅ Storage upgraded successfully!' 
                : '✅ Nâng cấp dung lượng thành công!',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      // Payment failed or cancelled
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEnglish 
                ? 'Payment failed or cancelled' 
                : 'Thanh toán thất bại',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF9F9FF),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEnglish ? 'Upgrade Storage' : 'Nâng cấp dung lượng',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryColor,
          ),
        ),
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFFF9F9FF),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Current storage info
                  _buildCurrentStorageCard(),
                  
                  const SizedBox(height: 32),
                  
                  // Package comparison
                  _buildPackageComparison(),
                  
                  const SizedBox(height: 32),
                  
                  // Features list
                  _buildFeaturesList(),
                  
                  const SizedBox(height: 32),
                  
                  // Upgrade button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _navigateToPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _isEnglish ? 'Buy Now' : 'Mua ngay',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildCurrentStorageCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryColor,
            AppColors.primaryLight,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isEnglish ? 'Current Storage' : 'Dung lượng hiện tại',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _storageInfo.usageFormatted,
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_isEnglish ? 'of' : 'trên'} ${_storageInfo.limitFormatted}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                ),
                child: const Icon(
                  Icons.cloud,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _storageInfo.percentageUsed,
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              '${_storageInfo.percentageText} ${_isEnglish ? 'used' : 'đã sử dụng'}',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageComparison() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isEnglish ? 'Choose Your Plan' : 'Chọn gói của bạn',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 16),
        
        // Base plan (current)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _storageInfo.isUpgraded ? const Color(0xFFE5E7EB) : AppColors.primaryColor,
              width: _storageInfo.isUpgraded ? 1 : 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isEnglish ? 'Basic' : 'Cơ bản',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isEnglish ? 'Current Plan' : 'Gói hiện tại',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '1 GB',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _isEnglish ? 'Free' : 'Miễn phí',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Premium plan (upgrade)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F3FF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _storageInfo.isUpgraded ? AppColors.primaryColor : const Color(0xFFD4E4F7),
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isEnglish ? 'Premium' : 'Premium',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (_storageInfo.isUpgraded)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _isEnglish ? 'Your Plan' : 'Gói của bạn',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  Text(
                    '5 GB',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '20,000 VND',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isEnglish ? 'Lifetime access' : 'Truy cập vĩnh viễn',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturesList() {
    final features = _isEnglish
        ? [
            '✓ 5GB storage space',
            '✓ Unlimited file types',
            '✓ Priority support',
            '✓ Lifetime access',
            '✓ One-time payment',
          ]
        : [
            '✓ Dung lượng 5GB',
            '✓ Loại tệp không giới hạn',
            '✓ Hỗ trợ ưu tiên',
            '✓ Truy cập vĩnh viễn',
            '✓ Thanh toán một lần',
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isEnglish ? 'Premium Features' : 'Các tính năng Premium',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 16),
        ...features.map((feature) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Text(
                feature.substring(0, 2),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade600,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                feature.substring(2),
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: const Color(0xFF4B5563),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }
}

// VNPAY WebView Payment Screen
class VNPayWebView extends StatefulWidget {
  final Function(bool) onReturn;

  const VNPayWebView({
    Key? key,
    required this.onReturn,
  }) : super(key: key);

  @override
  State<VNPayWebView> createState() => _VNPayWebViewState();
}

class _VNPayWebViewState extends State<VNPayWebView> {
  late WebViewController _webViewController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    // Generate payment URL
    final String orderId = 'ORDER_${DateTime.now().millisecondsSinceEpoch}';
    
    print('📱 Building VNPAY payment URL...');
    final String paymentUrl = VNPayService.buildPaymentUrl(
      orderInfo: 'StorageUpgrade5GB',
      amount: 20000, // 20,000 VND
      orderId: orderId,
      returnUrl: 'https://www.example.com/payment-return', // HTTPS URL for VNPAY sandbox
      ipAddress: '127.0.0.1',
    );
    
    print('📱 VNPAY Payment URL ready, initializing WebView...');
    
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            print('📄 WebView loading: $url');
            setState(() => _isLoading = true);
            
            // Check if returning from VNPAY
            if (url.contains('payment-return') || url.contains('SuccessTransaction')) {
              _handlePaymentReturn(url);
            }
          },
          onPageFinished: (url) {
            print('📄 WebView finished: $url');
            setState(() => _isLoading = false);
          },
          onWebResourceError: (error) {
            print('❌ WebView error: ${error.description}');
          },
          onNavigationRequest: (NavigationRequest request) {
            print('🔗 Navigation request: ${request.url}');
            
            // Check if this is a success or error page from VNPAY
            if (request.url.contains('SuccessTransaction') || 
                request.url.contains('payment-return') ||
                request.url.contains('code=00')) {
              _handlePaymentSuccess();
              return NavigationDecision.prevent;
            }
            
            // Check for error pages
            if (request.url.contains('Error.html') && request.url.contains('code=')) {
              _handlePaymentError(request.url);
              return NavigationDecision.prevent;
            }
            
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(paymentUrl));
  }

  void _handlePaymentSuccess() {
    print('✅ Payment successful detected');
    
    // Update Supabase profile
    _updateStorageAfterPayment();
  }

  Future<void> _updateStorageAfterPayment() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      
      if (userId == null) throw Exception('User not logged in');
      
      // Update profile level and premium status
      await supabase
          .from('profiles')
          .update({
            'level': 2,
            'is_premium': true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
      
      print('✅ Supabase profile updated: level=2, is_premium=true');
      
      if (mounted) {
        Navigator.pop(context);
        widget.onReturn(true);
      }
    } catch (e) {
      print('❌ Error updating profile: $e');
      if (mounted) {
        Navigator.pop(context);
        widget.onReturn(false);
      }
    }
  }

  void _handlePaymentError(String url) {
    print('❌ Payment error detected: $url');
    if (mounted) {
      Navigator.pop(context);
      widget.onReturn(false);
    }
  }

  void _handlePaymentReturn(String returnUrl) {
    print('💳 Payment return detected: $returnUrl');
    
    try {
      // Extract query parameters from the return URL
      final uri = Uri.parse(returnUrl);
      final queryParams = uri.queryParameters;
      
      print('📋 Query params: $queryParams');
      
      // Check response code - payment success
      final responseCode = queryParams['vnp_ResponseCode'] ?? '';
      final success = responseCode == '00';
      
      print('✅ Response Code: $responseCode (Success: $success)');
      
      if (success) {
        _updateStorageAfterPayment();
      } else {
        if (mounted) {
          Navigator.pop(context);
          widget.onReturn(false);
        }
      }
    } catch (e) {
      print('❌ Error parsing payment return: $e');
      if (mounted) {
        Navigator.pop(context);
        widget.onReturn(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF9F9FF),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryColor),
          onPressed: () {
            Navigator.pop(context);
            widget.onReturn(false); // User cancelled payment
          },
        ),
        title: Text(
          'VNPAY Payment',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryColor,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _webViewController),
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryColor,
              ),
            ),
        ],
      ),
    );
  }
}
