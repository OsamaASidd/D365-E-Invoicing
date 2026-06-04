enum 50502 "IRN Authorization Type"
{
    Extensible = true;

    value(0; None)
    {
        Caption = 'None';
    }
    value(1; APIKey)
    {
        Caption = 'API Key';
    }
    value(2; Bearer)
    {
        Caption = 'Bearer Token';
    }
}
