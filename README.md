# D365-E-Invoicing

**Cryptware NRS E-Invoicing** — A Microsoft Dynamics 365 Business Central AL extension for Nigeria Revenue Service (NRS/FIRS) e-invoicing compliance.

Developed by [Cryptware Systems LTD](https://cryptwaresystems.com)

---

## Overview

This extension integrates Business Central with the Nigeria Revenue Service (NRS) e-invoicing API, enabling automatic generation and submission of Invoice Reference Numbers (IRN) for posted sales invoices and credit memos.

## Features

- **IRN Generation** — Submit posted sales invoices to NRS and receive an IRN
- **Credit Note Support** — Submit credit memos with cancel references to original invoices
- **Invoice Cancellation** — Cancel a submitted invoice on NRS (PATCH endpoint)
- **QR Code** — Stores and displays the NRS-issued QR code image on the invoice
- **Professional Print Layout** — Custom RDLC invoice with company branding, line items table, VAT breakdown, and IRN/QR footer
- **Audit Log** — Full request/response logging for every NRS submission
- **JSON Viewer** — View raw API request and response payloads from the posted document
- **Validation** — Pre-submission validation of required fields (TIN, email, phone, address)
- **E.164 Phone Normalisation** — Automatic Nigerian phone number formatting

## Extension Details

| Property | Value |
|----------|-------|
| Publisher | Cryptware Systems LTD |
| Extension Name | Cryptware NRS E-Invoicing |
| Version | 1.0.0.0 |
| BC Platform | 27.0.0.0 |
| Target | Cloud + OnPrem |

## Project Structure

```
src/
├── Codeunits/
│   ├── IRNApiClient.Codeunit.al         # HTTP calls to NRS API
│   ├── IRNManagement.Codeunit.al        # Orchestration logic
│   ├── IRNPayloadBuilder.Codeunit.al    # JSON payload construction
│   ├── IRNResponseHandler.Codeunit.al   # Response parsing & logging
│   └── IRNValidation.Codeunit.al        # Pre-submission validation
├── Enums/
│   └── IRNStatus.Enum.al                # Pending / Submitted / Success / Failed / Cancelled
├── PageExtensions/
│   ├── PostedSalesInvExt.PageExt.al     # Actions on Posted Sales Invoice
│   └── PostedSalesCrMemoExt.PageExt.al  # Actions on Posted Sales Credit Memo
├── Pages/
│   ├── IRNCompanySetupCard.Page.al      # Setup page
│   ├── IRNDocumentLogList.Page.al       # Audit log list
│   └── IRNJSONViewer.Page.al            # JSON payload viewer
├── Reports/
│   ├── IRNSalesInvoice.Report.al        # Report definition
│   └── IRNSalesInvoice.rdl              # RDLC layout
├── Tables/
│   ├── IRNCompanySetup.Table.al         # API credentials & company config
│   ├── IRNDocumentLog.Table.al          # Submission audit log
│   └── TableExtensions/                 # Extensions on Sales Invoice/Cr.Memo headers
└── app.json
```

## Setup

1. Install the extension on your BC tenant
2. Search for **NRS E-Invoicing Setup** in BC
3. Enter your:
   - Entity Name & TIN
   - Business ID
   - IRN Template Code
   - Pre-production and/or Live API Keys
4. Fill in customer VAT Registration Nos. and contact details on Customer cards

## Actions Available

On a **Posted Sales Invoice**:
- **Submit to NRS** — Sends the invoice, stores IRN + QR code
- **Cancel on NRS** — Cancels a successfully submitted invoice
- **Print IRN Invoice** — Prints the professional invoice layout
- **See Request / See Response** — View API payloads
- **IRN Log** — Full audit trail

On a **Posted Sales Credit Memo**:
- **Submit to NRS** — Sends the credit memo with cancel references
- **Print IRN Credit Memo** — Prints the credit memo
- **See Request / See Response / IRN Log** — Same as above

## NRS API Endpoints Used

| Method | Endpoint | Purpose |
|--------|----------|---------|
| POST | `/invoice/generate` | Submit invoice or credit memo |
| PATCH | `/invoice/{IRN}/cancel` | Cancel a submitted invoice |

## License

Proprietary — Cryptware Systems LTD. All rights reserved.
