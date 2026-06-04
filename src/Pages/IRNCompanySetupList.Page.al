page 50503 "IRN Company Setup List"
{
    Caption = 'IRN Company Setup';
    PageType = List;
    SourceTable = "IRN Company Setup";
    ApplicationArea = All;
    UsageCategory = Administration;
    InherentPermissions = X;
    InherentEntitlements = X;
    CardPageId = "IRN Company Setup Card";

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Company Name"; Rec."Company Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'The Business Central company name (must match exactly).';
                }
                field("Entity Name"; Rec."Entity Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'The legal entity name for NRS submission.';
                }
                field(TIN; Rec.TIN)
                {
                    ApplicationArea = All;
                }
                field("IRN Code"; Rec."IRN Code")
                {
                    ApplicationArea = All;
                }
                field(Representative; Rec.Representative)
                {
                    ApplicationArea = All;
                }
                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = All;
                }
                field("Business ID"; Rec."Business ID")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}
