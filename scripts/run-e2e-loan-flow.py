#!/usr/bin/env python3
"""
CarLeasing PSD2 ASPSP – End-to-end loan flow (Python)
Runs against the MuleSoft mock API. Start the mock first: cd Mule_PSD2_Loan_ConsentMockAPI && mvn mule:run

Same steps and request/response handling as run-e2e-loan-flow.sh.
Usage:
  python run-e2e-loan-flow.py
  BASE_URL=http://localhost:8081 python run-e2e-loan-flow.py
"""

import json
import os
import sys
import uuid
from urllib.request import Request, urlopen
from urllib.error import HTTPError, URLError


BASE_URL = os.environ.get("BASE_URL", "http://localhost:8081")
DEFAULT_TOKEN = "mock-token-carleasing"


def req_id():
    return str(uuid.uuid4()).lower()


def pretty_body(body: str) -> str:
    """Pretty-print JSON body."""
    if not body or not body.strip():
        return "    (empty)"
    try:
        parsed = json.loads(body)
        return "    " + json.dumps(parsed, indent=2).replace("\n", "\n    ")
    except (json.JSONDecodeError, TypeError):
        return "    " + body.replace("\n", "\n    ")


def request(method: str, url: str, headers: dict = None, data: str = None) -> tuple[int, str]:
    """Perform HTTP request; return (status_code, body)."""
    req = Request(url, data=data.encode() if data else None, method=method)
    if headers:
        for k, v in headers.items():
            req.add_header(k, v)
    try:
        with urlopen(req, timeout=30) as resp:
            body = resp.read().decode()
            return resp.status, body
    except HTTPError as e:
        body = e.read().decode() if e.fp else ""
        return e.code, body
    except URLError as e:
        print(f"  Error: {e.reason}")
        sys.exit(1)


def psd2_headers(token: str, consent_id: str = None) -> dict:
    h = {
        "Accept": "application/json",
        "Authorization": f"Bearer {token}",
        "X-Request-ID": req_id(),
        "PSU-IP-Address": "192.168.1.1",
    }
    if consent_id:
        h["consentId"] = consent_id
    return h


def main():
    token = os.environ.get("TOKEN", DEFAULT_TOKEN)
    consent_id = ""
    loan_account_id = ""

    print("=== CarLeasing PSD2 E2E Loan Flow ===")
    print(f"Base URL: {BASE_URL}")
    print()

    # -------------------------------------------------------------------------
    # 1. Get mock token
    # -------------------------------------------------------------------------
    print("-" * 100)
    print("1. Get mock token")
    print("-" * 100)
    print(f"  Request:  GET {BASE_URL}/mock/token")
    status, body = request("GET", f"{BASE_URL}/mock/token")
    print(f"  Response: HTTP {status}")
    if status != 200:
        print("  Body:")
        print(pretty_body(body))
        print("  Summary:  Token request failed. Stopping.")
        sys.exit(1)
    try:
        data = json.loads(body)
        token = data.get("access_token", token) or DEFAULT_TOKEN
    except (json.JSONDecodeError, TypeError):
        pass
    print("  Body:")
    print(pretty_body(body))
    print(f"  Summary:  Token obtained (access_token present, length {len(token)} chars)")
    print()

    # -------------------------------------------------------------------------
    # 2. Create consent
    # -------------------------------------------------------------------------
    print("-" * 100)
    print("2. Create consent")
    print("-" * 100)
    print(f"  Request:  POST {BASE_URL}/v1/consents")
    print("  Headers:  Authorization: Bearer ***, Content-Type: application/json, X-Request-ID: <uuid>")
    print("  Body:     access.allAccounts/allPsd2, validUntil: 2026-12-31")
    create_body = json.dumps({
        "access": {"availableAccounts": "allAccounts", "allPsd2": "allAccounts"},
        "recurringIndicator": False,
        "validUntil": "2026-12-31",
        "frequencyPerDay": 4,
    })
    headers = psd2_headers(token)
    headers["Content-Type"] = "application/json"
    headers["TPP-Redirect-URI"] = "https://tpp.example/callback"
    status, body = request("POST", f"{BASE_URL}/v1/consents", headers=headers, data=create_body)
    print(f"  Response: HTTP {status}")
    if status != 201:
        print("  Body:")
        print(pretty_body(body))
        print("  Summary:  Create consent failed.")
        sys.exit(1)
    try:
        data = json.loads(body)
        consent_id = data.get("consentId", "consent-test-001")
    except (json.JSONDecodeError, TypeError):
        consent_id = "consent-test-001"
    print("  Body:")
    print(pretty_body(body))
    print(f"  Summary:  Consent created. CONSENT_ID={consent_id}")
    print()

    # -------------------------------------------------------------------------
    # 3. Simulate PSU approval
    # -------------------------------------------------------------------------
    print("-" * 100)
    print("3. Simulate PSU approval")
    print("-" * 100)
    print(f"  Request:  GET {BASE_URL}/mock/approve?consent={consent_id}")
    status, body = request("GET", f"{BASE_URL}/mock/approve?consent={consent_id}")
    print(f"  Response: HTTP {status}")
    if status != 200:
        print("  Body:")
        print(pretty_body(body))
        print("  Summary:  Simulate approval failed.")
        sys.exit(1)
    print("  Body:")
    print(pretty_body(body))
    print(f"  Summary:  Consent approved (status stored for consentId={consent_id})")
    print()

    # -------------------------------------------------------------------------
    # 4. Get consent
    # -------------------------------------------------------------------------
    print("-" * 100)
    print("4. Get consent")
    print("-" * 100)
    print(f"  Request:  GET {BASE_URL}/v1/consents/{consent_id}")
    print("  Headers:  Authorization: Bearer ***, X-Request-ID: <uuid>")
    status, body = request("GET", f"{BASE_URL}/v1/consents/{consent_id}", headers=psd2_headers(token))
    print(f"  Response: HTTP {status}")
    if status != 200:
        print("  Body:")
        print(pretty_body(body))
        print("  Summary:  Get consent failed.")
        sys.exit(1)
    consent_status = ""
    try:
        data = json.loads(body)
        consent_status = data.get("consentStatus", "")
    except (json.JSONDecodeError, TypeError):
        pass
    print("  Body:")
    print(pretty_body(body))
    print(f"  Summary:  consentStatus={consent_status}, consentId in path={consent_id}")
    print()

    # -------------------------------------------------------------------------
    # 5. Get loan list
    # -------------------------------------------------------------------------
    print("-" * 100)
    print("5. Get loan list")
    print("-" * 100)
    print(f"  Request:  GET {BASE_URL}/v1/loans")
    print(f"  Headers:  Authorization: Bearer ***, consentId: {consent_id}, X-Request-ID: <uuid>")
    status, body = request("GET", f"{BASE_URL}/v1/loans", headers=psd2_headers(token, consent_id))
    print(f"  Response: HTTP {status}")
    if status != 200:
        print("  Body:")
        print(pretty_body(body))
        print("  Summary:  Get loan list failed (ensure step 3 approved consent and consentId header is sent).")
        sys.exit(1)
    try:
        data = json.loads(body)
        accounts = data.get("loanAccounts") or []
        loan_account_id = accounts[0].get("resourceId", "") if accounts else ""
    except (json.JSONDecodeError, TypeError, KeyError, IndexError):
        loan_account_id = ""
    if not loan_account_id:
        loan_account_id = "3dc3d5b3-7023-4848-9853-f5400a64e81a"
    print("  Body:")
    print(pretty_body(body))
    print(f"  Summary:  Loan list OK; first loan resourceId={loan_account_id}")
    print()

    # -------------------------------------------------------------------------
    # 6. Get loan details
    # -------------------------------------------------------------------------
    print("-" * 100)
    print("6. Get loan details")
    print("-" * 100)
    print(f"  Request:  GET {BASE_URL}/v1/loans/{loan_account_id}")
    print(f"  Headers:  Authorization: Bearer ***, consentId: {consent_id}")
    status, body = request("GET", f"{BASE_URL}/v1/loans/{loan_account_id}", headers=psd2_headers(token, consent_id))
    print(f"  Response: HTTP {status}")
    if status != 200:
        print("  Body:")
        print(pretty_body(body))
        print("  Summary:  Get loan details failed.")
        sys.exit(1)
    print("  Body:")
    print(pretty_body(body))
    print(f"  Summary:  Loan details OK for resourceId={loan_account_id}")
    print()

    # -------------------------------------------------------------------------
    # 7. Get loan balances
    # -------------------------------------------------------------------------
    print("-" * 100)
    print("7. Get loan balances")
    print("-" * 100)
    print(f"  Request:  GET {BASE_URL}/v1/loans/{loan_account_id}/balances")
    print(f"  Headers:  Authorization: Bearer ***, consentId: {consent_id}")
    status, body = request("GET", f"{BASE_URL}/v1/loans/{loan_account_id}/balances", headers=psd2_headers(token, consent_id))
    print(f"  Response: HTTP {status}")
    if status != 200:
        print("  Body:")
        print(pretty_body(body))
        print("  Summary:  Get loan balances failed.")
        sys.exit(1)
    print("  Body:")
    print(pretty_body(body))
    print("  Summary:  Loan balances OK")
    print()

    # -------------------------------------------------------------------------
    # 8. Get loan transactions
    # -------------------------------------------------------------------------
    print("-" * 100)
    print("8. Get loan transactions")
    print("-" * 100)
    tx_url = f"{BASE_URL}/v1/loans/{loan_account_id}/transactions?dateFrom=2020-01-01&dateTo=2025-12-31"
    print(f"  Request:  GET {tx_url}")
    print(f"  Headers:  Authorization: Bearer ***, consentId: {consent_id}")
    status, body = request("GET", tx_url, headers=psd2_headers(token, consent_id))
    print(f"  Response: HTTP {status}")
    if status != 200:
        print("  Body:")
        print(pretty_body(body))
        print("  Summary:  Get loan transactions failed.")
        sys.exit(1)
    print("  Body:")
    print(pretty_body(body))
    print("  Summary:  Loan transactions OK")
    print()

    # -------------------------------------------------------------------------
    # 9. Delete consent
    # -------------------------------------------------------------------------
    print("-" * 100)
    print("9. Delete consent")
    print("-" * 100)
    print(f"  Request:  DELETE {BASE_URL}/v1/consents/{consent_id}")
    print("  Headers:  Authorization: Bearer ***")
    headers = psd2_headers(token)
    status, _ = request("DELETE", f"{BASE_URL}/v1/consents/{consent_id}", headers=headers)
    print(f"  Response: HTTP {status}")
    if status != 204:
        print("  Summary:  Delete consent failed. Stopping.")
        sys.exit(1)
    print("  Summary:  Consent deleted successfully")
    print()

    print("=== E2E loan flow completed successfully ===")


if __name__ == "__main__":
    main()
