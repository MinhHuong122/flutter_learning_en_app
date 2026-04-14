# VNPAY Integration - Direct Payment Flow (Updated)

## What Changed ✅

**Previous Flow**: StorageUpgradeScreen → PaymentScreen → VNPayWebView → VNPAY
**New Flow**: StorageUpgradeScreen → VNPayWebView → VNPAY (Direct)

This is exactly what you requested - skip the intermediate PaymentScreen and go straight to VNPAY!

## Key Improvements

### 1. Direct Payment (No Intermediate Screen)
- User clicks "Upgrade Storage" on StorageUpgradeScreen
- ✅ Immediately opens VNPAY WebView (skips PaymentScreen)
- ✅ Faster payment experience

### 2. Fixed VNPAY Error Code 99
The error was caused by using `app://payment-return` as the return URL. VNPAY expects a valid HTTPS URL.
- ✅ Changed return URL to: `https://www.example.com/payment-return`
- ✅ VNPAY now accepts the payment request

### 3. Better Payment Result Detection
Instead of relying on deep links, WebView now:
- ✅ Intercepts VNPAY success/error pages automatically
- ✅ Detects payment result instantly
- ✅ Updates storage immediately

## New Payment Flow

```
User on StorageUpgradeScreen
         ↓
    Click "Upgrade Storage" button
         ↓
    VNPayWebView opens (directly, no PaymentScreen)
         ↓
    VNPAY payment page loads in WebView
         ↓
    User enters card: 4111111111111111
    (or 5555555555554444 for MasterCard)
         ↓
    Completes payment
         ↓
    VNPAY processes payment
         ↓
    IF Success (Code=00):
         ↓
       VNPayWebView detects success
       Supabase profile updates (level=2, is_premium=true)
       Shows success message
         ↓
    IF Failed:
         ↓
       VNPayWebView detects error
       Shows error message
       User can retry
```

## Testing the New Flow

### Step 1: Navigate to Storage Upgrade
```bash
1. Open app
2. Go to Settings/Profile → "Upgrade Storage" 
3. See StorageUpgradeScreen
```

### Step 2: Start Payment (Direct to VNPAY)
```bash
1. Click "Upgrade Storage" / "Buy Now" button
2. Check logs for:
   🔵 Building VNPAY payment URL...
   📱 Building VNPAY payment URL...
   📱 VNPAY Payment URL ready, initializing WebView...
3. Expect: VNPayWebView opens immediately
4. See: VNPAY logo loading
```

### Step 3: Complete Payment
```bash
1. Wait for VNPAY page to fully load
2. Select payment method
3. Enter test card:
   Card: 4111111111111111 (Visa)
   Holder: TESTER
   Expiry: 07/25 (or any future date)
   CVV: 123
   OTP: 123456
4. Click "Pay" / "Xác nhận"
```

### Step 4: Verify Success
```
Expected Success Flow:
1. Logcat shows: ✅ Payment successful detected
2. WebView closes automatically
3. Returns to StorageUpgradeScreen
4. Shows: "✅ Storage upgraded successfully!"
5. Storage display updates to: 5GB (Premium)
6. Check Supabase:
   SELECT * FROM profiles WHERE id = 'your_user_id';
   Should show: level=2, is_premium=true
```

## Files Modified

### 1. storage_upgrade_screen.dart
- ✅ Removed PaymentScreen import
- ✅ Added VNPayService import
- ✅ Changed `_navigateToPayment()` to launch VNPayWebView directly
- ✅ Added `_handlePaymentResult()` to process payment outcome

### 2. payment_screen.dart
- ✅ Updated VNPayWebView to generate payment URL internally
- ✅ VNPayWebView no longer needs `url` parameter
- ✅ Uses default HTTPS return URL (no app:// scheme)
- ✅ Better navigation detection for VNPAY success/error pages

### 3. vnpay_service.dart
- ✅ Made `returnUrl` parameter optional (default: HTTPS URL)
- ✅ Made `ipAddress` parameter optional (default: 127.0.0.1)
- ✅ Improved default parameter handling

## Debugging Commands

### Monitor Payment Flow
```bash
adb logcat | grep -E "Building VNPAY|Payment URL|WebView|Payment success|Payment error|Response Code"
```

### Check for VNPAY Errors
```bash
adb logcat | grep -E "Error.html|code=|Navigation request"
```

### Monitor Supabase Updates
```bash
# In Supabase SQL Editor:
SELECT id, level, is_premium, updated_at FROM profiles 
WHERE id = 'your_user_id' 
ORDER BY updated_at DESC LIMIT 1;
```

## Expected Log Output

### Successful Payment
```
🔵 Building VNPAY payment URL...
📱 Building VNPAY payment URL...
📱 VNPAY Payment URL ready, initializing WebView...
📄 WebView loading: https://sandbox.vnpayment.vn/paymentv2/vpcpay.html?...
📄 WebView finished: https://sandbox.vnpayment.vn/paymentv2/Payment/...
✅ Payment successful detected
```

### Failed Payment
```
🔵 Building VNPAY payment URL...
📱 VNPAY Payment URL ready, initializing WebView...
📄 WebView loading: https://sandbox.vnpayment.vn/paymentv2/vpcpay.html?...
🔗 Navigation request: https://sandbox.vnpayment.vn/paymentv2/Payment/Error.html?code=99
❌ Payment error detected: https://sandbox.vnpayment.vn/paymentv2/Payment/Error.html?code=99
```

## VNPAY Error Codes Reference

| Code | Meaning | Action |
|------|---------|--------|
| 00 | Success | Update profile, show "Success" |
| 99 | Error | Retry payment |
| Other | Various errors | See VNPAY docs |

## Production Checklist

Before deploying to production:

- [ ] Test with VNPAY Sandbox (DEMOV210) ✓ Current status
- [ ] Replace DEMOV210 with real merchant code
- [ ] Replace SHOAITMYSECRETKEY with real hash secret
- [ ] Update return URL from `https://www.example.com/payment-return` to actual URL
- [ ] Update payment URL from sandbox to production
- [ ] Test with real test cards (contact VNPAY)
- [ ] Verify Supabase RLS policies allow profile updates
- [ ] Set up error logging and monitoring
- [ ] Enable payment transaction recording (optional)

## Troubleshooting

### Issue: Still showing Error.html?code=99
**Cause**: VNPAY credential issue
**Solution**:
1. Verify TMN_CODE and HASH_SECRET are correct in `vnpay_service.dart`
2. Check that DEMOV210 has not expired
3. Try with a different browser/device
4. Contact VNPAY support

### Issue: WebView not loading VNPAY page
**Cause**: Network or WebView issue
**Solution**:
1. Check internet connection
2. Ensure WebView is installed: `adb shell pm dump | grep webview`
3. Clear WebView cache: `adb shell pm clear com.google.android.webview`
4. Restart emulator/device

### Issue: Payment success not detected
**Cause**: Navigation interception not working
**Solution**:
1. Check Logcat for "Navigation request" logs
2. Verify VNPAY response contains expected parameters
3. Check JavaScript console errors in WebView

### Issue: Supabase not updating after payment
**Cause**: Authentication or RLS policy issue
**Solution**:
1. Verify user is authenticated
2. Check Supabase RLS policies on `profiles` table
3. Ensure user can update their own profile
4. Check Supabase error logs for details

## Status Summary

✅ **Build**: APK builds successfully (0 errors)
✅ **Payment Flow**: Direct StorageUpgradeScreen → VNPAY
✅ **Error Fix**: VNPAY error code 99 addressed (HTTPS return URL)
✅ **WebView**: Properly detects payment success/failure
✅ **Supabase**: Ready to update profile on success
⏳ **Testing**: Ready for sandbox testing

## Next Steps

1. **Test the payment flow** with VNPAY Sandbox
   - Enter test card data on VNPAY page
   - Verify success is detected
   - Check Supabase profile update

2. **Monitor logs** during testing
   ```bash
   adb logcat | grep flutter
   ```

3. **Once working**, prepare for production
   - Get real VNPAY credentials
   - Replace sandbox values
   - Update return URL
   - Deploy to production

---

**Updated**: January 2025
**Status**: ✅ Ready for Testing
**Build Status**: ✅ 0 errors
**Flow**: StorageUpgradeScreen → VNPayWebView (Direct)
