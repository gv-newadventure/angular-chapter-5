<!-- AI Vendor Suggestions -->
<div id="divAiVendorCandidates"
     title="Select Vendor (AI Suggestions)"
     style="display:none; padding: 10px 15px;">

    <p class="text-muted" style="font-size:14px; margin-bottom:15px;">
        Multiple vendors were suggested by AI. Please select the correct one:
    </p>

    <table id="tblAiVendorCandidates"
           class="table table-striped table-hover table-condensed"
           style="margin-bottom: 10px;">
        <thead>
        <tr>
            <th style="width:60%;">Vendor Name</th>
            <th style="width:20%;">Match Score</th>
            <th style="width:20%; text-align:right;">&nbsp;</th>
        </tr>
        </thead>
        <tbody>
        <!-- rows injected by JS -->
        </tbody>
    </table>

    <div class="text-right" style="margin-top:10px;">
        <button type="button"
                id="btnAiVendorNone"
                class="btn btn-default btn-sm">
            None of these – I will search manually
        </button>
    </div>
</div>







function ai_showVendorDialog(candidates) {

    candidates.sort(function (a, b) { return b.score - a.score; });
    var top = candidates.slice(0, 10);

    var $tbody = $('#tblAiVendorCandidates tbody');
    $tbody.empty();

    $.each(top, function (idx, c) {
        var $row = $('<tr></tr>');

        // Vendor name
        $('<td></td>')
            .text(c.vendorName)
            .appendTo($row);

        // Score
        $('<td></td>')
            .text((c.score * 100).toFixed(0) + '%')
            .appendTo($row);

        // Select button (Bootstrap)
        var $btn = $('<button/>', {
            type: 'button',
            class: 'btn btn-primary btn-sm',
            text: 'Select'
        });

        $btn.on('click', function () {
            $('#divAiVendorCandidates').dialog('close');
            ai_applyVendor(c);
        });

        $('<td style="text-align:right;"></td>')
            .append($btn)
            .appendTo($row);

        $tbody.append($row);
    });

    // “None of these” button behaviour
    $('#btnAiVendorNone').off('click').on('click', function () {
        $('#divAiVendorCandidates').dialog('close');
        // user goes back to normal predictive search
    });

    // jQuery UI dialog with Bootstrap content
    $('#divAiVendorCandidates').dialog({
        modal: true,
        width: 600,
        resizable: false,
        draggable: false,
        closeOnEscape: true,
        dialogClass: "bootstrap-dialog-fix",
        buttons: [] // we use the buttons in the markup
    });
}




.bootstrap-dialog-fix .ui-dialog-titlebar {
    padding: 8px 15px;
}

.bootstrap-dialog-fix .ui-dialog-titlebar-close {
    right: 8px;
}
