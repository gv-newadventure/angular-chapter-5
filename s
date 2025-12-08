Great — this is an excellent UX improvement and easy to add cleanly.

Below is a complete solution that:

1. Highlights all AI-filled fields on first load


2. Retains highlight even after postbacks


3. Removes highlight automatically if the user edits the value


4. Uses a reusable CSS class so design can tweak colors later




---

✅ Step 1 — Add a CSS style in Invoice.aspx

<style>
    .ai-filled {
        background-color: #fff6c7 !important;   /* soft yellow */
        border-color: #e3a600 !important;
        transition: background-color 0.3s ease;
    }
</style>

You can pick any color later — this is just a pleasant subtle highlight.


---

✅ Step 2 — When AI fills a field in JavaScript → add .ai-filled

Modify your ai_prefillInvoiceFields() function:

function ai_setField($ctl, value, hiddenFieldId) {
    if (!value) return;

    // Only set if empty (or if you want, always overwrite)
    if ($ctl.val().trim() === "") {
        $ctl.val(value);

        // Save to hidden field snapshot
        $('#' + hiddenFieldId).val(value);

        // Add highlight
        $ctl.addClass("ai-filled");
    }
}

Then use this helper:

ai_setField($('#<%= txtInvoiceNumber.ClientID %>'), inv.invoiceNumber, '<%= hdnAiInvoiceNumber.ClientID %>');
ai_setField($('#<%= txtInvoiceDate.ClientID %>'), inv.invoiceDate, '<%= hdnAiInvoiceDate.ClientID %>');
ai_setField($('#<%= txtDueDate.ClientID %>'), inv.dueDate, '<%= hdnAiDueDate.ClientID %>');
ai_setField($('#<%= txtInvoiceAmount.ClientID %>'), inv.totalAmount, '<%= hdnAiTotalAmount.ClientID %>');
ai_setField($('#<%= txtTaxAmount.ClientID %>'), inv.taxAmount, '<%= hdnAiTaxAmount.ClientID %>');
ai_setField($('#<%= txtDescription.ClientID %>'), inv.summaryDescription, '<%= hdnAiDescription.ClientID %>');

You solve:

Prefill

Tracking

Highlighting


All in one reusable function.


---

✅ Step 3 — Retain highlight after postback (C#)

When you restore values in Page_PreRender, also mark them as AI-filled again.

In your existing PreRender logic:

if (string.IsNullOrWhiteSpace(txtInvoiceNumber.Text) &&
    !string.IsNullOrWhiteSpace(hdnAiInvoiceNumber.Value))
{
    txtInvoiceNumber.Text = hdnAiInvoiceNumber.Value;
    txtInvoiceNumber.CssClass += " ai-filled";
}

Do the same for all fields.

This ensures:

AI highlight persists even after full page postbacks

Server logic cannot remove the highlight accidentally



---

✅ Step 4 — Remove highlight when user manually edits the field

Add a reusable JS listener:

$(document).ready(function () {

    $(".ai-filled").on("input change", function () {
        $(this).removeClass("ai-filled");
    });

});

This makes the page feel modern:

The moment the user touches the field, the highlight disappears.

They know AI filled it, but they also see exactly where they made manual adjustments.



---

SUMMARY OF WHAT YOU GET

Behavior	Result

AI fills field	Subtle yellow highlight appears
Postback happens	Highlight + values stay
User edits the field	Highlight automatically removed
Server accidentally clears field	PreRender restores field + highlight
User manually overrides value	No overwrite on next AI pass


This is the perfect interaction model for AI-assisted form filling.


---

If you want, I can also add:
✔ A “Reset AI fields” button
✔ A “Show all AI-filled fields” floating panel
✔ A legend box at the top ("Fields marked in yellow were extracted by AI")

Do you want those as well?
