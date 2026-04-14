# Kiểm tra Checksum Function - VNPAY Specification

## ✅ So sánh Code của Bạn vs VNPAY Specification

### VNPAY Specification (Đúng)
```dart
String createSignature(Map<String, String> params, String hashSecret) {
  // Sắp xếp key theo thứ tự alphabet
  var sortedKeys = params.keys.toList()..sort();
  
  // Build query string WITHOUT encoding for hash
  String query = sortedKeys
    .map((key) => "$key=${params[key]}")
    .join('&');
  
  // Tạo HMAC SHA512
  var hmac = Hmac(sha512, utf8.encode(hashSecret));
  var digest = hmac.convert(utf8.encode(query));
  
  return digest.toString();
}
```

### Code của Bạn (vnpay_service.dart - _generateSecureHash)
```dart
static String _generateSecureHash(Map<String, String> data) {
  // Sort data by keys ✅ ĐÚNG
  final sortedKeys = data.keys.toList()..sort();

  // Build hash input string - NO ENCODING ✅ ĐÚNG
  final hashInput = sortedKeys
      .map((key) => '$key=${data[key]}')
      .join('&');

  // Generate HMAC SHA512 ✅ ĐÚNG
  final bytes = utf8.encode(HASH_SECRET);
  final hmac = Hmac(sha512, bytes);
  final digest = hmac.convert(utf8.encode(hashInput));

  final hash = digest.toString();
  return hash;
}
```

---

## ✅ Kiểm tra Chi tiết

| Bước | VNPAY Specification | Code của Bạn | Status |
|------|-------------------|--------------|--------|
| 1. Sort keys A-Z | `params.keys.toList()..sort()` | `data.keys.toList()..sort()` | ✅ ĐÚNG |
| 2. Build string (NO encoding) | `"$key=${params[key]}"` | `'$key=${data[key]}'` | ✅ ĐÚNG |
| 3. Join with & | `.join('&')` | `.join('&')` | ✅ ĐÚNG |
| 4. HMAC SHA512 | `Hmac(sha512, utf8.encode(...))` | `Hmac(sha512, utf8.encode(...))` | ✅ ĐÚNG |
| 5. Convert input to UTF8 | `utf8.encode(query)` | `utf8.encode(hashInput)` | ✅ ĐÚNG |
| 6. Return hex string | `.toString()` | `.toString()` | ✅ ĐÚNG |

---

## ✅ Kiểm tra Tham số Bắt Buộc

Code của bạn tạo URL với tất cả tham số bắt buộc:

| Tham số | Giá trị | Code của Bạn | Status |
|--------|--------|--------------|--------|
| **vnp_Version** | 2.1.0 | `'vnp_Version': '2.1.0'` | ✅ ĐÚNG |
| **vnp_Command** | pay | `'vnp_Command': 'pay'` | ✅ ĐÚNG |
| **vnp_TmnCode** | 38EZDSNQ | `'vnp_TmnCode': TMN_CODE` | ✅ ĐÚNG |
| **vnp_Amount** | x100 | `(amount * 100).toInt()` | ✅ ĐÚNG |
| **vnp_CreateDate** | yyyyMMddHHmmss | `DateFormat('yyyyMMddHHmmss').format(now)` | ✅ ĐÚNG |
| **vnp_ExpireDate** | yyyyMMddHHmmss | `now.add(Duration(minutes: 15))` + format | ✅ ĐÚNG |
| **vnp_CurrCode** | VND | `'vnp_CurrCode': 'VND'` | ✅ ĐÚNG |
| **vnp_Locale** | vn | `'vnp_Locale': locale` | ✅ ĐÚNG |
| **vnp_IpAddr** | IP | `'vnp_IpAddr': ipAddress` | ✅ ĐÚNG |
| **vnp_OrderInfo** | Mô tả | `_sanitizeOrderInfo(orderInfo)` | ✅ ĐÚNG |
| **vnp_OrderType** | other | `'vnp_OrderType': 'other'` | ✅ ĐÚNG |
| **vnp_ReturnUrl** | URL | `'vnp_ReturnUrl': returnUrl` | ✅ ĐÚNG |
| **vnp_TxnRef** | Unique/ngày | `'vnp_TxnRef': orderId` | ✅ ĐÚNG |
| **vnp_SecureHash** | HMAC SHA512 | `_generateSecureHash(requestData)` | ✅ ĐÚNG |

---

## ✅ Kiểm tra Flow (Thứ tự)

### Flow của VNPAY Specification:
1. Tạo Map params (không có vnp_SecureHash)
2. Sort keys
3. Build string từ params (không encode)
4. HMAC SHA512
5. Add vnp_SecureHash vào params
6. Build URL với toàn bộ params (có encoding)

### Flow của Code Bạn:
1. Tạo requestData (không có vnp_SecureHash) ✅
2. Gọi _generateSecureHash(requestData) ✅
   - Sort keys ✅
   - Build string (không encode) ✅
   - HMAC SHA512 ✅
3. Add vnp_SecureHash vào requestData ✅
4. Gọi _buildQueryString(requestData) ✅
   - URL encode keys và values ✅
   - Build final URL ✅

---

## ✅ Kiểm tra Query String Building

Code bạn:
```dart
static String _buildQueryString(Map<String, String> data) {
  final sortedKeys = data.keys.toList()..sort();
  final params = sortedKeys
      .map((key) => '${Uri.encodeComponent(key)}=${Uri.encodeComponent(data[key]!)}')
      .join('&');
  return params;
}
```

✅ Cách này đúng vì:
1. Sắp xếp keys ✅
2. URL encode cả key và value ✅
3. Join bằng & ✅
4. Đây là cách để tạo query string an toàn cho URL ✅

---

## ✅ CONCLUSION

| Tiêu chí | Status | Ghi chú |
|---------|--------|---------|
| **Hash Function** | ✅ CHÍNH XÁC | Giống hệt VNPAY spec |
| **Tham số Bắt Buộc** | ✅ ĐẦY ĐỦ | Tất cả 14 tham số có |
| **Amount Conversion** | ✅ ĐÚNG | x100 cho hash, /100 cho parse |
| **DateTime Format** | ✅ ĐÚNG | yyyyMMddHHmmss |
| **URL Encoding** | ✅ ĐÚNG | Dùng Uri.encodeComponent |
| **Order ID** | ✅ ĐÚNG | Unique per transaction |
| **Sanitization** | ✅ ĐÚNG | Vietnamese chars removed |

---

## 🎯 **CODE CỦA BẠN 100% CHÍNH XÁC THEO VNPAY SPECIFICATION!**

Không có vấn đề nào với implementation!

