# VNPAY Sandbox Test Cards

## Demo Environment
- **Demo Link**: http://sandbox.vnpayment.vn/tryitnow/Home/CreateOrder
- **Payment Gateway**: https://sandbox.vnpayment.vn/paymentv2/vpcpay.html
- **Environment**: Test/Sandbox Only

---

## Domestic Bank Cards (NCB ATM)

### Card #1: Successful Payment ✅
| Field | Value |
|-------|-------|
| Bank | NCB |
| Card Number | 9704198526191432198 |
| Card Holder | NGUYEN VAN A |
| Issue Date | 07/15 |
| OTP | 123456 |
| Status | **Thành công (Successful)** |

### Card #2: Insufficient Balance ❌
| Field | Value |
|-------|-------|
| Bank | NCB |
| Card Number | 9704195798459170488 |
| Card Holder | NGUYEN VAN A |
| Issue Date | 07/15 |
| Status | **Thẻ không đủ số dư (Insufficient balance)** |

### Card #3: Not Activated ❌
| Field | Value |
|-------|-------|
| Bank | NCB |
| Card Number | 9704192181368742 |
| Card Holder | NGUYEN VAN A |
| Issue Date | 07/15 |
| Status | **Thẻ chưa kích hoạt (Card not activated)** |

### Card #4: Locked Card ❌
| Field | Value |
|-------|-------|
| Bank | NCB |
| Card Number | 9704193370791314 |
| Card Holder | NGUYEN VAN A |
| Issue Date | 07/15 |
| Status | **Thẻ bị khóa (Card locked)** |

### Card #5: Expired Card ❌
| Field | Value |
|-------|-------|
| Bank | NCB |
| Card Number | 9704194841945513 |
| Card Holder | NGUYEN VAN A |
| Issue Date | 07/15 |
| Status | **Thẻ bị hết hạn (Card expired)** |

### Card #6: Domestic ATM - NAPAS Network
| Field | Value |
|-------|-------|
| Type | Domestic ATM via NAPAS |
| Card Numbers | 9704000000000018 / 9704020000000016 |
| Card Holder | NGUYEN VAN A |
| Issue Date | 03/07 |
| OTP | otp |
| Status | **Thành công (Successful)** |

### Card #7: Domestic ATM - EXIMBANK
| Field | Value |
|-------|-------|
| Type | Domestic ATM - EXIMBANK |
| Card Number | 9704310005819191 |
| Card Holder | NGUYEN VAN A |
| Expiry Date | 10/26 |
| Status | **Thành công (Successful)** |

---

## International Cards (VISA, MasterCard, JCB)

### Card #6: VISA No 3DS ✅
| Field | Value |
|-------|-------|
| Type | VISA (No 3DS) |
| Card Number | 4456530000001005 |
| CVC/CVV | 123 |
| Card Holder | NGUYEN VAN A |
| Expiry Date | 12/26 |
| Email | test@gmail.com |
| Address | 22 Lang Ha, Ha Noi |
| Status | **Thành công (Successful)** |

### Card #7: VISA 3DS ✅
| Field | Value |
|-------|-------|
| Type | VISA (3DS) |
| Card Number | 4456530000001096 |
| CVC/CVV | 123 |
| Card Holder | NGUYEN VAN A |
| Expiry Date | 12/26 |
| Email | test@gmail.com |
| Address | 22 Lang Ha, Ha Noi |
| Status | **Thành công (Successful)** |

### Card #8: MasterCard No 3DS ✅
| Field | Value |
|-------|-------|
| Type | MasterCard (No 3DS) |
| Card Number | 5200000000001005 |
| CVC/CVV | 123 |
| Card Holder | NGUYEN VAN A |
| Expiry Date | 12/26 |
| Email | test@gmail.com |
| Address | 22 Lang Ha, Ha Noi |
| Status | **Thành công (Successful)** |

### Card #9: MasterCard 3DS ✅
| Field | Value |
|-------|-------|
| Type | MasterCard (3DS) |
| Card Number | 5200000000001096 |
| CVC/CVV | 123 |
| Card Holder | NGUYEN VAN A |
| Expiry Date | 12/26 |
| Email | test@gmail.com |
| Address | 22 Lang Ha, Ha Noi |
| Status | **Thành công (Successful)** |

### Card #10: JCB No 3DS ✅
| Field | Value |
|-------|-------|
| Type | JCB (No 3DS) |
| Card Number | 3337000000000008 |
| CVC/CVV | 123 |
| Card Holder | NGUYEN VAN A |
| Expiry Date | 12/26 |
| Email | test@gmail.com |
| Address | 22 Lang Ha, Ha Noi |
| Status | **Thành công (Successful)** |

### Card #11: JCB 3DS ✅
| Field | Value |
|-------|-------|
| Type | JCB (3DS) |
| Card Number | 3337000000200004 |
| CVC/CVV | 123 |
| Card Holder | NGUYEN VAN A |
| Expiry Date | 12/24 |
| Email | test@gmail.com |
| Address | 22 Lang Ha, Ha Noi |
| Status | **Thành công (Successful)** |

---

## Important Notes

⚠️ **Test Environment Only**
- These test cards are **ONLY valid in the VNPAY sandbox environment**
- They cannot be used in production
- Only use these cards for development and testing purposes

📋 **Ghi chú (Notes)**
- In test/sandbox environment, only test card information from above list can be used
- Other banks already integrated for a long time, so their test environments are temporarily closed

🔑 **Required Credentials**
Before testing in the app, you must:
1. Register at https://sandbox.vnpayment.vn/
2. Get real **TMN_CODE** (Merchant Code) from VNPAY dashboard
3. Get **HASH_SECRET** (Hash Secret) from VNPAY dashboard
4. Update credentials in `lib/services/vnpay_service.dart`:
   ```dart
   static const String TMN_CODE = 'YOUR_REAL_TMN_CODE';
   static const String HASH_SECRET = 'YOUR_REAL_HASH_SECRET';
   ```

🧪 **Testing Flow**
1. Build APK: `flutter build apk --debug`
2. Run app on device/emulator
3. Navigate to "Storage Upgrade" screen
4. Tap "Proceed to Payment"
5. WebView opens with VNPAY payment form
6. Use test card from above list
7. Payment processes and returns result to app

✅ **Success Indicators**
- Payment amount: 20,000 VND (displayed as 2,000,000 internally)
- Success response: `vnp_ResponseCode = 00`
- Profile updates: `level = 2`, `is_premium = true` in Supabase
- Banner shows: "👑 Premium Member"

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Error Code 99 (Merchant validation failed) | Check TMN_CODE and HASH_SECRET are correct real credentials |
| WebView blank page | Verify internet connection and VNPAY sandbox is accessible |
| Return URL error | Confirm return URL uses HTTPS: `https://www.example.com/payment-return` |
| Payment stuck | Check WebView navigation logs and timeout handling |

---

**Last Updated**: April 2026
**Source**: https://sandbox.vnpayment.vn/
