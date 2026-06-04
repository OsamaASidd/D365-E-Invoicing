pageextension 50503 "Posted Sales CrMemo List Ext" extends "Posted Sales Credit Memos"
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
                ToolTip = 'Submit all selected credit memos to Nigeria Revenue Service for IRN generation.';
                Image = SendElectronicDocument;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                var
                    SelectedCreditMemos: Record "Sales Cr.Memo Header";
                    IRNMgmt: Codeunit "IRN Management";
                begin
                    CurrPage.SetSelectionFilter(SelectedCreditMemos);
                    IRNMgmt.BulkSubmitPostedSalesCreditMemos(SelectedCreditMemos);
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
