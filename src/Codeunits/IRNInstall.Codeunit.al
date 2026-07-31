codeunit 50505 "IRN Install"
{
    Subtype = Install;
    InherentPermissions = X;
    InherentEntitlements = X;
    Permissions = tabledata "IRN Setup" = RIMD,
                  tabledata "IRN Company Setup" = RIMD;

    trigger OnInstallAppPerCompany()
    var
        IRNSetup: Record "IRN Setup";
    begin
        if not IRNSetup.Get() then begin
            IRNSetup.Init();
            IRNSetup.Enabled := true;
            IRNSetup."API Key Header Name" := 'x-api-key';
            IRNSetup."Timeout (ms)" := 30000;
            IRNSetup."Log Request Payload" := true;
            IRNSetup."Log Response Payload" := true;
            IRNSetup."Use Test Mode" := true;
            IRNSetup."Base URL" := 'https://api.cryptwaresystemsltd.com';
            IRNSetup."Test Base URL" := 'https://preprod-api.cryptwaresystemsltd.com';
            IRNSetup."Authorization Type" := IRNSetup."Authorization Type"::APIKey;
            IRNSetup.Insert();
        end else begin
            // Ensure existing setup is enabled and has URLs
            if not IRNSetup.Enabled or (IRNSetup."Base URL" = '') then begin
                IRNSetup.Enabled := true;
                if IRNSetup."Base URL" = '' then
                    IRNSetup."Base URL" := 'https://api.cryptwaresystemsltd.com';
                if IRNSetup."Test Base URL" = '' then
                    IRNSetup."Test Base URL" := 'https://preprod-api.cryptwaresystemsltd.com';
                if IRNSetup."API Key Header Name" = '' then
                    IRNSetup."API Key Header Name" := 'x-api-key';
                IRNSetup.Modify();
            end;
        end;

        SeedCurrentCompany();
    end;

    procedure SeedCurrentCompany()
    var
        CurrentCompany: Text;
        UpperCompany: Text;
    begin
        CurrentCompany := CompanyName;
        UpperCompany := UpperCase(CurrentCompany);

        // 1. PRIME ATLANTIC LIMITED - must check before others that contain "PRIME ATLANTIC"
        //    Exclude SAFETY, O&G, DOMAIN, GROUP, INVESTMENT, GLOBAL, INSTRUMENTS
        if UpperCompany.Contains('PRIME ATLANTIC') and
           not UpperCompany.Contains('SAFETY') and
           not UpperCompany.Contains('O&G') and
           not UpperCompany.Contains('DOMAIN') and
           not UpperCompany.Contains('GROUP') and
           not UpperCompany.Contains('INVESTMENT') and
           not UpperCompany.Contains('GLOBAL') and
           not UpperCompany.Contains('INSTRUMENTS') then begin
            InsertCompany(CurrentCompany, 'PRIME ATLANTIC LIMITED', '01213085-0001',
                '',
                '',
                'f16c2903-9399-4929-9cc8-60a2454ddd69', '86CE9399',
                'info@primeatlanticnigeria.com', '014606130',
                '33 ADEOLA HOPEWELL STREET, VICTORIA ISLAND', 'LAGOS STATE', '234-01', 'NG',
                'OIL AND GAS', 'Emmanuel');
            exit;
        end;

        // 2. PRIME ATLANTIC SAFETY SERVICES
        if UpperCompany.Contains('SAFETY') then begin
            InsertCompany(CurrentCompany, 'PRIME ATLANTIC SAFETY SERVICES LIMITED', '01425160-0001',
                '',
                '',
                '854c96a6-83c5-4a84-8be1-ca5909d44323', '3BFB83C5',
                'passfinance@primeatlanticsafetyservices.com', '01-4606130',
                '33 Adeola Hopewell Street', 'Lagos', '101241', 'NG',
                'Training, Consultancy and Technical Services', 'Kalu');
            exit;
        end;

        // 3. PRIME ATLANTIC O&G / GLOBAL ENGINEERING SERVICES
        if UpperCompany.Contains('O&G') or UpperCompany.Contains('GLOBAL ENGINEERING') then begin
            InsertCompany(CurrentCompany, 'PRIME ATLANTIC GLOBAL ENGINEERING SERVICES LIMITED', '10676712-0001',
                '',
                '',
                '0d35a861-14c9-466c-87e5-b410a5175d31', '13B914C9',
                'pagesfinance@pages-ng.com', '+234-8052290711',
                '33 Adeola Hopewell Street', 'Victoria Island', '101241', 'NG',
                'Engineering Services', 'Dayo');
            exit;
        end;

        // 4a. PAL SAFEHOUSE TEST SANDBOX — must be checked before the production block
        if UpperCompany.Contains('PAL SAFEHOUSE') and UpperCompany.Contains('TEST') then begin
            InsertCompany(CurrentCompany, 'PAL SAFEHOUSE NIGERIA LIMITED', '22446543-0001',
                '',
                '',
                '9083542f-a09b-424f-827e-d50b84d4e274', 'CD99A09B',
                'passfinance@primeatlanticsafetyservices.com', '01-4606130',
                '33 Adeola Hopewell Street', 'Lagos', '101241', 'NG',
                'Hot works Protection', 'Tosin');
            exit;
        end;

        // 4b. PA ASSETS / PAL SAFEHOUSE (production)
        if UpperCompany.Contains('PA ASSETS') or UpperCompany.Contains('PAL SAFEHOUSE') or UpperCompany.Contains('SAFEHOUSE') then begin
            InsertCompany(CurrentCompany, 'PAL SAFEHOUSE NIGERIA LIMITED', '22446543-0001',
                '',
                '',
                '9083542f-a09b-424f-827e-d50b84d4e274', 'CD99A09B',
                'passfinance@primeatlanticsafetyservices.com', '01-4606130',
                '33 Adeola Hopewell Street', 'Lagos', '101241', 'NG',
                'Hot works Protection', 'Tosin');
            exit;
        end;

        // 5. WEST ATLANTIC ENERGY / WAEL
        if UpperCompany.Contains('WEST ATLANTIC') or UpperCompany.Contains('WAEL') then begin
            InsertCompany(CurrentCompany, 'WEST ATLANTIC ENERGY NIGERIA LTD', '04998156-0001',
                '',
                '',
                'a94d300f-7551-4ae6-bce6-f6bebaf8e3cc', '77BA7551',
                'omotoso.adeyemo@waelng.com', '09062533604',
                '33 Adeola Hopewell Street, Victoria Island', 'Lagos', '101241', 'NG',
                'Provision of IT services', 'Omolara');
            exit;
        end;

        // 6. CINALT
        if UpperCompany.Contains('CINALT') then begin
            InsertCompany(CurrentCompany, 'CINALT RESOURCES LIMITED', '17863249-0001',
                '',
                '',
                '0dbed369-9cb4-40f8-9691-277525f03848', '4CC99CB4',
                'info@cinalt.com', '23408052290711',
                '1ST/2ND FLOOR TCF TOWER, 33 ADEOLA HOPEWELL STREET', 'VICTORIA ISLAND, LAGOS', '101241', 'NG',
                'SUPPLIER OF OFFSHORE & OILFIELD CHEMICALS', 'Abayomi');
            exit;
        end;

        // 7. SYNERPET
        if UpperCompany.Contains('SYNERPET') then begin
            InsertCompany(CurrentCompany, 'SYNERPET LIMITED', '18381779-0001',
                '',
                '',
                'ecf6733c-810c-4eef-b1b9-77aa01758ad6', '2C86810C',
                'info@synerpetnigeria.com', '014606130',
                '33 ADEOLA HOPEWELL STREET, VICTORIA ISLAND', 'LAGOS STATE', '234-01', 'NG',
                'SALES AND MARKETING OF DIFFERENT KINDS OF TECHNOLOGY', 'Blessing');
            exit;
        end;

        // 8. WESTON
        if UpperCompany.Contains('WESTON') then begin
            InsertCompany(CurrentCompany, 'WESTON INTEGRATED SERVICES LIMITED', '19356513-0001',
                '',
                '',
                '4a3d2fb0-4ef0-41c5-95bb-1427cd05e475', '6CA34EF0',
                'info@primeatlanticnigeria.com', '014606130',
                '33 ADEOLA HOPEWELL STREET, VICTORIA ISLAND', 'LAGOS STATE', '234-01', 'NG',
                'SECURITY', 'Blessing');
            exit;
        end;

        // No match — company not configured for NRS. IRN Setup is still created
        // but no Company Setup record. User can add one manually via IRN Setup > Company API Keys.
    end;

    local procedure InsertCompany(
        CompName: Text[100]; EntityName: Text[150]; TIN: Text[20];
        PreprodKey: Text[250]; LiveKey: Text[250];
        BusinessID: Text[100]; IRNCode: Text[20];
        Email: Text[100]; Phone: Text[30];
        Street: Text[200]; City: Text[100]; Postal: Text[20]; Country: Text[10];
        BizDesc: Text[200]; Rep: Text[50])
    var
        CompSetup: Record "IRN Company Setup";
    begin
        if CompSetup.Get(CompName) then begin
            // Patch missing keys if they were seeded as blank
            if ((CompSetup."Preprod API Key" = '') and (PreprodKey <> '')) or
               ((CompSetup."Live API Key" = '') and (LiveKey <> '')) then begin
                if CompSetup."Preprod API Key" = '' then
                    CompSetup."Preprod API Key" := PreprodKey;
                if CompSetup."Live API Key" = '' then
                    CompSetup."Live API Key" := LiveKey;
                CompSetup.Modify();
            end;
            exit;
        end;
        CompSetup.Init();
        CompSetup."Company Name" := CompName;
        CompSetup."Entity Name" := EntityName;
        CompSetup.TIN := TIN;
        CompSetup."Preprod API Key" := PreprodKey;
        CompSetup."Live API Key" := LiveKey;
        CompSetup."Business ID" := BusinessID;
        CompSetup."IRN Code" := IRNCode;
        CompSetup.Email := Email;
        CompSetup.Telephone := Phone;
        CompSetup."Street Name" := Street;
        CompSetup."City Name" := City;
        CompSetup."Postal Zone" := Postal;
        CompSetup.Country := Country;
        CompSetup."Business Description" := BizDesc;
        CompSetup.Representative := Rep;
        CompSetup.Enabled := true;
        CompSetup.Insert();
    end;
}
