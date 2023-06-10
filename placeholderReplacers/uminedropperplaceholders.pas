unit UMineDropperPlaceholders;

{$mode ObjFPC}{$H+}

interface

uses
  Classes,
  SysUtils,
  UPlaceholderReplacerCommons;

function GetMineDropperPlaceholderReplacers: TPlaceholderReplacerArray;

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

function TopSpeedReplacer(const FileStrings: TStrings; const BlockBeginLineNumber: ValSInt; const BlockEndLineNumber: ValSInt): String;
begin
  Result := UProjectileReplacers.TopSpeedReplacer(FindProjectileArch(FileStrings, BlockBeginLineNumber, BlockEndLineNumber));
end;

function AccelerationReplacer(const FileStrings: TStrings; const BlockBeginLineNumber: ValSInt; const BlockEndLineNumber: ValSInt): String;
begin
  Result := UProjectileReplacers.AccelerationReplacer(FindProjectileArch(FileStrings, BlockBeginLineNumber, BlockEndLineNumber));
end;

function SeekRangeReplacer(const FileStrings: TStrings; const BlockBeginLineNumber: ValSInt; const BlockEndLineNumber: ValSInt): String;
begin
  Result := UProjectileReplacers.SeekRangeReplacer(FindProjectileArch(FileStrings, BlockBeginLineNumber, BlockEndLineNumber));
end;

function DetonationDistanceReplacer(const FileStrings: TStrings; const BlockBeginLineNumber: ValSInt; const BlockEndLineNumber: ValSInt): String;
begin
  Result := UProjectileReplacers.DetonationDistanceReplacer(FindProjectileArch(FileStrings, BlockBeginLineNumber, BlockEndLineNumber));
end;

function SafeTimeReplacer(const FileStrings: TStrings; const BlockBeginLineNumber: ValSInt; const BlockEndLineNumber: ValSInt): String;
begin
  Result := UProjectileReplacers.SafeTimeReplacer(FindProjectileArch(FileStrings, BlockBeginLineNumber, BlockEndLineNumber));
end;

function LifetimeReplacer(const FileStrings: TStrings; const BlockBeginLineNumber: ValSInt; const BlockEndLineNumber: ValSInt): String;
begin
  Result := UProjectileReplacers.LifetimeReplacer(FindProjectileArch(FileStrings, BlockBeginLineNumber, BlockEndLineNumber));
end;

function HullDamageReplacer(const FileStrings: TStrings; const BlockBeginLineNumber: ValSInt; const BlockEndLineNumber: ValSInt): String;
begin
  Result := UProjectileReplacers.HullDamageReplacer(FindProjectileArch(FileStrings, BlockBeginLineNumber, BlockEndLineNumber));
end;

function EnergyDamageReplacer(const FileStrings: TStrings; const BlockBeginLineNumber: ValSInt; const BlockEndLineNumber: ValSInt): String;
begin
  Result := UProjectileReplacers.EnergyDamageReplacer(FindProjectileArch(FileStrings, BlockBeginLineNumber, BlockEndLineNumber));
end;

function ImpulseReplacer(const FileStrings: TStrings; const BlockBeginLineNumber: ValSInt; const BlockEndLineNumber: ValSInt): String;
begin
  Result := UProjectileReplacers.ImpulseReplacer(FindProjectileArch(FileStrings, BlockBeginLineNumber, BlockEndLineNumber));
end;

function ExplosionRadiusReplacer(const FileStrings: TStrings; const BlockBeginLineNumber: ValSInt; const BlockEndLineNumber: ValSInt): String;
begin
  Result := UProjectileReplacers.ExplosionRadiusReplacer(FindProjectileArch(FileStrings, BlockBeginLineNumber, BlockEndLineNumber));
end;

function GetMineDropperPlaceholderReplacers: TPlaceholderReplacerArray;
begin
  Result := nil;
  SetLength(Result, 15);

  Result[0].Placeholder := '$topSpeed';
  Result[0].Replacer := @TopSpeedReplacer;

  Result[1].Placeholder := '$acceleration';
  Result[1].Replacer := @AccelerationReplacer;

  Result[2].Placeholder := '$seekRange';
  Result[2].Replacer := @SeekRangeReplacer;

  Result[3].Placeholder := '$detonationDistance';
  Result[3].Replacer := @DetonationDistanceReplacer;

  Result[4].Placeholder := '$safeTime';
  Result[4].Replacer := @SafeTimeReplacer;

  Result[5].Placeholder := '$lifetime';
  Result[5].Replacer := @LifetimeReplacer;

  Result[6].Placeholder := '$hullDamage';
  Result[6].Replacer := @HullDamageReplacer;

  Result[7].Placeholder := '$energyDamage';
  Result[7].Replacer := @EnergyDamageReplacer;

  Result[8].Placeholder := '$impulse';
  Result[8].Replacer := @ImpulseReplacer;

  Result[9].Placeholder := '$explosionRadius';
  Result[9].Replacer := @ExplosionRadiusReplacer;       

  Result[10].Placeholder := '$refireRate';
  Result[10].Replacer := @RefireRateReplacer;

  Result[11] := GetHitpointsReplacer;      
  Result[12] := GetPowerUsageReplacer;
  Result[13] := GetMassReplacer;
  Result[14] := GetVolumeReplacer;
end;

end.
