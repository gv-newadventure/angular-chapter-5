Nice, you just hit the *other* classic WebForms landmine:
some server-side handler (button click) runs, clears fields, and your AI values disappear.

Key idea:

> **You need one “authoritative” copy of the AI values, and re-apply them *after* all server logic finishes.**
> In WebForms that “after everything is completed” point is `Page_PreRender`.

I’ll give you a concrete pattern you can drop in.

---

## 1. Capture AI values into hidden fields (snapshot)

In `Invoice.aspx`, add hidden fields for each AI-filled field:

```aspx
<asp:HiddenField runat="server" ID="hdnAiInvoiceNumber" />
<asp:HiddenField runat="server" ID="hdnAiInvoiceDate" />
<asp:HiddenField runat="server" ID="hdnAiDueDate" />
<asp:HiddenField runat="server" ID="hdnAiTotalAmount" />
<asp:HiddenField runat="server" ID="hdnAiTaxAmount" />
<asp:HiddenField runat="server" ID="hdnAiDescription" />
```

Then in your JS `ai_prefillInvoiceFields` function, when you fill a textbox, also write the same value into the hidden field:

```javascript
function ai_prefillInvoiceFields() {
    if (!aiInvoiceExtraction || !aiInvoiceExtraction.invoice)
        return;

    var inv = aiInvoiceExtraction.invoice;

    // Invoice Number
    if (inv.invoiceNumber &&
        $('#<%= txtInvoiceNumber.ClientID %>').val().trim() === '') {
        $('#<%= txtInvoiceNumber.ClientID %>').val(inv.invoiceNumber);
        $('#<%= hdnAiInvoiceNumber.ClientID %>').val(inv.invoiceNumber);
    }

    // Invoice Date
    if (inv.invoiceDate &&
        $('#<%= txtInvoiceDate.ClientID %>').val().trim() === '') {
        $('#<%= txtInvoiceDate.ClientID %>').val(inv.invoiceDate);
        $('#<%= hdnAiInvoiceDate.ClientID %>').val(inv.invoiceDate);
    }

    // Due Date
    if (inv.dueDate &&
        $('#<%= txtDueDate.ClientID %>').val().trim() === '') {
        $('#<%= txtDueDate.ClientID %>').val(inv.dueDate);
        $('#<%= hdnAiDueDate.ClientID %>').val(inv.dueDate);
    }

    // Total
    if (inv.totalAmount &&
        $('#<%= txtInvoiceAmount.ClientID %>').val().trim() === '') {
        $('#<%= txtInvoiceAmount.ClientID %>').val(inv.totalAmount);
        $('#<%= hdnAiTotalAmount.ClientID %>').val(inv.totalAmount);
    }

    // Tax
    if (inv.taxAmount &&
        $('#<%= txtTaxAmount.ClientID %>').val().trim() === '') {
        $('#<%= txtTaxAmount.ClientID %>').val(inv.taxAmount);
        $('#<%= hdnAiTaxAmount.ClientID %>').val(inv.taxAmount);
    }

    // Description
    if (inv.summaryDescription &&
        $('#<%= txtDescription.ClientID %>').val().trim() === '') {
        $('#<%= txtDescription.ClientID %>').val(inv.summaryDescription);
        $('#<%= hdnAiDescription.ClientID %>').val(inv.summaryDescription);
    }
}
```

Now you have a **server-side snapshot** of what AI filled in.

---

## 2. Re-apply AI snapshot in `Page_PreRender` (after all button logic)

In `Invoice.aspx.cs`:

```csharp
protected void Page_PreRender(object sender, EventArgs e)
{
    // This runs after ALL button click handlers, validators, etc.

    // Only bother if this document has AI extraction
    if (!string.Equals(hdnHasAiExtraction.Value, "true", StringComparison.OrdinalIgnoreCase))
        return;

    // If server logic cleared a field (Text == ""), but we have an AI value, restore it.

    if (string.IsNullOrWhiteSpace(txtInvoiceNumber.Text) &&
        !string.IsNullOrWhiteSpace(hdnAiInvoiceNumber.Value))
    {
        txtInvoiceNumber.Text = hdnAiInvoiceNumber.Value;
    }

    if (string.IsNullOrWhiteSpace(txtInvoiceDate.Text) &&
        !string.IsNullOrWhiteSpace(hdnAiInvoiceDate.Value))
    {
        txtInvoiceDate.Text = hdnAiInvoiceDate.Value;
    }

    if (string.IsNullOrWhiteSpace(txtDueDate.Text) &&
        !string.IsNullOrWhiteSpace(hdnAiDueDate.Value))
    {
        txtDueDate.Text = hdnAiDueDate.Value;
    }

    if (string.IsNullOrWhiteSpace(txtInvoiceAmount.Text) &&
        !string.IsNullOrWhiteSpace(hdnAiTotalAmount.Value))
    {
        txtInvoiceAmount.Text = hdnAiTotalAmount.Value;
    }

    if (string.IsNullOrWhiteSpace(txtTaxAmount.Text) &&
        !string.IsNullOrWhiteSpace(hdnAiTaxAmount.Value))
    {
        txtTaxAmount.Text = hdnAiTaxAmount.Value;
    }

    if (string.IsNullOrWhiteSpace(txtDescription.Text) &&
        !string.IsNullOrWhiteSpace(hdnAiDescription.Value))
    {
        txtDescription.Text = hdnAiDescription.Value;
    }
}
```

**Why this works:**

* `Page_PreRender` fires **after** all button click events and all your legacy logic.
* If some button click handler zeroes out the fields, they’re empty by the time we reach `PreRender`.
* We then restore them from the AI snapshot **only when empty**, so:

  * Server “accidental clears” are fixed.
  * If the user manually edits a value, it won’t be overwritten (because it’s not empty).

---

## 3. Keep the other safety rules

Together with what we already did:

* Do **not** clear these fields in `Page_Load` on every postback.
* Keep vendor gating – only run AI when vendor is valid.
* Let JS call `ai_prefillInvoiceFields()` as we designed; the snapshot + PreRender is just an extra safety net to survive any server clearing.

---

### Mental model you can use in the meeting

> “We store the AI values in hidden fields and, on every postback, during `Page_PreRender` we restore them if the server logic has accidentally blanked them out. This happens after all button handlers and validations, so AI prefill always wins over unintended clears but never overwrites what the user actually typed.”

If you want, I can also add a tiny safeguard so that **once the user edits a field**, we mark it as “user-overridden” and stop restoring it even if some server logic blanks it.
