table 50500 "IRN Setup"
{
    Caption = 'IRN Setup';
    DataClassification = CustomerContent;
    InherentPermissions = RIMD;
    InherentEntitlements = RIMD;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; Enabled; Boolean)
        {
            Caption = 'Enabled';
        }
        field(3; "Base URL"; Text[250])
        {
            Caption = 'Base URL';
            ExtendedDatatype = URL;
        }
        field(4; "Authorization Type"; Enum "IRN Authorization Type")
        {
            Caption = 'Authorization Type';
        }
        field(5; "API Key"; Text[250])
        {
            Caption = 'API Key';
            ExtendedDatatype = Masked;
        }
        field(6; "API Key Header Name"; Text[50])
        {
            Caption = 'API Key Header Name';
            InitValue = 'x-api-key';
        }
        field(7; "Bearer Token"; Text[500])
        {
            Caption = 'Bearer Token';
            ExtendedDatatype = Masked;
        }
        field(8; "Timeout (ms)"; Integer)
        {
            Caption = 'Timeout (ms)';
            InitValue = 30000;
            MinValue = 5000;
            MaxValue = 120000;
        }
        field(9; "Log Request Payload"; Boolean)
        {
            Caption = 'Log Request Payload';
            InitValue = true;
        }
        field(10; "Log Response Payload"; Boolean)
        {
            Caption = 'Log Response Payload';
            InitValue = true;
        }
        field(11; "Allow Resubmit Success"; Boolean)
        {
            Caption = 'Allow Resubmit Successful';
        }
        field(12; "Use Test Mode"; Boolean)
        {
            Caption = 'Use Pre-Production';
            InitValue = true;
        }
        field(13; "Test Base URL"; Text[250])
        {
            Caption = 'Pre-Production Base URL';
            ExtendedDatatype = URL;
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }

    procedure GetSetup()
    begin
        if not Get() then
            Error('IRN Setup has not been initialized. Please run the extension install or contact your administrator.');
    end;

    procedure GetActiveBaseURL(): Text[250]
    begin
        GetSetup();
        if "Use Test Mode" and ("Test Base URL" <> '') then
            exit("Test Base URL");
        exit("Base URL");
    end;
}
