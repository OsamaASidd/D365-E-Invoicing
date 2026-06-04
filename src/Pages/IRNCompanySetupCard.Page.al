page 50504 "IRN Company Setup Card"
{
    Caption = 'IRN Company Setup';
    PageType = Card;
    SourceTable = "IRN Company Setup";
    ApplicationArea = All;
    InherentPermissions = X;
    InherentEntitlements = X;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field("Company Name"; Rec."Company Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'The Business Central company name. Must match exactly what appears in BC.';
                }
                field("Entity Name"; Rec."Entity Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Legal entity name for NRS.';
                }
                field(TIN; Rec.TIN)
                {
                    ApplicationArea = All;
                    ToolTip = 'Tax Identification Number.';
                }
                field("Business ID"; Rec."Business ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Cryptware Business ID.';
                }
                field("IRN Code"; Rec."IRN Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'IRN template code (e.g. 86CE9399).';
                }
                field(Representative; Rec.Representative)
                {
                    ApplicationArea = All;
                }
                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = All;
                }
            }
            group(APIKeys)
            {
                Caption = 'API Keys';

                field("Preprod API Key"; Rec."Preprod API Key")
                {
                    ApplicationArea = All;
                    ToolTip = 'Pre-production x-api-key for testing.';
                }
                field("Live API Key"; Rec."Live API Key")
                {
                    ApplicationArea = All;
                    ToolTip = 'Production x-api-key for live NRS submission.';
                }
            }
            group(Contact)
            {
                Caption = 'Contact & Address';

                field(Email; Rec.Email)
                {
                    ApplicationArea = All;
                }
                field(Telephone; Rec.Telephone)
                {
                    ApplicationArea = All;
                }
                field("Street Name"; Rec."Street Name")
                {
                    ApplicationArea = All;
                }
                field("City Name"; Rec."City Name")
                {
                    ApplicationArea = All;
                }
                field("Postal Zone"; Rec."Postal Zone")
                {
                    ApplicationArea = All;
                }
                field(Country; Rec.Country)
                {
                    ApplicationArea = All;
                }
                field("Business Description"; Rec."Business Description")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}
