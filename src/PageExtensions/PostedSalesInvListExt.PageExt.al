pageextension 50502 "Posted Sales Inv. List Ext" extends "Posted Sales Invoices"
{
    layout
    {
        addafter("Amount Including VAT")
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
    }

    actions
    {
        addlast(Processing)
        {
            action(SubmitSelectedToNRS)
            {
                ApplicationArea = All;
                Caption = 'Submit Selected to NRS';
                ToolTip = 'Submit all selected invoices to Nigeria Revenue Service for IRN generation.';
                Image = SendElectronicDocument;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                var
                    SelectedInvoices: Record "Sales Invoice Header";
                    IRNMgmt: Codeunit "IRN Management";
                begin
                    CurrPage.SetSelectionFilter(SelectedInvoices);
                    IRNMgmt.BulkSubmitPostedSalesInvoices(SelectedInvoices);
                    CurrPage.Update(false);
                end;
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
            else
                IRNStatusStyle := 'Standard';
        end;
    end;
}
