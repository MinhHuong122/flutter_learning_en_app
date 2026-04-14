# Fixing VNPAY Error Code 99 - Merchant Credentials Issue

## Problem

You're getting **Error code 99** from VNPAY, which means:
- ❌ Merchant code (TMN_CODE) is invalid or not recognized
- ❌ Merchant is not authorized for payment service
- ❌ Signature verification failed due to wrong credentials

## Root Cause

The code is currently using **placeholder credentials**:
```dart
static const String TMN_CODE = 'DEMOV210';
static const String HASH_SECRET = 'SHOAITMYSECRETKEY';
```

These are **not real VNPAY credentials** - they won't work with VNPAY's actual sandbox environment.

## Solution - Get Real VNPAY Credentials

### Step 1: Register on VNPAY Sandbox

1. Visit: **https://sandbox.vnpayment.vn/**
2. Click **"Đăng ký"** (Register)
3. Fill in information:
   - Email
   - Password
   - Business info (can be test data)
   - Phone
4. Verify email
5. Log in

### Step 2: Get Merchant Code and Hash Secret

1. After logging in, go to: **"Cấu hình"** (Configuration) or **"Tài khoản"** (Account)
2. Look for section: **"Thông tin Merchant"** (Merchant Information)
3. Copy the following values:
   - **TMN Code** (Mã Merchant/Mã TMN) 
   - **Hash Secret Key** (Khóa bí mật)
   - **Account Number** (Số tài khoản)

Example format:
```
TMN Code:      XXXXX210  (usually 8 characters, ends with 210)
Hash Secret:   XXXXXXXXXXXXXXXXXXXXXX (40+ characters, alphanumeric)
```

### Step 3: Update Your Code

Edit `lib/services/vnpay_service.dart`:

```dart
class VNPayService {
  // ✅ REPLACE WITH YOUR REAL SANDBOX CREDENTIALS
  static const String TMN_CODE = 'YOUR_TMN_CODE_HERE';        // Copy from VNPAY sandbox
  static const String HASH_SECRET = 'YOUR_HASH_SECRET_HERE';  // Copy from VNPAY sandbox
  static const String PAYMENT_URL = 'https://sandbox.vnpayment.vn/paymentv2/vpcpay.html';
  static const String API_URL = 'https://sandbox.vnpayment.vn/merchant_webapi/api/transaction';
```

**Example** (these are fake, use your real ones):
```dart
  static const String TMN_CODE = 'ABC12345';        
  static const String HASH_SECRET = 'abcdef123456789abcdef123456789abcdef1234';
```

### Step 4: Rebuild and Test

```bash
cd d:\DHV\Year4\Semester2\DoAn\app_learn_english
flutter pub get
flutter run
```

## Debugging the Hash

I've added debug logging to show:
1. **Hash Input** - The parameters being hashed
2. **Hash Secret** - The secret key being used
3. **Generated Hash** - The computed HMAC SHA512

When you run the payment again, check Logcat:
```bash
adb logcat | grep "Hash"
```

You should see:
```
🔑 Hash Input: vnp_Amount=2000000&vnp_Command=pay&vnp_CreateDate=...
🔑 Hash Secret: YOUR_REAL_HASH_SECRET
🔑 Generated Hash: [your computed hash]
```

If the Hash Secret still shows `SHOAITMYSECRETKEY`, you forgot to update it!

## Common Issues

### Issue 1: Still getting Error 99 after updating credentials
**Solution:**
1. ✅ Verify credentials exactly match VNPAY portal (case-sensitive!)
2. ✅ Make sure there are no spaces or extra characters
3. ✅ Check that account is activated (not suspended)
4. ✅ Try logging out and back into VNPAY portal to refresh credentials

### Issue 2: Can't find Merchant Information on VNPAY
**Solution:**
1. Go to: https://sandbox.vnpayment.vn/
2. Log in with your account
3. Navigation varies by VNPAY version, look for:
   - "Cấu hình Merchant" (Merchant Configuration)
   - "Thông tin Tài khoản" (Account Information)
   - "API Credentials"
4. Or contact: VNPAY support via their portal

### Issue 3: Hash mismatch error even with correct credentials
**Possible Causes:**
- Parameter values changed after hash calculation
- Special characters in parameters not URL-encoded properly
- Timestamp misaligned with server time

**Solution:**
1. Check Logcat for actual hash being sent
2. Verify vnp_CreateDate is system time (not hardcoded)
3. Ensure all parameters match exactly

## Test Cards (Valid for any VNPAY merchant)

Once you have proper credentials, use these test cards:

### Visa - Always Success
```
Card Number: 4111111111111111
Holder Name: TESTER
Expiry Date: 07/25
CVV: 123  
OTP: 123456
```

### MasterCard - Always Success
```
Card Number: 5555555555554444
Holder Name: TESTER
Expiry Date: 07/25
CVV: 123
OTP: 123456
```

### Card - Always Fail (for testing error scenarios)
```
Card Number: 3782822463100005
Holder Name: TESTER
Expiry Date: 07/25
CVV: 123
OTP: 123456
```

## Alternative: Test with Mock VNPAY

If you can't get real credentials, you can mock the payment:

Edit `payment_screen.dart` - VNPayWebView:
```dart
// Temporary: Mock VNPAY response
void _handlePaymentSuccess() {
  print('✅ Payment successful detected');
  if (mounted) {
    Navigator.pop(context);
    widget.onReturn(true); // Simulate success
  }
}
```

This lets you test the UI flow without real VNPAY credentials. But for production, you need real credentials.

## Getting Help

### VNPAY Support
- **Website**: https://sandbox.vnpayment.vn/
- **Email**: Contact VNPAY support from that website
- **Chat**: Usually available on their portal

### Verify Your Integration
Once you have credentials, verify by:
1. Checking demo account exists
2. Running one successful payment test
3. Viewing transaction in VNPAY merchant portal
4. Confirming database updated (level=2, is_premium=true)

## Next Steps

1. **Get VNPAY Credentials** (this is required)
2. **Update VNPayService** with real TMN_CODE and HASH_SECRET
3. **Rebuild app** `flutter run`
4. **Test payment** with test card 4111111111111111
5. **Verify success** in both app and Supabase

---

**Important**: DEMOV210 is NOT a real merchant code. You MUST register on VNPAY and get your own credentials.

**Timeline**: Registration takes ~5-10 minutes, credentials instant upon creation.
