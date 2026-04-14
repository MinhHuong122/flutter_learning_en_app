#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
VNPAY Hash Verification Script
Dùng để kiểm tra xem hash được tính đúng không
"""

import hmac
import hashlib
from collections import OrderedDict

# ==================== CẤU HÌNH ====================
TMN_CODE = '38EZDSNQ'  # NEW SANDBOX ACCOUNT
HASH_SECRET = 'V78TIVHC8GTX7XCZN9Z5MO20G5Y6V44U'  # NEW - Official from VNPAY email (19:40)

# Ví dụ tham số từ app của bạn
# Thay đổi giá trị này theo logs từ app
request_data = {
    'vnp_Version': '2.1.0',
    'vnp_Command': 'pay',
    'vnp_TmnCode': TMN_CODE,
    'vnp_Amount': '2000000',          # 20000 * 100
    'vnp_CurrCode': 'VND',
    'vnp_TxnRef': 'ORDER_1776168183776',  # Thay bằng ORDER_ID thực tế
    'vnp_OrderInfo': 'StorageUpgrade5GB',
    'vnp_OrderType': 'other',
    'vnp_Locale': 'vn',
    'vnp_ReturnUrl': 'https://www.example.com/payment-return',
    'vnp_CreateDate': '20260414190303',   # Thay bằng thời gian thực tế
    'vnp_ExpireDate': '20260414191803',   # Thay bằng thời gian thực tế
    'vnp_IpAddr': '127.0.0.1',
}

# ==================== TÍNH HASH ====================
def calculate_vnpay_hash(data, secret):
    """
    Tính hash VNPAY theo đúng chuẩn VNPAY
    
    Bước 1: Sort tham số theo alphabet
    Bước 2: Build chuỗi: key1=value1&key2=value2&...
    Bước 3: HMAC SHA512 với secret
    """
    
    # Sắp xếp theo key alphabet
    sorted_keys = sorted(data.keys())
    
    # Build hash input
    hash_input = '&'.join([f'{key}={data[key]}' for key in sorted_keys])
    
    # HMAC SHA512
    signature = hmac.new(
        secret.encode('utf-8'),
        hash_input.encode('utf-8'),
        hashlib.sha512
    ).hexdigest()
    
    return hash_input, signature

# ==================== MAIN ====================
if __name__ == '__main__':
    print("=" * 80)
    print("VNPAY Hash Verification Script")
    print("=" * 80)
    
    print("\n📋 Configuration:")
    print(f"  TMN_CODE: {TMN_CODE}")
    print(f"  HASH_SECRET: {HASH_SECRET}")
    print(f"  HASH_SECRET Length: {len(HASH_SECRET)}")
    
    print("\n📝 Input Parameters:")
    for key in sorted(request_data.keys()):
        print(f"  {key}: {request_data[key]}")
    
    # Calculate hash
    hash_input, signature = calculate_vnpay_hash(request_data, HASH_SECRET)
    
    print("\n🔑 Hash Calculation:")
    print(f"  Hash Input: {hash_input}")
    print(f"  Generated Hash: {signature}")
    print(f"  Hash Length: {len(signature)}")
    
    # Build full URL
    vnpay_url = 'https://sandbox.vnpayment.vn/paymentv2/vpcpay.html?'
    params = []
    for key in sorted(request_data.keys()):
        params.append(f'{key}={request_data[key]}')
    params.append(f'vnp_SecureHash={signature}')
    
    full_url = vnpay_url + '&'.join(params)
    
    print(f"\n🌐 Full Payment URL (first 200 chars):")
    print(f"  {full_url[:200]}...")
    print(f"\n🌐 Full URL Length: {len(full_url)}")
    
    # Test VNPAY Logo check
    print("\n✅ Verification Tips:")
    print("  1. Copy hash từ logs app: 🔑 Generated Hash (SHA512): ...")
    print("  2. So sánh với output dưới đây")
    print(f"  3. Nếu khác -> HASH_SECRET/parameters sai")
    print(f"  4. Nếu giống -> tham số hoặc cách gửi sai")
    
    print("\n" + "=" * 80)
