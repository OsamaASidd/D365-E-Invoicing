page 50505 "IRN JSON Viewer"
{
    Caption = 'JSON Viewer';
    PageType = Card;
    Editable = false;
    InherentPermissions = X;
    InherentEntitlements = X;

    layout
    {
        area(Content)
        {
            group(Header)
            {
                Caption = '';
                ShowCaption = false;

                field(TitleField; Title)
                {
                    ApplicationArea = All;
                    Caption = 'Type';
                    Style = Strong;
                    MultiLine = false;
                }
            }
            group(JsonContent)
            {
                Caption = 'JSON';

                field(JsonTextField; FormattedJson)
                {
                    ApplicationArea = All;
                    Caption = '';
                    ShowCaption = false;
                    MultiLine = true;
                    RowSpan = 20;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(CopyToClipboard)
            {
                ApplicationArea = All;
                Caption = 'Copy JSON';
                ToolTip = 'Copy the JSON text.';
                Image = Copy;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                begin
                    Message(FormattedJson);
                end;
            }
        }
    }

    var
        Title: Text;
        FormattedJson: Text;
        RawJson: Text;

    procedure SetData(NewTitle: Text; JsonText: Text)
    begin
        Title := NewTitle;
        RawJson := JsonText;
        FormattedJson := PrettyPrintJson(JsonText);
    end;

    local procedure PrettyPrintJson(JsonText: Text): Text
    var
        JsonObj: JsonObject;
        JsonArr: JsonArray;
        Result: Text;
        Indent: Integer;
        i: Integer;
        Ch: Char;
        InString: Boolean;
        PrevCh: Char;
    begin
        // Try to parse and re-serialize with indentation
        if JsonObj.ReadFrom(JsonText) then begin
            JsonObj.WriteTo(Result);
            exit(ManualFormat(Result));
        end;
        if JsonArr.ReadFrom(JsonText) then begin
            JsonArr.WriteTo(Result);
            exit(ManualFormat(Result));
        end;
        // If can't parse, return as-is
        exit(JsonText);
    end;

    local procedure ManualFormat(JsonText: Text): Text
    var
        Result: TextBuilder;
        i: Integer;
        Ch: Char;
        Indent: Integer;
        InString: Boolean;
        PrevCh: Char;
        NewLine: Text[2];
    begin
        NewLine[1] := 13; // CR
        NewLine[2] := 10; // LF
        Indent := 0;
        InString := false;

        for i := 1 to StrLen(JsonText) do begin
            Ch := JsonText[i];

            if InString then begin
                Result.Append(Format(Ch));
                if (Ch = '"') and (PrevCh <> '\') then
                    InString := false;
            end else begin
                case Ch of
                    '"':
                        begin
                            InString := true;
                            Result.Append(Format(Ch));
                        end;
                    '{', '[':
                        begin
                            Result.Append(Format(Ch));
                            Indent += 1;
                            Result.Append(NewLine);
                            Result.Append(PadStr('', Indent * 2, ' '));
                        end;
                    '}', ']':
                        begin
                            Indent -= 1;
                            Result.Append(NewLine);
                            Result.Append(PadStr('', Indent * 2, ' '));
                            Result.Append(Format(Ch));
                        end;
                    ',':
                        begin
                            Result.Append(Format(Ch));
                            Result.Append(NewLine);
                            Result.Append(PadStr('', Indent * 2, ' '));
                        end;
                    ':':
                        begin
                            Result.Append(': ');
                        end;
                    ' ':
                        ; // skip whitespace outside strings
                    else
                        Result.Append(Format(Ch));
                end;
            end;

            PrevCh := Ch;
        end;

        exit(Result.ToText());
    end;

    local procedure PadStr(Str: Text; Length: Integer; PadChar: Char): Text
    var
        Result: TextBuilder;
        i: Integer;
    begin
        Result.Append(Str);
        for i := StrLen(Str) + 1 to Length do
            Result.Append(Format(PadChar));
        exit(Result.ToText());
    end;
}
