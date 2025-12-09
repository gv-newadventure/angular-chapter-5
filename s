<div id="divAiVendorNoMatch" title="Vendor Not Found by AI" style="display:none; padding: 10px 15px;">
    
    <p class="text-muted" style="font-size:14px;">
        The AI service could not confidently match this invoice to a Vendor in our system.
    </p>

    <p class="text-muted" style="font-size:14px; margin-top:10px;">
        Please use the Vendor search to select the correct Vendor manually.
        Once selected, the invoice fields will still be prefilled from the AI extraction.
    </p>

    <div class="text-right" style="margin-top:20px;">
        <button id="btnAiVendorNoMatchOk" 
                class="btn btn-primary btn-sm">
            OK – I will enter the Vendor manually
        </button>
    </div>
</div>



function ai_showVendorNoMatchDialog() {

    // Ensure click handler is clean
    $('#btnAiVendorNoMatchOk').off('click').on('click', function () {
        $('#divAiVendorNoMatch').dialog('close');
    });

    $('#divAiVendorNoMatch').dialog({
        modal: true,
        width: 480,
        resizable: false,
        draggable: false,
        closeOnEscape: true,
        dialogClass: "bootstrap-dialog-fix",
        buttons: [] // we use our own Bootstrap button inside
    });
}


.bootstrap-dialog-fix .ui-dialog-buttonpane button {
    font-size: inherit;
}
.bootstrap-dialog-fix .ui-dialog-titlebar {
    padding: 8px 15px;
}
