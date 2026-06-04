codeunit 50501 "IRN Payload Builder"
{
    InherentPermissions = X;
    InherentEntitlements = X;
    procedure BuildInvoicePayload(SalesInvHeader: Record "Sales Invoice Header"): Text
    var
        SalesInvLine: Record "Sales Invoice Line";
        Customer: Record Customer;
        CompanySetup: Record "IRN Company Setup";
        JsonObj: JsonObject;
        LinesArray: JsonArray;
        LineExtAmount: Decimal;
        TaxExclAmount: Decimal;
        TaxInclAmount: Decimal;
    begin
        if Customer.Get(SalesInvHeader."Sell-to Customer No.") then;
        CompanySetup.Get(CompanyName);

        // Header
        JsonObj.Add('document_identifier', BuildDocumentIdentifier(SalesInvHeader."No.", SalesInvHeader."Posting Date"));
        JsonObj.Add('invoice_type', 'STANDARD');
        JsonObj.Add('issue_date', Format(SalesInvHeader."Posting Date", 0, '<Year4>-<Month,2>-<Day,2>'));
        JsonObj.Add('due_date', Format(SalesInvHeader."Due Date", 0, '<Year4>-<Month,2>-<Day,2>'));
        JsonObj.Add('invoice_type_code', '381'); // Commercial Invoice
        JsonObj.Add('document_currency_code', MapCurrencyCode(SalesInvHeader."Currency Code"));
        JsonObj.Add('transaction_category', 'B2B');
        JsonObj.Add('payment_status', 'PAID');
        JsonObj.Add('business_id', CompanySetup."Business ID");
        JsonObj.Add('irn', CompanySetup."IRN Code");

        // Supplier (the company submitting)
        JsonObj.Add('accounting_supplier_party', BuildSupplierParty(CompanySetup));

        // Customer
        JsonObj.Add('accounting_customer_party', BuildCustomerParty(SalesInvHeader, Customer));

        // Lines
        SalesInvLine.SetRange("Document No.", SalesInvHeader."No.");
        SalesInvLine.SetFilter(Type, '<>%1', SalesInvLine.Type::" ");
        SalesInvLine.SetFilter(Quantity, '>0');
        if SalesInvLine.FindSet() then
            repeat
                LinesArray.Add(BuildInvoiceLine(SalesInvLine));
                LineExtAmount += SalesInvLine.Quantity * SalesInvLine."Unit Price";
            until SalesInvLine.Next() = 0;

        JsonObj.Add('invoice_lines', LinesArray);

        // Monetary totals
        TaxExclAmount := SalesInvHeader.Amount;
        TaxInclAmount := SalesInvHeader."Amount Including VAT";
        if LineExtAmount = 0 then
            LineExtAmount := TaxExclAmount;
        JsonObj.Add('legal_monetary_total', BuildMonetaryTotal(LineExtAmount, TaxExclAmount, TaxInclAmount));

        exit(JsonObjectToText(JsonObj));
    end;

    procedure BuildCreditMemoPayload(SalesCrMemoHeader: Record "Sales Cr.Memo Header"): Text
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        Customer: Record Customer;
        CompanySetup: Record "IRN Company Setup";
        JsonObj: JsonObject;
        LinesArray: JsonArray;
        LineExtAmount: Decimal;
        TaxExclAmount: Decimal;
        TaxInclAmount: Decimal;
    begin
        if Customer.Get(SalesCrMemoHeader."Sell-to Customer No.") then;
        CompanySetup.Get(CompanyName);

        // Header
        JsonObj.Add('document_identifier', BuildDocumentIdentifier(SalesCrMemoHeader."No.", SalesCrMemoHeader."Posting Date"));
        JsonObj.Add('invoice_type', 'STANDARD');
        JsonObj.Add('issue_date', Format(SalesCrMemoHeader."Posting Date", 0, '<Year4>-<Month,2>-<Day,2>'));
        JsonObj.Add('due_date', Format(SalesCrMemoHeader."Due Date", 0, '<Year4>-<Month,2>-<Day,2>'));
        JsonObj.Add('invoice_type_code', '380'); // Credit Note
        JsonObj.Add('document_currency_code', MapCurrencyCode(SalesCrMemoHeader."Currency Code"));
        JsonObj.Add('transaction_category', 'B2B');
        JsonObj.Add('payment_status', 'PAID');
        JsonObj.Add('business_id', CompanySetup."Business ID");
        JsonObj.Add('irn', CompanySetup."IRN Code");

        // Supplier (the company submitting)
        JsonObj.Add('accounting_supplier_party', BuildSupplierParty(CompanySetup));

        // Cancel references - required for Credit Notes and Debit Notes
        JsonObj.Add('cancel_references', BuildCancelReferences(SalesCrMemoHeader));

        // Customer
        JsonObj.Add('accounting_customer_party', BuildCrMemoCustomerParty(SalesCrMemoHeader, Customer));

        // Lines
        SalesCrMemoLine.SetRange("Document No.", SalesCrMemoHeader."No.");
        SalesCrMemoLine.SetFilter(Type, '<>%1', SalesCrMemoLine.Type::" ");
        SalesCrMemoLine.SetFilter(Quantity, '>0');
        if SalesCrMemoLine.FindSet() then
            repeat
                LinesArray.Add(BuildCreditMemoLine(SalesCrMemoLine));
                LineExtAmount += SalesCrMemoLine.Quantity * SalesCrMemoLine."Unit Price";
            until SalesCrMemoLine.Next() = 0;

        JsonObj.Add('invoice_lines', LinesArray);

        // Monetary totals
        TaxExclAmount := SalesCrMemoHeader.Amount;
        TaxInclAmount := SalesCrMemoHeader."Amount Including VAT";
        if LineExtAmount = 0 then
            LineExtAmount := TaxExclAmount;
        JsonObj.Add('legal_monetary_total', BuildMonetaryTotal(LineExtAmount, TaxExclAmount, TaxInclAmount));

        exit(JsonObjectToText(JsonObj));
    end;

    local procedure BuildDocumentIdentifier(DocumentNo: Code[20]; PostingDate: Date): Text
    begin
        // Format: {DocumentNo}-{YYYYMMDD}
        // API only allows letters, numbers, and hyphens
        exit(SanitizeDocumentNo(DocumentNo) + '-' + Format(PostingDate, 0, '<Year4><Month,2><Day,2>'));
    end;

    local procedure SanitizeDocumentNo(DocNo: Text): Text
    var
        Result: Text;
        i: Integer;
        Ch: Char;
    begin
        for i := 1 to StrLen(DocNo) do begin
            Ch := DocNo[i];
            case true of
                (Ch >= 'A') and (Ch <= 'Z'),
                (Ch >= 'a') and (Ch <= 'z'),
                (Ch >= '0') and (Ch <= '9'),
                Ch = '-':
                    Result += Format(Ch);
                else
                    Result += '-';
            end;
        end;
        exit(Result);
    end;

    local procedure BuildCustomerParty(SalesInvHeader: Record "Sales Invoice Header"; Customer: Record Customer): JsonObject
    var
        PartyObj: JsonObject;
        AddressObj: JsonObject;
        Email: Text;
        Phone: Text;
        TIN: Text;
        Street: Text;
        City: Text;
        PostCode: Text;
        CountryCode: Text;
    begin
        // Email: Sell-to → Customer card
        Email := ResolveField(SalesInvHeader."Sell-to E-Mail", '', Customer."E-Mail");
        // Phone: Sell-to → Customer card
        Phone := ResolveField(SalesInvHeader."Sell-to Phone No.", '', Customer."Phone No.");
        // TIN: Customer VAT Registration No.
        TIN := Customer."VAT Registration No.";
        // Address: Sell-to → Bill-to → Customer card
        Street := ResolveField(SalesInvHeader."Sell-to Address", SalesInvHeader."Bill-to Address", Customer.Address);
        // City: Sell-to → Bill-to → Customer card
        City := ResolveField(SalesInvHeader."Sell-to City", SalesInvHeader."Bill-to City", Customer.City);
        // Post Code: Sell-to → Bill-to → Customer card
        PostCode := ResolveField(SalesInvHeader."Sell-to Post Code", SalesInvHeader."Bill-to Post Code", Customer."Post Code");
        // Country: Sell-to → Bill-to → Customer card
        CountryCode := ResolveField(SalesInvHeader."Sell-to Country/Region Code", SalesInvHeader."Bill-to Country/Region Code", Customer."Country/Region Code");

        PartyObj.Add('party_name', SalesInvHeader."Sell-to Customer Name");
        PartyObj.Add('email', Email);
        PartyObj.Add('telephone', FormatPhone(Phone));
        PartyObj.Add('tin', TIN);
        PartyObj.Add('business_description', 'Customer');

        AddressObj.Add('street_name', Street);
        AddressObj.Add('city_name', City);
        AddressObj.Add('postal_zone', PostCode);
        AddressObj.Add('country', MapCountryCode(CountryCode));
        PartyObj.Add('postal_address', AddressObj);

        exit(PartyObj);
    end;

    local procedure BuildCrMemoCustomerParty(SalesCrMemoHeader: Record "Sales Cr.Memo Header"; Customer: Record Customer): JsonObject
    var
        PartyObj: JsonObject;
        AddressObj: JsonObject;
        Email: Text;
        Phone: Text;
        TIN: Text;
        Street: Text;
        City: Text;
        PostCode: Text;
        CountryCode: Text;
    begin
        // Email: Sell-to → Customer card
        Email := ResolveField(SalesCrMemoHeader."Sell-to E-Mail", '', Customer."E-Mail");
        // Phone: Sell-to → Customer card
        Phone := ResolveField(SalesCrMemoHeader."Sell-to Phone No.", '', Customer."Phone No.");
        // TIN: Customer VAT Registration No.
        TIN := Customer."VAT Registration No.";
        // Address: Sell-to → Bill-to → Customer card
        Street := ResolveField(SalesCrMemoHeader."Sell-to Address", SalesCrMemoHeader."Bill-to Address", Customer.Address);
        // City: Sell-to → Bill-to → Customer card
        City := ResolveField(SalesCrMemoHeader."Sell-to City", SalesCrMemoHeader."Bill-to City", Customer.City);
        // Post Code: Sell-to → Bill-to → Customer card
        PostCode := ResolveField(SalesCrMemoHeader."Sell-to Post Code", SalesCrMemoHeader."Bill-to Post Code", Customer."Post Code");
        // Country: Sell-to → Bill-to → Customer card
        CountryCode := ResolveField(SalesCrMemoHeader."Sell-to Country/Region Code", SalesCrMemoHeader."Bill-to Country/Region Code", Customer."Country/Region Code");

        PartyObj.Add('party_name', SalesCrMemoHeader."Sell-to Customer Name");
        PartyObj.Add('email', Email);
        PartyObj.Add('telephone', FormatPhone(Phone));
        PartyObj.Add('tin', TIN);
        PartyObj.Add('business_description', 'Customer');

        AddressObj.Add('street_name', Street);
        AddressObj.Add('city_name', City);
        AddressObj.Add('postal_zone', PostCode);
        AddressObj.Add('country', MapCountryCode(CountryCode));
        PartyObj.Add('postal_address', AddressObj);

        exit(PartyObj);
    end;

    local procedure ResolveField(SellToValue: Text; BillToValue: Text; CustomerValue: Text): Text
    begin
        if SellToValue <> '' then
            exit(SellToValue);
        if BillToValue <> '' then
            exit(BillToValue);
        exit(CustomerValue);
    end;

    local procedure BuildSupplierParty(CompanySetup: Record "IRN Company Setup"): JsonObject
    var
        PartyObj: JsonObject;
        AddressObj: JsonObject;
    begin
        PartyObj.Add('party_name', CompanySetup."Entity Name");
        PartyObj.Add('email', CompanySetup.Email);
        PartyObj.Add('telephone', FormatPhone(CompanySetup.Telephone));
        PartyObj.Add('tin', CompanySetup.TIN);
        PartyObj.Add('business_description', CompanySetup."Business Description");

        AddressObj.Add('street_name', CompanySetup."Street Name");
        AddressObj.Add('city_name', CompanySetup."City Name");
        AddressObj.Add('postal_zone', CompanySetup."Postal Zone");
        AddressObj.Add('country', CompanySetup.Country);
        PartyObj.Add('postal_address', AddressObj);

        exit(PartyObj);
    end;

    local procedure BuildMonetaryTotal(LineExtAmount: Decimal; TaxExclAmount: Decimal; TaxInclAmount: Decimal): JsonObject
    var
        TotalObj: JsonObject;
    begin
        TotalObj.Add('line_extension_amount', LineExtAmount);
        TotalObj.Add('tax_exclusive_amount', TaxExclAmount);
        TotalObj.Add('tax_inclusive_amount', TaxInclAmount);
        TotalObj.Add('payable_amount', TaxInclAmount);
        exit(TotalObj);
    end;

    local procedure BuildCancelReferences(SalesCrMemoHeader: Record "Sales Cr.Memo Header"): JsonArray
    var
        SalesInvHeader: Record "Sales Invoice Header";
        CancelRefArray: JsonArray;
        CancelRefObj: JsonObject;
        OriginalInvoiceNo: Code[20];
    begin
        // Find the original invoice referenced by this credit memo
        OriginalInvoiceNo := FindOriginalInvoiceNo(SalesCrMemoHeader);

        if (OriginalInvoiceNo <> '') and SalesInvHeader.Get(OriginalInvoiceNo) then begin
            CancelRefObj.Add('original_irn', SalesInvHeader."IRN No.");
            CancelRefObj.Add('original_issue_date', Format(SalesInvHeader."Posting Date", 0, '<Year4>-<Month,2>-<Day,2>'));
            CancelRefArray.Add(CancelRefObj);
        end;

        exit(CancelRefArray);
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
        // Extract invoice number from comments like "Invoice No. PSALV04225:"
        StartPos := StrPos(UpperCase(Comment), 'INVOICE NO.');
        if StartPos = 0 then
            exit('');

        InvoiceNo := CopyStr(Comment, StartPos + 12); // skip "Invoice No. "
        InvoiceNo := DelChr(InvoiceNo, '>', ': '); // trim trailing colon and spaces
        InvoiceNo := DelChr(InvoiceNo, '<', ' '); // trim leading spaces
        exit(CopyStr(InvoiceNo, 1, 20));
    end;

    local procedure BuildInvoiceLine(SalesInvLine: Record "Sales Invoice Line"): JsonObject
    var
        LineObj: JsonObject;
        DiscountRate: Decimal;
    begin
        LineObj.Add('description', GetNonBlank(SalesInvLine.Description, 'Service'));
        LineObj.Add('invoiced_quantity', SalesInvLine.Quantity);
        LineObj.Add('price_amount', SalesInvLine."Unit Price");
        LineObj.Add('hsn_code', '9820.10'); // Default services HSN
        LineObj.Add('price_unit', 'EA');
        LineObj.Add('product_category', 'General');
        LineObj.Add('tax_rate', SalesInvLine."VAT %");
        LineObj.Add('tax_category_id', GetTaxCategoryId(SalesInvLine."VAT %"));

        if SalesInvLine."Line Discount %" > 0 then
            DiscountRate := SalesInvLine."Line Discount %"
        else
            DiscountRate := 0;
        LineObj.Add('discount_rate', DiscountRate);

        if SalesInvLine."No." <> '' then
            LineObj.Add('internal_id', SalesInvLine."No.");

        exit(LineObj);
    end;

    local procedure BuildCreditMemoLine(SalesCrMemoLine: Record "Sales Cr.Memo Line"): JsonObject
    var
        LineObj: JsonObject;
        DiscountRate: Decimal;
    begin
        LineObj.Add('description', GetNonBlank(SalesCrMemoLine.Description, 'Service'));
        LineObj.Add('invoiced_quantity', SalesCrMemoLine.Quantity);
        LineObj.Add('price_amount', SalesCrMemoLine."Unit Price");
        LineObj.Add('hsn_code', '9820.10');
        LineObj.Add('price_unit', 'EA');
        LineObj.Add('product_category', 'General');
        LineObj.Add('tax_rate', SalesCrMemoLine."VAT %");
        LineObj.Add('tax_category_id', GetTaxCategoryId(SalesCrMemoLine."VAT %"));

        if SalesCrMemoLine."Line Discount %" > 0 then
            DiscountRate := SalesCrMemoLine."Line Discount %"
        else
            DiscountRate := 0;
        LineObj.Add('discount_rate', DiscountRate);

        if SalesCrMemoLine."No." <> '' then
            LineObj.Add('internal_id', SalesCrMemoLine."No.");

        exit(LineObj);
    end;

    local procedure GetTaxCategoryId(VATPercent: Decimal): Text
    begin
        if VATPercent > 0 then
            exit('STANDARD_VAT');
        exit('ZERO_VAT');
    end;

    local procedure MapCurrencyCode(BCCode: Code[10]): Text
    begin
        case UpperCase(BCCode) of
            '', 'NGN', 'NAIRA':
                exit('NGN');
            'USD', 'DOLLAR', 'US DOLLAR':
                exit('USD');
            'GBP', 'POUND':
                exit('GBP');
            'EUR', 'EURO':
                exit('EUR');
            else
                exit(BCCode);
        end;
    end;

    local procedure MapCountryCode(BCCode: Text): Text
    begin
        // Convert 3-letter or full name to ISO 3166-1 alpha-2
        case UpperCase(BCCode) of
            '', 'NG', 'NGA', 'NGR', 'NIGERIA':
                exit('NG');
            'US', 'USA', 'UNITED STATES':
                exit('US');
            'GB', 'GBR', 'UK', 'UNITED KINGDOM':
                exit('GB');
            'GH', 'GHA', 'GHANA':
                exit('GH');
            'ZA', 'ZAF', 'SOUTH AFRICA':
                exit('ZA');
            'CM', 'CMR', 'CAMEROON':
                exit('CM');
            'KE', 'KEN', 'KENYA':
                exit('KE');
            else begin
                // If already 2 chars, use as-is
                if StrLen(BCCode) = 2 then
                    exit(UpperCase(BCCode));
                // Default to NG
                exit('NG');
            end;
        end;
    end;

    local procedure FormatPhone(Phone: Text): Text
    var
        Cleaned: Text;
    begin
        if Phone = '' then
            exit('');

        Cleaned := DelChr(Phone, '=', ' .-()');

        // Already in E.164 format
        if CopyStr(Cleaned, 1, 1) = '+' then
            exit(Cleaned);

        // Already has country code 234 without +
        if CopyStr(Cleaned, 1, 3) = '234' then
            exit('+' + Cleaned);

        // Local Nigerian number starting with 0
        if (CopyStr(Cleaned, 1, 1) = '0') and (StrLen(Cleaned) >= 10) then
            exit('+234' + CopyStr(Cleaned, 2));

        // Short local number without leading 0
        exit('+234' + Cleaned);
    end;

    local procedure GetNonBlank(Value: Text; DefaultValue: Text): Text
    begin
        if Value <> '' then
            exit(Value);
        exit(DefaultValue);
    end;

    local procedure JsonObjectToText(JsonObj: JsonObject): Text
    var
        Result: Text;
    begin
        JsonObj.WriteTo(Result);
        exit(Result);
    end;
}
