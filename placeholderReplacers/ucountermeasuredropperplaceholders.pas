unit UCounterMeasureDropperPlaceholders;

{$mode ObjFPC}{$H+}

interface

uses
  Classes,
  SysUtils,
  UPlaceholderReplacerCommons;

function GetCounterMeasureDropperPlaceholderReplacers: TPlaceholderReplacerArray;

implementation

uses
  UBlockParsing,
  UProjectileReplacers;

function RefireRateReplacer(const FileStrings: TStrings; const BlockBeginLineNumber: ValSInt; const BlockEndLineNumber: ValSInt): String;
var
  RefireDelay: String;
  ParsedRefireDelay: Single;
begin
  Result := '';
  RefireDelay := FindKeyValue(FileStrings, BlockBeginLineNumber, BlockEndLineNumber, 'refire_delay');
  if TryStrToFloat(RefireDelay, ParsedRefireDelay) then
    Result := ParseFloatStringToNumberString((1 / ParsedRefireDelay).ToString);
end;

function SpeedReplacer(const FileStrings: TStrings; const BlockBeginLineNumber: ValSInt; const BlockEndLineNumber: ValSInt): String;
begin
  Result := ParseFloatStringToNumberString(FindKeyValue(FileStrings, BlockBeginLineNumber, BlockEndLineNumber, 'muzzle_velocity'));
end;

function RangeReplacer(const FileStrings: TStrings; const BlockBeginLineNumber: ValSInt; const BlockEndLineNumber: ValSInt): String;
begin                                        
  Result := UProjectileReplacers.RangeReplacer(FindProjectileArch(FileStrings, BlockBeginLineNumber, BlockEndLineNumber));
end;

function DiversionReplacer(const FileStrings: TStrings; const BlockBeginLineNumber: ValSInt; const BlockEndLineNumber: ValSInt): String;
begin                                             
  Result := UProjectileReplacers.DiversionReplacer(FindProjectileArch(FileStrings, BlockBeginLineNumber, BlockEndLineNumber));
end;

function LifetimeReplacer(const FileStrings: TStrings; const BlockBeginLineNumber: ValSInt; const BlockEndLineNumber: ValSInt): String;
begin
  Result := UProjectileReplacers.LifetimeReplacer(FindProjectileArch(FileStrings, BlockBeginLineNumber, BlockEndLineNumber));
end;

function GetCounterMeasureDropperPlaceholderReplacers: TPlaceholderReplacerArray;
begin
  Result := nil;
  SetLength(Result, 9);

  Result[0].Placeholder := '$refireRate';
  Result[0].Replacer := @RefireRateReplacer;

  Result[1].Placeholder := '$speed';
  Result[1].Replacer := @SpeedReplacer;

  Result[2].Placeholder := '$range';
  Result[2].Replacer := @RangeReplacer;

  Result[3].Placeholder := '$diversion';
  Result[3].Replacer := @DiversionReplacer;

  Result[4].Placeholder := '$lifetime';
  Result[4].Replacer := @LifetimeReplacer;

  Result[5] := GetHitpointsReplacer;
  Result[6] := GetPowerUsageReplacer;
  Result[7] := GetMassReplacer;
  Result[8] := GetVolumeReplacer;
end;

end.
