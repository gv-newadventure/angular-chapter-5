Here are **clean, realistic, production-style sample JSON payloads** you can use for mocking and testing your Invoice.ASPX page integration.

I will give you:

1. **Simple JSON** (minimal fields)
2. **Full realistic JSON** (with line items, fuzzy vendor matches, confidence scores)
3. **Multiple-vendor scenario**
4. **Single-perfect-match scenario**
5. **Edge-case JSON** (low-confidence, missing dates, partial data)

These match **exactly** the structure your JavaScript expects.

---

# ✅ **1. Minimal JSON (simple mock, easiest for UI testing)**

```json
{
  "documentId": "b8f4c7af-0a2b-4a84-a94f-5c26a0dc1123",
  "documentType": "Invoice",
  "extractedAtUtc": "2025-01-20T14:05:22Z",
  "provider": "Azure",
  "modelVersion": "2025-01",
  "overallConfidence": 0.88,
  "invoice": {
    "invoiceNumber": "INV-1001",
    "invoiceDate": "2025-01-15",
    "dueDate": "2025-02-15",
    "currency": "USD",
    "totalAmount": 1500.00,
    "taxAmount": 120.00,
    "summaryDescription": "Consulting Services"
  },
  "vendorCandidates": [
    {
      "vendorId": 101,
      "vendorName": "ABC Consulting Inc.",
      "score": 0.96,
      "matchType": "ExactName"
    }
  ]
}
```

This will trigger **auto vendor selection** because score ≥ 0.95.

---

# ✅ **2. Full Realistic JSON (use this for most testing)**

```json
{
  "documentId": "11100022-3344-5566-7788-99aabbccddeeff",
  "documentType": "Invoice",
  "extractedAtUtc": "2025-01-21T10:11:55Z",
  "provider": "AzureAI",
  "modelVersion": "2025-01-V2",
  "overallConfidence": 0.92,

  "invoice": {
    "invoiceNumber": "INV-34782",
    "invoiceDate": "2025-01-10",
    "dueDate": "2025-02-10",
    "currency": "CAD",
    "totalAmount": 2845.75,
    "taxAmount": 245.75,
    "summaryDescription": "Software Development Services for January 2025",

    "lineItems": [
      {
        "lineNumber": 1,
        "description": "Development sprint work (Jan 1 - Jan 15)",
        "quantity": 40,
        "unitPrice": 50.00,
        "lineTotal": 2000.00
      },
      {
        "lineNumber": 2,
        "description": "Code Review & QA",
        "quantity": 10,
        "unitPrice": 40.00,
        "lineTotal": 400.00
      },
      {
        "lineNumber": 3,
        "description": "Project Management",
        "quantity": 8,
        "unitPrice": 55.00,
        "lineTotal": 445.00
      }
    ]
  },

  "vendorCandidates": [
    {
      "vendorId": 561,
      "vendorName": "TechNova Solutions Ltd.",
      "score": 0.93,
      "matchType": "FuzzyName"
    },
    {
      "vendorId": 227,
      "vendorName": "TechNova Services Inc.",
      "score": 0.87,
      "matchType": "FuzzyName"
    },
    {
      "vendorId": 993,
      "vendorName": "Tech Innovations Nova",
      "score": 0.74,
      "matchType": "PartialMatch"
    }
  ]
}
```

This JSON will trigger the **vendor selection popup** (multiple candidates).

---

# ✅ **3. Multi-Vendor Example (5–10 candidates)**

Good for testing the popup layout.

```json
{
  "documentId": "99887766-5544-2211-aabb-ccddeeff0011",
  "documentType": "Invoice",
  "extractedAtUtc": "2025-01-20T18:44:12Z",
  "provider": "Azure",
  "modelVersion": "2025-v3",
  "overallConfidence": 0.79,

  "invoice": {
    "invoiceNumber": "2025-8791",
    "invoiceDate": "2025-01-02",
    "dueDate": "2025-01-30",
    "currency": "USD",
    "totalAmount": 780.00,
    "taxAmount": 0,
    "summaryDescription": "Cloud hosting subscription"
  },

  "vendorCandidates": [
    { "vendorId": 41, "vendorName": "CloudCore Hosting", "score": 0.88 },
    { "vendorId": 233, "vendorName": "CloudCore Services", "score": 0.84 },
    { "vendorId": 991, "vendorName": "CloudCore Technology", "score": 0.81 },
    { "vendorId": 401, "vendorName": "CoreCloud Hosting Ltd.", "score": 0.77 },
    { "vendorId": 882, "vendorName": "Cloud Corp LLC", "score": 0.73 },
    { "vendorId": 119, "vendorName": "CloudCord Systems", "score": 0.70 }
  ]
}
```

Popup will show 6 vendor rows.

---

# ✅ **4. Single-Perfect-Match (auto-populate scenario)**

```json
{
  "documentId": "88880000-aaaa-bbbb-cccc-ddddeeeeffff",
  "documentType": "Invoice",
  "extractedAtUtc": "2025-01-15T14:55:22Z",
  "provider": "Azure",
  "modelVersion": "v1",
  "overallConfidence": 0.94,

  "invoice": {
    "invoiceNumber": "556621-A",
    "invoiceDate": "2025-01-05",
    "dueDate": "2025-02-05",
    "currency": "USD",
    "totalAmount": 1120.90,
    "taxAmount": 120.90,
    "summaryDescription": "January maintenance services"
  },

  "vendorCandidates": [
    {
      "vendorId": 77,
      "vendorName": "BlueWave Maintenance Inc.",
      "score": 0.99,
      "matchType": "ExactName"
    }
  ]
}
```

JS will:

* auto-fill vendor
* call `OnVendorSelected`
* prefill invoice fields

No dialog appears.

---

# ✅ **5. Edge Case JSON (useful for testing fallback behavior)**

### Missing dates + low vendor score → Should NOT auto-populate vendor

```json
{
  "documentId": "ccddeeaa-1122-3344-5566-77889900aabb",
  "documentType": "Invoice",
  "extractedAtUtc": "2025-01-22T09:30:00Z",
  "provider": "Azure",
  "modelVersion": "v2",
  "overallConfidence": 0.58,

  "invoice": {
    "invoiceNumber": null,
    "invoiceDate": null,
    "dueDate": null,
    "currency": "CAD",
    "totalAmount": 270.35,
    "taxAmount": null,
    "summaryDescription": "Office supplies"
  },

  "vendorCandidates": [
    {
      "vendorId": 5001,
      "vendorName": "Office Supply Depot",
      "score": 0.48,
      "matchType": "FuzzyName"
    }
  ]
}
```

Expected behavior:

* No auto vendor
* No dialog
* User manually types vendor
* JS still fills **total amount** and **summary description** WHEN vendor finally gets chosen

---

# Want mock JSON for **Payment** and **Deposit** too?

I can generate JSON for those future document types so your microservice can evolve consistently.

Just say:
**“Give me Payment & Deposit sample JSON”**
