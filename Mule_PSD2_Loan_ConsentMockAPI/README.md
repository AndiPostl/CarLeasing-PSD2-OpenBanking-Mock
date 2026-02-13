# Mule PSD2 Loan Consent Mock API (CarLeasing)

Mock Mule 4 API for testing the CarLeasing PSD2 flow: Consents (AIS), Consent Authorisation, and Loans (Savings and Loans). Project folder: **Mule_PSD2_Loan_ConsentMockAPI**. Config: `src/main/mule/psd2-loan-consent-mock-api.xml`. Use with the Postman collection in `../postman/` or the e2e scripts in `../scripts/` (bash or Python).

## Prerequisites

- Maven 3.6+
- **Java 17**
- Mule 4.10.x runtime (see `app.runtime` in `pom.xml`)

## Run the mock

From the repo root:

```bash
cd Mule_PSD2_Loan_ConsentMockAPI
mvn clean package
mvn mule:run
```

The API listens on **http://localhost:8081**.

## Flow names and PSD2 APIs

Each flow name ends with the PSD2 API it implements:

| Step | Flow name | API |
|------|-----------|-----|
| 1 | `1-mock-token-Non-PSD2-PAMA-Mock` | CarLeasing Mock (not in Berlin Group spec) |
| 2 | `2-create-consent-PSD2-Account-Information-Service-AIS` | Account Information Service (AIS) |
| 2a | `2a-start-consent-authorisation-PSD2-Account-Information-Service-AIS` | AIS |
| 2b | `2b-get-consent-authorisation-PSD2-Account-Information-Service-AIS` | AIS |
| 3 | `3-mock-approve-Non-PSD2-PAMA-Mock` | CarLeasing Mock |
| 4 | `4-get-consent-PSD2-Account-Information-Service-AIS` | AIS |
| 5 | `5-get-loan-list-PSD2-Savings-And-Loans` | Savings and Loans Extended API |
| 6 | `6-get-loan-details-PSD2-Savings-And-Loans` | Savings and Loans |
| 7 | `7-get-loan-balances-PSD2-Savings-And-Loans` | Savings and Loans |
| 8 | `8-get-loan-transactions-PSD2-Savings-And-Loans` | Savings and Loans |
| 9 | `9-delete-consent-PSD2-Account-Information-Service-AIS` | AIS |

## Test sequence (steps 1–9)

Run in this order (matches Postman collection and `run-e2e-loan-flow.sh` / `run-e2e-loan-flow.py`):

1. **Get mock token** – GET `/mock/token` (optional; mock accepts any Bearer token).
2. **Create consent** – POST `/v1/consents` (saves `consentId` = `consent-test-001`).
3. **Simulate PSU approval** – GET `/mock/approve?consent={consentId}` (marks consent as valid).
4. **Get consent** – GET `/v1/consents/{consentId}` (verify `consentStatus: valid`).
5. **Get loan list** – GET `/v1/loans` (header `consentId` required).
6. **Get loan details** – GET `/v1/loans/{loanAccountId}`.
7. **Get loan balances** – GET `/v1/loans/{loanAccountId}/balances`.
8. **Get loan transactions** – GET `/v1/loans/{loanAccountId}/transactions?dateFrom=...&dateTo=...`.
9. **Delete consent** – DELETE `/v1/consents/{consentId}` (optional).

## Postman collection

1. Import **postman/CarLeasing_PSD2_ASPSP_Test_Collection.json**.
2. Set **baseUrl** to `http://localhost:8081` (default).
3. Run requests in step order (1 → 9). Request names include step numbers.

Collection variables (set by the collection or e2e script): `baseUrl`, `access_token`, `consentId`, `authorisationId`, `loanAccountId`, `dateFrom`, `dateTo`.

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | /mock/token | Returns a placeholder token (mock only). |
| GET | /mock/approve?consent={consentId} | Sets consent status to `valid`. |
| POST | /v1/consents | Creates consent; returns `consent-test-001` and `scaRedirect` link. |
| GET | /v1/consents/{consentId} | Returns consent status (`received` or `valid`). |
| DELETE | /v1/consents/{consentId} | Removes consent. |
| POST | /v1/consents/{consentId}/authorisations | Starts SCA; returns `auth-mock-001`. |
| GET | /v1/consents/{consentId}/authorisations/{authorisationId} | Returns SCA status. |
| GET | /v1/loans | Loan list (200 only if consent is valid; otherwise 403). |
| GET | /v1/loans/{loanAccountId} | Loan details. |
| GET | /v1/loans/{loanAccountId}/balances | Loan balances. |
| GET | /v1/loans/{loanAccountId}/transactions | Loan transactions. |

## E2E scripts (bash / Python)

From the repo root:

```bash
./scripts/run-e2e-loan-flow.sh
# or
python scripts/run-e2e-loan-flow.py
```

Uses `BASE_URL=http://localhost:8081` by default. See `../scripts/README.md`. Request bodies and headers match the Postman collection (e.g. Create consent body with `access.allPsd2`, `validUntil: 2026-12-31`).

## Test data (loans)

- Mock loan data represents **VW Group car loans** (e.g. ID.4 Finance, Golf Finance) with current dates.
- First loan `resourceId`: `3dc3d5b3-7023-4848-9853-f5400a64e81a` (use for steps 6–8 if not taken from step 5 response).
- Transactions request: use `dateFrom=2020-01-01` and `dateTo=2026-12-31` (or as in e2e script).

## Notes

- Consent status is stored in memory (object store). Restarting the app resets it.
- For **GET /v1/loans**, send header `consentId: consent-test-001` (or the ID from Create consent). Call **Simulate approval** (step 3) first so the consent is valid.
