page 50502 "IRN Log Payload FactBox"
{
    Caption = 'Payload Details';
    PageType = CardPart;
    SourceTable = "IRN Document Log";

    layout
    {
        area(Content)
        {
            field("Cryptware Invoice Id"; Rec."Cryptware Invoice Id")
            {
                ApplicationArea = All;
                Caption = 'Cryptware ID';
            }
            field("Ack No."; Rec."Ack No.")
            {
                ApplicationArea = All;
            }
            field(RequestJSON; RequestText)
            {
                ApplicationArea = All;
                Caption = 'Request JSON';
                MultiLine = true;
            }
            field(ResponseJSON; ResponseText)
            {
                ApplicationArea = All;
                Caption = 'Response JSON';
                MultiLine = true;
            }
        }
    }

    var
        RequestText: Text;
        ResponseText: Text;

    trigger OnAfterGetRecord()
    begin
        RequestText := Rec.GetRequestJSON();
        ResponseText := Rec.GetResponseJSON();
    end;
}
