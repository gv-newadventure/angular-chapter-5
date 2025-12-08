Got you — here’s a **complete, end-to-end example** showing:

* AI prefill
* Snapshot into hidden fields
* Highlighting with `.ai-filled`
* Restoring values + highlight after **any** postback
* Removing highlight when the user edits a field

You can lift this pattern into your monster page.

---

## 1️⃣ Invoice.aspx (UI + CSS + JS)

```aspx
<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Invoice.aspx.cs"
    Inherits="LegacyApp.Invoice" %>

<!DOCTYPE html>
<html>
<head runat="server">
    <title>Invoice Entry</title>

    <script src="https://code.jquery.com/jquery-1.12.4.min.js"></script>
    <script src="https://code.jquery.com/ui/1.12.1/jquery-ui.min.js"></script>
    <link rel="stylesheet"
          href="https://code.jquery.com/ui/1.12.1/themes/base/jquery-ui.css" />

    <style>
        /* Fields populated by AI */
        .ai-filled {
            background-color: #fff6c7 !important;   /* soft yellow */
            border-color: #e3a600 !important;
            transition: background-color 0.25s ease;
        }
    </style>
</head>
<body>
<form id="form1" runat="server">

    <!-- ========================= -->
    <!-- Vendor (simplified)      -->
    <!-- ========================= -->
    <div>
        <asp:Label runat="server" ID="lblVendor" Text="Vendor" />
        <asp:TextBox runat="server" ID="txtVendor" />
        <asp:HiddenField runat="server" ID="hdnVendorId" />
        <asp:HiddenField runat="server" ID="hdnVendorKey" />
    </div>

    <!-- ========================= -->
    <!-- Invoice fields            -->
    <!-- ========================= -->
    <div>
        <asp:Label runat="server" ID="lblInvoiceNumber" Text="Invoice #" />
        <asp:TextBox runat="server" ID="txtInvoiceNumber" />
    </div>

    <div>
        <asp:Label runat="server" ID="lblInvoiceDate" Text="Invoice Date" />
        <asp:TextBox runat="server" ID="txtInvoiceDate" />
    </div>

    <div>
        <asp:Label runat="server" ID="lblDueDate" Text="Due Date" />
        <asp:TextBox runat="server" ID="txtDueDate" />
    </div>

    <div>
        <asp:Label runat="server" ID="lblInvoiceAmount" Text="Total Amount" />
        <asp:TextBox runat="server" ID="txtInvoiceAmount" />
    </div>

    <div>
        <asp:Label runat="server" ID="lblTaxAmount" Text="Tax Amount" />
        <asp:TextBox runat="server" ID="txtTaxAmount" />
    </div>

    <div>
        <asp:Label runat="server" ID="lblDescription" Text="Description" />
        <asp:TextBox runat="server" ID="txtDescription"
                     TextMode="MultiLine" Rows="3" />
    </div>

    <!-- ========================= -->
    <!-- AI control hidden fields  -->
    <!-- ========================= -->

    <!-- AI JSON + control flags -->
    <asp:HiddenField runat="server" ID="hdnDocumentId" />
    <asp:HiddenField runat="server" ID="hdnHasAiExtraction" />
    <asp:HiddenField runat="server" ID="hdnAiExtractionJson" />
    <asp:HiddenField runat="server" ID="hdnAiPrefillDone" />

    <!-- Snapshot of each AI-filled value -->
    <asp:HiddenField runat="server" ID="hdnAiInvoiceNumber" />
    <asp:HiddenField runat="server" ID="hdnAiInvoiceDate" />
    <asp:HiddenField runat="server" ID="hdnAiDueDate" />
    <asp:HiddenField runat="server" ID="hdnAiTotalAmount" />
    <asp:HiddenField runat="server" ID="hdnAiTaxAmount" />
    <asp:HiddenField runat="server" ID="hdnAiDescription" />

    <!-- ========================= -->
    <!-- AI Vendor Candidates popup -->
    <!-- ========================= -->
    <div id="divAiVendorCandidates" style="display:none;">
        <p>Multiple vendors were suggested by AI. Please select the correct one:</p>

        <table id="tblAiVendorCandidates" class="table table-striped">
            <thead>
            <tr>
                <th>Vendor</th>
                <th>Score</th>
                <th></th>
            </tr>
            </thead>
            <tbody></tbody>
        </table>

        <button type="button" id="btnAiVendorNone" class="btn btn-secondary">
            None of these – I’ll search manually
        </button>
    </div>

    <!-- ========================= -->
    <!-- Existing vendor callback  -->
    <!-- ========================= -->
    <script type="text/javascript">
        // Your existing function which runs when vendor is selected/validated.
        function OnVendorSelected(vendorId, vendorName) {
            // ... legacy logic here (locks vendor, enables fields, etc.) ...

            // After legacy logic, AI can safely prefill
            if (typeof ai_prefillInvoiceFields === 'function') {
                ai_prefillInvoiceFields();
            }
        }
    </script>

    <!-- ========================= -->
    <!-- AI Integration + Highlight -->
    <!-- ========================= -->
    <script type="text/javascript">
        var aiInvoiceExtraction = null;

        $(document).ready(function () {

            // Any input the user touches should lose the AI highlight
            $(document).on('input change', '.ai-filled', function () {
                $(this).removeClass('ai-filled');
            });

            try {
                var hasAi = $('#<%= hdnHasAiExtraction.ClientID %>').val() === 'true';
                if (!hasAi) return;

                var raw = $('#<%= hdnAiExtractionJson.ClientID %>').val();
                if (!raw || raw.trim() === '') return;

                aiInvoiceExtraction = JSON.parse(raw);

                var prefillDone = $('#<%= hdnAiPrefillDone.ClientID %>').val() === 'true';
                var vendorEmpty = ai_isVendorEmpty();

                if (!vendorEmpty) {
                    // Vendor already valid (maybe after server-side CheckValidVendor)
                    if (!prefillDone) {
                        ai_prefillInvoiceFields();
                        $('#<%= hdnAiPrefillDone.ClientID %>').val('true');
                    }
                } else {
                    // Vendor empty, first time landing here – try AI suggestions
                    if (!prefillDone) {
                        ai_tryVendorSelectionFlow();
                    }
                }

            } catch (ex) {
                console.log('AI init failed', ex);
                aiInvoiceExtraction = null;
            }
        });

        // -------------------------
        // Helper: is vendor empty?
        // -------------------------
        function ai_isVendorEmpty() {
            return $('#<%= txtVendor.ClientID %>').val().trim() === '';
        }

        // -------------------------
        // AI vendor flow
        // -------------------------
        function ai_tryVendorSelectionFlow() {
            if (!aiInvoiceExtraction || !aiInvoiceExtraction.vendorCandidates) return;

            var candidates = aiInvoiceExtraction.vendorCandidates;
            if (!candidates || candidates.length === 0) return;

            var strong = candidates.filter(function (c) { return c.score >= 0.95; });

            if (strong.length === 1) {
                ai_applyVendor(strong[0]);
                return;
            }

            if (candidates.length > 1) {
                ai_showVendorDialog(candidates);
            }
        }

        // Apply selected vendor (from AI or dialog)
        function ai_applyVendor(candidate) {
            $('#<%= hdnVendorId.ClientID %>').val(candidate.vendorId);
            $('#<%= hdnVendorKey.ClientID %>').val(candidate.vendorKey || '');
            $('#<%= txtVendor.ClientID %>').val(candidate.vendorName);

            // Reset prefill flag so next load knows to prefill
            $('#<%= hdnAiPrefillDone.ClientID %>').val('false');

            // Call existing legacy selection logic
            if (typeof OnVendorSelected === 'function') {
                OnVendorSelected(candidate.vendorId, candidate.vendorName);
            }

            // In your real page you may instead call CheckValidVendor(), which posts back
            // CheckValidVendor();
        }

        // Show dialog when there are multiple AI vendor candidates
        function ai_showVendorDialog(candidates) {
            candidates.sort(function (a, b) { return b.score - a.score; });
            var top = candidates.slice(0, 10);

            var $tbody = $('#tblAiVendorCandidates tbody');
            $tbody.empty();

            $.each(top, function (idx, c) {
                var $row = $('<tr></tr>');
                $('<td></td>').text(c.vendorName).appendTo($row);
                $('<td></td>').text((c.score * 100).toFixed(0) + '%').appendTo($row);

                var $btn = $('<button type="button" class="btn btn-primary btn-sm">Select</button>');
                $btn.on('click', function () {
                    $('#divAiVendorCandidates').dialog('close');
                    ai_applyVendor(c);
                });

                $('<td></td>').append($btn).appendTo($row);
                $tbody.append($row);
            });

            $('#btnAiVendorNone').off('click').on('click', function () {
                $('#divAiVendorCandidates').dialog('close');
                // user will use normal predictive search
            });

            $('#divAiVendorCandidates').dialog({
                modal: true,
                title: 'Select Vendor (AI Suggestions)',
                width: 600
            });
        }

        // -------------------------
        // Helper to set + snapshot + highlight
        // -------------------------
        function ai_setField($ctl, value, hiddenClientId) {
            if (value === null || value === undefined || value === '') return;

            // Only prefill if user hasn't typed anything yet
            if ($ctl.val().trim() === '') {
                $ctl.val(value);

                // snapshot for server-side restore
                $('#' + hiddenClientId).val(value);

                // mark as AI-filled
                $ctl.addClass('ai-filled');
            }
        }

        // -------------------------
        // Main prefill routine
        // -------------------------
        function ai_prefillInvoiceFields() {
            if (!aiInvoiceExtraction || !aiInvoiceExtraction.invoice) return;

            var inv = aiInvoiceExtraction.invoice;

            ai_setField($('#<%= txtInvoiceNumber.ClientID %>'),
                inv.invoiceNumber, '<%= hdnAiInvoiceNumber.ClientID %>');
            ai_setField($('#<%= txtInvoiceDate.ClientID %>'),
                inv.invoiceDate, '<%= hdnAiInvoiceDate.ClientID %>');
            ai_setField($('#<%= txtDueDate.ClientID %>'),
                inv.dueDate, '<%= hdnAiDueDate.ClientID %>');
            ai_setField($('#<%= txtInvoiceAmount.ClientID %>'),
                inv.totalAmount, '<%= hdnAiTotalAmount.ClientID %>');
            ai_setField($('#<%= txtTaxAmount.ClientID %>'),
                inv.taxAmount, '<%= hdnAiTaxAmount.ClientID %>');
            ai_setField($('#<%= txtDescription.ClientID %>'),
                inv.summaryDescription, '<%= hdnAiDescription.ClientID %>');

            $('#<%= hdnAiPrefillDone.ClientID %>').val('true');
        }
    </script>

</form>
</body>
</html>
```

---

## 2️⃣ Invoice.aspx.cs (AI init + restore + highlight on postback)

```csharp
using System;
using System.Web.UI;

namespace LegacyApp
{
    public partial class Invoice : Page
    {
        private readonly IInvoiceExtractionService _extractionService;

        public Invoice()
        {
            _extractionService = new InvoiceExtractionService(); // or DI
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                InitializeAiExtractionForDocument();
            }

            // other Page_Load logic (do NOT clear AI fields here)
        }

        private void InitializeAiExtractionForDocument()
        {
            var docIdString = Request.QueryString["DocumentId"];
            if (!Guid.TryParse(docIdString, out var documentId))
            {
                hdnHasAiExtraction.Value = "false";
                hdnAiExtractionJson.Value = string.Empty;
                hdnAiPrefillDone.Value = "false";
                return;
            }

            hdnDocumentId.Value = documentId.ToString();

            var extraction = _extractionService.GetExtractionByDocumentId(documentId);

            if (extraction != null &&
                extraction.Status == ExtractionStatus.Success &&
                !string.IsNullOrWhiteSpace(extraction.NormalizedJson))
            {
                hdnHasAiExtraction.Value = "true";
                hdnAiExtractionJson.Value = extraction.NormalizedJson;
                hdnAiPrefillDone.Value = "false"; // first time for this doc
            }
            else
            {
                hdnHasAiExtraction.Value = "false";
                hdnAiExtractionJson.Value = string.Empty;
                hdnAiPrefillDone.Value = "false";
            }
        }

        // After ALL button click logic, validations, etc.
        protected void Page_PreRender(object sender, EventArgs e)
        {
            if (!string.Equals(hdnHasAiExtraction.Value, "true",
                    StringComparison.OrdinalIgnoreCase))
                return;

            RestoreAiField(txtInvoiceNumber, hdnAiInvoiceNumber);
            RestoreAiField(txtInvoiceDate,   hdnAiInvoiceDate);
            RestoreAiField(txtDueDate,       hdnAiDueDate);
            RestoreAiField(txtInvoiceAmount, hdnAiTotalAmount);
            RestoreAiField(txtTaxAmount,     hdnAiTaxAmount);
            RestoreAiField(txtDescription,   hdnAiDescription);
        }

        private void RestoreAiField(System.Web.UI.WebControls.TextBox textBox,
                                   System.Web.UI.WebControls.HiddenField snapshot)
        {
            if (string.IsNullOrWhiteSpace(snapshot.Value))
                return;

            // If some server logic cleared the field, restore value
            if (string.IsNullOrWhiteSpace(textBox.Text))
            {
                textBox.Text = snapshot.Value;
            }

            // Ensure CSS class contains ai-filled (to keep highlight after postback)
            if (!textBox.CssClass.Contains("ai-filled"))
            {
                if (string.IsNullOrWhiteSpace(textBox.CssClass))
                    textBox.CssClass = "ai-filled";
                else
                    textBox.CssClass += " ai-filled";
            }
        }
    }
}
```

---

With this setup you now have:

* AI-prefilled fields **highlighted** in yellow.
* Highlights + values **persisting across any number of postbacks**.
* Server code can accidentally clear fields; PreRender and snapshots restore them.
* As soon as a user edits a field, the highlight is removed (so they know what they changed).

If you paste me the *real* control IDs for your vendor + invoice fields, I can give you a version that matches your actual names exactly so you can drop it in with minimal edits.
