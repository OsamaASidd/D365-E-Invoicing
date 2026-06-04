page 50500 "IRN Setup"
{
    Caption = 'IRN E-Invoicing Setup';
    PageType = Card;
    SourceTable = "IRN Setup";
    UsageCategory = Administration;
    ApplicationArea = All;
    InsertAllowed = false;
    DeleteAllowed = false;
    InherentPermissions = X;
    InherentEntitlements = X;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = All;
                    ToolTip = 'Enable or disable IRN e-invoicing submission.';
                }
                field("Use Test Mode"; Rec."Use Test Mode")
                {
                    ApplicationArea = All;
                    ToolTip = 'Use pre-production endpoint for testing.';
                }
            }
            group(Endpoint)
            {
                Caption = 'Endpoint Configuration';

                field("Base URL"; Rec."Base URL")
                {
                    ApplicationArea = All;
                    ToolTip = 'Production API base URL (e.g. https://api.cryptwaresystemsltd.com).';
                }
                field("Test Base URL"; Rec."Test Base URL")
                {
                    ApplicationArea = All;
                    ToolTip = 'Pre-production API base URL (e.g. https://preprod-api.cryptwaresystemsltd.com).';
                }
                field("Timeout (ms)"; Rec."Timeout (ms)")
                {
                    ApplicationArea = All;
                    ToolTip = 'HTTP request timeout in milliseconds.';
                }
            }
            group(Authentication)
            {
                Caption = 'Authentication';

                field("Authorization Type"; Rec."Authorization Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Authentication method for the API.';
                }
                field("API Key Header Name"; Rec."API Key Header Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'HTTP header name for API key (default: x-api-key).';
                    Enabled = Rec."Authorization Type" = Rec."Authorization Type"::APIKey;
                }
                field("API Key"; Rec."API Key")
                {
                    ApplicationArea = All;
                    ToolTip = 'API key value.';
                    Enabled = Rec."Authorization Type" = Rec."Authorization Type"::APIKey;
                }
                field("Bearer Token"; Rec."Bearer Token")
                {
                    ApplicationArea = All;
                    ToolTip = 'Bearer token value.';
                    Enabled = Rec."Authorization Type" = Rec."Authorization Type"::Bearer;
                }
            }
            group(Options)
            {
                Caption = 'Options';

                field("Allow Resubmit Success"; Rec."Allow Resubmit Success")
                {
                    ApplicationArea = All;
                    ToolTip = 'Allow resubmitting documents that already have a successful IRN.';
                }
                field("Log Request Payload"; Rec."Log Request Payload")
                {
                    ApplicationArea = All;
                    ToolTip = 'Store full request JSON in the log.';
                }
                field("Log Response Payload"; Rec."Log Response Payload")
                {
                    ApplicationArea = All;
                    ToolTip = 'Store full response JSON in the log.';
                }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(CompanySetup)
            {
                ApplicationArea = All;
                Caption = 'Company API Keys';
                ToolTip = 'Configure API keys for each entity/company.';
                Image = Company;
                RunObject = page "IRN Company Setup List";
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
            }
            action(ViewLog)
            {
                ApplicationArea = All;
                Caption = 'Submission Log';
                ToolTip = 'View all IRN submission logs.';
                Image = Log;
                RunObject = page "IRN Document Log List";
                Promoted = true;
                PromotedCategory = Process;
            }
        }
    }

    trigger OnOpenPage()
    begin
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Enabled := true;
            Rec."API Key Header Name" := 'x-api-key';
            Rec."Timeout (ms)" := 30000;
            Rec."Log Request Payload" := true;
            Rec."Log Response Payload" := true;
            Rec."Use Test Mode" := true;
            Rec."Base URL" := 'https://api.cryptwaresystemsltd.com';
            Rec."Test Base URL" := 'https://preprod-api.cryptwaresystemsltd.com';
            Rec."Authorization Type" := Rec."Authorization Type"::APIKey;
            Rec.Insert();
        end;
    end;
}
