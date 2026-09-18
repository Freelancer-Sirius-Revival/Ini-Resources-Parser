unit UGunPlaceholders;

{$mode ObjFPC}{$H+}

interface

uses
  Classes,
  SysUtils,
  UPlaceholderReplacerCommons;

function GetGunPlaceholderReplacers: TPlaceholderReplacerArray;
function GetGunClassHandle(const GunHardpointType: String): String;

implementation

uses
  UBlockParsing,
  UProjectileReplacers,
  Math;

function GetGunClassHandle(const GunHardpointType: String): String;
begin
  case GunHardpointType.ToLower of
    'hp_gun_special_1': Result := 'L';
    'hp_gun_special_2': Result := 'M';
    'hp_gun_special_3': Result := 'H';
    'hp_gun_special_4': Result := '';
    'hp_gun_special_5': Result := '';
    'hp_gun_special_6': Result := '';
    'hp_gun_special_7': Result := '';
    'hp_gun_special_8': Result := '';
    'hp_gun_special_9': Result := '';
    'hp_gun_special_10': Result := 'X';
    'hp_turret_special_1': Result := '';
    'hp_turret_special_2': Result := 'L';
    'hp_turret_special_3': Result := 'M';
    'hp_turret_special_4': Result := 'H';
    'hp_turret_special_5': Result := 'X';
    'hp_turret_special_6': Result := '';
    'hp_turret_special_7': Result := 'L';
    'hp_turret_special_8': Result := 'M';
    'hp_turret_special_9': Result := 'H';
    'hp_turret_special_10': Result := 'X';
    'hp_torpedo_special_1': Result := 'X';
    'hp_torpedo_special_2': Result := 'X';
    else
      Result := '';
  end;
end;

function ShortClassReplacer(const FileStrings: TStrings; const BlockBeginLineNumber: ValSInt; const BlockEndLineNumber: ValSInt): String;
begin
  Result := GetGunClassHandle(FindKeyValue(FileStrings, BlockBeginLineNumber, BlockEndLineNumber, 'hp_gun_type'));
end;

function LongClassReplacer(const FileStrings: TStrings; const BlockBeginLineNumber: ValSInt; const BlockEndLineNumber: ValSInt): String;
begin
  case FindKeyValue(FileStrings, BlockBeginLineNumber, BlockEndLineNumber, 'hp_gun_type') of
    'hp_gun_special_1': Result := 'Light';
    'hp_gun_special_2': Result := 'Medium';
    'hp_gun_special_3': Result := 'Heavy';
    'hp_gun_special_4': Result := '';
    'hp_gun_special_5': Result := '';
    'hp_gun_special_6': Result := '';
    'hp_gun_special_7': Result := '';
    'hp_gun_special_8': Result := '';
    'hp_gun_special_9': Result := '';
    'hp_gun_special_10': Result := 'Super Heavy';
    'hp_turret_special_1': Result := '';
    'hp_turret_special_2': Result := 'Light';
    'hp_turret_special_3': Result := 'Medium';
    'hp_turret_special_4': Result := 'Heavy';
    'hp_turret_special_5': Result := 'Super Heavy';
    'hp_turret_special_6': Result := '';
    'hp_turret_special_7': Result := 'Light';
    'hp_turret_special_8': Result := 'Medium';
    'hp_turret_special_9': Result := 'Heavy';
    'hp_turret_special_10': Result := 'Super Heavy';
    'hp_torpedo_special_1': Result := 'Super Heavy';
    'hp_torpedo_special_2': Result := 'Super Heavy';
    else
      Result := '';
  end;
end;

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
var
  ParsedMuzzleVelocity: Single;
  ParsedTopSpeed: Single;
begin
  Result := '';
  if TryStrToFloat(FindKeyValue(FileStrings, BlockBeginLineNumber, BlockEndLineNumber, 'muzzle_velocity'), ParsedMuzzleVelocity) then
  begin
    ParsedTopSpeed := TopSpeedParser(FindProjectileArch(FileStrings, BlockBeginLineNumber, BlockEndLineNumber));
    Result := ParseFloatStringToNumberString((ParsedMuzzleVelocity + ParsedTopSpeed).ToString);
  end;
end;

function RangeParser(const FileStrings: TStrings; const BlockBeginLineNumber: ValSInt; const BlockEndLineNumber: ValSInt): Single;
var
  ParsedMuzzleVelocity: Single;
  ParsedTopSpeed: Single;
  ParsedLifetime: Single;
begin
  Result := 0;
  if TryStrToFloat(FindKeyValue(FileStrings, BlockBeginLineNumber, BlockEndLineNumber, 'muzzle_velocity'), ParsedMuzzleVelocity) then
  begin
    ParsedTopSpeed := TopSpeedParser(FindProjectileArch(FileStrings, BlockBeginLineNumber, BlockEndLineNumber));
    ParsedLifetime := LifetimeParser(FindProjectileArch(FileStrings, BlockBeginLineNumber, BlockEndLineNumber));
    Result := ParsedLifetime * (ParsedMuzzleVelocity + ParsedTopSpeed);
  end;
end;

function DispersionReplacer(const FileStrings: TStrings; const BlockBeginLineNumber: ValSInt; const BlockEndLineNumber: ValSInt): String;
var
  ParsedDispersionAngle: Single;
begin
  Result := '';
  if TryStrToFloat(FindKeyValue(FileStrings, BlockBeginLineNumber, BlockEndLineNumber, 'dispersion_angle'), ParsedDispersionAngle) then
    Result := ParseFloatStringToNumberString((RangeParser(FileStrings, BlockBeginLineNumber, BlockEndLineNumber) * Math.Tan(Math.DegToRad(ParsedDispersionAngle)) * 2).ToString);
end;

function AccelerationReplacer(const FileStrings: TStrings; const BlockBeginLineNumber: ValSInt; const BlockEndLineNumber: ValSInt): String;
begin
  Result := UProjectileReplacers.AccelerationReplacer(FindProjectileArch(FileStrings, BlockBeginLineNumber, BlockEndLineNumber));
end;

function MunitionTurnRateReplacer(const FileStrings: TStrings; const BlockBeginLineNumber: ValSInt; const BlockEndLineNumber: ValSInt): String;
begin
  Result := UProjectileReplacers.TurnRateReplacer(FindProjectileArch(FileStrings, BlockBeginLineNumber, BlockEndLineNumber));
end;

function SeekRangeReplacer(const FileStrings: TStrings; const BlockBeginLineNumber: ValSInt; const BlockEndLineNumber: ValSInt): String;
begin
  Result := UProjectileReplacers.SeekRangeReplacer(FindProjectileArch(FileStrings, BlockBeginLineNumber, BlockEndLineNumber));
end;

function TimeToLockReplacer(const FileStrings: TStrings; const BlockBeginLineNumber: ValSInt; const BlockEndLineNumber: ValSInt): String;
begin
  Result := UProjectileReplacers.TimeToLockReplacer(FindProjectileArch(FileStrings, BlockBeginLineNumber, BlockEndLineNumber));
end;

function DetonationDistanceReplacer(const FileStrings: TStrings; const BlockBeginLineNumber: ValSInt; const BlockEndLineNumber: ValSInt): String;
begin
  Result := UProjectileReplacers.DetonationDistanceReplacer(FindProjectileArch(FileStrings, BlockBeginLineNumber, BlockEndLineNumber));
end;

function DamageTypeReplacer(const FileStrings: TStrings; const BlockBeginLineNumber: ValSInt; const BlockEndLineNumber: ValSInt): String;
begin
  Result := UProjectileReplacers.DamageTypeReplacer(FindProjectileArch(FileStrings, BlockBeginLineNumber, BlockEndLineNumber));
end;

function LifetimeReplacer(const FileStrings: TStrings; const BlockBeginLineNumber: ValSInt; const BlockEndLineNumber: ValSInt): String;
begin
  Result := UProjectileReplacers.LifetimeReplacer(FindProjectileArch(FileStrings, BlockBeginLineNumber, BlockEndLineNumber));
end;

function RangeReplacer(const FileStrings: TStrings; const BlockBeginLineNumber: ValSInt; const BlockEndLineNumber: ValSInt): String;
begin
  Result := ParseFloatStringToNumberString(RangeParser(FileStrings, BlockBeginLineNumber, BlockEndLineNumber).ToString);
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

function TurretTurnRateReplacer(const FileStrings: TStrings; const BlockBeginLineNumber: ValSInt; const BlockEndLineNumber: ValSInt): String;
begin
  Result := ParseFloatStringToNumberString(FindKeyValue(FileStrings, BlockBeginLineNumber, BlockEndLineNumber, 'turn_rate'));
end;         

function AmmoLimitReplacer(const FileStrings: TStrings; const BlockBeginLineNumber: ValSInt; const BlockEndLineNumber: ValSInt): String;
begin
  Result := UProjectileReplacers.AmmoLimitReplacer(FindProjectileArch(FileStrings, BlockBeginLineNumber, BlockEndLineNumber));
end;

function GetGunPlaceholderReplacers: TPlaceholderReplacerArray;
begin
  Result := nil;
  SetLength(Result, 23);

  Result[0].Placeholder := '$classLong';
  Result[0].Replacer := @LongClassReplacer;

  Result[1].Placeholder := '$class';
  Result[1].Replacer := @ShortClassReplacer;

  Result[2].Placeholder := '$turnRate';
  Result[2].Replacer := @TurretTurnRateReplacer;

  Result[3].Placeholder := '$speed';
  Result[3].Replacer := @SpeedReplacer;

  Result[4].Placeholder := '$dispersion';
  Result[4].Replacer := @DispersionReplacer;

  Result[5].Placeholder := '$acceleration';
  Result[5].Replacer := @AccelerationReplacer;

  Result[6].Placeholder := '$munitionTurnRate';
  Result[6].Replacer := @MunitionTurnRateReplacer;

  Result[7].Placeholder := '$seekRange';
  Result[7].Replacer := @SeekRangeReplacer;

  Result[8].Placeholder := '$timeToLock';
  Result[8].Replacer := @TimeToLockReplacer;

  Result[9].Placeholder := '$detonationDistance';
  Result[9].Replacer := @DetonationDistanceReplacer;

  Result[10].Placeholder := '$damageType';
  Result[10].Replacer := @DamageTypeReplacer;

  Result[11].Placeholder := '$lifetime';
  Result[11].Replacer := @LifetimeReplacer;

  Result[12].Placeholder := '$range';
  Result[12].Replacer := @RangeReplacer;

  Result[13].Placeholder := '$hullDamage';
  Result[13].Replacer := @HullDamageReplacer;

  Result[14].Placeholder := '$energyDamage';
  Result[14].Replacer := @EnergyDamageReplacer;

  Result[15].Placeholder := '$impulse';
  Result[15].Replacer := @ImpulseReplacer;

  Result[16].Placeholder := '$explosionRadius';
  Result[16].Replacer := @ExplosionRadiusReplacer;

  Result[17].Placeholder := '$refireRate';
  Result[17].Replacer := @RefireRateReplacer;

  Result[18].Placeholder := '$ammoLimit';
  Result[18].Replacer := @AmmoLimitReplacer;

  Result[19] := GetHitpointsReplacer;
  Result[20] := GetPowerUsageReplacer;
  Result[21] := GetMassReplacer;
  Result[22] := GetVolumeReplacer;
end;

end.
