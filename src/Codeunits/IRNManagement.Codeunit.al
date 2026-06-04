codeunit 50504 "IRN Management"
{
    InherentPermissions = X;
    InherentEntitlements = X;
    Permissions = tabledata "IRN Setup" = R,
                  tabledata "IRN Document Log" = RIMD,
                  tabledata "Sales Invoice Header" = RM,
                  tabledata "Sales Cr.Memo Header" = RM;

    procedure SubmitPostedSalesInvoice(var SalesInvHeader: Record "Sales Invoice Header")
    var
        Validation: Codeunit "IRN Validation";
        PayloadBuilder: Codeunit "IRN Payload Builder";
        ApiClient: Codeunit "IRN API Client";
        ResponseHandler: Codeunit "IRN Response Handler";
        Payload: Text;
        ResponseBody: Text;
        HttpStatus: Integer;
        HttpSuccess: Boolean;
    begin
        // Step 1: Validate
        Validation.ValidatePostedSalesInvoice(SalesInvHeader);

        // Step 2: Build payload
        Payload := PayloadBuilder.BuildInvoicePayload(SalesInvHeader);

        // Step 3: Mark as submitted
        SalesInvHeader."IRN Status" := SalesInvHeader."IRN Status"::Submitted;
        SalesInvHeader.Modify(true);
        Commit();

        // Step 4: Call API
        ApiClient.SubmitInvoice(Payload, HttpStatus, ResponseBody, HttpSuccess);

        // Step 5: Handle response
        ResponseHandler.HandleInvoiceResponse(SalesInvHeader, Payload, ResponseBody, HttpStatus, HttpSuccess);

        // Step 6: Notify user
        if SalesInvHeader."IRN Status" = SalesInvHeader."IRN Status"::Success then
            Message('Invoice %1 submitted successfully.\IRN: %2', SalesInvHeader."No.", SalesInvHeader."IRN No.")
        else
            Message('Invoice %1 submission failed.\Error: %2', SalesInvHeader."No.", SalesInvHeader."IRN Last Error");
    end;

    procedure CancelPostedSalesInvoice(var SalesInvHeader: Record "Sales Invoice Header")
    var
        Validation: Codeunit "IRN Validation";
        ApiClient: Codeunit "IRN API Client";
        ResponseHandler: Codeunit "IRN Response Handler";
        ResponseBody: Text;
        ErrorMsg: Text;
        HttpStatus: Integer;
        HttpSuccess: Boolean;
    begin
        Validation.ValidateSetup();

        if SalesInvHeader."IRN Status" <> SalesInvHeader."IRN Status"::Success then
            Error('Invoice %1 can only be cancelled when its IRN status is Success.', SalesInvHeader."No.");

        if SalesInvHeader."IRN No." = '' then
            Error('Invoice %1 does not have an IRN to cancel.', SalesInvHeader."No.");

        // Call cancel API
        ApiClient.CancelInvoice(SalesInvHeader."IRN No.", HttpStatus, ResponseBody, HttpSuccess);

        // Handle response
        if HttpSuccess then begin
            SalesInvHeader."IRN Status" := SalesInvHeader."IRN Status"::Cancelled;
            SalesInvHeader."IRN Last Error" := '';
            SalesInvHeader.Modify(true);
            Message('Invoice %1 cancelled successfully on NRS.\IRN: %2', SalesInvHeader."No.", SalesInvHeader."IRN No.");
        end else begin
            ErrorMsg := ParseErrorMessage(ResponseBody);
            SalesInvHeader."IRN Last Error" := CopyStr(ErrorMsg, 1, 500);
            SalesInvHeader.Modify(true);
            Message('Invoice %1 cancellation failed.\Error: %2', SalesInvHeader."No.", ErrorMsg);
        end;

        // Log the cancellation attempt
        ResponseHandler.HandleCancelResponse(SalesInvHeader, ResponseBody, HttpStatus, HttpSuccess);
    end;

    local procedure ParseErrorMessage(ResponseBody: Text): Text
    var
        JsonObj: JsonObject;
        Token: JsonToken;
    begin
        if JsonObj.ReadFrom(ResponseBody) then
            if JsonObj.Get('message', Token) then
                if Token.IsValue() then
                    exit(Token.AsValue().AsText());
        exit(ResponseBody);
    end;

    procedure SubmitPostedSalesCreditMemo(var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        Validation: Codeunit "IRN Validation";
        PayloadBuilder: Codeunit "IRN Payload Builder";
        ApiClient: Codeunit "IRN API Client";
        ResponseHandler: Codeunit "IRN Response Handler";
        Payload: Text;
        ResponseBody: Text;
        HttpStatus: Integer;
        HttpSuccess: Boolean;
    begin
        // Step 1: Validate
        Validation.ValidatePostedSalesCrMemo(SalesCrMemoHeader);

        // Step 2: Build payload
        Payload := PayloadBuilder.BuildCreditMemoPayload(SalesCrMemoHeader);

        // Step 3: Mark as submitted
        SalesCrMemoHeader."IRN Status" := SalesCrMemoHeader."IRN Status"::Submitted;
        SalesCrMemoHeader.Modify(true);
        Commit();

        // Step 4: Call API
        ApiClient.SubmitInvoice(Payload, HttpStatus, ResponseBody, HttpSuccess);

        // Step 5: Handle response
        ResponseHandler.HandleCreditMemoResponse(SalesCrMemoHeader, Payload, ResponseBody, HttpStatus, HttpSuccess);

        // Step 6: Notify user
        if SalesCrMemoHeader."IRN Status" = SalesCrMemoHeader."IRN Status"::Success then
            Message('Credit Memo %1 submitted successfully.\IRN: %2', SalesCrMemoHeader."No.", SalesCrMemoHeader."IRN No.")
        else
            Message('Credit Memo %1 submission failed.\Error: %2', SalesCrMemoHeader."No.", SalesCrMemoHeader."IRN Last Error");
    end;

    procedure BulkSubmitPostedSalesInvoices(var SalesInvHeader: Record "Sales Invoice Header")
    var
        Validation: Codeunit "IRN Validation";
        PayloadBuilder: Codeunit "IRN Payload Builder";
        ApiClient: Codeunit "IRN API Client";
        ResponseHandler: Codeunit "IRN Response Handler";
        IRNSetup: Record "IRN Setup";
        Payload: Text;
        ResponseBody: Text;
        HttpStatus: Integer;
        HttpSuccess: Boolean;
        TotalCount: Integer;
        SuccessCount: Integer;
        FailCount: Integer;
        SkipCount: Integer;
        ProgressDialog: Dialog;
        CurrentNo: Integer;
    begin
        Validation.ValidateSetup();

        TotalCount := SalesInvHeader.Count;
        if TotalCount = 0 then
            Error('No invoices selected.');

        if not Confirm('Submit %1 selected invoice(s) to NRS?', false, TotalCount) then
            exit;

        IRNSetup.GetSetup();
        SuccessCount := 0;
        FailCount := 0;
        SkipCount := 0;
        CurrentNo := 0;

        ProgressDialog.Open('Submitting invoices to NRS...\#1#### of #2####\Invoice: #3################\Status: #4################');
        ProgressDialog.Update(2, TotalCount);

        if SalesInvHeader.FindSet() then
            repeat
                CurrentNo += 1;
                ProgressDialog.Update(1, CurrentNo);
                ProgressDialog.Update(3, SalesInvHeader."No.");
                ProgressDialog.Update(4, 'Processing...');

                // Skip already successful unless resubmit is allowed
                if (SalesInvHeader."IRN Status" = SalesInvHeader."IRN Status"::Success) and
                   (not IRNSetup."Allow Resubmit Success") then begin
                    SkipCount += 1;
                    ProgressDialog.Update(4, 'Skipped (already submitted)');
                end else begin
                    if not TrySubmitSingleInvoice(SalesInvHeader) then begin
                        FailCount += 1;
                        ProgressDialog.Update(4, 'Failed');
                    end else begin
                        // Re-read to get updated status from response handler
                        SalesInvHeader.Get(SalesInvHeader."No.");
                        if SalesInvHeader."IRN Status" = SalesInvHeader."IRN Status"::Success then begin
                            SuccessCount += 1;
                            ProgressDialog.Update(4, 'Success');
                        end else begin
                            FailCount += 1;
                            ProgressDialog.Update(4, 'Failed');
                        end;
                    end;
                end;

                Commit();
            until SalesInvHeader.Next() = 0;

        ProgressDialog.Close();

        Message('Bulk submission complete.\Total: %1\Successful: %2\Failed: %3\Skipped: %4',
            TotalCount, SuccessCount, FailCount, SkipCount);
    end;

    procedure BulkSubmitPostedSalesCreditMemos(var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        Validation: Codeunit "IRN Validation";
        PayloadBuilder: Codeunit "IRN Payload Builder";
        ApiClient: Codeunit "IRN API Client";
        ResponseHandler: Codeunit "IRN Response Handler";
        IRNSetup: Record "IRN Setup";
        Payload: Text;
        ResponseBody: Text;
        HttpStatus: Integer;
        HttpSuccess: Boolean;
        TotalCount: Integer;
        SuccessCount: Integer;
        FailCount: Integer;
        SkipCount: Integer;
        ProgressDialog: Dialog;
        CurrentNo: Integer;
    begin
        Validation.ValidateSetup();

        TotalCount := SalesCrMemoHeader.Count;
        if TotalCount = 0 then
            Error('No credit memos selected.');

        if not Confirm('Submit %1 selected credit memo(s) to NRS?', false, TotalCount) then
            exit;

        IRNSetup.GetSetup();
        SuccessCount := 0;
        FailCount := 0;
        SkipCount := 0;
        CurrentNo := 0;

        ProgressDialog.Open('Submitting credit memos to NRS...\#1#### of #2####\Credit Memo: #3################\Status: #4################');
        ProgressDialog.Update(2, TotalCount);

        if SalesCrMemoHeader.FindSet() then
            repeat
                CurrentNo += 1;
                ProgressDialog.Update(1, CurrentNo);
                ProgressDialog.Update(3, SalesCrMemoHeader."No.");
                ProgressDialog.Update(4, 'Processing...');

                if (SalesCrMemoHeader."IRN Status" = SalesCrMemoHeader."IRN Status"::Success) and
                   (not IRNSetup."Allow Resubmit Success") then begin
                    SkipCount += 1;
                    ProgressDialog.Update(4, 'Skipped (already submitted)');
                end else begin
                    if not TrySubmitSingleCreditMemo(SalesCrMemoHeader) then begin
                        FailCount += 1;
                        ProgressDialog.Update(4, 'Failed');
                    end else begin
                        SalesCrMemoHeader.Get(SalesCrMemoHeader."No.");
                        if SalesCrMemoHeader."IRN Status" = SalesCrMemoHeader."IRN Status"::Success then begin
                            SuccessCount += 1;
                            ProgressDialog.Update(4, 'Success');
                        end else begin
                            FailCount += 1;
                            ProgressDialog.Update(4, 'Failed');
                        end;
                    end;
                end;

                Commit();
            until SalesCrMemoHeader.Next() = 0;

        ProgressDialog.Close();

        Message('Bulk submission complete.\Total: %1\Successful: %2\Failed: %3\Skipped: %4',
            TotalCount, SuccessCount, FailCount, SkipCount);
    end;

    [TryFunction]
    local procedure TrySubmitSingleInvoice(var SalesInvHeader: Record "Sales Invoice Header")
    var
        Validation: Codeunit "IRN Validation";
        PayloadBuilder: Codeunit "IRN Payload Builder";
        ApiClient: Codeunit "IRN API Client";
        ResponseHandler: Codeunit "IRN Response Handler";
        Payload: Text;
        ResponseBody: Text;
        HttpStatus: Integer;
        HttpSuccess: Boolean;
    begin
        Validation.ValidatePostedSalesInvoice(SalesInvHeader);
        Payload := PayloadBuilder.BuildInvoicePayload(SalesInvHeader);

        SalesInvHeader."IRN Status" := SalesInvHeader."IRN Status"::Submitted;
        SalesInvHeader.Modify(true);
        Commit();

        ApiClient.SubmitInvoice(Payload, HttpStatus, ResponseBody, HttpSuccess);
        ResponseHandler.HandleInvoiceResponse(SalesInvHeader, Payload, ResponseBody, HttpStatus, HttpSuccess);
    end;

    [TryFunction]
    local procedure TrySubmitSingleCreditMemo(var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        Validation: Codeunit "IRN Validation";
        PayloadBuilder: Codeunit "IRN Payload Builder";
        ApiClient: Codeunit "IRN API Client";
        ResponseHandler: Codeunit "IRN Response Handler";
        Payload: Text;
        ResponseBody: Text;
        HttpStatus: Integer;
        HttpSuccess: Boolean;
    begin
        Validation.ValidatePostedSalesCrMemo(SalesCrMemoHeader);
        Payload := PayloadBuilder.BuildCreditMemoPayload(SalesCrMemoHeader);

        SalesCrMemoHeader."IRN Status" := SalesCrMemoHeader."IRN Status"::Submitted;
        SalesCrMemoHeader.Modify(true);
        Commit();

        ApiClient.SubmitInvoice(Payload, HttpStatus, ResponseBody, HttpSuccess);
        ResponseHandler.HandleCreditMemoResponse(SalesCrMemoHeader, Payload, ResponseBody, HttpStatus, HttpSuccess);
    end;
}
