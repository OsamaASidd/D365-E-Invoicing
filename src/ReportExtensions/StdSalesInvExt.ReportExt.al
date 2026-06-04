reportextension 50500 "Std Sales Inv IRN Ext" extends "Standard Sales - Invoice"
{
    dataset
    {
        add(Header)
        {
            column(IRN_No; "IRN No.")
            {
            }
            column(IRN_Status; "IRN Status")
            {
            }
            column(IRN_QR_Code_URL; "IRN QR Code URL")
            {
            }
            column(IRN_Submitted_At; "IRN Submitted At")
            {
            }
            column(IRN_QR_Image; "IRN QR Image")
            {
            }
        }
    }
}
