# CarLeasing PSD2 ASPSP – Postman collection

Postman collection for the CarLeasing ASPSP APIs: Consents, Consent Authorisation, and Loans (Berlin Group PSD2 / extended AIS).

## Setup

1. Import **CarLeasing_PSD2_ASPSP_Test_Collection.json** into Postman.
2. Set (or keep) collection variables:
   - **baseUrl**: `http://localhost:8081` when using the MuleSoft mock; change for real API.
   - **access_token**: set automatically by **Get Mock Token** for the mock; use your OAuth2 token for real API.

## Recommended run order (steps 1–9)

Run requests in order; request names include step numbers:

1. **Get Mock Token** (Auth) – mock only; for real API use your OAuth2 flow.
2. **Create consent** (Consents) – body: `access.allPsd2`, `validUntil: 2026-12-31` (matches `run-e2e-loan-flow.sh`).
3. **Simulate approval** (Mock – Simulate PSU approval) – sets consent to valid.
4. **Get consent** (Consents) – verify status is `valid`.
5. **Get loan list** (Loans) – then
6. **Get loan details**
7. **Get loan balances**
8. **Get loan transactions**.
9. **Delete consent** (Consents) – optional.

Variables `consentId` and `loanAccountId` are set from responses. Default `loanAccountId` = `3dc3d5b3-7023-4848-9853-f5400a64e81a`. Use `dateFrom` = `2020-01-01`, `dateTo` = `2026-12-31` for transactions.

To test consent authorisation (Redirect SCA):

- After **Create consent**, run **Consent authorisation** → **Start consent authorisation**, then **Get consent authorisation status**. After **Simulate approval**, status should be `finalised`.

## MuleSoft mock

Run the mock from `../Mule_PSD2_Loan_ConsentMockAPI` (see its README). Keep **baseUrl** as `http://localhost:8081`.

## Headers

Requests use:

- **X-Request-ID**: UUID (set in pre-request script).
- **Authorization**: Bearer {{access_token}}
- **consentId**: {{consentId}} (for Loans and, if required, AIS).
- **PSU-IP-Address**: 192.168.1.1 (example).

For production you would also send **Digest**, **Signature**, and **TPP-Signature-Certificate** (QSEAL).
