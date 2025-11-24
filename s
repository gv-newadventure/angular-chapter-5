Absolutely — I’ve fully digested everything you shared.

You don’t need to repeat anything.

Here’s a concise understanding of your situation, in my own words, to confirm alignment:


---

My Understanding of Your Situation

Current Legacy System Context

Highly complex, fragile legacy application based on:

ASP.NET WebForms (ASPX)

MVC 4

.NET Framework


Major cornerstone UI = Invoice.ASPX page.

Lots of patchwork over many years — brittle, risky to touch.

Used extensively by financial/account managers.

Users manually key in invoice data based on scanned documents.


Existing Document Ingestion

Documents can be added via:

1. Single document upload


2. Multi document upload


3. Direct upload from Invoice.ASPX



After upload:

Documents appear in an inbox-like queue: “To Enter Invoice”

User opens an item → navigates to Invoice.ASPX

They manually enter vendor/date/amount/etc while eyeballing the invoice


Volume

~400,000 invoices per month → MASSIVE throughput.

Even saving 2–3 min per invoice = massive ROI



---

Business Goal

Introduce AI-driven invoice data extraction, in a minimal-impact, safe, incremental, non-disruptive way.

NOT a rewrite.
NOT a new UI.
NOT a rebuilt invoice module.

Just:

AI auto-populates existing invoice entry screen.

User reviews + submits as usual.

Workflow unchanged.



---

Strategic Architecture Direction (from management)

AI layer should be encapsulated in a black-box microservice.

Invoice.ASPX should NOT call Azure directly.

No UI overhaul.

No change in user flow.

No dependency on a single AI vendor (Azure / AWS / Custom)

Pluggable backend extraction engine.

Corporate governance concerns require:

flexibility

swappability

vendor independence




---

Your Position

You understand the fragility & risk deeply.

You understand management's strategic direction.

You want something stable, deliberate, and iterative.

You want a clean, safe first release in 4–6 months.

You want to contribute thoughtfully—not impulsively suggest architecture like others.



---

Next Step

I will wait for your next input, just like you asked.

Whenever you're ready:
Tell me what direction you want help on next — architecture, risks, flow diagram, tech choices, metadata storage, JSON schema, or executive explanation.


ǰjjjjjffjfueyheuddd

Gotcha — let’s turn this into something you can say in a meeting plus the technical backbone behind it.

I’ll break it into 3 parts:

1. Where to save the AI-extracted JSON (with a concrete recommendation)


2. How to design the AI microservice (blackbox, swappable)


3. A point-by-point meeting script, including how to counter “let’s build a new invoice page”




---

1. Where do we save the AI-extracted JSON?

You basically have three realistic options. I’ll give you all three and then a clear recommendation.

Option A – Store JSON in the existing “document” table as a new column

Add one or two columns to the table that already tracks each uploaded document:

ExtractedJson (NVARCHAR(MAX) or similar)

ExtractionStatus (Pending / Success / Failed / Skipped)

ExtractionProvider (Azure / AWS / Custom)

ExtractionConfidence (numeric)


Pros:

Simple to access from Invoice.ASPX (one lookup).

No schema explosion, easy for a first release.

Easy to keep in sync with the document record (1:1 relationship).


Cons:

Table may already be hot and large → huge JSON might bloat it.

Harder to store multiple versions of extraction (if we change AI models later).


Option B – Separate “DocumentExtraction” table (recommended)

Create a new table, e.g. DocumentExtraction:

DocumentExtraction
------------------
Id (PK)
DocumentId (FK to Document table)
ExtractionJson (NVARCHAR(MAX))
ExtractionStatus (Pending / Success / Failed / Skipped)
ExtractionProvider (Azure / AWS / Custom)
ModelNameOrVersion (NVARCHAR(100))
ExtractionConfidence (DECIMAL(5,2))
CreatedOn
UpdatedOn

You can also allow multiple rows per document later (versioning) but start with 1:1.

Pros:

Clean separation of concerns (document vs AI extraction).

Future-proof: you can add a second extraction later (new model) without changing core document table.

Easier to manage size, indexes, and retention policies.


Cons:

Slightly more joins (Invoice.ASPX must join document → extraction).

Slightly more work up front (but not much).


Option C – Store JSON as a blob side-by-side with the PDF/image

For example:

Main document in blob: invoices/1234.pdf

Extracted JSON in blob: invoices/1234.json


In DB you only store:

ExtractionBlobPath

Status, Provider, etc.


Pros:

Offloads large JSON from DB.

Works well if JSON is big and you don’t query inside it.


Cons:

Slower to fetch if you need it often.

Harder to write queries/analytics on extraction data.

Slightly more moving parts in code.



---

My recommendation (what you can say in the meeting)

> We’ll store the AI extraction in a separate DocumentExtraction table, linked by DocumentId.
For each document, we’ll have:

The full JSON

Status

Provider

Model version
This keeps our core document schema simple, lets us switch AI providers easily, and lets Invoice.ASPX just do a single join to get the JSON when it needs to pre-fill the fields.




If you’re worried about JSON size later, you can say:

> If extraction JSON grows too large or we need to store multiple versions, we’ll move the raw JSON to blob storage and keep just a pointer in the DocumentExtraction table. But for the first release, storing JSON directly in SQL is simpler and enough.




---

2. How to go about the AI microservice (blackbox design)

Think of the microservice as a “Document → StructuredData” box with a stable contract.

2.1 Responsibilities of the microservice

Accept a document reference (not the binary file itself if you can avoid it):

DocumentId

Blob URL / Blob key

Document type (Invoice / Payment / Deposit, etc.)


Call the chosen AI engine (Azure/AWS/custom) internally.

Normalize the result into your common JSON schema for invoices.

Write the extracted JSON + metadata into DocumentExtraction.

Expose status/results through an API if needed (e.g., for diagnostics).


2.2 API shape (simple example)

Endpoint 1 – Trigger extraction

POST /api/extraction/invoice

Body:

{
  "documentId": 123456,
  "blobPath": "invoices/123456.pdf",
  "documentType": "Invoice"
}

Response (for async):

{
  "documentId": 123456,
  "status": "Accepted"
}

Endpoint 2 – Optional status check

GET /api/extraction/invoice/123456

Response:

{
  "documentId": 123456,
  "status": "Success",
  "provider": "Azure",
  "model": "v1.0",
  "confidence": 0.94
}

In reality, for day-to-day work, Invoice.ASPX doesn’t call the microservice. It just checks the database: “is there extraction JSON for this DocumentId?”

2.3 Async vs Sync

For 400k invoices/month, async is safer.

On upload:

Upload completes.

Upload process calls microservice (or drops a message on a queue which the microservice listens to).

Microservice processes in background and writes to DocumentExtraction.


When user opens invoice in Invoice.ASPX:

If JSON is already ready → prefill.

If not ready or failed → user sees normal, manual entry (no worse than today).



This makes the system fail-safe:

AI down? Users still can enter invoices.

AI slow? User just falls back to manual.


2.4 Vendor-agnostic design

Inside the microservice:

Define a clean internal interface, something like:


public interface IInvoiceExtractor
{
    InvoiceExtractionResult Extract(InvoiceExtractionRequest request);
}

Then have implementations:

AzureInvoiceExtractor : IInvoiceExtractor

AwsInvoiceExtractor : IInvoiceExtractor

CustomInvoiceExtractor : IInvoiceExtractor


Choose which one to use via config (appsettings, environment variable, feature flag).

To your manager / governance:

> The application never talks to Azure or AWS directly.
It talks only to our internal microservice endpoint.
If governance says “no Azure” later, we switch the implementation inside the microservice and keep the contract the same.




---

3. Meeting script – point-by-point (including countering “new invoice page”)

Here’s a script you can more or less read out loud. I’ll structure it in steps.


---

3.1 Opening (anchor on business value and risk)

> 1. We currently key in around 400,000 invoices per month. Even saving 2–3 minutes per invoice is a massive productivity gain.


2. The Invoice.ASPX page is extremely fragile – it’s been patched by many developers for many years. Changing its core behavior or replacing it completely is high-risk.


3. Our goal for this first AI release is simple and surgical:
Use AI to pre-fill the existing invoice fields and let users review and submit as they do today. No change to their flow, just less typing.


4. At the same time, we have AI governance and vendor lock-in concerns, so the solution must keep Azure/AWS/custom options open.






---

3.2 Where we store the extracted data (simple explanation)

> 5. For each uploaded document, we will create a corresponding entry in a new table called DocumentExtraction.


6. This table will store:

The DocumentId

The extracted JSON

Status (pending/success/failed)

The provider (Azure, AWS, custom)

Model version and confidence



7. When the user opens an item from the “To Enter Invoice” inbox, Invoice.ASPX will simply look up this DocumentExtraction record by DocumentId and:

If JSON exists and status is success → we pre-populate the invoice fields.

If JSON doesn’t exist or extraction failed → we show the page exactly as today.







---

3.3 How the microservice works (blackbox story)

> 8. When a document is uploaded, the upload flow will call a Document Extraction microservice with:

DocumentId

The blob path (where the file lives)

The document type (e.g., “Invoice”)



9. The microservice will:

Fetch the document from blob storage

Send it to whatever AI engine is approved (Azure, AWS, or internal)

Normalize the result into our common JSON schema for invoices

Write it into DocumentExtraction



10. The invoice page never needs to know which AI vendor we use.
It only cares: “Is there JSON for this document? Yes or no.”






---

3.4 Why NOT build a new invoice page (your counters)

You’ll probably hear: “This is a good chance to build a new invoice page with the AI integrated nicely in a modern stack.”

Here are clear counters you can use.

Counter 1 – Risk to a mission-critical, fragile page

> 11. The current Invoice.ASPX page is fragile and mission-critical. Replacing it or heavily redesigning it in this first release increases our risk of breaking a process that creates 400k invoices a month.


12. The safest approach is to change nothing about the user flow and add AI as a behind-the-scenes enhancement that pre-fills fields.





Counter 2 – Scope and hidden complexity

> 13. A “new invoice page” sounds simple, but it’s actually a rewrite of years of business rules, edge cases, and bug fixes embedded in the existing page.


14. We don’t have full documentation of all the little behaviors. Re-implementing them in a new UI is high-effort and high-risk, especially for a 4–6 month timeline.





Counter 3 – Change management & adoption

> 15. Hundreds of users are trained on the existing screen and flow.
Changing the UI itself means:



Training

Helpdesk calls

Resistance from users


16. Management’s direction is clear: no behavior changes in phase 1, only efficiency improvements. That’s exactly what this design delivers.





Counter 4 – Governance and vendor flexibility

> 17. If we bake AI logic directly into a “new invoice page”, the UI becomes tied to a specific provider and approach.


18. With a microservice + DocumentExtraction design:



The UI is stable.

The AI engine can be swapped without breaking the page.

We can comply with governance changes by updating only the microservice internals.




Counter 5 – Phased innovation plan

> 19. This design doesn’t block innovation. It unlocks it:



Phase 1: AI-driven prefill in the existing page (low risk, high ROI).

Phase 2: Once we prove value and stabilize, we can design a modern invoice UI—maybe in Angular / React / MVC or a different module—using the same DocumentExtraction and microservice.


20. So we’re not saying “no new invoice page forever.” We’re saying:
“Not in Phase 1. Phase 1 is about safe, quick value with minimal risk.”






---

3.5 Closing argument (what you can say verbatim)

> 21. To summarize:

We keep the existing Invoice.ASPX behavior for users.

We add a new DocumentExtraction table to hold AI output as JSON.

We introduce a vendor-agnostic Document Extraction microservice that can call Azure, AWS, or a custom engine.

Invoice.ASPX just reads JSON when available and pre-fills fields.



22. This approach:

Delivers measurable time savings for 400,000 invoices/month.

Minimizes risk to a fragile, critical legacy page.

Aligns with AI governance and vendor independence.

Sets us up for future innovation, including a potential new invoice UI in a later phase.







---

If you want, next we can:

Draft a sample JSON schema for an invoice (fields, types, structure).

Sketch SQL DDL for the DocumentExtraction table.

Draft a 1–2 slide architecture diagram description you can give to whoever is making slides.



