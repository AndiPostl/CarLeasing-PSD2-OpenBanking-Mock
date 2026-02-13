# CarLeasing API specs (RAML 1.0)

RAML 1.0 API specifications for the CarLeasing PSD2 ASPSP. Based on `scripts/run-e2e-loan-flow.sh` and the Postman collection.

| File | Description |
|------|-------------|
| **car-leasing-psd2-loan-api.raml** | PSD2 Loan API – list loans, loan details, balances, transactions. Sample data from e2e script (VW Group car loans, resourceIds, dateFrom/dateTo). |
| **car-leasing-psd2-consent-api.raml** | PSD2 Consent API (AIS) – create consent, get consent, delete consent. Request/response examples match the script. |
| **car-leasing-non-psd2-api.raml** | Non-PSD2 mock API – GET /mock/token, GET /mock/approve. Used before calling PSD2 Consent and Loan APIs. |

Base URI in all specs: `http://localhost:8081` (Mule mock default).
