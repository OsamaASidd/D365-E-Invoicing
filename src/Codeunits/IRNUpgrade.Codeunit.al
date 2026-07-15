codeunit 50506 "IRN Upgrade"
{
    Subtype = Upgrade;
    InherentPermissions = X;
    InherentEntitlements = X;
    Permissions = tabledata "IRN Company Setup" = RIMD;

    trigger OnUpgradePerCompany()
    var
        IRNInstall: Codeunit "IRN Install";
    begin
        // Re-run seeder on upgrade so missing keys get patched
        IRNInstall.SeedCurrentCompany();
    end;
}
