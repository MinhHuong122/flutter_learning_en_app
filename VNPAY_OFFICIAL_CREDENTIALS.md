# VNPAY Sandbox - Official Credentials

## ✅ Terminal Configuration

| Item | Value |
|------|-------|
| **Terminal ID (TMN_CODE)** | `KDL3TTDI` |
| **Secret Key (HASH_SECRET)** | `20RPKIIIIOAKUXLZRLUIA3XBEG2B6YDP` |
| **Payment URL** | https://sandbox.vnpayment.vn/paymentv2/vpcpay.html |
| **API URL** | https://sandbox.vnpayment.vn/merchant_webapi/api/transaction |

---

## 🔐 Merchant Account

- **Portal**: https://sandbox.vnpayment.vn/merchantv2/
- **Email**: donguyenminhhuong0122@gmail.com
- **Password**: (Same as registration)

---

## 🧪 Test Case (SIT)

- **Portal**: https://sandbox.vnpayment.vn/vnpaygw-sit-testing/user/login
- **Email**: donguyenminhhuong0122@gmail.com
- **Password**: (Same as registration)

---

## 💳 Test Card

| Field | Value |
|-------|-------|
| **Bank** | NCB |
| **Card Number** | 9704198526191432198 |
| **Cardholder** | NGUYEN VAN A |
| **Issue Date** | 07/15 |
| **OTP Password** | 123456 |

---

## 📚 Documentation

- **Integration Guide**: https://sandbox.vnpayment.vn/apis/docs/thanh-toan-pay/pay.html
- **Code Demo**: https://sandbox.vnpayment.vn/apis/vnpay-demo/code-demo-tích-hợp
- **Live Demo**: https://sandbox.vnpayment.vn/apis/vnpay-demo/

---

## 📞 Support

- **Email**: support.vnpayment@vnpay.vn
- **Hotline**: 1900 55 55 77

---

## ✅ Status

- ✅ Terminal ID: Confirmed
- ✅ Secret Key: **UPDATED** (was wrong before!)
- ✅ Test Card: Ready
- ✅ Merchant Account: Active
- ⏳ IPN URL: Needs to be set in VNPAY merchant portal

---

## 🚀 Next Steps

1. **Rebuild App** with correct SECRET KEY
2. **Test Payment** with provided test card
3. **Set IPN URL** in VNPAY merchant portal (for production-like setup)
4. **Verify Hash** in logs (should match SECRET KEY now)
