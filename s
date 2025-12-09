Here is a **clean, confident, meeting-ready script** you can read verbatim during your touch-base.
It covers:

* JSON shape (exact / fuzzy match)
* UI behavior end-to-end
* Technical challenges of ASPX
* Why modernization is needed
* Why this Phase-1 AI approach is safe and minimal-impact

Use it as-is or customize wording.

---

# 🚀 **Meeting Script — AI Invoice Ingestion POC Walkthrough**

### **1. Introduction**

“Hi everyone, I want to walk you through the Proof of Concept for integrating AI-extracted invoice data into our existing Invoice.aspx page.

The goal of this POC is to demonstrate *how* AI data can flow into this very old legacy page with minimum disruption, while giving users a meaningful productivity boost in Phase 1.”

---

# **2. JSON Data Shape**

“First, I want to show the JSON data shape that the AI microservice returns after extracting an invoice.

We support two scenarios: **exact vendor match** and **fuzzy vendor match**.”

---

### **2.1 Exact Match JSON**

“In the exact-match case, the JSON contains a **single vendor candidate** with a high confidence score—for example 0.95 or higher:

```json
{
  "invoice": {
    "invoiceNumber": "INV-1001",
    "invoiceDate": "2025-01-15",
    "dueDate": "2025-02-15",
    "totalAmount": 1500.00,
    "summaryDescription": "Consulting Services"
  },
  "vendorCandidates": [
    { "vendorId": 101, "vendorName": "ABC Consulting Inc.", "score": 0.97 }
  ]
}
```

Because there is exactly one strong match, the UI **auto-selects** the vendor on page load.
The vendor field locks, just like today, and then the invoice fields are automatically filled in.”

---

### **2.2 Fuzzy Match JSON**

“In the fuzzy-match scenario, the JSON contains **multiple candidates** with different confidence levels:

```json
{
  "invoice": {
    "invoiceNumber": "INV-34782",
    "totalAmount": 2845.75
  },
  "vendorCandidates": [
    { "vendorId": 561, "vendorName": "TechNova Solutions Ltd.", "score": 0.93 },
    { "vendorId": 227, "vendorName": "TechNova Services Inc.", "score": 0.87 },
    { "vendorId": 993, "vendorName": "Tech Innovations Nova", "score": 0.74 }
  ]
}
```

In this case, instead of auto-selecting a vendor, the UI displays a **popup dialog** listing the top 5–10 suggestions.
The user selects one manually, and then the page behaves the same as a normal vendor selection.”

---

# **3. UI Behavior Flow**

“Here’s the full user flow with AI enabled:

1. **User selects a document** from ‘To Enter Invoice’.
2. Invoice.aspx loads and checks whether AI JSON exists.
3. If **one strong vendor** → vendor is auto-selected.
4. If **multiple candidates** → popup shows suggestions.
5. Once a vendor is selected and validated, AI pre-fills fields like invoice number, dates, amounts, and description.
6. AI-filled fields are **highlighted** in yellow so users know what came from AI.
7. If the user edits any field, the highlight disappears.
8. Even if the page **postbacks**, we restore all AI-filled values to avoid losing user context.”

---

# **4. Challenges in ASPX (and why this is tricky)**

“I also want to highlight some of the technical challenges we had to work around.

The Invoice.aspx page is:

✔ 20+ years old technology
✔ 5,000+ lines of markup
✔ 7,000+ lines of C# code-behind
✔ Intermixed business logic, UI logic, and event handling
✔ Highly fragile — even small changes break random flows
✔ Dependent on full page postbacks (not modern AJAX or SPA behavior)
✔ State is scattered across:

* ViewState
* Hidden fields
* Server-side validation
* Client-side jQuery
* Predictive search callbacks
* Button click postbacks

ASPX also has extremely dated patterns:

* Poor separation of concerns
* No componentization
* No reactive UI
* Hard to debug lifecycle events
* Heavy reliance on postbacks, which wipe JavaScript state unless carefully managed
* UI behavior split between JS, server events, and hidden fields

Because of all this, introducing AI into this page requires a **very defensive approach**—we can’t rewrite anything major, and we can’t break existing flows.”

---

# **5. How the POC safely integrates into this legacy environment**

“To avoid destabilizing the Invoice page, the POC follows these principles:

### ✔ Zero disruption to current workflow

Users still follow the exact same flow:
select vendor → fill fields → submit.

### ✔ Vendor remains the gatekeeper

We don’t bypass or modify any of the vendor validation logic.

### ✔ AI logic is additive, not invasive

Everything is injected through:

* Hidden fields
* `$(document).ready()`
* PreRender event
* Minimal JS hook-in to `OnVendorSelected`

### ✔ Postback-safe

We snapshot AI values into hidden fields and restore them from server-side `Page_PreRender` so nothing is lost.

### ✔ Field-level highlighting

Users clearly see which fields were filled by AI.

### ✔ Full fallback

If JSON is missing or AI fails, the page works **exactly as today**.”

---

# **6. Closing**

“The purpose of today’s demo is to show that despite the age and fragility of Invoice.aspx, we can still introduce AI-assisted data entry safely, predictably, and with minimal changes to existing behavior.

This POC shows the full end-to-end flow and lets us evaluate what Phase 1 should include and how we can scale this in future releases.”

---

If you'd like, I can also prepare:

✔ A short **PowerPoint-style outline**
✔ A **one-slide summary** for leadership
✔ A **risk & mitigation** slide
✔ A **future roadmap** slide (Phase 2, Phase 3)

Just tell me what you need!
