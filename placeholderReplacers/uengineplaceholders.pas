unit UEnginePlaceholders;

{$mode ObjFPC}{$H+}

interface

uses
  Classes,
  SysUtils,
  UPlaceholderReplacerCommons;

function GetEnginePlaceholderReplacers: TPlaceholderReplacerArray;  
function GetEngineClassHandle(const EngineHardpointType: String): String;

implementation

uses
  UBlockParsing;

function GetEngineClassHandle(const EngineHardpointType: String): String;
begin
  case EngineHardpointType.ToLower of
    'hp_fighter_engine_special_1': Result := 'L';
    'hp_fighter_engine_special_2': Result := 'H';
    'hp_freighter_engine_special_1': Result := 'X';
    'hp_freighter_engine_special_2': Result := 'L';
    'hp_freighter_engine_special_3': Result := 'M';
    'hp_freighter_engine_special_4': Result := 'H';
    'hp_freighter_engine_special_5': Result := 'X';
    'hp_freighter_engine_special_8': Result := 'L';
    'hp_freighter_engine_special_9': Result := 'M';
    'hp_freighter_engine_special_10': Result := 'H';
    else
      Result := '';
  end;
end;

function ShortClassReplacer(const FileStrings: TStrings; const BlockBeginLineNumber: ValSInt; const BlockEndLineNumber: ValSInt): String;
begin
  Result := GetEngineClassHandle(FindKeyValue(FileStrings, BlockBeginLineNumber, BlockEndLineNumber, 'hp_type'));
end;

function LongClassReplacer(const FileStrings: TStrings; const BlockBeginLineNumber: ValSInt; const BlockEndLineNumber: ValSInt): String;
begin
  case FindKeyValue(FileStrings, BlockBeginLineNumber, BlockEndLineNumber, 'hp_type') of
    'hp_fighter_engine_special_1': Result := 'Light';
    'hp_fighter_engine_special_2': Result := 'Heavy';
    'hp_freighter_engine_special_1': Result := 'Super Heavy';
    'hp_freighter_engine_special_2': Result := 'Light';
    'hp_freighter_engine_special_3': Result := 'Medium';
    'hp_freighter_engine_special_4': Result := 'Heavy';
    'hp_freighter_engine_special_5': Result := 'Super Heavy';
    'hp_freighter_engine_special_8': Result := 'Light';
    'hp_freighter_engine_special_9': Result := 'Medium';
    'hp_freighter_engine_special_10': Result := 'Heavy';
    else
      Result := '';
  end;
end;

function SpeedReplacer(const FileStrings: TStrings; const BlockBeginLineNumber: ValSInt; const BlockEndLineNumber: ValSInt): String;
var
  Force: String;
  Drag: String;
  ParsedForce: Single;
  ParsedDrag: Single;
begin
  Result := '';
  Force := FindKeyValue(FileStrings, BlockBeginLineNumber, BlockEndLineNumber, 'max_force');
  Drag := FindKeyValue(FileStrings, BlockBeginLineNumber, BlockEndLineNumber, 'linear_drag');
  if TryStrToFloat(Force, ParsedForce) and TryStrToFloat(Drag, ParsedDrag) then
    Result := ParseFloatStringToNumberString((ParsedForce / ParsedDrag).ToString);
end;

function ReverseSpeedReplacer(const FileStrings: TStrings; const BlockBeginLineNumber: ValSInt; const BlockEndLineNumber: ValSInt): String;
var
  Force: String;
  Drag: String;
  ReverseFraction: String;
  ParsedForce: Single;
  ParsedDrag: Single;
  ParsedReverseFraction: Single;
begin
  Result := '';
  Force := FindKeyValue(FileStrings, BlockBeginLineNumber, BlockEndLineNumber, 'max_force');
  Drag := FindKeyValue(FileStrings, BlockBeginLineNumber, BlockEndLineNumber, 'linear_drag');
  ReverseFraction := FindKeyValue(FileStrings, BlockBeginLineNumber, BlockEndLineNumber, 'reverse_fraction');
  if TryStrToFloat(Force, ParsedForce) and TryStrToFloat(Drag, ParsedDrag) and TryStrToFloat(ReverseFraction, ParsedReverseFraction) then
    Result := ParseFloatStringToNumberString(((ParsedForce / ParsedDrag) * ParsedReverseFraction).ToString);
end;

function CruiseSpeedReplacer(const FileStrings: TStrings; const BlockBeginLineNumber: ValSInt; const BlockEndLineNumber: ValSInt): String;
begin
  Result := ParseFloatStringToNumberString(FindKeyValue(FileStrings, BlockBeginLineNumber, BlockEndLineNumber, 'cruise_speed'));
end;

function CruiseChargeTimeReplacer(const FileStrings: TStrings; const BlockBeginLineNumber: ValSInt; const BlockEndLineNumber: ValSInt): String;
begin
  Result := ParseFloatStringToNumberString(FindKeyValue(FileStrings, BlockBeginLineNumber, BlockEndLineNumber, 'cruise_charge_time'));
end;

function CruisePowerUsageReplacer(const FileStrings: TStrings; const BlockBeginLineNumber: ValSInt; const BlockEndLineNumber: ValSInt): String;
begin
  Result := ParseFloatStringToNumberString(FindKeyValue(FileStrings, BlockBeginLineNumber, BlockEndLineNumber, 'cruise_power_usage'));
end;

function GetEnginePlaceholderReplacers: TPlaceholderReplacerArray;
begin
  Result := nil;
  SetLength(Result, 10);

  Result[0].Placeholder := '$classLong';
  Result[0].Replacer := @LongClassReplacer;

  Result[1].Placeholder := '$class';
  Result[1].Replacer := @ShortClassReplacer;

  Result[2].Placeholder := '$speed';
  Result[2].Replacer := @SpeedReplacer;

  Result[3].Placeholder := '$reverseSpeed';
  Result[3].Replacer := @ReverseSpeedReplacer;

  Result[4] := GetPowerUsageReplacer;

  Result[5].Placeholder := '$cruiseSpeed';
  Result[5].Replacer := @CruiseSpeedReplacer;

  Result[6].Placeholder := '$cruiseChargeTime';
  Result[6].Replacer := @CruiseChargeTimeReplacer;

  Result[7].Placeholder := '$cruisePowerUsage';
  Result[7].Replacer := @CruisePowerUsageReplacer;

  Result[8] := GetMassReplacer;
  Result[9] := GetVolumeReplacer;
end;

end.
