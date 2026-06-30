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

function AmmoRefillReplacer(const FileStrings: TStrings; const BlockBeginLineNumber: ValSInt; const BlockEndLineNumber: ValSInt): String;
var
  RefillDelay: String;
  ParsedRefillDelay: Single;
begin
  Result := '';
  RefillDelay := FindKeyValue(FileStrings, BlockBeginLineNumber, BlockEndLineNumber, 'ammo_refill_delay');
  if TryStrToFloat(RefillDelay, ParsedRefillDelay) then
    Result := ParseFloatStringToNumberString((1 / ParsedRefillDelay).ToString);
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

  Result[5].Placeholder := '$refillDelay';
  Result[5].Replacer := @AmmoRefillReplacer;

  Result[6] := GetHitpointsReplacer;
  Result[7] := GetPowerUsageReplacer;
  Result[8] := GetMassReplacer;
  Result[9] := GetVolumeReplacer;
end;

end.
