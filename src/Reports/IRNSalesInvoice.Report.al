report 50500 "IRN Sales Invoice"
{
    Caption = 'IRN Sales Invoice';
    DefaultRenderingLayout = IRNInvoiceRDLC;
    PreviewMode = PrintLayout;
    InherentPermissions = X;
    InherentEntitlements = X;

    dataset
    {
        dataitem(Header; "Sales Invoice Header")
        {
            RequestFilterFields = "No.", "Posting Date";

            column(No_; "No.") { }
            column(Posting_Date; "Posting Date") { }
            column(Due_Date; "Due Date") { }
            column(Document_Date; "Document Date") { }
            column(Currency_Code; "Currency Code") { }
            column(Sell_to_Customer_No_; "Sell-to Customer No.") { }
            column(Sell_to_Customer_Name; "Sell-to Customer Name") { }
            column(Sell_to_Address; "Sell-to Address") { }
            column(Sell_to_City; "Sell-to City") { }
            column(Sell_to_Post_Code; "Sell-to Post Code") { }
            column(Sell_to_Country_Region_Code; "Sell-to Country/Region Code") { }
            column(Bill_to_Name; "Bill-to Name") { }
            column(Bill_to_Address; "Bill-to Address") { }
            column(Bill_to_City; "Bill-to City") { }
            column(External_Document_No_; "External Document No.") { }
            column(IRN_Status; "IRN Status") { }
            column(IRN_No_; "IRN No.") { }
            column(IRN_QR_Code_URL; "IRN QR Code URL") { }
            column(IRN_QR_Image; "IRN QR Image") { }
            column(IRN_Submitted_At; "IRN Submitted At") { }
            column(CompanyName; CompanyInfo.Name) { }
            column(CompanyAddress; CompanyInfo.Address) { }
            column(CompanyCity; CompanyInfo.City) { }
            column(CompanyPhone; CompanyInfo."Phone No.") { }
            column(CompanyEmail; CompanyInfo."E-Mail") { }
            column(CompanyPicture; CompanyInfo.Picture) { }
            column(CompanyVATRegNo; CompanyInfo."VAT Registration No.") { }
            column(CompanyHomePage; CompanyInfo."Home Page") { }
            column(Header_Amount; Amount) { }
            column(Header_Amount_Including_VAT; "Amount Including VAT") { }

            dataitem(Line; "Sales Invoice Line")
            {
                DataItemLink = "Document No." = field("No.");
                DataItemTableView = sorting("Document No.", "Line No.");

                column(Line_No_; "Line No.") { }
                column(Type_Line; Type) { }
                column(No_Line; "No.") { }
                column(Description_Line; Description) { }
                column(Quantity_Line; Quantity) { }
                column(Unit_of_Measure_Code; "Unit of Measure Code") { }
                column(Unit_Price; "Unit Price") { }
                column(Line_Discount_Pct; "Line Discount %") { }
                column(Line_Amount; "Line Amount") { }
                column(Amount_Including_VAT; "Amount Including VAT") { }
                column(VAT_Pct; "VAT %") { }
            }

            trigger OnAfterGetRecord()
            begin
                CalcFields("IRN QR Image");
            end;
        }
    }

    rendering
    {
        layout(IRNInvoiceRDLC)
        {
            Type = RDLC;
            LayoutFile = 'src/Reports/IRNSalesInvoice.rdl';
            Caption = 'IRN Sales Invoice (RDLC)';
        }
    }

    trigger OnPreReport()
    begin
        CompanyInfo.Get();
        CompanyInfo.CalcFields(Picture);
    end;

    var
        CompanyInfo: Record "Company Information";
}
