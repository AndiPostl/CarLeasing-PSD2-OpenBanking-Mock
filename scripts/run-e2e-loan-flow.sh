#!/usr/bin/env bash
#
# CarLeasing PSD2 ASPSP – End-to-end loan flow (curl)
# Runs against the MuleSoft mock API. Start the mock first: cd Mule_PSD2_Loan_ConsentMockAPI && mvn mule:run
#
set -e

BASE_URL="${BASE_URL:-http://localhost:8081}"
TOKEN="${TOKEN:-mock-token-carleasing}"
CONSENT_ID=""
LOAN_ACCOUNT_ID=""
REQ_ID() { echo "$(uuidgen | tr '[:upper:]' '[:lower:]')"; }

# Pretty-print JSON body (uses jq when available)
pretty_body() {
  local b="$1"
  [ -z "$b" ] && return
  if command -v jq >/dev/null 2>&1; then
    echo "$b" | jq . 2>/dev/null | sed 's/^/    /'
  else
    echo "$b" | sed 's/^/    /'
  fi
}

echo "=== CarLeasing PSD2 E2E Loan Flow ==="
echo "Base URL: $BASE_URL"
echo ""

# ------------------------------------------------------------------------------------------------
# 1. Get mock token (optional; mock accepts any Bearer)
# ------------------------------------------------------------------------------------------------

echo "------------------------------------------------------------------------------------------------"
echo "1. Get mock token"
echo "------------------------------------------------------------------------------------------------"
echo "  Request:  GET $BASE_URL/mock/token"
TOKEN_RESP=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/mock/token")
TOKEN_HTTP=$(echo "$TOKEN_RESP" | tail -n1)
TOKEN_BODY=$(echo "$TOKEN_RESP" | sed '$d')
echo "  Response: HTTP $TOKEN_HTTP"
if [ "$TOKEN_HTTP" != "200" ]; then
  echo "  Body:"
  pretty_body "$TOKEN_BODY"
  echo "  Summary:  Token request failed. Stopping."
  exit 1
fi
TOKEN=$(echo "$TOKEN_BODY" | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')
[ -n "$TOKEN" ] || TOKEN="mock-token-carleasing"
echo "  Body:"
pretty_body "$TOKEN_BODY"
echo "  Summary:  Token obtained (access_token present, length ${#TOKEN} chars)"
echo ""

# ------------------------------------------------------------------------------------------------
# 2. Create consent
# ------------------------------------------------------------------------------------------------
echo "------------------------------------------------------------------------------------------------"
echo "2. Create consent"
echo "------------------------------------------------------------------------------------------------"
echo "  Request:  POST $BASE_URL/v1/consents"
echo "  Headers:  Authorization: Bearer ***, Content-Type: application/json, X-Request-ID: <uuid>"
echo "  Body:     access.allAccounts/allPsd2, validUntil: 2026-12-31"
CREATE_RESP=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/v1/consents" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -H "X-Request-ID: $(REQ_ID)" \
  -H "PSU-IP-Address: 192.168.1.1" \
  -H "TPP-Redirect-URI: https://tpp.example/callback" \
  -d '{
    "access": {
      "availableAccounts": "allAccounts",
      "allPsd2": "allAccounts"
    },
    "recurringIndicator": false,
    "validUntil": "2026-12-31",
    "frequencyPerDay": 4
  }')
CREATE_HTTP=$(echo "$CREATE_RESP" | tail -n1)
CREATE_BODY=$(echo "$CREATE_RESP" | sed '$d')
echo "  Response: HTTP $CREATE_HTTP"
if [ "$CREATE_HTTP" != "201" ]; then
  echo "  Body:"
  pretty_body "$CREATE_BODY"
  echo "  Summary:  Create consent failed."
  exit 1
fi
CONSENT_ID=$(echo "$CREATE_BODY" | sed -n 's/.*"consentId":"\([^"]*\)".*/\1/p')
CONSENT_ID="${CONSENT_ID:-consent-test-001}"
echo "  Body:"
pretty_body "$CREATE_BODY"
echo "  Summary:  Consent created. CONSENT_ID=$CONSENT_ID"
echo ""

# ------------------------------------------------------------------------------------------------
# 3. Simulate PSU approval
# ------------------------------------------------------------------------------------------------
echo "------------------------------------------------------------------------------------------------"
echo "3. Simulate PSU approval"
echo "------------------------------------------------------------------------------------------------"
echo "  Request:  GET $BASE_URL/mock/approve?consent=$CONSENT_ID"
APPROVE_RESP=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/mock/approve?consent=$CONSENT_ID")
APPROVE_HTTP=$(echo "$APPROVE_RESP" | tail -n1)
echo "  Response: HTTP $APPROVE_HTTP"
if [ "$APPROVE_HTTP" != "200" ]; then
  echo "  Body:"
  pretty_body "$(echo "$APPROVE_RESP" | sed '$d')"
  echo "  Summary:  Simulate approval failed."
  exit 1
fi
echo "  Body:"
pretty_body "$(echo "$APPROVE_RESP" | sed '$d')"
echo "  Summary:  Consent approved (status stored for consentId=$CONSENT_ID)"
echo ""

# ------------------------------------------------------------------------------------------------
# 4. Get consent (verify status = valid)
# ------------------------------------------------------------------------------------------------
echo "------------------------------------------------------------------------------------------------"
echo "4. Get consent"
echo "------------------------------------------------------------------------------------------------"
echo "  Request:  GET $BASE_URL/v1/consents/$CONSENT_ID"
echo "  Headers:  Authorization: Bearer ***, X-Request-ID: <uuid>"
GET_CONSENT_RESP=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/v1/consents/$CONSENT_ID" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -H "X-Request-ID: $(REQ_ID)" \
  -H "PSU-IP-Address: 192.168.1.1")
GET_CONSENT_HTTP=$(echo "$GET_CONSENT_RESP" | tail -n1)
GET_CONSENT_BODY=$(echo "$GET_CONSENT_RESP" | sed '$d')
echo "  Response: HTTP $GET_CONSENT_HTTP"
if [ "$GET_CONSENT_HTTP" != "200" ]; then
  echo "  Body:"
  pretty_body "$GET_CONSENT_BODY"
  echo "  Summary:  Get consent failed."
  exit 1
fi
CONSENT_STATUS=$(echo "$GET_CONSENT_BODY" | sed -n 's/.*"consentStatus":"\([^"]*\)".*/\1/p')
echo "  Body:"
pretty_body "$GET_CONSENT_BODY"
echo "  Summary:  consentStatus=$CONSENT_STATUS, consentId in path=$CONSENT_ID"
echo ""

# ------------------------------------------------------------------------------------------------
# 5. Get loan list
# ------------------------------------------------------------------------------------------------
echo "------------------------------------------------------------------------------------------------"
echo "5. Get loan list"
echo "------------------------------------------------------------------------------------------------"
echo "  Request:  GET $BASE_URL/v1/loans"
echo "  Headers:  Authorization: Bearer ***, consentId: $CONSENT_ID, X-Request-ID: <uuid>"
LOANS_RESP=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/v1/loans" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -H "consentId: $CONSENT_ID" \
  -H "X-Request-ID: $(REQ_ID)" \
  -H "PSU-IP-Address: 192.168.1.1")
LOANS_HTTP=$(echo "$LOANS_RESP" | tail -n1)
LOANS_BODY=$(echo "$LOANS_RESP" | sed '$d')
echo "  Response: HTTP $LOANS_HTTP"
if [ "$LOANS_HTTP" != "200" ]; then
  echo "  Body:"
  pretty_body "$LOANS_BODY"
  echo "  Summary:  Get loan list failed (ensure step 3 approved consent and consentId header is sent)."
  exit 1
fi
LOAN_ACCOUNT_ID=$(echo "$LOANS_BODY" | sed -n 's/.*"resourceId":"\([^"]*\)".*/\1/p' | head -1)
[ -z "$LOAN_ACCOUNT_ID" ] && LOAN_ACCOUNT_ID="3dc3d5b3-7023-4848-9853-f5400a64e81a"
echo "  Body:"
pretty_body "$LOANS_BODY"
echo "  Summary:  Loan list OK; first loan resourceId=$LOAN_ACCOUNT_ID"
echo ""

# ------------------------------------------------------------------------------------------------
# 6. Get loan details
# ------------------------------------------------------------------------------------------------
echo "------------------------------------------------------------------------------------------------"
echo "6. Get loan details"
echo "------------------------------------------------------------------------------------------------"
echo "  Request:  GET $BASE_URL/v1/loans/$LOAN_ACCOUNT_ID"
echo "  Headers:  Authorization: Bearer ***, consentId: $CONSENT_ID"
DETAIL_RESP=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/v1/loans/$LOAN_ACCOUNT_ID" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -H "consentId: $CONSENT_ID" \
  -H "X-Request-ID: $(REQ_ID)" \
  -H "PSU-IP-Address: 192.168.1.1")
DETAIL_HTTP=$(echo "$DETAIL_RESP" | tail -n1)
DETAIL_BODY=$(echo "$DETAIL_RESP" | sed '$d')
echo "  Response: HTTP $DETAIL_HTTP"
if [ "$DETAIL_HTTP" != "200" ]; then
  echo "  Body:"
  pretty_body "$DETAIL_BODY"
  echo "  Summary:  Get loan details failed."
  exit 1
fi
echo "  Body:"
pretty_body "$DETAIL_BODY"
echo "  Summary:  Loan details OK for resourceId=$LOAN_ACCOUNT_ID"
echo ""

# ------------------------------------------------------------------------------------------------
# 7. Get loan balances
# ------------------------------------------------------------------------------------------------

echo "------------------------------------------------------------------------------------------------"
echo "7. Get loan balances"
echo "------------------------------------------------------------------------------------------------"
echo "  Request:  GET $BASE_URL/v1/loans/$LOAN_ACCOUNT_ID/balances"
echo "  Headers:  Authorization: Bearer ***, consentId: $CONSENT_ID"
BAL_RESP=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/v1/loans/$LOAN_ACCOUNT_ID/balances" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -H "consentId: $CONSENT_ID" \
  -H "X-Request-ID: $(REQ_ID)" \
  -H "PSU-IP-Address: 192.168.1.1")
BAL_HTTP=$(echo "$BAL_RESP" | tail -n1)
BAL_BODY=$(echo "$BAL_RESP" | sed '$d')
echo "  Response: HTTP $BAL_HTTP"
if [ "$BAL_HTTP" != "200" ]; then
  echo "  Body:"
  pretty_body "$BAL_BODY"
  echo "  Summary:  Get loan balances failed."
  exit 1
fi
echo "  Body:"
pretty_body "$BAL_BODY"
echo "  Summary:  Loan balances OK"
echo ""

# ------------------------------------------------------------------------------------------------
# 8. Get loan transactions
# ------------------------------------------------------------------------------------------------
echo "------------------------------------------------------------------------------------------------"
echo "8. Get loan transactions"
echo "------------------------------------------------------------------------------------------------"
echo "  Request:  GET $BASE_URL/v1/loans/$LOAN_ACCOUNT_ID/transactions?dateFrom=2020-01-01&dateTo=2025-12-31"
echo "  Headers:  Authorization: Bearer ***, consentId: $CONSENT_ID"
TX_RESP=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/v1/loans/$LOAN_ACCOUNT_ID/transactions?dateFrom=2020-01-01&dateTo=2025-12-31" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -H "consentId: $CONSENT_ID" \
  -H "X-Request-ID: $(REQ_ID)" \
  -H "PSU-IP-Address: 192.168.1.1")
TX_HTTP=$(echo "$TX_RESP" | tail -n1)
TX_BODY=$(echo "$TX_RESP" | sed '$d')
echo "  Response: HTTP $TX_HTTP"
if [ "$TX_HTTP" != "200" ]; then
  echo "  Body:"
  pretty_body "$TX_BODY"
  echo "  Summary:  Get loan transactions failed."
  exit 1
fi
echo "  Body:"
pretty_body "$TX_BODY"
echo "  Summary:  Loan transactions OK"
echo ""

# 9. Delete consent
echo "------------------------------------------------------------------------------------------------"
echo "9. Delete consent"
echo "------------------------------------------------------------------------------------------------"
echo "  Request:  DELETE $BASE_URL/v1/consents/$CONSENT_ID"
echo "  Headers:  Authorization: Bearer ***"
DEL_RESP=$(curl -s -w "\n%{http_code}" -X DELETE "$BASE_URL/v1/consents/$CONSENT_ID" \
  -H "Authorization: Bearer $TOKEN" \
  -H "X-Request-ID: $(REQ_ID)" \
  -H "PSU-IP-Address: 192.168.1.1")
DEL_HTTP=$(echo "$DEL_RESP" | tail -n1)
echo "  Response: HTTP $DEL_HTTP"
if [ "$DEL_HTTP" != "204" ]; then
  echo "  Summary:  Delete consent failed. Stopping."
  exit 1
fi
echo "  Summary:  Consent deleted successfully"
echo ""

echo "=== E2E loan flow completed successfully ==="
