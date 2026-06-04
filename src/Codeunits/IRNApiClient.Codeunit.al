codeunit 50502 "IRN API Client"
{
    InherentPermissions = X;
    InherentEntitlements = X;
    Permissions = tabledata "IRN Setup" = R,
                  tabledata "IRN Company Setup" = R;

    procedure SubmitInvoice(Payload: Text; var HttpStatusCode: Integer; var ResponseBody: Text; var Success: Boolean)
    var
        IRNSetup: Record "IRN Setup";
        CompanySetup: Record "IRN Company Setup";
        Client: HttpClient;
        Request: HttpRequestMessage;
        Response: HttpResponseMessage;
        Content: HttpContent;
        Headers: HttpHeaders;
        ContentHeaders: HttpHeaders;
        BaseURL: Text;
        FullURL: Text;
        APIKey: Text;
    begin
        IRNSetup.GetSetup();
        BaseURL := IRNSetup.GetActiveBaseURL();
        FullURL := BaseURL.TrimEnd('/') + '/invoice/generate';

        // Get company-specific API key
        APIKey := GetCompanyAPIKey(IRNSetup);

        // Set request
        Request.SetRequestUri(FullURL);
        Request.Method := 'POST';

        // Set content
        Content.WriteFrom(Payload);
        Content.GetHeaders(ContentHeaders);
        if ContentHeaders.Contains('Content-Type') then
            ContentHeaders.Remove('Content-Type');
        ContentHeaders.Add('Content-Type', 'application/json');
        Request.Content := Content;

        // Set auth headers - always use x-api-key with company-specific key
        Request.GetHeaders(Headers);
        Headers.Add(IRNSetup."API Key Header Name", APIKey);

        // Set timeout
        Client.Timeout(IRNSetup."Timeout (ms)");

        // Send request
        Success := Client.Send(Request, Response);

        if Success then begin
            HttpStatusCode := Response.HttpStatusCode;
            Response.Content.ReadAs(ResponseBody);
            Success := Response.IsSuccessStatusCode;
        end else begin
            HttpStatusCode := 0;
            ResponseBody := 'HTTP request failed. Check network connectivity and endpoint URL.';
        end;
    end;

    procedure TransmitInvoice(IRN: Text; var HttpStatusCode: Integer; var ResponseBody: Text; var Success: Boolean)
    var
        IRNSetup: Record "IRN Setup";
        Client: HttpClient;
        Request: HttpRequestMessage;
        Response: HttpResponseMessage;
        Headers: HttpHeaders;
        BaseURL: Text;
        FullURL: Text;
        APIKey: Text;
    begin
        IRNSetup.GetSetup();
        BaseURL := IRNSetup.GetActiveBaseURL();
        FullURL := BaseURL.TrimEnd('/') + '/invoice/transmit/' + IRN;

        APIKey := GetCompanyAPIKey(IRNSetup);

        Request.SetRequestUri(FullURL);
        Request.Method := 'POST';

        Request.GetHeaders(Headers);
        Headers.Add(IRNSetup."API Key Header Name", APIKey);

        Client.Timeout(IRNSetup."Timeout (ms)");

        Success := Client.Send(Request, Response);
        if Success then begin
            HttpStatusCode := Response.HttpStatusCode;
            Response.Content.ReadAs(ResponseBody);
            Success := Response.IsSuccessStatusCode;
        end else begin
            HttpStatusCode := 0;
            ResponseBody := 'HTTP request failed.';
        end;
    end;

    procedure CancelInvoice(IRN: Text; var HttpStatusCode: Integer; var ResponseBody: Text; var Success: Boolean)
    var
        IRNSetup: Record "IRN Setup";
        Client: HttpClient;
        Request: HttpRequestMessage;
        Response: HttpResponseMessage;
        Headers: HttpHeaders;
        BaseURL: Text;
        FullURL: Text;
        APIKey: Text;
    begin
        IRNSetup.GetSetup();
        BaseURL := IRNSetup.GetActiveBaseURL();
        FullURL := BaseURL.TrimEnd('/') + '/invoice/' + IRN + '/cancel';

        APIKey := GetCompanyAPIKey(IRNSetup);

        Request.SetRequestUri(FullURL);
        Request.Method := 'PATCH';

        Request.GetHeaders(Headers);
        Headers.Add(IRNSetup."API Key Header Name", APIKey);

        Client.Timeout(IRNSetup."Timeout (ms)");

        Success := Client.Send(Request, Response);
        if Success then begin
            HttpStatusCode := Response.HttpStatusCode;
            Response.Content.ReadAs(ResponseBody);
            Success := Response.IsSuccessStatusCode;
        end else begin
            HttpStatusCode := 0;
            ResponseBody := 'HTTP request failed. Check network connectivity and endpoint URL.';
        end;
    end;

    local procedure GetCompanyAPIKey(IRNSetup: Record "IRN Setup"): Text
    var
        CompanySetup: Record "IRN Company Setup";
        APIKey: Text;
    begin
        // Try company-specific API key first
        if CompanySetup.Get(CompanyName) then begin
            if not CompanySetup.Enabled then
                Error('IRN submission is disabled for company %1.', CompanyName);
            APIKey := CompanySetup.GetActiveAPIKey(IRNSetup."Use Test Mode");
            if APIKey <> '' then
                exit(APIKey);
        end;

        // Fall back to global API key from IRN Setup
        if IRNSetup."Authorization Type" = IRNSetup."Authorization Type"::APIKey then
            if IRNSetup."API Key" <> '' then
                exit(IRNSetup."API Key");

        Error('No API key configured for company %1. Go to IRN Setup > Company API Keys to configure.', CompanyName);
    end;
}
