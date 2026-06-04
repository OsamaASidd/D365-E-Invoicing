table 50502 "IRN Company Setup"
{
    Caption = 'IRN Company Setup';
    DataClassification = CustomerContent;
    InherentPermissions = RIMD;
    InherentEntitlements = RIMD;

    fields
    {
        field(1; "Company Name"; Text[100])
        {
            Caption = 'BC Company Name';
            NotBlank = true;
        }
        field(2; "Entity Name"; Text[150])
        {
            Caption = 'Entity Name';
        }
        field(3; "TIN"; Text[20])
        {
            Caption = 'TIN';
        }
        field(4; "Preprod API Key"; Text[250])
        {
            Caption = 'Pre-Production API Key';
            ExtendedDatatype = Masked;
        }
        field(5; "Live API Key"; Text[250])
        {
            Caption = 'Live/Production API Key';
            ExtendedDatatype = Masked;
        }
        field(6; "Business ID"; Text[100])
        {
            Caption = 'Business ID';
        }
        field(7; "IRN Code"; Text[20])
        {
            Caption = 'IRN Template Code';
        }
        field(8; Email; Text[100])
        {
            Caption = 'Email';
        }
        field(9; Telephone; Text[30])
        {
            Caption = 'Telephone';
        }
        field(10; "Street Name"; Text[200])
        {
            Caption = 'Street Name';
        }
        field(11; "City Name"; Text[100])
        {
            Caption = 'City Name';
        }
        field(12; "Postal Zone"; Text[20])
        {
            Caption = 'Postal Zone';
        }
        field(13; Country; Text[10])
        {
            Caption = 'Country Code';
            InitValue = 'NG';
        }
        field(14; "Business Description"; Text[200])
        {
            Caption = 'Business Description';
        }
        field(15; "Representative"; Text[50])
        {
            Caption = 'Representative';
        }
        field(20; Enabled; Boolean)
        {
            Caption = 'Enabled';
            InitValue = true;
        }
    }

    keys
    {
        key(PK; "Company Name")
        {
            Clustered = true;
        }
    }

    procedure GetActiveAPIKey(UseTestMode: Boolean): Text[250]
    begin
        if UseTestMode then
            exit("Preprod API Key");
        exit("Live API Key");
    end;
}
