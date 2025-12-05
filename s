 var prefillDone = $('#<%= hdnAiPrefillDone.ClientID %>').val() === 'true';
        var vendorEmpty = ai_isVendorEmpty();

        if (!vendorEmpty) {
            // Vendor is already valid (maybe after CheckValidVendor postback)
            if (!prefillDone) {
                ai_prefillInvoiceFields();
                $('#<%= hdnAiPrefillDone.ClientID %>').val('true');
            }
        } else {
            // Vendor empty: first time we land here → try AI vendor selection
            if (!prefillDone) {
                ai_tryVendorSelectionFlow();  // may call ai_applyVendor -> CheckValidVendor -> postback
                // We don't set prefillDone here; we only mark done after actual prefill
            }
        }
