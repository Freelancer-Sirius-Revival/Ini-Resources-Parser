unit UMunitionPlaceholders;

{$mode ObjFPC}{$H+}

interface

uses
  Classes,
  SysUtils,
  UPlaceholderReplacerCommons;

function GetMunitionPlaceholderReplacers: TPlaceholderReplacerArray;

implementation

uses
  UBlockParsing,
  UProjectileReplacers;

function TopSpeedReplacer(const FileStrings: TStrings; const BlockBeginLineNumber: ValSInt; const BlockEndLineNumber: ValSInt): String;
begin
  Result := UProjectileReplacers.TopSpeedReplacer(TBlockPositions.Create(FileStrings, BlockBeginLineNumber, BlockEndLineNumber));
end;

function AccelerationReplacer(const FileStrings: TStrings; const BlockBeginLineNumber: ValSInt; const BlockEndLineNumber: ValSInt): String;
begin
  Result := UProjectileReplacers.AccelerationReplacer(TBlockPositions.Create(FileStrings, BlockBeginLineNumber, BlockEndLineNumber));
end;            

function TurnRateReplacer(const FileStrings: TStrings; const BlockBeginLineNumber: ValSInt; const BlockEndLineNumber: ValSInt): String;
begin
  Result := UProjectileReplacers.TurnRateReplacer(TBlockPositions.Create(FileStrings, BlockBeginLineNumber, BlockEndLineNumber));
end;

function SeekRangeReplacer(const FileStrings: TStrings; const BlockBeginLineNumber: ValSInt; const BlockEndLineNumber: ValSInt): String;
begin
  Result := UProjectileReplacers.SeekRangeReplacer(TBlockPositions.Create(FileStrings, BlockBeginLineNumber, BlockEndLineNumber));
end;

function TimeToLockReplacer(const FileStrings: TStrings; const BlockBeginLineNumber: ValSInt; const BlockEndLineNumber: ValSInt): String;
begin
  Result := UProjectileReplacers.TimeToLockReplacer(TBlockPositions.Create(FileStrings, BlockBeginLineNumber, BlockEndLineNumber));
end;

function DetonationDistanceReplacer(const FileStrings: TStrings; const BlockBeginLineNumber: ValSInt; const BlockEndLineNumber: ValSInt): String;
begin
  Result := UProjectileReplacers.DetonationDistanceReplacer(TBlockPositions.Create(FileStrings, BlockBeginLineNumber, BlockEndLineNumber));
end;

function DamageTypeReplacer(const FileStrings: TStrings; const BlockBeginLineNumber: ValSInt; const BlockEndLineNumber: ValSInt): String;
begin
  Result := UProjectileReplacers.DamageTypeReplacer(TBlockPositions.Create(FileStrings, BlockBeginLineNumber, BlockEndLineNumber));
end;

function LifetimeReplacer(const FileStrings: TStrings; const BlockBeginLineNumber: ValSInt; const BlockEndLineNumber: ValSInt): String;
begin
  Result := UProjectileReplacers.LifetimeReplacer(TBlockPositions.Create(FileStrings, BlockBeginLineNumber, BlockEndLineNumber));
end;

function HullDamageReplacer(const FileStrings: TStrings; const BlockBeginLineNumber: ValSInt; const BlockEndLineNumber: ValSInt): String;
begin
  Result := UProjectileReplacers.HullDamageReplacer(TBlockPositions.Create(FileStrings, BlockBeginLineNumber, BlockEndLineNumber));
end;

function EnergyDamageReplacer(const FileStrings: TStrings; const BlockBeginLineNumber: ValSInt; const BlockEndLineNumber: ValSInt): String;
begin
  Result := UProjectileReplacers.EnergyDamageReplacer(TBlockPositions.Create(FileStrings, BlockBeginLineNumber, BlockEndLineNumber));
end;

function ImpulseReplacer(const FileStrings: TStrings; const BlockBeginLineNumber: ValSInt; const BlockEndLineNumber: ValSInt): String;
begin
  Result := UProjectileReplacers.ImpulseReplacer(TBlockPositions.Create(FileStrings, BlockBeginLineNumber, BlockEndLineNumber));
end;

function ExplosionRadiusReplacer(const FileStrings: TStrings; const BlockBeginLineNumber: ValSInt; const BlockEndLineNumber: ValSInt): String;
begin
  Result := UProjectileReplacers.ExplosionRadiusReplacer(TBlockPositions.Create(FileStrings, BlockBeginLineNumber, BlockEndLineNumber));
end;       

function AmmoLimitReplacer(const FileStrings: TStrings; const BlockBeginLineNumber: ValSInt; const BlockEndLineNumber: ValSInt): String;
begin
  Result := UProjectileReplacers.AmmoLimitReplacer(TBlockPositions.Create(FileStrings, BlockBeginLineNumber, BlockEndLineNumber));
end;

function GetMunitionPlaceholderReplacers: TPlaceholderReplacerArray;
begin
  Result := nil;
  SetLength(Result, 16);

  Result[0].Placeholder := '$topSpeed';
  Result[0].Replacer := @TopSpeedReplacer;

  Result[1].Placeholder := '$acceleration';
  Result[1].Replacer := @AccelerationReplacer;       

  Result[2].Placeholder := '$turnRate';
  Result[2].Replacer := @TurnRateReplacer;

  Result[3].Placeholder := '$seekRange';
  Result[3].Replacer := @SeekRangeReplacer;
                                                 
  Result[4].Placeholder := '$timeToLock';
  Result[4].Replacer := @TimeToLockReplacer;

  Result[5].Placeholder := '$detonationDistance';
  Result[5].Replacer := @DetonationDistanceReplacer;

  Result[6].Placeholder := '$damageType';
  Result[6].Replacer := @DamageTypeReplacer;

  Result[7].Placeholder := '$lifetime';
  Result[7].Replacer := @LifetimeReplacer;

  Result[8].Placeholder := '$hullDamage';
  Result[8].Replacer := @HullDamageReplacer;

  Result[9].Placeholder := '$energyDamage';
  Result[9].Replacer := @EnergyDamageReplacer;

  Result[10].Placeholder := '$impulse';
  Result[10].Replacer := @ImpulseReplacer;

  Result[11].Placeholder := '$explosionRadius';
  Result[11].Replacer := @ExplosionRadiusReplacer;

  Result[12].Placeholder := '$ammoLimit';
  Result[12].Replacer := @AmmoLimitReplacer;

  Result[13] := GetHitpointsReplacer;
  Result[14] := GetMassReplacer;
  Result[15] := GetVolumeReplacer;
end;

end.
