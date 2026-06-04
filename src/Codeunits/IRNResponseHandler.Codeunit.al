codeunit 50503 "IRN Response Handler"
{
    InherentPermissions = X;
    InherentEntitlements = X;
    Permissions = tabledata "IRN Setup" = R,
                  tabledata "IRN Document Log" = RIMD,
                  tabledata "Sales Invoice Header" = RM,
                  tabledata "Sales Cr.Memo Header" = RM;
    procedure HandleInvoiceResponse(var SalesInvHeader: Record "Sales Invoice Header"; RequestPayload: Text; ResponseBody: Text; HttpStatus: Integer; HttpSuccess: Boolean)
    var
        IRNSetup: Record "IRN Setup";
        LogEntry: Record "IRN Document Log";
        IRN: Text[250];
        QRCodeURL: Text[500];
        CryptwareId: Text[100];
        ErrorMsg: Text;
    begin
        IRNSetup.GetSetup();

        // Parse response
        if HttpSuccess then begin
            ParseSuccessResponse(ResponseBody, IRN, QRCodeURL, CryptwareId);
            SalesInvHeader."IRN Status" := SalesInvHeader."IRN Status"::Success;
            SalesInvHeader."IRN No." := IRN;
            SalesInvHeader."IRN QR Code URL" := QRCodeURL;
            SalesInvHeader."IRN Cryptware Id" := CryptwareId;
            SalesInvHeader."IRN Last Error" := '';
            // Download QR image from URL and store in Blob field
            if QRCodeURL <> '' then
                DownloadQRImageToBlob(QRCodeURL, SalesInvHeader);
        end else begin
            ErrorMsg := ParseErrorResponse(ResponseBody, HttpStatus);
            SalesInvHeader."IRN Status" := SalesInvHeader."IRN Status"::Failed;
            SalesInvHeader."IRN Last Error" := CopyStr(ErrorMsg, 1, 500);

            // Handle 409 duplicate - treat as success
            if HttpStatus = 409 then begin
                ParseDuplicateResponse(ResponseBody, IRN);
                if IRN <> '' then begin
                    SalesInvHeader."IRN Status" := SalesInvHeader."IRN Status"::Success;
                    SalesInvHeader."IRN No." := IRN;
                    SalesInvHeader."IRN Last Error" := 'Duplicate - already submitted';
                end;
            end;
        end;

        SalesInvHeader."IRN Submitted At" := CurrentDateTime;
        SalesInvHeader."IRN Submitted By" := CopyStr(UserId, 1, 50);
        SalesInvHeader.Modify(true);

        // Write log
        WriteLog(
            "IRN Document Type"::SalesInvoice,
            SalesInvHeader."No.",
            SalesInvHeader.SystemId,
            SalesInvHeader."Posting Date",
            SalesInvHeader."Sell-to Customer No.",
            SalesInvHeader."Sell-to Customer Name",
            SalesInvHeader."IRN Status",
            IRN, QRCodeURL, CryptwareId,
            HttpStatus, ErrorMsg,
            RequestPayload, ResponseBody
        );
    end;

    procedure HandleCreditMemoResponse(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; RequestPayload: Text; ResponseBody: Text; HttpStatus: Integer; HttpSuccess: Boolean)
    var
        IRNSetup: Record "IRN Setup";
        IRN: Text[250];
        QRCodeURL: Text[500];
        CryptwareId: Text[100];
        ErrorMsg: Text;
    begin
        IRNSetup.GetSetup();

        if HttpSuccess then begin
            ParseSuccessResponse(ResponseBody, IRN, QRCodeURL, CryptwareId);
            SalesCrMemoHeader."IRN Status" := SalesCrMemoHeader."IRN Status"::Success;
            SalesCrMemoHeader."IRN No." := IRN;
            SalesCrMemoHeader."IRN QR Code URL" := QRCodeURL;
            SalesCrMemoHeader."IRN Cryptware Id" := CryptwareId;
            SalesCrMemoHeader."IRN Last Error" := '';
            // Download QR image from URL and store in Blob field
            if QRCodeURL <> '' then
                DownloadQRImageToCrMemoBlob(QRCodeURL, SalesCrMemoHeader);
        end else begin
            ErrorMsg := ParseErrorResponse(ResponseBody, HttpStatus);
            SalesCrMemoHeader."IRN Status" := SalesCrMemoHeader."IRN Status"::Failed;
            SalesCrMemoHeader."IRN Last Error" := CopyStr(ErrorMsg, 1, 500);

            if HttpStatus = 409 then begin
                ParseDuplicateResponse(ResponseBody, IRN);
                if IRN <> '' then begin
                    SalesCrMemoHeader."IRN Status" := SalesCrMemoHeader."IRN Status"::Success;
                    SalesCrMemoHeader."IRN No." := IRN;
                    SalesCrMemoHeader."IRN Last Error" := 'Duplicate - already submitted';
                end;
            end;
        end;

        SalesCrMemoHeader."IRN Submitted At" := CurrentDateTime;
        SalesCrMemoHeader."IRN Submitted By" := CopyStr(UserId, 1, 50);
        SalesCrMemoHeader.Modify(true);

        WriteLog(
            "IRN Document Type"::SalesCreditMemo,
            SalesCrMemoHeader."No.",
            SalesCrMemoHeader.SystemId,
            SalesCrMemoHeader."Posting Date",
            SalesCrMemoHeader."Sell-to Customer No.",
            SalesCrMemoHeader."Sell-to Customer Name",
            SalesCrMemoHeader."IRN Status",
            IRN, QRCodeURL, CryptwareId,
            HttpStatus, ErrorMsg,
            RequestPayload, ResponseBody
        );
    end;

    procedure HandleCancelResponse(SalesInvHeader: Record "Sales Invoice Header"; ResponseBody: Text; HttpStatus: Integer; HttpSuccess: Boolean)
    var
        ErrorMsg: Text;
    begin
        if not HttpSuccess then
            ErrorMsg := ParseErrorResponse(ResponseBody, HttpStatus);

        WriteLog(
            "IRN Document Type"::SalesInvoice,
            SalesInvHeader."No.",
            SalesInvHeader.SystemId,
            SalesInvHeader."Posting Date",
            SalesInvHeader."Sell-to Customer No.",
            SalesInvHeader."Sell-to Customer Name",
            SalesInvHeader."IRN Status",
            SalesInvHeader."IRN No.",
            SalesInvHeader."IRN QR Code URL",
            SalesInvHeader."IRN Cryptware Id",
            HttpStatus, ErrorMsg,
            'CANCEL: ' + SalesInvHeader."IRN No.", ResponseBody
        );
    end;

    local procedure ParseSuccessResponse(ResponseBody: Text; var IRN: Text[250]; var QRCodeURL: Text[500]; var CryptwareId: Text[100])
    var
        JsonObj: JsonObject;
        DataToken: JsonToken;
        DataObj: JsonObject;
    begin
        // Response: { "status": "success", "data": { "id": "...", "irn": "...", "qr_code_url": "..." } }
        if not JsonObj.ReadFrom(ResponseBody) then
            exit;

        if JsonObj.Get('data', DataToken) then
            if DataToken.IsObject() then begin
                DataObj := DataToken.AsObject();
                IRN := CopyStr(GetJsonText(DataObj, 'irn'), 1, 250);
                QRCodeURL := CopyStr(GetJsonText(DataObj, 'qr_code_url'), 1, 500);
                CryptwareId := CopyStr(GetJsonText(DataObj, 'id'), 1, 100);
            end;

        // Fallback: try top-level
        if IRN = '' then
            IRN := CopyStr(GetJsonText(JsonObj, 'irn'), 1, 250);
    end;

    local procedure ParseErrorResponse(ResponseBody: Text; HttpStatus: Integer): Text
    var
        JsonObj: JsonObject;
        Msg: Text;
    begin
        if JsonObj.ReadFrom(ResponseBody) then begin
            Msg := GetJsonText(JsonObj, 'message');
            if Msg = '' then
                Msg := GetJsonText(JsonObj, 'error');
        end;

        if Msg = '' then
            Msg := StrSubstNo('HTTP %1: %2', HttpStatus, CopyStr(ResponseBody, 1, 500));

        exit(Msg);
    end;

    local procedure ParseDuplicateResponse(ResponseBody: Text; var IRN: Text[250])
    var
        JsonObj: JsonObject;
        DataToken: JsonToken;
        DataObj: JsonObject;
    begin
        if not JsonObj.ReadFrom(ResponseBody) then
            exit;
        if JsonObj.Get('data', DataToken) then
            if DataToken.IsObject() then begin
                DataObj := DataToken.AsObject();
                IRN := CopyStr(GetJsonText(DataObj, 'irn'), 1, 250);
            end;
    end;

    local procedure GetJsonText(JsonObj: JsonObject; PropertyName: Text): Text
    var
        Token: JsonToken;
    begin
        if JsonObj.Get(PropertyName, Token) then
            if Token.IsValue() then
                exit(Token.AsValue().AsText());
        exit('');
    end;

    local procedure WriteLog(DocType: Enum "IRN Document Type"; DocNo: Code[20]; DocSystemId: Guid; PostingDate: Date; CustomerNo: Code[20]; CustomerName: Text[100]; Status: Enum "IRN Status"; IRN: Text[250]; QRCodeURL: Text[500]; CryptwareId: Text[100]; HttpStatus: Integer; ErrorMsg: Text; RequestPayload: Text; ResponseBody: Text)
    var
        LogEntry: Record "IRN Document Log";
        IRNSetup: Record "IRN Setup";
    begin
        IRNSetup.GetSetup();

        LogEntry.Init();
        LogEntry."Document Type" := DocType;
        LogEntry."Document No." := DocNo;
        LogEntry."Document SystemId" := DocSystemId;
        LogEntry."Posting Date" := PostingDate;
        LogEntry."Customer No." := CustomerNo;
        LogEntry."Customer Name" := CopyStr(CustomerName, 1, 100);
        LogEntry."IRN Status" := Status;
        LogEntry.IRN := IRN;
        LogEntry."QR Code URL" := QRCodeURL;
        LogEntry."Cryptware Invoice Id" := CryptwareId;
        LogEntry."HTTP Status Code" := HttpStatus;
        LogEntry."Error Message" := CopyStr(ErrorMsg, 1, 2048);
        LogEntry."Created At" := CurrentDateTime;
        LogEntry."Created By" := CopyStr(UserId, 1, 50);

        if IRNSetup."Log Request Payload" then
            LogEntry.SetRequestJSON(RequestPayload);
        if IRNSetup."Log Response Payload" then
            LogEntry.SetResponseJSON(ResponseBody);

        LogEntry.Insert(true);
    end;

    local procedure DownloadQRImageToBlob(QRUrl: Text; var SalesInvHeader: Record "Sales Invoice Header")
    var
        Client: HttpClient;
        Response: HttpResponseMessage;
        InStr: InStream;
        OutStr: OutStream;
    begin
        if QRUrl = '' then
            exit;
        if not Client.Get(QRUrl, Response) then
            exit;
        if not Response.IsSuccessStatusCode then
            exit;

        // Write raw image bytes directly to Blob
        Response.Content.ReadAs(InStr);
        SalesInvHeader."IRN QR Image".CreateOutStream(OutStr);
        CopyStream(OutStr, InStr);
    end;

    local procedure DownloadQRImageToCrMemoBlob(QRUrl: Text; var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        Client: HttpClient;
        Response: HttpResponseMessage;
        InStr: InStream;
        OutStr: OutStream;
    begin
        if QRUrl = '' then
            exit;
        if not Client.Get(QRUrl, Response) then
            exit;
        if not Response.IsSuccessStatusCode then
            exit;

        // Write raw image bytes directly to Blob
        Response.Content.ReadAs(InStr);
        SalesCrMemoHeader."IRN QR Image".CreateOutStream(OutStr);
        CopyStream(OutStr, InStr);
    end;
}
