Yep, let’s pull it all together into one coherent “Phase 1 AI” implementation.

This will be a **reference implementation** you can:

* Show in a design review
* Adapt into your monster `Invoice.aspx` / `.cs` safely

I’ll cover:

1. `Invoice.aspx` (UI markup: fields, hidden fields, vendor popup, JS include)
2. `Invoice.aspx.cs` (code-behind to load the JSON)
3. C# models / service interface for extraction
4. Full JavaScript AI integration (wired to the page)

You’ll need to **rename IDs and tweak wiring** to match your actual page, but the structure is end-to-end.

---

## 1️⃣ Invoice.aspx – UI + Hidden Fields + Vendor Popup + JS

```aspx
<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Invoice.aspx.cs" Inherits="LegacyApp.Invoice" %>

<!DOCTYPE html>
<html>
<head runat="server">
    <title>Invoice Entry</title>

    <!-- Your existing CSS & JS references here -->
    <script src="https://code.jquery.com/jquery-1.12.4.min.js"></script>
    <script src="https://code.jquery.com/ui/1.12.1/jquery-ui.min.js"></script>
    <link rel="stylesheet" href="https://code.jquery.com/ui/1.12.1/themes/base/jquery-ui.css" />
</head>
<body>
    <form id="form1" runat="server">

        <!-- ================================== -->
        <!-- Existing Vendor Section (simplified) -->
        <!-- ================================== -->
        <div>
            <asp:Label runat="server" ID="lblVendor" Text="Vendor"></asp:Label>
            <!-- This is your predictive search textbox -->
            <asp:TextBox runat="server" ID="txtVendor"></asp:TextBox>

            <!-- Hidden Vendor ID field that your predictive search already uses -->
            <asp:HiddenField runat="server" ID="hdnVendorId" />
        </div>

        <!-- ================================== -->
        <!-- Existing Invoice Fields (simplified) -->
        <!-- ================================== -->
        <div>
            <asp:Label runat="server" ID="lblInvoiceNumber" Text="Invoice #"></asp:Label>
            <asp:TextBox runat="server" ID="txtInvoiceNumber"></asp:TextBox>
        </div>

        <div>
            <asp:Label runat="server" ID="lblInvoiceDate" Text="Invoice Date"></asp:Label>
            <asp:TextBox runat="server" ID="txtInvoiceDate"></asp:TextBox>
        </div>

        <div>
            <asp:Label runat="server" ID="lblDueDate" Text="Due Date"></asp:Label>
            <asp:TextBox runat="server" ID="txtDueDate"></asp:TextBox>
        </div>

        <div>
            <asp:Label runat="server" ID="lblInvoiceAmount" Text="Total Amount"></asp:Label>
            <asp:TextBox runat="server" ID="txtInvoiceAmount"></asp:TextBox>
        </div>

        <div>
            <asp:Label runat="server" ID="lblTaxAmount" Text="Tax Amount"></asp:Label>
            <asp:TextBox runat="server" ID="txtTaxAmount"></asp:TextBox>
        </div>

        <div>
            <asp:Label runat="server" ID="lblDescription" Text="Description"></asp:Label>
            <asp:TextBox runat="server" ID="txtDescription" TextMode="MultiLine" Rows="3"></asp:TextBox>
        </div>

        <!-- ================================== -->
        <!-- Hidden fields for AI integration -->
        <!-- ================================== -->
        <asp:HiddenField runat="server" ID="hdnDocumentId" />
        <asp:HiddenField runat="server" ID="hdnHasAiExtraction" />
        <asp:HiddenField runat="server" ID="hdnAiExtractionJson" />

        <!-- ================================== -->
        <!-- AI Vendor Candidates Popup Dialog -->
        <!-- ================================== -->
        <div id="divAiVendorCandidates" style="display:none;">
            <p>Multiple vendors were suggested by AI. Please select the correct one:</p>

            <table id="tblAiVendorCandidates" class="table table-striped">
                <thead>
                    <tr>
                        <th>Vendor Name</th>
                        <th>Match Score</th>
                        <th></th>
                    </tr>
                </thead>
                <tbody>
                    <!-- Rows injected by JavaScript -->
                </tbody>
            </table>

            <button type="button" id="btnAiVendorNone" class="btn btn-secondary">
                None of these – I will search manually
            </button>
        </div>

        <!-- ================================== -->
        <!-- Your existing JavaScript goes here -->
        <!-- ================================== -->
        <script type="text/javascript">
            // Example of your existing vendor selection function
            // (You probably already have something like this in the real page)
            function OnVendorSelected(vendorId, vendorName) {
                // EXISTING LEGACY LOGIC:
                // - Lock vendor
                // - Enable other fields
                // - Load vendor-specific defaults, etc.

                // ...

                // NEW: Let AI prefill fields AFTER existing logic
                if (typeof ai_prefillInvoiceFields === 'function') {
                    ai_prefillInvoiceFields();
                }
            }
        </script>

        <!-- ================================== -->
        <!-- AI Integration JavaScript (FULL) -->
        <!-- ================================== -->
        <script type="text/javascript">
            // ===========================================================
            //  AI-INVOICE EXTRACTION INTEGRATION LAYER
            //  SAFE + NON-INTRUSIVE: if anything fails, page behaves as today
            // ===========================================================

            var aiInvoiceExtraction = null;

            // -----------------------------------------------------------
            // PAGE LOAD HOOK
            // -----------------------------------------------------------
            $(document).ready(function () {

                try {
                    var hasAi = $('#<%= hdnHasAiExtraction.ClientID %>').val() === 'true';
                    if (!hasAi) return;

                    var raw = $('#<%= hdnAiExtractionJson.ClientID %>').val();
                    if (!raw || raw.trim() === '') return;

                    aiInvoiceExtraction = JSON.parse(raw);

                    // Vendor gating logic: only try AI if vendor is not already chosen
                    ai_tryVendorSelectionFlow();

                } catch (ex) {
                    console.log("AI Initialization Failed:", ex);
                    aiInvoiceExtraction = null;
                }
            });

            // -----------------------------------------------------------
            // AI Vendor Selection Flow
            // -----------------------------------------------------------
            function ai_tryVendorSelectionFlow() {

                if (!aiInvoiceExtraction) return;
                if (!aiInvoiceExtraction.vendorCandidates) return;
                if (!ai_isVendorEmpty()) return; // if user/vendor already filled, don’t touch

                var candidates = aiInvoiceExtraction.vendorCandidates;

                if (!candidates || candidates.length === 0) return;

                // High confidence auto-match
                var strong = candidates.filter(function (c) { return c.score >= 0.95; });

                if (strong.length === 1) {
                    ai_applyVendor(strong[0]);
                    return;
                }

                // Multiple candidates → show vendor dialog
                if (candidates.length > 1) {
                    ai_showVendorDialog(candidates);
                    return;
                }

                // Single low-score candidate → do nothing, user chooses manually
            }

            // -----------------------------------------------------------
            // Vendor Helpers
            // -----------------------------------------------------------
            function ai_isVendorEmpty() {
                return $('#<%= txtVendor.ClientID %>').val().trim() === '';
            }

            function ai_applyVendor(candidate) {

                // Fill controls just like predictive search would
                $('#<%= hdnVendorId.ClientID %>').val(candidate.vendorId);
                $('#<%= txtVendor.ClientID %>').val(candidate.vendorName);

                // IMPORTANT: Call existing logic
                if (typeof OnVendorSelected === 'function') {
                    OnVendorSelected(candidate.vendorId, candidate.vendorName);
                }

                // Wait a bit to let existing scripts finish (enable fields, etc.)
                setTimeout(function () {
                    ai_prefillInvoiceFields();
                }, 250);
            }

            // -----------------------------------------------------------
            // Vendor Dialog (for multiple suggestions)
            // -----------------------------------------------------------
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

                    var $action = $('<td></td>').append($btn);
                    $row.append($action);

                    $tbody.append($row);
                });

                $('#btnAiVendorNone').off('click').on('click', function () {
                    $('#divAiVendorCandidates').dialog('close');
                    // User will do manual vendor search
                });

                $('#divAiVendorCandidates').dialog({
                    modal: true,
                    title: 'Select Vendor (AI Suggestions)',
                    width: 600
                });
            }

            // -----------------------------------------------------------
            // Prefill Invoice Fields (AFTER vendor is chosen)
            // -----------------------------------------------------------
            function ai_prefillInvoiceFields() {

                if (!aiInvoiceExtraction || !aiInvoiceExtraction.invoice)
                    return;

                var inv = aiInvoiceExtraction.invoice;

                // Only fill if user hasn't typed anything

                if (inv.invoiceNumber &&
                    $('#<%= txtInvoiceNumber.ClientID %>').val().trim() === '') {
                    $('#<%= txtInvoiceNumber.ClientID %>').val(inv.invoiceNumber);
                }

                if (inv.invoiceDate &&
                    $('#<%= txtInvoiceDate.ClientID %>').val().trim() === '') {
                    $('#<%= txtInvoiceDate.ClientID %>').val(inv.invoiceDate);
                }

                if (inv.dueDate &&
                    $('#<%= txtDueDate.ClientID %>').val().trim() === '') {
                    $('#<%= txtDueDate.ClientID %>').val(inv.dueDate);
                }

                if (inv.totalAmount &&
                    $('#<%= txtInvoiceAmount.ClientID %>').val().trim() === '') {
                    $('#<%= txtInvoiceAmount.ClientID %>').val(inv.totalAmount);
                }

                if (inv.taxAmount &&
                    $('#<%= txtTaxAmount.ClientID %>').val().trim() === '') {
                    $('#<%= txtTaxAmount.ClientID %>').val(inv.taxAmount);
                }

                if (inv.summaryDescription &&
                    $('#<%= txtDescription.ClientID %>').val().trim() === '') {
                    $('#<%= txtDescription.ClientID %>').val(inv.summaryDescription);
                }
            }

            // Optional: if your predictive search has a "manual vendor changed" hook
            function ai_onManualVendorChanged() {
                ai_prefillInvoiceFields();
            }
        </script>

    </form>
</body>
</html>
```

---

## 2️⃣ Invoice.aspx.cs – Load JSON from DB and set hidden fields

This is the **code-behind** that pulls the JSON produced by your microservice and feeds it into the hidden fields.

```csharp
using System;
using System.Web.UI;

namespace LegacyApp
{
    public partial class Invoice : Page
    {
        // You can inject this via your DI mechanism, or use your own repository pattern.
        private readonly IInvoiceExtractionService _extractionService;

        public Invoice()
        {
            // In real code, use DI / Service Locator, etc.
            _extractionService = new InvoiceExtractionService();
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                InitializeAiExtractionForDocument();
            }

            // Existing Page_Load logic continues as-is below
            // ...
        }

        private void InitializeAiExtractionForDocument()
        {
            var documentIdString = Request.QueryString["DocumentId"];
            if (!Guid.TryParse(documentIdString, out var documentId))
            {
                hdnDocumentId.Value = string.Empty;
                hdnHasAiExtraction.Value = "false";
                hdnAiExtractionJson.Value = string.Empty;
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
            }
            else
            {
                hdnHasAiExtraction.Value = "false";
                hdnAiExtractionJson.Value = string.Empty;
            }
        }
    }
}
```

---

## 3️⃣ C# Models + Service Interface

### 3.1. DocumentExtraction entity (data from microservice)

```csharp
public enum ExtractionStatus
{
    Pending = 0,
    InProgress = 1,
    Success = 2,
    Failed = 3
}

public sealed class DocumentExtraction
{
    public Guid DocumentId { get; set; }
    public string DocumentType { get; set; } = "Invoice";

    public ExtractionStatus Status { get; set; }

    public string Provider { get; set; } = string.Empty;
    public string ModelVersion { get; set; } = string.Empty;

    public decimal? OverallConfidence { get; set; }

    // JSON passed to the page
    public string NormalizedJson { get; set; } = string.Empty;

    public DateTimeOffset CreatedOnUtc { get; set; }
    public DateTimeOffset? CompletedOnUtc { get; set; }

    public string? ErrorCode { get; set; }
    public string? ErrorMessage { get; set; }
}
```

### 3.2. JSON payload model (matches what JS expects)

```csharp
public sealed class InvoiceExtractionPayload
{
    public Guid DocumentId { get; set; }
    public string DocumentType { get; set; } = "Invoice";
    public DateTimeOffset ExtractedAtUtc { get; set; }

    public string Provider { get; set; } = string.Empty;
    public string ModelVersion { get; set; } = string.Empty;
    public decimal? OverallConfidence { get; set; }

    public InvoiceDocumentModel? Invoice { get; set; }

    public List<VendorCandidate> VendorCandidates { get; set; } = new();
}

public sealed class InvoiceDocumentModel
{
    public string? InvoiceNumber { get; set; }
    public string? InvoiceDate { get; set; } // serialized as ISO 8601 / yyyy-MM-dd for JS
    public string? DueDate { get; set; }

    public string? Currency { get; set; }
    public decimal? TotalAmount { get; set; }
    public decimal? TaxAmount { get; set; }

    public string? SummaryDescription { get; set; }

    public List<InvoiceLineItem> LineItems { get; set; } = new();
}

public sealed class InvoiceLineItem
{
    public int LineNumber { get; set; }
    public string? Description { get; set; }
    public decimal? Quantity { get; set; }
    public decimal? UnitPrice { get; set; }
    public decimal? LineTotal { get; set; }
}

public sealed class VendorCandidate
{
    public int VendorId { get; set; }
    public string VendorName { get; set; } = string.Empty;
    public decimal Score { get; set; }         // 0.0–1.0
    public string? MatchType { get; set; }     // "ExactName", "FuzzyName", etc.
}
```

### 3.3. Service interface used by the page

```csharp
public interface IInvoiceExtractionService
{
    DocumentExtraction GetExtractionByDocumentId(Guid documentId);
}
```

Minimal dummy implementation (in real life, you’d do ADO.NET/EF to query the `DocumentExtraction` table):

```csharp
public sealed class InvoiceExtractionService : IInvoiceExtractionService
{
    public DocumentExtraction GetExtractionByDocumentId(Guid documentId)
    {
        // TODO: Replace with actual DB call
        // SELECT TOP 1 * FROM DocumentExtraction WHERE DocumentId = @documentId

        return null; // null means "no extraction" → page behaves as today
    }
}
```

---

## 4️⃣ How it all fits together (flow)

1. **Upload time (outside this page):**

   * Microservice is called with `DocumentId` + blob path.
   * Azure AI / fuzzy logic runs.
   * Microservice stores JSON in `DocumentExtraction.NormalizedJson`.

2. **Invoice.aspx load:**

   * `Page_Load` calls `InitializeAiExtractionForDocument()`.
   * That populates `hdnHasAiExtraction` + `hdnAiExtractionJson`.

3. **Client-side on ready:**

   * JS reads hidden fields, parses JSON into `aiInvoiceExtraction`.
   * If vendor empty:

     * One strong candidate → auto vendor select → `OnVendorSelected` → AI prefill.
     * Multiple → show dialog → user chooses → `OnVendorSelected` → AI prefill.
     * None / low score → no change; user does manual vendor selection.

4. **If anything fails (no JSON, bad JSON, AI down, etc.):**

   * All the early `return` statements kick in.
   * Page works 100% like today.

---

If you want, next we can:

* Draft a **“before & after” UX narrative** to reassure business.
* Or a **risk/mitigation** table specifically around touching Invoice.aspx and how this design keeps risk low.
