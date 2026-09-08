tableextension 50500 "Sales Invoice Header Ext" extends "Sales Invoice Header"
{
    fields
    {
        field(50500; "IRN Status"; Enum "IRN Status")
        {
            Caption = 'IRN Status';
            DataClassification = CustomerContent;
        }
        field(50501; "IRN No."; Text[250])
        {
            Caption = 'IRN';
            DataClassification = CustomerContent;
        }
        field(50502; "IRN QR Code URL"; Text[500])
        {
            Caption = 'IRN QR Code URL';
            DataClassification = CustomerContent;
        }
        field(50503; "IRN Ack No."; Text[100])
        {
            Caption = 'IRN Ack No.';
            DataClassification = CustomerContent;
        }
        field(50504; "IRN Submitted At"; DateTime)
        {
            Caption = 'IRN Submitted At';
            DataClassification = CustomerContent;
        }
        field(50505; "IRN Submitted By"; Code[50])
        {
            Caption = 'IRN Submitted By';
            DataClassification = CustomerContent;
        }
        field(50506; "IRN Last Error"; Text[500])
        {
            Caption = 'IRN Last Error';
            DataClassification = CustomerContent;
        }
        field(50507; "IRN Cryptware Id"; Text[100])
        {
            Caption = 'IRN Cryptware Id';
            DataClassification = CustomerContent;
        }
        field(50508; "IRN QR Image"; Blob)
        {
            Caption = 'IRN QR Image';
            DataClassification = CustomerContent;
        }
        field(50509; "IRN QR Media"; Media)
        {
            Caption = 'IRN QR Media';
            DataClassification = CustomerContent;
        }
        field(50510; "IRN Payment Status"; Enum "IRN Payment Status")
        {
            Caption = 'Payment Status';
            DataClassification = CustomerContent;
        }
    }
}
