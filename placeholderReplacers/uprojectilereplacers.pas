unit UProjectileReplacers;

{$mode ObjFPC}{$H+}

interface

uses
  Classes,
  SysUtils,
  UBlockParsing;

function FindProjectileArch(const FileStrings: TStrings; const BlockBeginLineNumber: ValSInt; const BlockEndLineNumber: ValSInt): TBlockPositions;
function DamageTypeReplacer(const ProjectileArch: TBlockPositions): String;
function LifetimeParser(const ProjectileArch: TBlockPositions): Single;
function LifetimeReplacer(const ProjectileArch: TBlockPositions): String;
function RangeReplacer(const ProjectileArch: TBlockPositions): String;
function DiversionReplacer(const ProjectileArch: TBlockPositions): String;
function TopSpeedParser(const ProjectileArch: TBlockPositions): Single;
function TopSpeedReplacer(const ProjectileArch: TBlockPositions): String;
function AccelerationReplacer(const ProjectileArch: TBlockPositions): String;
function TurnRateReplacer(const ProjectileArch: TBlockPositions): String;
function SeekRangeReplacer(const ProjectileArch: TBlockPositions): String;
function DetonationDistanceReplacer(const ProjectileArch: TBlockPositions): String;
function SafeTimeReplacer(const ProjectileArch: TBlockPositions): String;
function TimeToLockReplacer(const ProjectileArch: TBlockPositions): String;
function HullDamageReplacer(const ProjectileArch: TBlockPositions): String;
function EnergyDamageReplacer(const ProjectileArch: TBlockPositions): String;
function ImpulseReplacer(const ProjectileArch: TBlockPositions): String;
function ExplosionRadiusReplacer(const ProjectileArch: TBlockPositions): String;
function AmmoLimitReplacer(const ProjectileArch: TBlockPositions): String;                 
function AmmoRefillDelayReplacer(const ProjectileArch: TBlockPositions): String;

implementation

uses
  Math,
  UPlaceholderReplacerCommons,
  UExplosionReplacers;

const
  ShieldDamageFactor = 0.5;

function FindProjectileArch(const FileStrings: TStrings; const BlockBeginLineNumber: ValSInt; const BlockEndLineNumber: ValSInt): TBlockPositions;
var
  ProjectileNickname: String;
begin
  Result.Strings := FileStrings;
  Result.BeginLineNumber := -1;
  Result.EndLineNumber := -1;
  ProjectileNickname := FindKeyValue(FileStrings, BlockBeginLineNumber, BlockEndLineNumber, 'projectile_archetype');
  if ProjectileNickname.Length > 0 then
  begin
    Result.BeginLineNumber := FindBlockBeginByNickname(FileStrings, ProjectileNickname) + 1;
    Result.EndLineNumber := FindBlockEnd(FileStrings, Result.BeginLineNumber);
  end;
end;

function DamageTypeReplacer(const ProjectileArch: TBlockPositions): String;
begin
  Result := '';
  if (ProjectileArch.BeginLineNumber >= 0) and (ProjectileArch.EndLineNumber > ProjectileArch.BeginLineNumber) then
  begin
    case FindKeyValue(ProjectileArch.Strings, ProjectileArch.BeginLineNumber, ProjectileArch.EndLineNumber, 'weapon_type') of
      'w_laser': Result := 'Laser';
      'w_plasma': Result := 'Plasma';
      'w_tachyon': Result := 'Tachyon';
      'w_neutron': Result := 'Neutron';
      'w_particle': Result := 'Particle';
      'w_photon': Result := 'Photon';
      'w_pulse': Result := 'Pulse';
      else
        Result := '';
    end;
  end;
end;

function LifetimeParser(const ProjectileArch: TBlockPositions): Single;
begin
  Result := 0;
  if (ProjectileArch.BeginLineNumber >= 0) and (ProjectileArch.EndLineNumber > ProjectileArch.BeginLineNumber) then
    TryStrToFloat(FindKeyValue(ProjectileArch.Strings, ProjectileArch.BeginLineNumber, ProjectileArch.EndLineNumber, 'lifetime'), Result);
end;

function LifetimeReplacer(const ProjectileArch: TBlockPositions): String;
begin
  Result := '';
  if (ProjectileArch.BeginLineNumber >= 0) and (ProjectileArch.EndLineNumber > ProjectileArch.BeginLineNumber) then
    Result := ParseFloatStringToNumberString(LifetimeParser(ProjectileArch).ToString);
end;

function RangeReplacer(const ProjectileArch: TBlockPositions): String;
begin
  Result := '';
  if (ProjectileArch.BeginLineNumber >= 0) and (ProjectileArch.EndLineNumber > ProjectileArch.BeginLineNumber) then
    Result := ParseFloatStringToNumberString(FindKeyValue(ProjectileArch.Strings, ProjectileArch.BeginLineNumber, ProjectileArch.EndLineNumber, 'range'));
end;

function DiversionReplacer(const ProjectileArch: TBlockPositions): String;
begin
  Result := '';
  if (ProjectileArch.BeginLineNumber >= 0) and (ProjectileArch.EndLineNumber > ProjectileArch.BeginLineNumber) then
    Result := ParseFloatStringToNumberString(FindKeyValue(ProjectileArch.Strings, ProjectileArch.BeginLineNumber, ProjectileArch.EndLineNumber, 'diversion_pctg'));
end;

function TopSpeedParser(const ProjectileArch: TBlockPositions): Single;
var
  TopSpeed: String;
  MotorNickname: String;
  MotorBeginLineNumber: ValSInt;
  MotorEndLineNumber: ValSInt;
  MotorAcceleration: String;
  MotorLifetime: String;
  ParsedMotorAcceleration: Single;
  ParsedMotorLifetime: Single;
begin
  Result := 0;
  if (ProjectileArch.BeginLineNumber >= 0) and (ProjectileArch.EndLineNumber > ProjectileArch.BeginLineNumber) then
  begin
    // This is for Mines
    TopSpeed := FindKeyValue(ProjectileArch.Strings, ProjectileArch.BeginLineNumber, ProjectileArch.EndLineNumber, 'top_speed');
    if not TopSpeed.IsEmpty then
      TryStrToFloat(TopSpeed, Result)
    // This is for any Missiles
    else
    begin
      MotorNickname := FindKeyValue(ProjectileArch.Strings, ProjectileArch.BeginLineNumber, ProjectileArch.EndLineNumber, 'motor');
      if MotorNickname.Length > 0 then
      begin
        MotorBeginLineNumber := FindBlockBeginByNickname(ProjectileArch.Strings, MotorNickname) + 1;
        MotorEndLineNumber := FindBlockEnd(ProjectileArch.Strings, MotorBeginLineNumber);
        MotorAcceleration := FindKeyValue(ProjectileArch.Strings, MotorBeginLineNumber, MotorEndLineNumber, 'accel');
        MotorLifetime := FindKeyValue(ProjectileArch.Strings, MotorBeginLineNumber, MotorEndLineNumber, 'lifetime');
        if TryStrToFloat(MotorAcceleration, ParsedMotorAcceleration) and TryStrToFloat(MotorLifetime, ParsedMotorLifetime) then
          Result := ParsedMotorAcceleration * ParsedMotorLifetime;
      end;
    end;
  end;
end;

function TopSpeedReplacer(const ProjectileArch: TBlockPositions): String;
begin
  Result := '';
  if (ProjectileArch.BeginLineNumber >= 0) and (ProjectileArch.EndLineNumber > ProjectileArch.BeginLineNumber) then
    Result := ParseFloatStringToNumberString(TopSpeedParser(ProjectileArch).ToString);
end;

function AccelerationReplacer(const ProjectileArch: TBlockPositions): String;
var
  MotorNickname: String;
  MotorBeginLineNumber: ValSInt;
  MotorEndLineNumber: ValSInt;
begin
  Result := '';
  if (ProjectileArch.BeginLineNumber >= 0) and (ProjectileArch.EndLineNumber > ProjectileArch.BeginLineNumber) then
  begin
    // This is for Mines
    Result := ParseFloatStringToNumberString(FindKeyValue(ProjectileArch.Strings, ProjectileArch.BeginLineNumber, ProjectileArch.EndLineNumber, 'acceleration'));
    // This is for any Missiles
    if Result.IsEmpty then
    begin
      MotorNickname := FindKeyValue(ProjectileArch.Strings, ProjectileArch.BeginLineNumber, ProjectileArch.EndLineNumber, 'motor');
      if MotorNickname.Length > 0 then
      begin
        MotorBeginLineNumber := FindBlockBeginByNickname(ProjectileArch.Strings, MotorNickname) + 1;
        MotorEndLineNumber := FindBlockEnd(ProjectileArch.Strings, MotorBeginLineNumber);
        Result := ParseFloatStringToNumberString(FindKeyValue(ProjectileArch.Strings, MotorBeginLineNumber, MotorEndLineNumber, 'accel'));
      end;
    end;
  end;
end;

function TurnRateReplacer(const ProjectileArch: TBlockPositions): String;
var
  ParsedAngularVelocity: Single;
begin
  Result := '';
  if (ProjectileArch.BeginLineNumber >= 0) and (ProjectileArch.EndLineNumber > ProjectileArch.BeginLineNumber) then
    if TryStrToFloat(FindKeyValue(ProjectileArch.Strings, ProjectileArch.BeginLineNumber, ProjectileArch.EndLineNumber, 'max_angular_velocity'), ParsedAngularVelocity) then
      Result := ParseFloatStringToNumberString(Math.RadToDeg(ParsedAngularVelocity).ToString);
end;

function SeekRangeReplacer(const ProjectileArch: TBlockPositions): String;
begin
  Result := '';
  if (ProjectileArch.BeginLineNumber >= 0) and (ProjectileArch.EndLineNumber > ProjectileArch.BeginLineNumber) then
  begin
    // This is for Mines
    Result := ParseFloatStringToNumberString(FindKeyValue(ProjectileArch.Strings, ProjectileArch.BeginLineNumber, ProjectileArch.EndLineNumber, 'seek_dist'));
    // This is for any Missiles
    if Result.IsEmpty then
      Result := ParseFloatStringToNumberString(FindKeyValue(ProjectileArch.Strings, ProjectileArch.BeginLineNumber, ProjectileArch.EndLineNumber, 'seeker_range'));
  end;
end;

function DetonationDistanceReplacer(const ProjectileArch: TBlockPositions): String;
begin
  Result := '';
  if (ProjectileArch.BeginLineNumber >= 0) and (ProjectileArch.EndLineNumber > ProjectileArch.BeginLineNumber) then
    Result := ParseFloatStringToNumberString(FindKeyValue(ProjectileArch.Strings, ProjectileArch.BeginLineNumber, ProjectileArch.EndLineNumber, 'detonation_dist'));
end;

function SafeTimeReplacer(const ProjectileArch: TBlockPositions): String;
begin
  Result := '';
  if (ProjectileArch.BeginLineNumber >= 0) and (ProjectileArch.EndLineNumber > ProjectileArch.BeginLineNumber) then
    Result := ParseFloatStringToNumberString(FindKeyValue(ProjectileArch.Strings, ProjectileArch.BeginLineNumber, ProjectileArch.EndLineNumber, 'owner_safe_time'));
end;

function TimeToLockReplacer(const ProjectileArch: TBlockPositions): String;
begin
  Result := '';
  if (ProjectileArch.BeginLineNumber >= 0) and (ProjectileArch.EndLineNumber > ProjectileArch.BeginLineNumber) then
    Result := ParseFloatStringToNumberString(FindKeyValue(ProjectileArch.Strings, ProjectileArch.BeginLineNumber, ProjectileArch.EndLineNumber, 'time_to_lock'));
end;

function HullDamageReplacer(const ProjectileArch: TBlockPositions): String;
begin
  Result := '';
  if (ProjectileArch.BeginLineNumber >= 0) and (ProjectileArch.EndLineNumber > ProjectileArch.BeginLineNumber) then
  begin
    // This is for any explosive projectiles
    Result := UExplosionReplacers.HullDamageReplacer(FindExplosionArch(ProjectileArch.Strings, ProjectileArch.BeginLineNumber, ProjectileArch.EndLineNumber));
    // This is for gun projectiles
    if Result.IsEmpty then
      Result := ParseFloatStringToNumberString(FindKeyValue(ProjectileArch.Strings, ProjectileArch.BeginLineNumber, ProjectileArch.EndLineNumber, 'hull_damage'));
  end;
end;

function EnergyDamageReplacer(const ProjectileArch: TBlockPositions): String;
var
  HullDamage: String;
  EnergyDamage: String;
  ParsedHullDamage: Single;
  ParsedEnergyDamage: Single;
begin
  Result := '';
  if (ProjectileArch.BeginLineNumber >= 0) and (ProjectileArch.EndLineNumber > ProjectileArch.BeginLineNumber) then
  begin
    // This is for any explosive projectiles
    Result := UExplosionReplacers.EnergyDamageReplacer(FindExplosionArch(ProjectileArch.Strings, ProjectileArch.BeginLineNumber, ProjectileArch.EndLineNumber));
    if Result.IsEmpty then
    begin
      HullDamage := FindKeyValue(ProjectileArch.Strings, ProjectileArch.BeginLineNumber, ProjectileArch.EndLineNumber, 'hull_damage');
      EnergyDamage := FindKeyValue(ProjectileArch.Strings, ProjectileArch.BeginLineNumber, ProjectileArch.EndLineNumber, 'energy_damage');
      if TryStrToFloat(HullDamage, ParsedHullDamage) and TryStrToFloat(EnergyDamage, ParsedEnergyDamage) then
        Result := ParseFloatStringToNumberString((ParsedHullDamage * ShieldDamageFactor + ParsedEnergyDamage).ToString);
    end;
  end;
end;

function ImpulseReplacer(const ProjectileArch: TBlockPositions): String;
begin
  Result := '';
  if (ProjectileArch.BeginLineNumber >= 0) and (ProjectileArch.EndLineNumber > ProjectileArch.BeginLineNumber) then
    Result := UExplosionReplacers.ImpulseReplacer(FindExplosionArch(ProjectileArch.Strings, ProjectileArch.BeginLineNumber, ProjectileArch.EndLineNumber));
end;

function ExplosionRadiusReplacer(const ProjectileArch: TBlockPositions): String;
begin
  Result := '';
  if (ProjectileArch.BeginLineNumber >= 0) and (ProjectileArch.EndLineNumber > ProjectileArch.BeginLineNumber) then
    Result := UExplosionReplacers.ExplosionRadiusReplacer(FindExplosionArch(ProjectileArch.Strings, ProjectileArch.BeginLineNumber, ProjectileArch.EndLineNumber));
end;

function AmmoLimitReplacer(const ProjectileArch: TBlockPositions): String;
begin
  Result := '';
  if (ProjectileArch.BeginLineNumber >= 0) and (ProjectileArch.EndLineNumber > ProjectileArch.BeginLineNumber) then
    Result := ParseFloatStringToNumberString(FindKeyValue(ProjectileArch.Strings, ProjectileArch.BeginLineNumber, ProjectileArch.EndLineNumber, 'ammo_limit'));
end;

function AmmoRefillDelayReplacer(const ProjectileArch: TBlockPositions): String;
begin
  Result := '';
  if (ProjectileArch.BeginLineNumber >= 0) and (ProjectileArch.EndLineNumber > ProjectileArch.BeginLineNumber) then
    Result := ParseFloatStringToNumberString(FindKeyValue(ProjectileArch.Strings, ProjectileArch.BeginLineNumber, ProjectileArch.EndLineNumber, 'ammo_refill_delay'));
end;

end.
