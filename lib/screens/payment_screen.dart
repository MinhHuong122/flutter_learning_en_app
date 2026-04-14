import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/constants.dart';
import '../services/language_service.dart';
import '../services/storage_quota_service.dart';
import '../services/vnpay_service.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({Key? key}) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _paymentConfirmed = false;
  
  bool get _isEnglish => context.read<LanguageService>().isEnglish;

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
          _isEnglish ? 'Payment' : 'Thanh toán',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryColor,
          ),
        ),
        centerTitle: true,
      ),
      body: _paymentConfirmed ? _buildSuccessView() : _buildPaymentView(),
    );
  }

  Widget _buildPaymentView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          
          // Package info card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F3FF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primaryColor),
            ),
            child: Column(
              children: [
                Text(
                  _isEnglish ? 'Premium Package' : 'Gói Premium',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        const Icon(Icons.cloud, color: AppColors.primaryColor, size: 32),
                        const SizedBox(height: 8),
                        Text(
                          _isEnglish ? 'Storage' : 'Dung lượng',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '5 GB',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    Container(width: 1, height: 60, color: AppColors.primaryColor),
                    Column(
                      children: [
                        const Icon(Icons.wallet, color: AppColors.primaryColor, size: 32),
                        const SizedBox(height: 8),
                        Text(
                          _isEnglish ? 'Price' : 'Giá',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '20,000 VND',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // QR Code section
          Text(
            _isEnglish ? 'Scan QR Code to Pay' : 'Quét QR để thanh toán',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F2937),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // QR Code
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // QR Code image from Google Charts API
                Image.network(
                  'https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=VNPay:amount=20000;description=PUPU-Storage-Upgrade-5GB;orderInfo=storage_upgrade',
                  width: 250,
                  height: 250,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 250,
                      height: 250,
                      color: const Color(0xFFF3F4F6),
                      child: Center(
                        child: Text(
                          _isEnglish ? 'QR Code\nUnavailable' : 'Mã QR\nkhông có sẵn',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: const Color(0xFF9CA3AF),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Bank details (for manual transfer)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info, color: Color(0xFFB45309), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      _isEnglish ? 'Bank Transfer' : 'Chuyển khoản',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildBankDetail(
                  _isEnglish ? 'Bank' : 'Ngân hàng',
                  'Vietcombank',
                ),
                _buildBankDetail(
                  _isEnglish ? 'Account' : 'Số tài khoản',
                  '0071000123456789',
                ),
                _buildBankDetail(
                  _isEnglish ? 'Name' : 'Tên',
                  'PUPU LEARNING',
                ),
                _buildBankDetail(
                  _isEnglish ? 'Amount' : 'Số tiền',
                  '20,000 VND',
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Confirm button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                // Navigate directly to VNPAY WebView
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VNPayWebView(
                      onReturn: (success) {
                        if (success) {
                          setState(() => _paymentConfirmed = true);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                _isEnglish ? 'Payment cancelled' : 'Da huy thanh toan',
                              ),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _isEnglish ? 'Proceed to Payment' : 'Tien hanh thanh toan',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Cancel button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFE5E7EB)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _isEnglish ? 'Cancel' : 'Hủy',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Success icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green.shade100,
              ),
              child: Icon(
                Icons.check_circle,
                color: Colors.green.shade700,
                size: 48,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Success message
            Text(
              _isEnglish ? 'Payment Successful!' : 'Thanh toán thành công!',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1F2937),
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 12),
            
            Text(
              _isEnglish 
                  ? 'Your storage has been upgraded to 5GB'
                  : 'Dung lượng của bạn đã nâng cấp lên 5GB',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            // Confirmation details
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                children: [
                  _buildConfirmDetail(
                    _isEnglish ? 'Package' : 'Gói',
                    'Premium - 5GB',
                  ),
                  const SizedBox(height: 12),
                  _buildConfirmDetail(
                    _isEnglish ? 'Amount' : 'Số tiền',
                    '20,000 VND',
                  ),
                  const SizedBox(height: 12),
                  _buildConfirmDetail(
                    _isEnglish ? 'Status' : 'Trạng thái',
                    _isEnglish ? 'Completed' : 'Hoàn tất',
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Close button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () async {
                  // Upgrade storage
                  await StorageQuotaService().upgradeStorage();
                  
                  // Close all dialogs and navigate back
                  if (mounted) {
                    Navigator.pop(context, true); // Return true to indicate success
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _isEnglish ? 'Done' : 'Xong',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFFB45309),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFB45309),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmDetail(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: Colors.green.shade700,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.green.shade700,
          ),
        ),
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
  bool _hasReceivedValidResponse = false;

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
      amount: 20000,
      orderId: orderId,
      returnUrl: 'https://example.com/payment-return',
      ipAddress: '127.0.0.1',
    );
    
    print('📱 Payment URL: ${paymentUrl.substring(0, 100)}...');
    
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            print('📄 WebView loading: $url');
            setState(() => _isLoading = true);
          },
          onPageFinished: (url) {
            print('📄 WebView finished: $url');
            setState(() => _isLoading = false);
          },
          onWebResourceError: (error) {
            print('❌ WebView error: ${error.description}');
          },
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url;
            print('🔗 Navigation: $url');
            
            // Handle intent:// schemes - redirect to external app/browser
            if (url.startsWith('intent://')) {
              print('🔗 Intercepting intent:// - launching external');
              _launchExternalUrl(url);
              return NavigationDecision.prevent;
            }
            
            // Check for success response
            if (url.contains('payment-return') || url.contains('vnp_ResponseCode')) {
              _handlePaymentReturn(url);
              return NavigationDecision.prevent;
            }
            
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(paymentUrl));
  }

  void _launchExternalUrl(String url) async {
    try {
      // Remove the Intent wrapper and extract the actual URL if needed
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        );
        print('✅ Launched external app');
      } else {
        print('❌ Cannot launch URL: $url');
      }
    } catch (e) {
      print('❌ Error launching URL: $e');
    }
  }

  void _handlePaymentReturn(String returnUrl) {
    print('💳 Payment return detected');
    _hasReceivedValidResponse = true;
    
    try {
      final uri = Uri.parse(returnUrl);
      final queryParams = uri.queryParameters;
      
      final responseCode = queryParams['vnp_ResponseCode'] ?? '';
      final success = responseCode == '00';
      
      print('✅ Response Code: $responseCode (Success: $success)');
      
      if (success) {
        // Update storage in Supabase when payment succeeds
        _updateStorageAfterPayment();
      } else {
        if (mounted) {
          Navigator.pop(context);
          widget.onReturn(false);
        }
      }
    } catch (e) {
      print('❌ Error parsing return: $e');
      if (mounted) {
        Navigator.pop(context);
        widget.onReturn(false);
      }
    }
  }

  Future<void> _updateStorageAfterPayment() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      
      if (userId == null) throw Exception('User not logged in');
      
      print('👤 Updating storage for user: $userId');
      
      // 1. Update Supabase profile
      await supabase
          .from('profiles')
          .update({
            'level': 2,
            'is_premium': true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
      
      print('✅ Supabase profile updated: level=2, is_premium=true');
      
      // 2. Update local SharedPreferences (IMPORTANT!)
      final quotaService = StorageQuotaService();
      await quotaService.upgradeStorage();
      print('✅ Local storage upgraded (SharedPreferences updated)');
      
      // 3. Clear storage cache to force refresh
      await quotaService.clearStorageCache();
      print('✅ Storage cache cleared');
      
      // Wait for updates to propagate
      await Future.delayed(const Duration(milliseconds: 500));
      
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF9F9FF),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryColor),
          onPressed: () {
            if (!_hasReceivedValidResponse) {
              Navigator.pop(context);
              widget.onReturn(false);
            }
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

