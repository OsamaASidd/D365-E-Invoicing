codeunit 50500 "IRN Validation"
{
    InherentPermissions = X;
    InherentEntitlements = X;
    Permissions = tabledata "IRN Setup" = R,
                  tabledata "IRN Company Setup" = R,
                  tabledata "Sales Invoice Header" = R,
                  tabledata "Cust. Ledger Entry" = R,
                  tabledata "Sales Cr.Memo Line" = R,
                  tabledata Customer = R;

    procedure ValidateSetup()
    var
        IRNSetup: Record "IRN Setup";
        CompanySetup: Record "IRN Company Setup";
        HasCompanyKey: Boolean;
    begin
        IRNSetup.GetSetup();
        if not IRNSetup.Enabled then
            Error('IRN e-invoicing is not enabled. Open IRN Setup to enable it.');

        if IRNSetup.GetActiveBaseURL() = '' then
            Error('IRN Setup: Base URL is not configured.');

        if IRNSetup."API Key Header Name" = '' then
            Error('IRN Setup: API Key Header Name is required.');

        // Check if company-specific API key exists
        HasCompanyKey := false;
        if CompanySetup.Get(CompanyName) then
            if CompanySetup.Enabled then
                HasCompanyKey := CompanySetup.GetActiveAPIKey(IRNSetup."Use Test Mode") <> '';

        // If no company key, check global key
        if not HasCompanyKey then begin
            if IRNSetup."Authorization Type" = IRNSetup."Authorization Type"::APIKey then begin
                if IRNSetup."API Key" = '' then
                    Error('No API key found. Configure a company API key in IRN Setup > Company API Keys for "%1", or set a global API key.', CompanyName);
            end;
            if IRNSetup."Authorization Type" = IRNSetup."Authorization Type"::Bearer then
                if IRNSetup."Bearer Token" = '' then
                    Error('IRN Setup: Bearer Token is required when using Bearer authentication.');
        end;
    end;

    procedure ValidatePostedSalesInvoice(SalesInvHeader: Record "Sales Invoice Header")
    var
        IRNSetup: Record "IRN Setup";
        Customer: Record Customer;
    begin
        ValidateSetup();

        if not IsCorrectiveInvoice(SalesInvHeader) then
            Error('Only corrective invoices can be submitted to NRS. Document %1 is not corrective.', SalesInvHeader."No.");

        IRNSetup.GetSetup();
        if (SalesInvHeader."IRN Status" = SalesInvHeader."IRN Status"::Success) and
           (not IRNSetup."Allow Resubmit Success") then
            Error('Invoice %1 has already been submitted successfully (IRN: %2). Enable "Allow Resubmit Successful" in IRN Setup to resubmit.',
                SalesInvHeader."No.", SalesInvHeader."IRN No.");

        if SalesInvHeader."Sell-to Customer No." = '' then
            Error('Invoice %1: Customer No. is required.', SalesInvHeader."No.");

        if SalesInvHeader."Posting Date" = 0D then
            Error('Invoice %1: Posting Date is required.', SalesInvHeader."No.");

        // Validate customer data required by NRS
        if Customer.Get(SalesInvHeader."Sell-to Customer No.") then;
        ValidateCustomerDataForInvoice(SalesInvHeader, Customer);
    end;

    procedure ValidatePostedSalesCrMemo(SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        IRNSetup: Record "IRN Setup";
        SalesInvHeader: Record "Sales Invoice Header";
        Customer: Record Customer;
        OriginalInvoiceNo: Code[20];
    begin
        ValidateSetup();

        IRNSetup.GetSetup();
        if (SalesCrMemoHeader."IRN Status" = SalesCrMemoHeader."IRN Status"::Success) and
           (not IRNSetup."Allow Resubmit Success") then
            Error('Credit Memo %1 has already been submitted successfully (IRN: %2). Enable "Allow Resubmit Successful" in IRN Setup to resubmit.',
                SalesCrMemoHeader."No.", SalesCrMemoHeader."IRN No.");

        if SalesCrMemoHeader."Sell-to Customer No." = '' then
            Error('Credit Memo %1: Customer No. is required.', SalesCrMemoHeader."No.");

        if SalesCrMemoHeader."Posting Date" = 0D then
            Error('Credit Memo %1: Posting Date is required.', SalesCrMemoHeader."No.");

        // Validate customer data required by NRS
        if Customer.Get(SalesCrMemoHeader."Sell-to Customer No.") then;
        ValidateCustomerDataForCrMemo(SalesCrMemoHeader, Customer);

        // Validate original invoice reference for cancel_references
        OriginalInvoiceNo := FindOriginalInvoiceNo(SalesCrMemoHeader);
        if OriginalInvoiceNo = '' then
            Error('Credit Memo %1: Cannot find the original invoice reference. The credit memo must be linked to a posted sales invoice (via "Applies-to Doc. No." or comment lines) for NRS submission.',
                SalesCrMemoHeader."No.");

        if not SalesInvHeader.Get(OriginalInvoiceNo) then
            Error('Credit Memo %1: Original invoice %2 not found in posted sales invoices.',
                SalesCrMemoHeader."No.", OriginalInvoiceNo);

        if SalesInvHeader."IRN No." = '' then
            Error('Credit Memo %1: Original invoice %2 does not have an IRN. Submit the original invoice to NRS first before submitting the credit memo.',
                SalesCrMemoHeader."No.", OriginalInvoiceNo);
    end;

    local procedure FindOriginalInvoiceNo(SalesCrMemoHeader: Record "Sales Cr.Memo Header"): Code[20]
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
    begin
        // Method 1: Check "Applies-to Doc. No." on the header
        if SalesCrMemoHeader."Applies-to Doc. No." <> '' then
            exit(SalesCrMemoHeader."Applies-to Doc. No.");

        // Method 2: Look for the original invoice via Customer Ledger Entries
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::"Credit Memo");
        CustLedgerEntry.SetRange("Document No.", SalesCrMemoHeader."No.");
        if CustLedgerEntry.FindFirst() then begin
            CustLedgerEntry.SetRange("Closed by Entry No.", CustLedgerEntry."Entry No.");
            CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
            if CustLedgerEntry.FindFirst() then
                exit(CustLedgerEntry."Document No.");
        end;

        // Method 3: Check comment lines for invoice reference (e.g. "Invoice No. PSALV04225:")
        SalesCrMemoLine.SetRange("Document No.", SalesCrMemoHeader."No.");
        SalesCrMemoLine.SetRange(Type, SalesCrMemoLine.Type::" ");
        if SalesCrMemoLine.FindSet() then
            repeat
                if StrPos(UpperCase(SalesCrMemoLine.Description), 'INVOICE NO.') > 0 then
                    exit(ExtractInvoiceNoFromComment(SalesCrMemoLine.Description));
            until SalesCrMemoLine.Next() = 0;

        exit('');
    end;

    local procedure ExtractInvoiceNoFromComment(Comment: Text): Code[20]
    var
        StartPos: Integer;
        InvoiceNo: Text;
    begin
        StartPos := StrPos(UpperCase(Comment), 'INVOICE NO.');
        if StartPos = 0 then
            exit('');

        InvoiceNo := CopyStr(Comment, StartPos + 12);
        InvoiceNo := DelChr(InvoiceNo, '>', ': ');
        InvoiceNo := DelChr(InvoiceNo, '<', ' ');
        exit(CopyStr(InvoiceNo, 1, 20));
    end;

    local procedure ValidateCustomerDataForInvoice(SalesInvHeader: Record "Sales Invoice Header"; Customer: Record Customer)
    var
        DocNo: Code[20];
    begin
        DocNo := SalesInvHeader."No.";

        if ResolveField(SalesInvHeader."Sell-to E-Mail", '', Customer."E-Mail") = '' then
            Error('Invoice %1: Customer email is required for NRS submission. Update the email on the Customer Card for %2 (%3).',
                DocNo, SalesInvHeader."Sell-to Customer Name", SalesInvHeader."Sell-to Customer No.");

        if ResolveField(SalesInvHeader."Sell-to Phone No.", '', Customer."Phone No.") = '' then
            Error('Invoice %1: Customer phone number is required for NRS submission. Update the phone on the Customer Card for %2 (%3).',
                DocNo, SalesInvHeader."Sell-to Customer Name", SalesInvHeader."Sell-to Customer No.");

        if Customer."VAT Registration No." = '' then
            Error('Invoice %1: Customer TIN (VAT Registration No.) is required for NRS submission. Update the VAT Registration No. on the Customer Card for %2 (%3).',
                DocNo, SalesInvHeader."Sell-to Customer Name", SalesInvHeader."Sell-to Customer No.");

        if ResolveField(SalesInvHeader."Sell-to Address", SalesInvHeader."Bill-to Address", Customer.Address) = '' then
            Error('Invoice %1: Customer address is required for NRS submission. Update the address on the Customer Card for %2 (%3).',
                DocNo, SalesInvHeader."Sell-to Customer Name", SalesInvHeader."Sell-to Customer No.");

        if ResolveField(SalesInvHeader."Sell-to City", SalesInvHeader."Bill-to City", Customer.City) = '' then
            Error('Invoice %1: Customer city is required for NRS submission. Update the city on the Customer Card for %2 (%3).',
                DocNo, SalesInvHeader."Sell-to Customer Name", SalesInvHeader."Sell-to Customer No.");

        if ResolveField(SalesInvHeader."Sell-to Post Code", SalesInvHeader."Bill-to Post Code", Customer."Post Code") = '' then
            Error('Invoice %1: Customer post code is required for NRS submission. Update the Post Code on the Customer Card for %2 (%3).',
                DocNo, SalesInvHeader."Sell-to Customer Name", SalesInvHeader."Sell-to Customer No.");
    end;

    local procedure ValidateCustomerDataForCrMemo(SalesCrMemoHeader: Record "Sales Cr.Memo Header"; Customer: Record Customer)
    var
        DocNo: Code[20];
    begin
        DocNo := SalesCrMemoHeader."No.";

        if ResolveField(SalesCrMemoHeader."Sell-to E-Mail", '', Customer."E-Mail") = '' then
            Error('Credit Memo %1: Customer email is required for NRS submission. Update the email on the Customer Card for %2 (%3).',
                DocNo, SalesCrMemoHeader."Sell-to Customer Name", SalesCrMemoHeader."Sell-to Customer No.");

        if ResolveField(SalesCrMemoHeader."Sell-to Phone No.", '', Customer."Phone No.") = '' then
            Error('Credit Memo %1: Customer phone number is required for NRS submission. Update the phone on the Customer Card for %2 (%3).',
                DocNo, SalesCrMemoHeader."Sell-to Customer Name", SalesCrMemoHeader."Sell-to Customer No.");

        if Customer."VAT Registration No." = '' then
            Error('Credit Memo %1: Customer TIN (VAT Registration No.) is required for NRS submission. Update the VAT Registration No. on the Customer Card for %2 (%3).',
                DocNo, SalesCrMemoHeader."Sell-to Customer Name", SalesCrMemoHeader."Sell-to Customer No.");

        if ResolveField(SalesCrMemoHeader."Sell-to Address", SalesCrMemoHeader."Bill-to Address", Customer.Address) = '' then
            Error('Credit Memo %1: Customer address is required for NRS submission. Update the address on the Customer Card for %2 (%3).',
                DocNo, SalesCrMemoHeader."Sell-to Customer Name", SalesCrMemoHeader."Sell-to Customer No.");

        if ResolveField(SalesCrMemoHeader."Sell-to City", SalesCrMemoHeader."Bill-to City", Customer.City) = '' then
            Error('Credit Memo %1: Customer city is required for NRS submission. Update the city on the Customer Card for %2 (%3).',
                DocNo, SalesCrMemoHeader."Sell-to Customer Name", SalesCrMemoHeader."Sell-to Customer No.");

        if ResolveField(SalesCrMemoHeader."Sell-to Post Code", SalesCrMemoHeader."Bill-to Post Code", Customer."Post Code") = '' then
            Error('Credit Memo %1: Customer post code is required for NRS submission. Update the Post Code on the Customer Card for %2 (%3).',
                DocNo, SalesCrMemoHeader."Sell-to Customer Name", SalesCrMemoHeader."Sell-to Customer No.");
    end;

    local procedure ResolveField(SellToValue: Text; BillToValue: Text; CustomerValue: Text): Text
    begin
        if SellToValue <> '' then
            exit(SellToValue);
        if BillToValue <> '' then
            exit(BillToValue);
        exit(CustomerValue);
    end;

    procedure IsCorrectiveInvoice(SalesInvHeader: Record "Sales Invoice Header"): Boolean
    begin
        // Corrective invoices have status = 'Corrective' in D365
        // For BC, a corrective invoice is one that references a previous invoice
        // or has the "Corrective" flag. For now, treat all posted invoices as eligible.
        exit(true);
    end;
}
