permissionset 50501 "IRN USER"
{
    Caption = 'IRN E-Invoicing User';
    Assignable = true;

    Permissions =
        table "IRN Setup" = X,
        table "IRN Document Log" = X,
        table "IRN Company Setup" = X,
        tabledata "IRN Setup" = R,
        tabledata "IRN Document Log" = RI,
        tabledata "IRN Company Setup" = R,
        page "IRN Document Log List" = X,
        page "IRN Log Payload FactBox" = X,
        codeunit "IRN Validation" = X,
        codeunit "IRN Payload Builder" = X,
        codeunit "IRN API Client" = X,
        codeunit "IRN Response Handler" = X,
        codeunit "IRN Management" = X,
        report "IRN Sales Invoice" = X;
}
