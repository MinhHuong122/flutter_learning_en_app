# VNPAY Integration Guide

## Overview

This document describes the VNPAY Sandbox payment gateway integration implemented in the app. The system allows users to upgrade their storage to 5GB by paying 20,000 VND through VNPAY.

## Integration Architecture

### Components

1. **VNPayService** (`lib/services/vnpay_service.dart`)
   - Handles all VNPAY protocol operations
   - Generates payment URLs with HMAC SHA512 signatures
   - Verifies payment responses from VNPAY
   - Parses payment data

2. **PaymentScreen** (`lib/screens/payment_screen.dart`)
   - Displays payment information (5GB storage, 20,000 VND)
   - Launches VNPAY payment URL via url_launcher
   - Shows QR code and bank transfer details as alternatives

3. **PaymentReturnScreen** (`lib/screens/payment_return_screen.dart`)
   - Receives VNPAY callback via deep link
   - Verifies payment signature
   - Updates user profile (level=2, is_premium=true)
   - Records payment transaction in database

4. **StorageUpgradeScreen** (`lib/screens/storage_upgrade_screen.dart`)
   - UI for upgrading storage
   - Navigates to PaymentScreen

### Payment Flow

```
StorageUpgradeScreen
        ↓
    (Click Upgrade)
        ↓
  PaymentScreen
        ↓
    (Click "Proceed to Payment")
        ↓
  VNPAY Payment URL Launched
        ↓
    (User completes payment on VNPAY)
        ↓
  VNPAY Redirects to app://payment-return?vnp_Amount=...&vnp_ResponseCode=00...
        ↓
  PaymentReturnScreen (via Deep Link)
        ↓
    (Verify signature)
        ↓
  Update Supabase Profile (level=2, is_premium=true)
        ↓
  Show Success/Failure
```

## Configuration

### 1. VNPAY Sandbox Credentials

Edit `lib/services/vnpay_service.dart` to replace placeholder credentials:

```dart
class VNPayService {
  // ⚠️ REPLACE THESE WITH YOUR VNPAY CREDENTIALS
  static const String TMN_CODE = 'DEMOV210';        // Your merchant code
  static const String HASH_SECRET = 'SHOAITMYSECRETKEY'; // Your hash secret
```

**How to Get Credentials:**

1. Sign up for VNPAY Sandbox at https://sandbox.vnpayment.vn/
2. Log in to merchant portal
3. Navigate to: Configuration > Merchant Information
4. Copy your **TMN Code** and **Hash Secret**
5. Update the constants above

### 2. Deep Linking Setup

Deep linking is **already configured**:

- **Android**: Intent filter added to `android/app/src/main/AndroidManifest.xml`
- **Return URL Scheme**: `app://payment-return`
- **Handler**: Configured in `lib/main.dart` via `onGenerateRoute`

### 3. Return URL Configuration in VNPAY

The app uses: `app://payment-return`

To capture query parameters:
- VNPAY will redirect to: `app://payment-return?vnp_Amount=2000000&vnp_ResponseCode=00&...`
- The `onGenerateRoute` handler extracts query parameters and passes to PaymentReturnScreen

## VNPAY Test Cards (Sandbox)

For testing payment on VNPAY Sandbox:

### Visa Card

```
Card Number: 4111111111111111
Holder Name: TESTER
Expiry Date: 07/25
CVV: 123
OTP: 123456
```

### Mastercard

```
Card Number: 5555555555554444
Holder Name: TESTER
Expiry Date: 07/25
CVV: 123
OTP: 123456
```

### Notes

- All test cards are configured to succeed by default in sandbox
- Use any expiry date in the future
- OTP is always `123456` in sandbox

## Testing the Payment Flow

### Step 1: Launch the App and Navigate to Storage Upgrade

```bash
cd d:\DHV\Year4\Semester2\DoAn\app_learn_english
flutter run
```

1. Log in with your test account
2. Navigate to Settings/Profile → Storage Upgrade (or Storage option)
3. Click "Upgrade Storage" button

### Step 2: Test Payment

1. Click **"Proceed to Payment"** button
2. The app will:
   - Generate VNPAY payment URL with HMAC SHA512 hash
   - Launch the VNPAY payment page in browser
3. Select a test card and complete payment
4. VNPAY will redirect back to the app via deep link

### Step 3: Verify Result

1. **PaymentReturnScreen** should receive the callback
2. Check for:
   - ✅ Signature verification passes
   - ✅ Payment status shows "Success" (ResponseCode=00)
   - ✅ Transaction details displayed
3. Close the screen

### Step 4: Verify Database Update

Check Supabase to confirm profile was updated:

```sql
-- In Supabase SQL Editor
SELECT id, level, is_premium, created_at FROM profiles 
WHERE id = 'your_user_id'
LIMIT 1;

-- Should show: level=2, is_premium=true
```

## Important Parameters

### Payment Request Parameters

| Parameter | Value | Notes |
|-----------|-------|-------|
| vnp_Amount | 2000000 | Multiply actual amount by 100 (20,000 VND = 2,000,000) |
| vnp_TmnCode | DEMOV210 | Your merchant code |
| vnp_Command | pay | Standard payment command |
| vnp_Version | 2.1.0 | VNPAY version |
| vnp_OrderInfo | "Upgrade to 5GB Storage" | User-friendly description |
| vnp_TxnRef | "ORDER_[timestamp]" | Unique order ID (prevents duplicates) |
| vnp_ReturnUrl | "app://payment-return" | Where VNPAY redirects after payment |
| vnp_CreateDate | Current time (GMT+7) | Format: YYYYMMDDHHmmss |
| vnp_ExpireDate | +15 minutes | Format: YYYYMMDDHHmmss |
| vnp_SecureHash | HMAC SHA512 | Calculated from sorted parameters |

### Payment Response Parameters

VNPAY returns (via query string):

```
?vnp_Amount=2000000
&vnp_BankCode=NCB
&vnp_BankTranNo=ABC123
&vnp_CardType=CC
&vnp_OrderInfo=Upgrade to 5GB Storage
&vnp_PayDate=20250107150530
&vnp_ResponseCode=00
&vnp_TmnCode=DEMOV210
&vnp_TransactionNo=13862088
&vnp_TxnRef=ORDER_1704626730000
&vnp_SecureHash=... (to verify)
```

### Response Codes

| Code | Meaning | Action |
|------|---------|--------|
| 00 | Successful | Update profile, show success |
| Other | Failed | Show error message, don't update profile |

## HMAC SHA512 Signature Generation

The signature is generated using **HMAC SHA512**:

1. Sort all VNPAY parameters alphabetically by key
2. Concatenate key-value pairs: `key1=value1&key2=value2&...`
3. Append hash secret: `data=string + HASH_SECRET`
4. Calculate HMAC SHA512: `hmac_sha512(data, HASH_SECRET)`
5. Add to request as `vnp_SecureHash` parameter

This is **automatic** - VNPayService handles it:

```dart
final paymentUrl = VNPayService.buildPaymentUrl(
  orderInfo: 'Upgrade to 5GB Storage',
  amount: 20000,
  orderId: 'ORDER_${DateTime.now().millisecondsSinceEpoch}',
  returnUrl: 'app://payment-return',
  ipAddress: '0.0.0.0',
);
// Returns: Complete VNPAY payment URL with HMAC SHA512 hash calculated
```

## Database Updates

### Supabase Profile Table

When payment succeeds:

```sql
UPDATE profiles 
SET 
  level = 2,
  is_premium = true,
  updated_at = NOW()
WHERE id = 'user_id';
```

### Payment Transaction Record

Optional - creates record in `payments` table if implemented:

```sql
INSERT INTO payments (user_id, amount, transaction_id, order_id, status, bank_code, payment_date)
VALUES (
  'user_id',           -- UUID
  20000,               -- Amount in VND
  '13862088',          -- VNPAY transaction ID
  'ORDER_1704626730000' -- Our order ID
  'success',
  'NCB',
  NOW()
);
```

## File Changes Summary

### New Files Created

1. **lib/services/vnpay_service.dart** - VNPAY service layer (200+ lines)
2. **lib/screens/payment_return_screen.dart** - VNPAY callback handler (350+ lines)

### Modified Files

1. **lib/screens/payment_screen.dart**
   - Replaced mock verification with real VNPAY payment
   - Added `_launchVNPayment()` method
   - Changed button text to "Proceed to Payment"
   - Added loading indicator

2. **lib/main.dart**
   - Imported PaymentReturnScreen
   - Added `onGenerateRoute` handler for deep links

3. **android/app/src/main/AndroidManifest.xml**
   - Added deep link intent filter for `app://payment-return`

4. **pubspec.yaml**
   - Added `intl: ^0.19.0` (date formatting)
   - Added `crypto: ^3.0.3` (HMAC SHA512)

## Troubleshooting

### Issue: Payment URL Not Launching

**Possible Causes:**
- url_launcher plugin not properly configured
- App not installed in Android device/emulator

**Solution:**
```dart
// Check Logcat for url_launcher errors
// Verify app:// scheme is registered in AndroidManifest.xml
```

### Issue: Deep Link Not Triggered

**Possible Causes:**
- Intent filter not properly configured
- Deep link scheme doesn't match app://payment-return
- App not in foreground when VNPAY redirects

**Solution:**
```bash
# Test deep link manually
adb shell am start -W -a android.intent.action.VIEW -d "app://payment-return?vnp_Amount=2000000&vnp_ResponseCode=00" com.example.pupu
```

### Issue: Signature Verification Fails

**Possible Causes:**
- VNPAY credentials (Hash Secret) incorrect
- Query parameters modified after VNPAY generates them

**Solution:**
1. Double-check Hash Secret in VNPayService
2. Add debug logging:
```dart
// In PaymentReturnScreen._processPayment()
print('Raw Params: ${widget.queryParams}');
final isValid = VNPayService.verifyResponse(widget.queryParams);
print('Signature Valid: $isValid');
```

### Issue: Profile Not Updated

**Possible Causes:**
- Supabase authentication not initialized
- Database permissions not set correctly
- Transaction failed silently

**Solution:**
```dart
// Check Supabase logs
final response = await supabase
  .from('profiles')
  .update({'level': 2, 'is_premium': true})
  .eq('id', userId);

print('Supabase Response: $response');
```

## Next Steps

### Production Deployment

Before going live:

1. **Replace Sandbox Credentials**
   - Get production TMN Code and Hash Secret from VNPAY
   - Update VNPayService constants

2. **Update Payment URL**
   - Change from sandbox: `https://sandbox.vnpayment.vn/paymentv2/vpcpay.html`
   - To production: `https://paymentv2.vnpayment.vn/vpcpay.html`

3. **Test with Real Cards**
   - Contact VNPAY to enable live card payments
   - Test with real credit card (small amount first)

4. **Security Considerations**
   - Never commit credentials to version control
   - Use environment variables for sensitive data
   - Verify all signatures server-side (not just client)

5. **Monitoring**
   - Log all payment transactions
   - Set up alerts for failed payments
   - Monitor VNPAY webhook callbacks (optional)

## Resources

- **VNPAY Documentation**: https://sandbox.vnpayment.vn/ → Help
- **VNPAY API Guide**: Check merchant portal for latest API documentation
- **Dart crypto Package**: https://pub.dev/packages/crypto
- **Date Formatting (intl)**: https://pub.dev/packages/intl

## Support

For issues with:
- **VNPAY**: Contact VNPAY support via merchant portal
- **Flutter Integration**: Check Flutter documentation and Dart packages
- **Deep Linking**: Refer to Android Intent Filters documentation

---

**Last Updated**: January 2025
**Status**: ✅ Ready for Testing
**Compilation**: APK builds successfully with 0 errors
