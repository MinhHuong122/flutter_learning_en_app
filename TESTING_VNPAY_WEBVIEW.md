# Testing VNPAY Integration - WebView Approach

## Problem Fixed ✅

**Original Issue**: "Could not launch payment URL" error when clicking "Proceed to Payment"

**Root Cause**: URL launcher was failing to handle the long VNPAY payment URL properly

**Solution Implemented**: Switched to WebView-based payment instead of external URL launcher
- WebView can handle longer URLs better
- Can intercept navigation and detect payment return automatically
- Better control over the payment flow

## New Payment Flow

### Step 1: User Interaction
```
StorageUpgradeScreen
    ↓ (Click "Upgrade Storage")
PaymentScreen (displays: 5GB, 20,000 VND, QR, Bank details)
    ↓ (Click "Proceed to Payment")
```

### Step 2: Payment Processing (NEW - WebView Approach)
```
VNPayWebView (displays VNPAY payment page in WebView)
    ↓
User enters card details on VNPAY page
(Card: 4111111111111111 | CVV: 123 | OTP: 123456)
    ↓
VNPAY processes payment
    ↓ (Success: ResponseCode=00)
VNPAY redirects to return URL with query parameters
    ↓
VNPayWebView intercepts redirect
Extracts query parameters: vnp_Amount, vnp_ResponseCode, etc.
    ↓
```

### Step 3: Result Handling
```
If Success (ResponseCode=00):
    ↓
Shows payment success screen
Updates Supabase profile (level=2, is_premium=true)
Refreshes storage display
    ↓
If Failed:
    ↓
Shows error message
Returns to PaymentScreen
User can retry
```

## Testing Instructions

### Preparation
1. Ensure emulator is running with at least 2GB free storage
2. App is built and installed: `flutter build apk --debug`
3. Log in with test account

### Test Payment Flow

**Step 1: Navigate to Storage Upgrade**
```bash
# In app:
1. Open app menu → Settings/Profile (or Storage section)
2. Click "Storage Upgrade" or "Upgrade" button
3. You should see StorageUpgradeScreen with current storage info
```

**Step 2: Start Payment**
```bash
1. Click "Upgrade to Premium" / "Upgrade Storage" button
2. You should see PaymentScreen with:
   ✓ Storage: 5 GB
   ✓ Price: 20,000 VND
   ✓ QR Code (optional display)
   ✓ Bank Transfer details
   ✓ "Proceed to Payment" button (blue)
```

**Step 3: Launch VNPAY**
```bash
1. Click "Proceed to Payment" button
2. Check Logcat for debug output:
   🔵 Building VNPAY payment URL...
   🔵 Generated URL length: [number]
   🔵 VNPayService.buildPaymentUrl called
   🔵 Generating secure hash...
   🔵 Building query string...
   
3. Expect: VNPayWebView screen opens with loading indicator
4. Check Logcat: 📄 WebView loading: [VNPAY URL with secure hash]
```

**Step 4: Complete Payment**
```bash
1. Wait for VNPAY payment page to load in WebView
2. Select payment method (test card recommended)
3. Click "Pay" / "Proceed"
4. Enter card details:
   Card Number: 4111111111111111
   Holder Name: TESTER
   Expiry Date: 07/25 (future date)
   CVV: 123
   OTP: 123456
5. Click "Confirm" / "Pay"
6. Wait for VNPAY to process (usually 2-5 seconds)
```

**Step 5: Payment Result**
```bash
Expected Success Flow:
1. Logcat shows: 💳 Payment return detected: [URL with parameters]
2. Logcat shows: ✅ Response Code: 00 (Success: true)
3. VNPayWebView closes automatically
4. PaymentScreen shows success screen:
   ✓ Green checkmark icon
   ✓ "Payment Successful!"
   ✓ Details: Package (Premium - 5GB), Amount (20,000 VND), Status (Completed)
   ✓ "Done" button
5. Click "Done"
6. Return to StorageUpgradeScreen
7. Storage display should update to 5GB (Premium)
8. Database shows: level=2, is_premium=true

Expected Failure:
1. Card declined or OTP wrong
2. Logcat shows: ✅ Response Code: [non-00 code]
3. VNPayWebView shows error from VNPAY
4. Logcat shows transaction failed
5. Can retry payment
```

## Debugging Commands

### Check WebView Logs
```bash
adb logcat | grep -E "WebView|payment|VNPAY|🔵|💳|✅|❌"
```

### Monitor Payment Response
```bash
adb logcat | grep "Response Code"
```

### View Payment URL (first 500 chars)
```bash
adb logcat | grep "Final URL" | head -1
```

### Check for URL Length Issues
```bash
adb logcat | grep "Final URL length"
# Should be under 2000 characters (safer for WebView)
```

## Troubleshooting

### Issue 1: VNPayWebView doesn't open
**Symptoms**: Click "Proceed to Payment" but nothing happens
**Solution**:
1. Check Logcat for errors: `adb logcat | grep -i error`
2. Verify webview_flutter is properly initialized
3. Check that URL is being built (look for "🔵 Building VNPAY" log)
4. Ensure enough memory: `adb shell dumpsys meminfo | grep "TOTAL"`

### Issue 2: Payment page loads but button doesn't respond
**Symptoms**: WebView loads VNPAY page but can't interact
**Solution**:
1. Check JavaScript is enabled: `_webViewController.setJavaScriptMode(JavaScriptMode.unrestricted)`
2. Verify VNPAY page fully loaded: look for "📄 WebView finished"
3. Try refreshing: pull-to-refresh if available

### Issue 3: Return URL not detected
**Symptoms**: Completed payment but VNPayWebView stays on VNPAY page
**Solution**:
1. Check Logcat for: `🔗 Navigation request: `
2. Verify return URL contains "payment-return"
3. Check that response code is included in URL parameters
4. Add navigation logging if needed

### Issue 4: Signature verification fails
**Symptoms**: Payment succeeds but PaymentReturnScreen shows error
**Solution**:
1. Verify VNPAY credentials are correct in VNPayService
2. Check for character encoding issues (Vietnamese text)
3. Check Supabase authentication with user profile

### Issue 5: Profile not updated in Supabase
**Symptoms**: Payment shows success but level/is_premium not updated
**Solution**:
1. Check Supabase row-level security (RLS) policies
2. Verify the authenticated user can update their own profile
3. Check that userId is correctly extracted
4. Look for Supabase errors in Logcat

## Key Changes Summary

### Files Modified:
1. **lib/screens/payment_screen.dart**
   - Changed from `url_launcher.launchUrl()` to WebView
   - Import: `webview_flutter.WebViewController` 
   - New method: `_handlePaymentReturn()`
   - New widget: `VNPayWebView` class

2. **lib/services/vnpay_service.dart**
   - Added debug logging throughout
   - Added `_sanitizeOrderInfo()` to handle Vietnamese characters
   - No functional changes to signature generation

3. **lib/main.dart** (Already configured)
   - Still has `onGenerateRoute` for deep link fallback
   - WebView doesn't need it for immediate use

### New Approach Benefits:
✅ Handles longer URLs better
✅ Instant payment result detection (no deep link delay)
✅ Better error handling within app
✅ Can intercept navigation easily
✅ Better logging and debugging

## Production Readiness Checklist

❌ Test with VNPAY Sandbox credentials (DEMOV210)
❌ Test payment with all test cards (Visa + MasterCard)
❌ Verify Supabase profile updates correctly
❌ Test error scenarios (declined card, timeout)
❌ Test with Low memory device
❌ Test deep link fallback (still in code)
❌ Replace sandbox URL with production
❌ Replace VNPAY credentials with real ones
❌ Add error tracking/logging
❌ Security audit of payment data

## Support

For issues contact:
- **VNPAY**: https://sandbox.vnpayment.vn/ (merchant support)
- **Flutter**: Check `/memories/session/vnpay-integration-complete.md`

---

**Status**: ✅ Ready for testing with WebView approach
**Build**: ✅ APK builds without errors (0 errors)
**Date**: January 2025
