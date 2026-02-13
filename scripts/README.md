# CarLeasing PSD2 – Scripts

**RAML API specs** for the E2E flow are in [`../api-spec/`](../api-spec/) (PSD2 Loan, PSD2 Consent, Non-PSD2).

## run-e2e-loan-flow.sh / run-e2e-loan-flow.py

Both scripts run the same full end-to-end loan flow against the MuleSoft mock API (bash uses curl, Python uses `urllib`).

**Prerequisites**

- Mock API running: `cd Mule_PSD2_Loan_ConsentMockAPI && mvn mule:run` (listens on http://localhost:8081)
- **Bash:** `curl` and `uuidgen` (macOS/Linux)
- **Python:** Python 3.6+ (no extra packages; uses standard library only)

**Usage**

```bash
# Bash – default: http://localhost:8081
./run-e2e-loan-flow.sh

# Python
python run-e2e-loan-flow.py
# or
./run-e2e-loan-flow.py

# Custom base URL (either script)
BASE_URL=http://localhost:8081 ./run-e2e-loan-flow.sh
BASE_URL=http://localhost:8081 python run-e2e-loan-flow.py
```

**Steps executed (same for both)**

1. Get mock token
2. Create consent (POST /v1/consents) with sample body
3. Simulate PSU approval (GET /mock/approve?consent=...)
4. Get consent (GET /v1/consents/{id}) – verify valid
5. Get loan list (GET /v1/loans)
6. Get loan details (GET /v1/loans/{id})
7. Get loan balances (GET /v1/loans/{id}/balances)
8. Get loan transactions (GET /v1/loans/{id}/transactions)
9. Delete consent (DELETE /v1/consents/{id})

Either script exits with code 1 if any step fails.
