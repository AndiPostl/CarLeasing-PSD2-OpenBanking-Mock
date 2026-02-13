

CarLeasing acts as an ASPSP; the car buyer is the PSU and the TPP is the car company.

The customer confirms their consent to the transfer of information to the requesting financial institution.

After the initial entry to the financial institution's website, the customer confirms that they wish to share personal information about their loans in CarLeasing.

The financial institution creates a new consent identifier (CreateConsent API) and generates a one-time link for the process. The link contains parameters unique to the consent-approval process, based on the BaseUrl of the desired environment. The financial institution redirects the customer to the link. The customer is taken to their personal area in CarLeasing, and after authentication enters the consent approval process.  
 For a **BankOffered** consent, the customer selects the loans for which they agree to share information.  
 For a **Detailed** consent, the customer preselects the loans for which they agree to share information.

The customer approves the consent details, which include, among other things, data scopes, a general description of the loans, loan balances, and payment history.

If the consent is approved, the customer receives a confirmation message and is redirected back to the financial institution's website from which they originated. The company redirects the customer via a Redirect to the URL provided by the financial institution at the beginning of the process.

---

**Retrieving information about the customer's loans:**

The financial institution invokes the required APIs according to the data scopes approved by the customer.

Support for two types of certificates: **QSEAL** (for message signing) and **QWAC** (for application authentication).

Consent registration will be handled through **MuleSoft** interfaces, while the actual consent management will be performed in the operational CarLeasing system.

It is required to expose a **Swagger** identical to the one attached (internal endpoints may change according to Mule conventions), but these represent all the services required for the activity. Regarding authentication, there may be considerations in line with Mule best practices, but it must be **OAuth2**.

---

The Swagger includes **four domains**:

* **Consents** – registration, deletion, and retrieval

* **Authentication** – OAuth2 authentication against the services

* **Loans** – four GET APIs for loan data and loan balances

* **Management APIs for consents** – it is not clear whether these are needed at all

