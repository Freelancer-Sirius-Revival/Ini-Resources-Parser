unit UBlockParsing;

{$mode ObjFPC}
{$H+}
{$modeSwitch advancedRecords}

interface

uses
  Classes,
  SysUtils;

type
  TBlockPositions = record
  public
    constructor Create(const Strings: TStrings; const BeginLineNumber: ValSInt; const EndLineNumber: ValSInt);
  var
    Strings: TStrings;
    BeginLineNumber: ValSInt;
    EndLineNumber: ValSInt;
  end;

function FindNextBlockBegin(const Strings: TStrings; LineNumber: ValSInt): ValSInt;
function FindBlockBegin(const Strings: TStrings; LineNumber: ValSInt): ValSInt;
function FindBlockBeginByNickname(const Strings: TStrings; const Nickname: String): ValSInt;
function FindBlockEnd(const Strings: TStrings; LineNumber: ValSInt): ValSInt;
function FindBlockType(const Strings: TStrings; LineNumber: ValSInt): String;
function FindKeyValue(const Strings: TStrings; const StartLineNumber: ValSInt; const EndLineNumber: ValSInt; const Key: String): String;

implementation

function FindNextBlockBegin(const Strings: TStrings; LineNumber: ValSInt): ValSInt;
var
  Line: String;
begin
  Result := -1;
  for LineNumber := LineNumber to Strings.Count - 1 do
  begin
    Line := Strings.Strings[LineNumber].Split(';')[0].Trim;
    if Line.StartsWith('[') and Line.EndsWith(']') then
    begin
      Result := LineNumber;
      Break;
    end;
  end;
end;

function FindBlockBegin(const Strings: TStrings; LineNumber: ValSInt): ValSInt;
var
  Line: String;
begin
  Result := -1;
  for LineNumber := LineNumber downto 0 do
  begin
    Line := Strings.Strings[LineNumber].Split(';')[0].Trim;
    if Line.StartsWith('[') and Line.EndsWith(']') then
    begin
      Result := LineNumber;
      Break;
    end;
  end;
end;

function FindBlockBeginByNickname(const Strings: TStrings; const Nickname: String): ValSInt;
var
  LineNumber: ValSInt;
  Line: String;
begin
  Result := -1;
  for LineNumber := 0 to Strings.Count - 1 do
  begin
    Line := Strings.Strings[LineNumber].Split(';')[0].Trim.ToLower;
    if Line.StartsWith('nickname') and Line.EndsWith(Nickname) then
    begin
      Result := FindBlockBegin(Strings, LineNumber);
      Break;
    end;
  end;
end;

function FindBlockEnd(const Strings: TStrings; LineNumber: ValSInt): ValSInt;
var
  Line: String;
begin
  Result := Strings.Count - 1;
  for LineNumber := LineNumber to Strings.Count - 1 do
  begin
    Line := Strings.Strings[LineNumber].Split(';')[0].Trim;
    if Line.StartsWith('[') and Line.EndsWith(']') then
    begin
      Result := LineNumber - 1;
      Break;
    end;
  end;
end;

function FindBlockType(const Strings: TStrings; LineNumber: ValSInt): String;
var
  Line: String;
begin
  Result := '';
  LineNumber := FindBlockBegin(Strings, LineNumber);
  if LineNumber >= 0 then
  begin
    Line := Strings.Strings[LineNumber].Split(';')[0].Trim;
    if Line.StartsWith('[') and Line.EndsWith(']') then
    begin
      Result := Line.Substring(1, Line.Length - 2);
    end;
  end;
end;

function FindKeyValue(const Strings: TStrings; const StartLineNumber: ValSInt; const EndLineNumber: ValSInt; const Key: String): String;
var
  LineNumber: ValSInt;
  Line: String;
begin
  Result := '';
  for LineNumber := StartLineNumber to EndLineNumber do
  begin
    Line := Strings.Strings[LineNumber].Split(';')[0].Trim.ToLower;
    if Line.StartsWith(Key) then
    begin
      Result := Line.Substring(Line.IndexOf('=') + 1).Trim;
      Break;
    end;
  end;
end;

constructor TBlockPositions.Create(const Strings: TStrings; const BeginLineNumber: ValSInt; const EndLineNumber: ValSInt);
begin
  Self.Strings := Strings;
  Self.BeginLineNumber := BeginLineNumber;
  Self.EndLineNumber := EndLineNumber;
end;

end.
