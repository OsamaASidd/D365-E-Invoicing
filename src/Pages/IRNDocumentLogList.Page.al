page 50501 "IRN Document Log List"
{
    Caption = 'IRN Document Log';
    PageType = List;
    SourceTable = "IRN Document Log";
    ApplicationArea = All;
    UsageCategory = History;
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = All;
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = All;
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = All;
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = All;
                }
                field("Customer Name"; Rec."Customer Name")
                {
                    ApplicationArea = All;
                }
                field("IRN Status"; Rec."IRN Status")
                {
                    ApplicationArea = All;
                    StyleExpr = StatusStyle;
                }
                field(IRN; Rec.IRN)
                {
                    ApplicationArea = All;
                }
                field("QR Code URL"; Rec."QR Code URL")
                {
                    ApplicationArea = All;
                }
                field("HTTP Status Code"; Rec."HTTP Status Code")
                {
                    ApplicationArea = All;
                }
                field("Error Message"; Rec."Error Message")
                {
                    ApplicationArea = All;
                }
                field("Created At"; Rec."Created At")
                {
                    ApplicationArea = All;
                }
                field("Created By"; Rec."Created By")
                {
                    ApplicationArea = All;
                }
            }
        }
        area(FactBoxes)
        {
            part(RequestPayload; "IRN Log Payload FactBox")
            {
                ApplicationArea = All;
                SubPageLink = "Entry No." = field("Entry No.");
                Caption = 'Request/Response';
            }
        }
    }

    var
        StatusStyle: Text;

    trigger OnAfterGetRecord()
    begin
        case Rec."IRN Status" of
            Rec."IRN Status"::Success:
                StatusStyle := 'Favorable';
            Rec."IRN Status"::Failed:
                StatusStyle := 'Unfavorable';
            else
                StatusStyle := 'Standard';
        end;
    end;
}
