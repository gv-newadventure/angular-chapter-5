<!-- No-match dialog (AI couldn't find a vendor) -->
<div id="divAiVendorNoMatch" style="display:none;">
    <p>
        The AI service could not confidently match this invoice to a Vendor in our system.
    </p>
    <p>
        Please use the existing Vendor search to select the correct Vendor manually.
        Once a Vendor is selected, the invoice fields will still be prefilled from the AI extraction.
    </p>

    <button type="button" id="btnAiVendorNoMatchOk" class="btn btn-primary">
        OK – I will enter the Vendor manually
    </button>
</div>

=======================================================

 // Case 1: explicit no_match OR no candidates at all
    if (status === "no_match" || candidates.length === 0) {
        ai_showVendorNoMatchDialog();
        return;
    }



function ai_showVendorNoMatchDialog() {
    $('#btnAiVendorNoMatchOk').off('click').on('click', function () {
        $('#divAiVendorNoMatch').dialog('close');
        // After this, user just uses the existing Vendor predictive search.
        // When they pick a Vendor, OnVendorSelected + ai_prefillInvoiceFields() will still run.
    });

    $('#divAiVendorNoMatch').dialog({
        modal: true,
        title: 'Vendor Not Found by AI',
        width: 500
    });
}
