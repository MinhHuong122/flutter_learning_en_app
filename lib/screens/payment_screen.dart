import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../utils/constants.dart';
import '../services/language_service.dart';
import '../services/storage_quota_service.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({Key? key}) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _paymentConfirmed = false;
  
  bool get _isEnglish => context.read<LanguageService>().isEnglish;
  
  // Mock payment verification - in real app, check with backend
  Future<void> _simulatePaymentVerification() async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(
          color: AppColors.primaryColor,
        ),
      ),
    );
    
    // Simulate checking payment for 3 seconds
    await Future.delayed(const Duration(seconds: 3));
    
    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context); // Close loading dialog
    }
    
    // In real app, verify with backend/payment gateway
    // For now, simulate success
    setState(() => _paymentConfirmed = true);
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
              onPressed: _simulatePaymentVerification,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _isEnglish ? 'I have paid - Continue' : 'Tôi đã thanh toán - Tiếp tục',
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
