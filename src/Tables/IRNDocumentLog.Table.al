table 50501 "IRN Document Log"
{
    Caption = 'IRN Document Log';
    DataClassification = CustomerContent;
    InherentPermissions = RIMD;
    InherentEntitlements = RIMD;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
        }
        field(2; "Document Type"; Enum "IRN Document Type")
        {
            Caption = 'Document Type';
        }
        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(4; "Document SystemId"; Guid)
        {
            Caption = 'Document SystemId';
        }
        field(5; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(6; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
        }
        field(7; "Customer Name"; Text[100])
        {
            Caption = 'Customer Name';
        }
        field(10; "IRN Status"; Enum "IRN Status")
        {
            Caption = 'IRN Status';
        }
        field(11; IRN; Text[250])
        {
            Caption = 'IRN';
        }
        field(12; "Ack No."; Text[100])
        {
            Caption = 'Acknowledgement No.';
        }
        field(13; "Ack Date Time"; DateTime)
        {
            Caption = 'Ack Date Time';
        }
        field(14; "QR Code URL"; Text[500])
        {
            Caption = 'QR Code URL';
        }
        field(15; "Cryptware Invoice Id"; Text[100])
        {
            Caption = 'Cryptware Invoice Id';
        }
        field(20; "HTTP Status Code"; Integer)
        {
            Caption = 'HTTP Status Code';
        }
        field(21; "Error Message"; Text[2048])
        {
            Caption = 'Error Message';
        }
        field(22; "Request JSON"; Blob)
        {
            Caption = 'Request JSON';
        }
        field(23; "Response JSON"; Blob)
        {
            Caption = 'Response JSON';
        }
        field(30; "Created At"; DateTime)
        {
            Caption = 'Created At';
        }
        field(31; "Created By"; Code[50])
        {
            Caption = 'Created By';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(Document; "Document Type", "Document No.")
        {
        }
    }

    procedure SetRequestJSON(JsonText: Text)
    var
        OutStream: OutStream;
    begin
        "Request JSON".CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(JsonText);
    end;

    procedure GetRequestJSON(): Text
    var
        InStream: InStream;
        Result: Text;
    begin
        CalcFields("Request JSON");
        if not "Request JSON".HasValue() then
            exit('');
        "Request JSON".CreateInStream(InStream, TextEncoding::UTF8);
        InStream.ReadText(Result);
        exit(Result);
    end;

    procedure SetResponseJSON(JsonText: Text)
    var
        OutStream: OutStream;
    begin
        "Response JSON".CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(JsonText);
    end;

    procedure GetResponseJSON(): Text
    var
        InStream: InStream;
        Result: Text;
    begin
        CalcFields("Response JSON");
        if not "Response JSON".HasValue() then
            exit('');
        "Response JSON".CreateInStream(InStream, TextEncoding::UTF8);
        InStream.ReadText(Result);
        exit(Result);
    end;
}
