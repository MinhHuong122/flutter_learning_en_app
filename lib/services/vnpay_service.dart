import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class VNPayService {
  // Sandbox credentials - Real VNPAY sandbox environment (NEW ACCOUNT - April 14, 2026)
  static const String TMN_CODE = '38EZDSNQ'; // VNPAY Sandbox Terminal ID (NEW)
  static const String HASH_SECRET = 'V78TIVHC8GTX7XCZN9Z5MO20G5Y6V44U'; // VNPAY Sandbox Secret Key (NEW)
  static const String PAYMENT_URL = 'https://sandbox.vnpayment.vn/paymentv2/vpcpay.html';
  static const String API_URL = 'https://sandbox.vnpayment.vn/merchant_webapi/api/transaction';

  /// Build payment URL for VNPAY
  static String buildPaymentUrl({
    required String orderInfo,
    required double amount, // Amount in VND
    required String orderId,
    String returnUrl = 'https://www.example.com/payment-return', // Default HTTPS URL
    String ipAddress = '127.0.0.1',
    String locale = 'vn', // 'vn' or 'en'
    String bankCode = '', // Optional: 'VNPAYQR', 'VNBANK', 'INTCARD'
  }) {
    print('🔵 VNPayService.buildPaymentUrl called');
    print('  - orderInfo: $orderInfo');
    print('  - amount: $amount');
    print('  - orderId: $orderId');
    print('  - returnUrl: $returnUrl');
    print('  - ipAddress: $ipAddress');
    
    // Amount must be multiplied by 100 (remove decimal part)
    final amountInCents = (amount * 100).toInt();

    // Create create date and expire date
    final now = DateTime.now();
    final createDate = DateFormat('yyyyMMddHHmmss').format(now);
    final expireDate = now.add(const Duration(minutes: 15));
    final expireDateStr = DateFormat('yyyyMMddHHmmss').format(expireDate);

    // Build request data - use only ASCII-safe characters to avoid encoding issues
    final requestData = <String, String>{
      'vnp_Version': '2.1.0',
      'vnp_Command': 'pay',
      'vnp_TmnCode': TMN_CODE,
      'vnp_Amount': amountInCents.toString(),
      'vnp_CurrCode': 'VND',
      'vnp_TxnRef': orderId,
      'vnp_OrderInfo': _sanitizeOrderInfo(orderInfo), // Sanitize to avoid encoding issues
      'vnp_OrderType': 'other',
      'vnp_Locale': locale,
      'vnp_ReturnUrl': returnUrl,
      'vnp_CreateDate': createDate,
      'vnp_ExpireDate': expireDateStr,
      'vnp_IpAddr': ipAddress,
    };

    // Add bank code if provided
    if (bankCode.isNotEmpty) {
      requestData['vnp_BankCode'] = bankCode;
    }

    // Generate secure hash
    print('🔵 Generating secure hash...');
    final secureHash = _generateSecureHash(requestData);
    requestData['vnp_SecureHash'] = secureHash;

    print('🔵 Building query string...');
    // Build URL
    final queryString = _buildQueryString(requestData);
    final fullUrl = '$PAYMENT_URL?$queryString';
    
    print('🔵 Final URL (first 200 chars): ${fullUrl.substring(0, 200)}...');
    print('🔵 Final URL length: ${fullUrl.length}');
    
    return fullUrl;
  }

  /// Sanitize order info to avoid encoding issues with special characters
  static String _sanitizeOrderInfo(String orderInfo) {
    // Replace Vietnamese characters with ASCII equivalents
    var sanitized = orderInfo
        .replaceAll('â', 'a')
        .replaceAll('ă', 'a')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ô', 'o')
        .replaceAll('ơ', 'o')
        .replaceAll('ư', 'u')
        .replaceAll('ư', 'u')
        .replaceAll('ơ', 'o')
        .replaceAll('Â', 'A')
        .replaceAll('Ă', 'A')
        .replaceAll('É', 'E')
        .replaceAll('Ê', 'E')
        .replaceAll('Ô', 'O')
        .replaceAll('Ơ', 'O')
        .replaceAll('Ư', 'U');
    
    return sanitized;
  }

  /// Verify response from VNPAY
  static bool verifyResponse(Map<String, dynamic> responseData) {
    try {
      // Extract secure hash from response
      final secureHash = responseData['vnp_SecureHash'] as String?;
      if (secureHash == null || secureHash.isEmpty) {
        return false;
      }

      // Create a copy of response data without secure hash
      final dataCopy = Map<String, dynamic>.from(responseData);

      // Convert to string map for hashing
      final hashData = <String, String>{};
      dataCopy.forEach((key, value) {
        if (value != null) {
          hashData[key] = value.toString();
        }
      });

      // Generate hash for verification
      final calculatedHash = _generateSecureHash(hashData);

      // Compare hashes (case-insensitive)
      return calculatedHash.toString().toLowerCase() ==
          secureHash.toLowerCase();
    } catch (e) {
      print('Error verifying response: $e');
      return false;
    }
  }

  /// Generate HMAC SHA512 secure hash
  static String _generateSecureHash(Map<String, String> data) {
    // Sort data by keys
    final sortedKeys = data.keys.toList()..sort();

    // Build hash input string
    final hashInput = sortedKeys
        .map((key) =>
            '${Uri.encodeQueryComponent(key)}=${Uri.encodeQueryComponent(data[key]!)}')
        .join('&');

    print('🔑 Hash Parameters (sorted):');
    for (var key in sortedKeys) {
      print('   $key = ${data[key]}');
    }
    print('🔑 Hash Input String: $hashInput');
    print('🔑 Hash Secret Length: ${HASH_SECRET.length}');
    print('🔑 Hash Secret (first 10 chars): ${HASH_SECRET.substring(0, 10)}...');

    // Generate HMAC SHA512
    final bytes = utf8.encode(HASH_SECRET);
    final hmac = Hmac(sha512, bytes);
    final digest = hmac.convert(utf8.encode(hashInput));

    final hash = digest.toString().toUpperCase(); // ✅ MUST BE UPPERCASE
    print('🔑 Generated Hash (SHA512): $hash');
    print('🔑 Hash Length: ${hash.length}');
    
    return hash;
  }

  /// Build query string from data
  static String _buildQueryString(Map<String, String> data) {
    final sortedKeys = data.keys.toList()..sort();
    final params = sortedKeys
        .map((key) => '${Uri.encodeComponent(key)}=${Uri.encodeComponent(data[key]!)}')
        .join('&');
    return params;
  }

  /// Parse payment response from URL parameters
  static Map<String, dynamic> parsePaymentResponse(Map<String, String> queryParams) {
    return {
      'vnp_Amount': queryParams['vnp_Amount'] != null
          ? int.parse(queryParams['vnp_Amount'] ?? '0') ~/ 100
          : 0,
      'vnp_BankCode': queryParams['vnp_BankCode'],
      'vnp_ResponseCode': queryParams['vnp_ResponseCode'],
      'vnp_TransactionNo': queryParams['vnp_TransactionNo'],
      'vnp_TxnRef': queryParams['vnp_TxnRef'],
      'vnp_PayDate': queryParams['vnp_PayDate'],
      'vnp_OrderInfo': queryParams['vnp_OrderInfo'],
      'isSuccess': queryParams['vnp_ResponseCode'] == '00',
    };
  }
}
