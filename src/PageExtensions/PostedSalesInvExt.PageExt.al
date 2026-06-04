pageextension 50500 "Posted Sales Inv. Ext" extends "Posted Sales Invoice"
{
    layout
    {
        addafter("No.")
        {
            field("IRN Status"; Rec."IRN Status")
            {
                ApplicationArea = All;
                ToolTip = 'Shows the IRN submission status.';
                StyleExpr = IRNStatusStyle;
            }
            field("IRN No."; Rec."IRN No.")
            {
                ApplicationArea = All;
                ToolTip = 'The Invoice Reference Number from NRS.';
            }
        }
        addlast(General)
        {
            group(IRNGroup)
            {
                Caption = 'NRS E-Invoicing';
                Visible = true;

                field("IRN No.2"; Rec."IRN No.")
                {
                    ApplicationArea = All;
                    Caption = 'IRN';
                    ToolTip = 'Invoice Reference Number.';
                    Editable = false;
                }
                field("IRN QR Code URL"; Rec."IRN QR Code URL")
                {
                    ApplicationArea = All;
                    ToolTip = 'QR code URL from NRS.';
                    Editable = false;
                }
                field("IRN Submitted At"; Rec."IRN Submitted At")
                {
                    ApplicationArea = All;
                    ToolTip = 'Date and time of last submission.';
                    Editable = false;
                }
                field("IRN Submitted By"; Rec."IRN Submitted By")
                {
                    ApplicationArea = All;
                    ToolTip = 'User who submitted.';
                    Editable = false;
                }
                field("IRN Last Error"; Rec."IRN Last Error")
                {
                    ApplicationArea = All;
                    ToolTip = 'Last error message from submission.';
                    Editable = false;
                    Style = Attention;
                }
            }
        }
    }

    actions
    {
        addlast(Processing)
        {
            action(PrintIRNInvoice)
            {
                ApplicationArea = All;
                Caption = 'Print IRN Invoice';
                ToolTip = 'Print the sales invoice with IRN and QR code.';
                Image = Print;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                var
                    SalesInvHeader: Record "Sales Invoice Header";
                begin
                    SalesInvHeader := Rec;
                    SalesInvHeader.SetRecFilter();
                    Report.Run(Report::"IRN Sales Invoice", true, false, SalesInvHeader);
                end;
            }
            action(SubmitIRN)
            {
                ApplicationArea = All;
                Caption = 'Submit to NRS';
                ToolTip = 'Submit this invoice to Nigeria Revenue Service for IRN generation.';
                Image = SendElectronicDocument;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                var
                    IRNMgmt: Codeunit "IRN Management";
                begin
                    if not Confirm('Submit invoice %1 to NRS?', false, Rec."No.") then
                        exit;
                    IRNMgmt.SubmitPostedSalesInvoice(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(CancelIRN)
            {
                ApplicationArea = All;
                Caption = 'Cancel on NRS';
                ToolTip = 'Cancel this invoice on the Nigeria Revenue Service.';
                Image = Cancel;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Enabled = Rec."IRN Status" = Rec."IRN Status"::Success;

                trigger OnAction()
                var
                    IRNMgmt: Codeunit "IRN Management";
                begin
                    if not Confirm('Are you sure you want to cancel invoice %1 on NRS?\IRN: %2\\\This action cannot be undone.', false, Rec."No.", Rec."IRN No.") then
                        exit;
                    IRNMgmt.CancelPostedSalesInvoice(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(SeeRequest)
            {
                ApplicationArea = All;
                Caption = 'See Request';
                ToolTip = 'View the JSON payload that was sent to the API.';
                Image = XMLFile;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    LogEntry: Record "IRN Document Log";
                    JsonViewer: Page "IRN JSON Viewer";
                    JsonText: Text;
                begin
                    LogEntry.SetRange("Document Type", LogEntry."Document Type"::SalesInvoice);
                    LogEntry.SetRange("Document No.", Rec."No.");
                    if LogEntry.FindLast() then begin
                        JsonText := LogEntry.GetRequestJSON();
                        if JsonText <> '' then begin
                            JsonViewer.SetData('Request Payload - ' + Rec."No.", JsonText);
                            JsonViewer.RunModal();
                        end else
                            Message('No request payload found. Submit the invoice first.');
                    end else
                        Message('No submission log found for this invoice. Submit it first.');
                end;
            }
            action(SeeResponse)
            {
                ApplicationArea = All;
                Caption = 'See Response';
                ToolTip = 'View the JSON response received from the API.';
                Image = XMLFile;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    LogEntry: Record "IRN Document Log";
                    JsonViewer: Page "IRN JSON Viewer";
                    JsonText: Text;
                begin
                    LogEntry.SetRange("Document Type", LogEntry."Document Type"::SalesInvoice);
                    LogEntry.SetRange("Document No.", Rec."No.");
                    if LogEntry.FindLast() then begin
                        JsonText := LogEntry.GetResponseJSON();
                        if JsonText <> '' then begin
                            JsonViewer.SetData('API Response - ' + Rec."No.", JsonText);
                            JsonViewer.RunModal();
                        end else
                            Message('No response payload found.');
                    end else
                        Message('No submission log found for this invoice. Submit it first.');
                end;
            }
            action(ViewIRNLog)
            {
                ApplicationArea = All;
                Caption = 'IRN Log';
                ToolTip = 'View submission log for this document.';
                Image = Log;
                RunObject = page "IRN Document Log List";
                RunPageLink = "Document No." = field("No."), "Document Type" = const(SalesInvoice);
            }
        }
    }

    var
        IRNStatusStyle: Text;

    trigger OnAfterGetRecord()
    begin
        case Rec."IRN Status" of
            Rec."IRN Status"::Success:
                IRNStatusStyle := 'Favorable';
            Rec."IRN Status"::Failed:
                IRNStatusStyle := 'Unfavorable';
            Rec."IRN Status"::Submitted:
                IRNStatusStyle := 'Ambiguous';
            Rec."IRN Status"::Cancelled:
                IRNStatusStyle := 'AttentionAccent';
            else
                IRNStatusStyle := 'Standard';
        end;
    end;
}
