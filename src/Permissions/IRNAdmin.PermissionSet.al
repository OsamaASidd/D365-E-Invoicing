permissionset 50500 "IRN ADMIN"
{
    Caption = 'IRN E-Invoicing Admin';
    Assignable = true;

    Permissions =
        table "IRN Setup" = X,
        table "IRN Document Log" = X,
        table "IRN Company Setup" = X,
        tabledata "IRN Setup" = RIMD,
        tabledata "IRN Document Log" = RIMD,
        tabledata "IRN Company Setup" = RIMD,
        page "IRN Setup" = X,
        page "IRN Document Log List" = X,
        page "IRN Log Payload FactBox" = X,
        page "IRN Company Setup List" = X,
        page "IRN Company Setup Card" = X,
        codeunit "IRN Validation" = X,
        codeunit "IRN Payload Builder" = X,
        codeunit "IRN API Client" = X,
        codeunit "IRN Response Handler" = X,
        codeunit "IRN Management" = X,
        report "IRN Sales Invoice" = X;
}
