enum 50500 "IRN Status"
{
    Extensible = true;

    value(0; " ")
    {
        Caption = ' ';
    }
    value(1; Pending)
    {
        Caption = 'Pending';
    }
    value(2; Submitted)
    {
        Caption = 'Submitted';
    }
    value(3; Success)
    {
        Caption = 'Success';
    }
    value(4; Failed)
    {
        Caption = 'Failed';
    }
    value(5; Cancelled)
    {
        Caption = 'Cancelled';
    }
}
