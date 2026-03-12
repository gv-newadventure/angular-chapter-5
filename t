Great question. Let’s go very explicitly and concretely so you can refactor safely without breaking anything. I will show:

1. Current files (17)


2. Which files will be deleted


3. Where their code moves


4. Final files (11)


5. Why each merge is safe




---

1. Your Current Structure (17 files)

From the screenshots your invoice-ai module currently contains:

API

1️⃣ api/invoiceApi.ts

DOM

2️⃣ dom/events.ts
3️⃣ dom/inputs.ts
4️⃣ dom/pageDetection.ts
5️⃣ dom/visibility.ts
6️⃣ dom/webforms.ts

State

7️⃣ state/interopState.ts

Types

8️⃣ types/invoiceTypes.ts

Utils

9️⃣ utils/helper.ts

Vendor

10️⃣ vendor/vendorApply.ts
11️⃣ vendor/vendorDialog.ts
12️⃣ vendor/vendorFlow.ts
13️⃣ vendor/vendorNoMatch.ts
14️⃣ vendor/vendorNoMatchDialog.ts
15️⃣ vendor/vendorState.ts
16️⃣ vendor/restoreVendorNoMatchUI.ts

Root

17️⃣ index.ts


---

2. Main Problem Area

The vendor folder has 7 files.

vendor/
vendorApply.ts
vendorDialog.ts
vendorFlow.ts
vendorNoMatch.ts
vendorNoMatchDialog.ts
restoreVendorNoMatchUI.ts
vendorState.ts

But these files all represent one single feature.

They should be 3 files maximum.


---

3. Files That Will Be Removed

These files will disappear completely:

vendorApply.ts
vendorNoMatch.ts
vendorNoMatchDialog.ts
restoreVendorNoMatchUI.ts

That is 4 files removed.


---

4. Where Each Removed File Goes

File 1 removed

❌ vendorApply.ts

Move its code into:

vendorFlow.ts

Example:

Current vendorApply.ts

export function applyVendor(v: VendorCandidate) {
   set("MainContent_hdnVendorID", v.vendorId);
   set("MainContent_txtVendor", v.vendorName);
   callCheckValidVendor();
}

Move that function directly into vendorFlow.ts.

So vendorFlow.ts becomes the central vendor logic file.


---

File 2 removed

❌ vendorNoMatch.ts

Move these functions into:

vendorFlow.ts

Functions like:

handleVendorNoMatch()
handleVendorMatched()
showVendorNoMatchDialog()

All belong to the main vendor flow logic.


---

File 3 removed

❌ vendorNoMatchDialog.ts

Move this code into:

vendorDialog.ts

Because both files represent dialogs.

So after merge:

vendorDialog.ts

contains:

showVendorDialog()
showVendorNoMatchDialog()
closeVendorDialog()

Everything related to popups.


---

File 4 removed

❌ restoreVendorNoMatchUI.ts

Move its function:

restoreVendorNoMatchUI()

into:

vendorFlow.ts

Reason: restoring UI state is part of the vendor logic flow, not a separate module.


---

5. Vendor Folder After Refactor

Before:

vendor/
7 files

After:

vendor/
vendorFlow.ts
vendorDialog.ts
vendorState.ts

Only 3 files.


---

6. Utils Cleanup

Your file:

utils/helper.ts

contains DOM logic like:

highlightAiField()
getElement()
getInputElement()

These are not utilities, they are DOM helpers.

Move these functions to:

dom/inputs.ts

Then delete:

utils/helper.ts

So:

❌ delete

utils/helper.ts

That removes 1 more file.


---

7. Final File Reduction

Removed files

vendorApply.ts
vendorNoMatch.ts
vendorNoMatchDialog.ts
restoreVendorNoMatchUI.ts
utils/helper.ts

Total removed:

5 files


---

8. Final Structure (11 files)

invoice-ai
│
├── api
│   invoiceApi.ts
│
├── dom
│   events.ts
│   inputs.ts
│   pageDetection.ts
│   visibility.ts
│   webforms.ts
│
├── vendor
│   vendorFlow.ts
│   vendorDialog.ts
│   vendorState.ts
│
├── state
│   interopState.ts
│
├── types
│   invoiceTypes.ts
│
└── index.ts

Total:

11 files


---

9. Responsibility of Each File (Very Important)

vendorFlow.ts

Business logic:

handleVendorSelection
applyVendor
handleVendorNoMatch
restoreVendorNoMatchUI


---

vendorDialog.ts

UI dialogs:

showVendorDialog
showVendorNoMatchDialog
closeVendorDialog


---

vendorState.ts

Vendor selection state.


---

inputs.ts

All DOM input manipulation.

setInputValue
getHiddenValue
markAiField
highlightAiField


---

invoiceApi.ts

Fetch extracted AI invoice.


---

10. Why This Refactor Is Safe

Nothing changes in behavior because:

Functions remain identical

Only file location changes

Imports change slightly


Example:

Before:

import { applyVendor } from "./vendorApply"

After:

import { applyVendor } from "./vendorFlow"


---

11. One More Strong Suggestion

Rename:

vendorFlow.ts

to

vendorService.ts

Because it is business logic, not flow.

But that is optional.


---

12. Refactor Order (Important)

Do it step-by-step to avoid breaking things.

Step 1

Move applyVendor() → vendorFlow.ts

Delete vendorApply.ts


---

Step 2

Move vendorNoMatch.ts functions → vendorFlow.ts

Delete vendorNoMatch.ts


---

Step 3

Move vendorNoMatchDialog.ts → vendorDialog.ts

Delete vendorNoMatchDialog.ts


---

Step 4

Move restoreVendorNoMatchUI() → vendorFlow.ts

Delete restoreVendorNoMatchUI.ts


---

Step 5

Move highlight helpers → inputs.ts

Delete utils/helper.ts


---

13. Result

Your code becomes:

✔ Easier to navigate
✔ Vendor logic centralized
✔ Dialog UI separated
✔ Less file hopping


---

If you'd like, I can also show you one extremely clean refactor that senior frontend architects use which would reduce your module to only 7 files total while keeping it very scalable for:

PO AI extraction

Receipt extraction

Contract ingestion

Any document type.


It's a very elegant pattern.