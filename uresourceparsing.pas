unit UResourceParsing;

{$mode ObjFPC}{$H+}

interface

uses
  Classes,
  SysUtils,
  Generics.Collections;

procedure Process(const DirectoryPath: String; const IdOffset: Uint32; const OutputFileName: String; const Log: TStrings);

implementation

uses
  FileUtil,
  UPlaceholderReplacing,
  UBlockParsing;

type
  TFileStrings = record
    FileName: String;
    Strings: TStringList;
  end;
  TFileStringsArray = array of TFileStrings;

  TResourceType = (NoType, StringType, HtmlType, LinkType);

  TFileResourceLink = record
    FileStrings: TStringList;
    FileStringsLineNumber: ValSInt;
    Resource: TStringList;
    ResourceType: TResourceType;
    MetaName: String;
    Id: Uint32;
  end;
  TFileResourceLinkArray = array of TFileResourceLink;

  TGameExplorationType = (Other, Group, SpaceObject, Zone, Base, StarSystem);

  TGameExploration = record
    ExplorationType: TGameExplorationType;
    Nickname: String;
    Ids: array of Uint32;
  end;
  TGameExplorationMap = specialize THashMap<String, TGameExploration>;

var
  Resources: TFileResourceLinkArray = nil;
  InfocardMap: TFileStrings = (FileName: ''; Strings: nil);
  KnowledgeMap: TFileStrings = (FileName: ''; Strings: nil);

procedure AddFileResource(const FileStrings: TStringList; const FileStringsLineNumber: ValSInt; const Resource: TStringList; const ResourceType: TResourceType; const MetaName: String; const ExistingId: Uint32);
var
  Entry: ^TFileResourceLink;
begin
  SetLength(Resources, Length(Resources) + 1);
  Entry := @Resources[High(Resources)];
  Entry^.FileStrings := FileStrings;
  Entry^.FileStringsLineNumber := FileStringsLineNumber;
  if Assigned(Resource) then
  begin
    Entry^.Resource := TStringList.Create;
    Entry^.Resource.Assign(Resource);
  end
  else
    Entry^.Resource := nil;
  Entry^.ResourceType := ResourceType;
  Entry^.MetaName := MetaName;
  Entry^.Id := ExistingId;
end;

type
  TUint32ResourceTypeMap = specialize THashMap<Uint32, TResourceType>;

function FindNextFreeIdForResourceType(const ExistingIdsWithType: TUint32ResourceTypeMap; const IdStart: Uint32; const ResourceType: TResourceType): Uint32;
var
  NextFreeId: Uint32;
  BlockStartId: Uint32;
  BlockId: Uint32;
  FoundType: TResourceType;
  SameResourceBlock: Boolean;
begin
  NextFreeId := IdStart;
  repeat
    begin
      while ExistingIdsWithType.ContainsKey(NextFreeId) do
        NextFreeId := NextFreeId + 1;
      BlockStartId := NextFreeId - NextFreeId mod 16;
      SameResourceBlock := True;
      for BlockId := BlockStartId to BlockStartId + 16 do
        if ExistingIdsWithType.TryGetValue(BlockId, FoundType) and (FoundType <> ResourceType) then
        begin
          SameResourceBlock := False;
          NextFreeId := BlockStartId + 16;
          Break;
        end;
    end
  until SameResourceBlock;
  Result := NextFreeId;
end;

procedure LinkResourcesWithIds(const Resources: TFileResourceLinkArray; const IdOffset: Uint32; const Log: TStrings);
var
  Index: ValSInt;
  MetaIndex: ValSInt;
  SameResourceCount: ValSInt;         
  ContinousIdCount: ValSInt;
  NextId: ValSInt;
  ExistingIdsWithType: TUint32ResourceTypeMap;
begin
  // Collect all already existing IDs
  ExistingIdsWithType := TUint32ResourceTypeMap.Create;
  for Index := 0 to High(Resources) do
    if Resources[Index].Id <> 0 then
    begin
      try
        ExistingIdsWithType.Add(Resources[Index].Id, Resources[Index].ResourceType);
      except
        On EListError do Log.Append('ID duplicated! ' + UIntToStr(Resources[Index].Id));
      end;
    end;

  for Index := 0 to High(Resources) do
    if (Resources[Index].ResourceType = TResourceType.StringType) and (Resources[Index].Id = 0) then
    begin
      for SameResourceCount := 0 to High(Resources) - Index do
        if (Resources[Index].FileStrings <> Resources[Index + SameResourceCount].FileStrings) or (Resources[Index].FileStringsLineNumber <> Resources[Index + SameResourceCount].FileStringsLineNumber) then
          Break;

      // Find a block of continous free IDs
      NextId := FindNextFreeIdForResourceType(ExistingIdsWithType, IdOffset, Resources[Index].ResourceType);            
      ContinousIdCount := 1;
      while ContinousIdCount < SameResourceCount do
      begin
        if NextId + ContinousIdCount = FindNextFreeIdForResourceType(ExistingIdsWithType, NextId + ContinousIdCount, Resources[Index].ResourceType) then
          ContinousIdCount := ContinousIdCount + 1
        else
        begin                
          NextId := FindNextFreeIdForResourceType(ExistingIdsWithType, NextId + ContinousIdCount + 1, Resources[Index].ResourceType);
          ContinousIdCount := 1;
        end;
      end;

      Resources[Index].Id := NextId;
      ExistingIdsWithType.Add(Resources[Index].Id, Resources[Index].ResourceType);
      Log.Append('Added new ID: ' + UIntToStr(Resources[Index].Id));
    end;

  for Index := 0 to High(Resources) do
    if (Resources[Index].ResourceType = TResourceType.HtmlType) and (Resources[Index].Id = 0) then
    begin
      Resources[Index].Id := FindNextFreeIdForResourceType(ExistingIdsWithType, IdOffset, Resources[Index].ResourceType);
      ExistingIdsWithType.Add(Resources[Index].Id, Resources[Index].ResourceType);
      Log.Append('Added new ID: ' + UIntToStr(Resources[Index].Id));
    end;

  // Link all ids that want other ids that are already existing.
  for Index := 0 to High(Resources) do
    if Resources[Index].ResourceType = TResourceType.LinkType then
      for MetaIndex := 0 to High(Resources) do
        if (Resources[MetaIndex].ResourceType <> TResourceType.LinkType) and (Resources[MetaIndex].MetaName.ToLower = Resources[Index].MetaName.ToLower) then
          Resources[Index].Id := Resources[MetaIndex].Id;

  ExistingIdsWithType.Free;
end;

function CreateFrcStrings(const Resources: TFileResourceLinkArray): TStringList;
var
  Resource: TFileResourceLink;
  LineIndex: ValSInt;
begin
  Result := TStringList.Create;
  for Resource in Resources do
    if Assigned(Resource.Resource) then
    begin
      if Resource.ResourceType = TResourceType.StringType then
      begin
        Result.Append('S ' + UIntToStr(Resource.Id) + ' ' + Resource.Resource.Strings[0]);
        for LineIndex := 1 to Resource.Resource.Count - 1 do
          Result.Append(' ' + Resource.Resource.Strings[LineIndex]);
      end
      else if Resource.ResourceType = TResourceType.HtmlType then
      begin
        Result.Append('H ' + UIntToStr(Resource.Id));
        for LineIndex := 0 to Resource.Resource.Count - 1 do
          Result.Append(' ' + Resource.Resource.Strings[LineIndex]);
      end;
    end;
end;

procedure AssignIdToLine(const FileStrings: TStringList; const FileStringsLineNumber: ValSInt; const Resources: TFileResourceLinkArray);
var
  Line: String;
  LineParts: TStringArray = nil;
  ValueParts: TStringArray = nil;
  ValueIndex: ValSInt;
  Commentary: String;
begin
  if Assigned(FileStrings) and (FileStringsLineNumber >= 0) and (Length(Resources) > 0) then
  begin
    Line := FileStrings.Strings[FileStringsLineNumber];
    LineParts := Line.Split('=');
    if Length(LineParts) > 1 then
    begin
      Commentary := '';
      if Line.Contains(';') then
        Commentary := ' ' + Line.Substring(Line.IndexOf(';'));
      case LineParts[0].Trim.ToLower of
        'rumor':
        begin
          ValueParts := LineParts[1].Split(',');
          if Length(ValueParts) > 2 then
            Line := LineParts[0] + '=' + ValueParts[0] + ',' + ValueParts[1] + ',' + ValueParts[2] + ', ' + UIntToStr(Resources[0].Id) + Commentary;
        end;
        'rumor_type2':
        begin
          ValueParts := LineParts[1].Split(',');
          if Length(ValueParts) > 2 then
            Line := LineParts[0] + '=' + ValueParts[0] + ',' + ValueParts[1] + ',' + ValueParts[2] + ', ' + UIntToStr(Resources[0].Id) + Commentary;
        end;
        'know':
        begin
          ValueParts := LineParts[1].Split(';')[0].Split(',');
          if (Length(ValueParts) > 3) and (Length(Resources) > 1) then
            Line := LineParts[0] + '=' + UIntToStr(Resources[0].Id) + ',' + UIntToStr(Resources[1].Id) + ',' + ValueParts[2] + ',' + ValueParts[3] + Commentary;
        end;
        'firstname_male',
        'firstname_female',
        'lastname',
        'formation_desig',
        'large_ship_names':
        begin
          if Length(Resources) > 1 then
            Line := LineParts[0] + '= ' + UIntToStr(Resources[0].Id) + ', ' + UIntToStr(Resources[High(Resources)].Id) + Commentary;
        end;
        'rank_desig':
        begin
          ValueParts := LineParts[1].Split(';')[0].Split(',');
          if (Length(ValueParts) > 4) and (Length(Resources) > 2) then
            Line := LineParts[0] + '= ' + UIntToStr(Resources[0].Id) + ', ' + UIntToStr(Resources[1].Id) + ', ' + UIntToStr(Resources[2].Id) + ',' + ValueParts[3] + ',' + ValueParts[4] + Commentary;
        end;
        'ids_info':
        begin
          Line := LineParts[0] + '= ' + UIntToStr(Resources[0].Id) + Commentary;
          if Assigned(InfocardMap.Strings) and (Length(Resources) > 1) then
            InfocardMap.Strings.Append('map = ' + UIntToStr(Resources[0].Id) + ', ' + UIntToStr(Resources[1].Id));
        end;
        'act_changestate',
        'act_setnnobj':
        begin
          ValueParts := LineParts[1].Split(';')[0].Split(',');
          if Length(ValueParts) > 0 then
          begin
            Line := LineParts[0] + '=' + ValueParts[0] + ', ' + UIntToStr(Resources[0].Id);
            for ValueIndex := 2 to High(ValueParts) do
              Line := Line + ',' + ValueParts[ValueIndex];
            Line := Line + Commentary;
          end;
        end;
        'act_ethercomm':
        begin     
          ValueParts := LineParts[1].Split(';')[0].Split(',');      
          if Length(ValueParts) > 0 then
          begin
            Line := LineParts[0] + '=' + ValueParts[0];
            for ValueIndex := 1 to High(ValueParts) do
              if (ValueParts[ValueIndex - 1].Trim.ToLower = 'true') or (ValueParts[ValueIndex - 1].Trim.ToLower = 'false') then
                Line := Line + ', ' + UIntToStr(Resources[0].Id)
              else
                Line := Line + ',' + ValueParts[ValueIndex];
            Line := Line + Commentary;
          end;
        end;          
        'ethersender':
        begin
          ValueParts := LineParts[1].Split(';')[0].Split(',');
          if Length(ValueParts) > 2 then
          begin
            Line := LineParts[0] + '=' + ValueParts[0] + ',' + ValueParts[1] + ', ' + UIntToStr(Resources[0].Id);
            for ValueIndex := 3 to High(ValueParts) do
              Line := Line + ',' + ValueParts[ValueIndex];
            Line := Line + Commentary;
          end;
        end;
        else
          Line := LineParts[0] + '= ' + UIntToStr(Resources[0].Id) + Commentary;
      end;
      FileStrings.Strings[FileStringsLineNumber] := Line;
    end;
  end;
end;

procedure ApplyIdsToFiles(const Resources: TFileResourceLinkArray);
var
  Resource: TFileResourceLink;
  CurrentFileStrings: TStringList = nil;
  CurrentFileStringsLineNumber: ValSInt = -1;
  ResourcesOfCurrentLine: TFileResourceLinkArray = nil;
begin
  // It is assumed that Resources are sorted 1. by File and 2. by Lines due the way they are generated in the program.
  for Resource in Resources do
  begin
    if (Resource.FileStrings <> CurrentFileStrings) or (Resource.FileStringsLineNumber <> CurrentFileStringsLineNumber) then
    begin
      AssignIdToLine(CurrentFileStrings, CurrentFileStringsLineNumber, ResourcesOfCurrentLine);
      SetLength(ResourcesOfCurrentLine, 0);
      CurrentFileStrings := Resource.FileStrings;
      CurrentFileStringsLineNumber := Resource.FileStringsLineNumber;
    end;
    SetLength(ResourcesOfCurrentLine, Length(ResourcesOfCurrentLine) + 1);
    ResourcesOfCurrentLine[High(ResourcesOfCurrentLine)] := Resource;
  end;
  AssignIdToLine(CurrentFileStrings, CurrentFileStringsLineNumber, ResourcesOfCurrentLine);
end;

procedure SaveAllFiles(const FilesStrings: TFileStringsArray);
var
  FileStrings: TFileStrings;
begin
  for FileStrings in FilesStrings do
    FileStrings.Strings.SaveToFile(FileStrings.FileName);
end;

procedure FindResources(const Strings: TStringList);
const
  StringIdentifier = ';res str';
  HtmlIdentifier = ';res html';
  LinkIdentifier = ';res $';
var
  Line: String;
  LineNumber: ValSInt;
  LineParts: TStringArray = nil;
  ValueParts: TStringArray = nil;
  ValuePartsIndex: ValSInt;
  ParentLineNumber: ValSInt = -1;
  FoundResourceType: TResourceType = TResourceType.NoType;
  ResourceContent: TStringList;
  FoundMetaName: String = '';
  ExistingId: Uint32 = 0;
begin
  ResourceContent := TStringList.Create;

  // Search through each line of the file.
  for LineNumber := 0 to Strings.Count - 1 do
  begin
    SetLength(LineParts, 0);
    Line := Strings.Strings[LineNumber].TrimLeft;

    // If we had found a resource and it does end, save the resource strings and reset the state.
    if (FoundResourceType <> TResourceType.NoType) and (not Line.StartsWith(';') or Line.StartsWith(StringIdentifier) or Line.StartsWith(HtmlIdentifier) or not Line.StartsWith('; ')) then
    begin
      AddFileResource(Strings, ParentLineNumber, ResourceContent, FoundResourceType, FoundMetaName, ExistingId);
      ExistingId := ExistingId + 1;
      ResourceContent.Clear;
      FoundResourceType := TResourceType.NoType;
    end;

    // Handle lines not starting with a ';'.
    if not Line.StartsWith(';') then
    begin
      Assert(FoundResourceType = TResourceType.NoType);
      ParentLineNumber := LineNumber;
      ExistingId := 0;
      ValueParts := nil;
      LineParts := Line.ToLower.Split('=');
      if Length(LineParts) > 1 then
      begin
        LineParts[1] := LineParts[1].Split(';')[0]; // Remove everything that might be commented out
        ValueParts := LineParts[1].Split(',');
      end;
      if Length(ValueParts) > 0 then
      begin
        case LineParts[0].Trim of
          'rumor',
          'rumor_type2':
          begin
            if Length(ValueParts) > 3 then
              TryStrToUInt(ValueParts[3].Trim, ExistingId);
          end;
          'act_changestate',
          'act_setnnobj':
          begin
            if Length(ValueParts) > 1 then
              TryStrToUInt(ValueParts[1].Trim, ExistingId);
          end;          
          'act_ethercomm':
          begin
            for ValuePartsIndex := 6 to High(ValueParts) do 
              if (ValueParts[ValuePartsIndex - 1].Trim = 'true') or (ValueParts[ValuePartsIndex - 1].Trim = 'false') then
              begin
                TryStrToUInt(ValueParts[ValuePartsIndex].Trim, ExistingId);
                Break;
              end;
          end;
          'ethersender':
          begin
            if Length(ValueParts) > 2 then
              TryStrToUInt(ValueParts[2].Trim, ExistingId);
          end
          else
            TryStrToUInt(ValueParts[0].Trim, ExistingId);
        end;
      end;
      Continue;
    end;

    // If we have a resource and our line starts with '; ' do add it to the current resource strings.
    if (FoundResourceType <> TResourceType.NoType) and Line.StartsWith('; ') then
    begin
      ResourceContent.Append(Line.Substring(2));
      Continue;
    end;

    // If the line starts with an identifier for plain string resources.
    if Line.StartsWith(StringIdentifier) then
    begin
      FoundResourceType := TResourceType.StringType;
      FoundMetaName := Line.Substring(Length(StringIdentifier) + 1).Trim;
      Continue;
    end;

    // If the line starts with an identifier for HTML resources.
    if Line.StartsWith(HtmlIdentifier) then
    begin
      FoundResourceType := TResourceType.HtmlType;
      FoundMetaName := Line.Substring(Length(StringIdentifier) + 1).Trim;
      Continue;
    end;

    // If the line starts with an identifier for linked resources.
    if Line.StartsWith(LinkIdentifier) then
    begin
      AddFileResource(Strings, ParentLineNumber, nil, TResourceType.LinkType, Line.Substring(Length(LinkIdentifier)).Trim, 0);
      Continue;
    end;
  end;

  // If we had found a resource and the file does end, save the resource strings and reset the state.
  if (FoundResourceType <> TResourceType.NoType) then
    AddFileResource(Strings, ParentLineNumber, ResourceContent, FoundResourceType, '', ExistingId);

  ResourceContent.Free;
end;

procedure ClearInfocardMapOfNonVanillaEntries(const FileStrings: TStringList; const IdOffset: Uint32);
var
  LineNumber: ValSInt = 0;
  Line: String;
  LineParts: TStringArray = nil;
  ValueParts: TStringArray = nil;
  Id: Int32;
begin
  while LineNumber < FileStrings.Count do
  begin
    Line := FileStrings.Strings[LineNumber];
    LineParts := Line.Split('=');
    if (Length(LineParts) = 2) and (LineParts[0].Trim.ToLower = 'map') then
    begin
      ValueParts := LineParts[1].Split(',');
      if (Length(ValueParts) > 1) and (TryStrToInt(ValueParts[0].Trim, Id) and (Id >= IdOffset)) or (TryStrToInt(ValueParts[1].Trim, Id) and (Id >= IdOffset)) then
      begin
        FileStrings.Delete(LineNumber);
        Continue;
      end;
    end;
    LineNumber := LineNumber + 1;
  end;
end;

function CollectAllExplorationEntities(const FilesStrings: TFileStringsArray; const IdOffset: Uint32; const Log: TStrings): TGameExplorationMap;
var
  FileStrings: TFileStrings;
  LineNumber: ValSInt;    
  BlockStart: ValSInt;
  BlockEnd: ValSInt;
  Entry: TGameExploration;
  Id: Uint32;
  Index: ValSInt;
begin
  Result := TGameExplorationMap.Create;
  for FileStrings in FilesStrings do
  begin                                 
    LineNumber := 0;
    while LineNumber < FileStrings.Strings.Count - 1 do
    begin
      BlockStart := FindNextBlockBegin(FileStrings.Strings, LineNumber);
      if BlockStart >= 0 then
      begin
        BlockEnd := FindBlockEnd(FileStrings.Strings, BlockStart + 1);
        LineNumber := BlockEnd;
        Entry.ExplorationType := TGameExplorationType.Other;
        Entry.Ids := nil;
        case FindBlockType(FileStrings.Strings, BlockStart).ToLower of
          'object':
          begin
            Entry.ExplorationType := TGameExplorationType.SpaceObject;
            Entry.Nickname := FindKeyValue(FileStrings.Strings, BlockStart, BlockEnd, 'nickname');
            if Entry.Nickname.IsEmpty then
              Continue;
            if not (FindKeyValue(FileStrings.Strings, BlockStart, BlockEnd, 'prev_ring').IsEmpty and FindKeyValue(FileStrings.Strings, BlockStart, BlockEnd, 'next_ring').IsEmpty) then
              Continue;
            if not TryStrToUInt(FindKeyValue(FileStrings.Strings, BlockStart, BlockEnd, 'ids_name'), Id) or (Id <= 1) then
              Continue;
            SetLength(Entry.Ids, 1);
            Entry.Ids[0] := Id;
            if not FindKeyValue(FileStrings.Strings, BlockStart, BlockEnd, 'base').IsEmpty then
              Entry.ExplorationType := TGameExplorationType.Base;
          end;
          'zone':
          begin
            Entry.ExplorationType := TGameExplorationType.Zone;
            Entry.Nickname := FindKeyValue(FileStrings.Strings, BlockStart, BlockEnd, 'nickname');
            if Entry.Nickname.IsEmpty then
              Continue;
            if not TryStrToUInt(FindKeyValue(FileStrings.Strings, BlockStart, BlockEnd, 'ids_name'), Id) or (Id <= 1) then
              Continue;
            if Id < IdOffset then
            begin
              SetLength(Entry.Ids, 11);
              Entry.Ids[0] := Id;
              Id := Id + 70473; // Offset to grammatical case versions
              for Index := 1 to High(Entry.Ids) do
              begin
                Entry.Ids[Index] := Id;
                Id := Id + 200;
              end;
            end
            else
            begin
              SetLength(Entry.Ids, 3);
              Entry.Ids[0] := Id;
              Entry.Ids[1] := Id + 1;
              Entry.Ids[2] := Id + 2;
            end;
          end;
          'group':
          begin
            Entry.ExplorationType := TGameExplorationType.Group;
            Entry.Nickname := FindKeyValue(FileStrings.Strings, BlockStart, BlockEnd, 'nickname');
            if Entry.Nickname.IsEmpty then
              Continue;
            if TryStrToUInt(FindKeyValue(FileStrings.Strings, BlockStart, BlockEnd, 'ids_name'), Id) or (Id <= 1) then
            if Id < IdOffset then
            begin
              SetLength(Entry.Ids, 5);
              Entry.Ids[0] := Id;
              Id := Id + 131834; // Offset to grammatical case versions
              for Index := 1 to High(Entry.Ids) do
              begin
                Entry.Ids[Index] := Id;
                Id := Id + 100;
              end;
            end
            else
            begin
              SetLength(Entry.Ids, 4);
              Entry.Ids[0] := Id;
              Entry.Ids[1] := Id + 1;
              Entry.Ids[2] := Id + 2;
              Entry.Ids[3] := Id + 3;
            end;
            if TryStrToUInt(FindKeyValue(FileStrings.Strings, BlockStart, BlockEnd, 'ids_short_name'), Id) then
            begin
              SetLength(Entry.Ids, Length(Entry.Ids) + 1);
              Entry.Ids[High(Entry.Ids)] := Id;
            end;
          end;
          'system':
          begin
            Entry.ExplorationType := TGameExplorationType.StarSystem;
            Entry.Nickname := FindKeyValue(FileStrings.Strings, BlockStart, BlockEnd, 'nickname');
            if Entry.Nickname.IsEmpty then
              Continue;
            if not TryStrToUInt(FindKeyValue(FileStrings.Strings, BlockStart, BlockEnd, 'strid_name'), Id) or (Id <= 1) then
              Continue;
            SetLength(Entry.Ids, 1);
            Entry.Ids[0] := Id;
          end;
          'base':
          begin
            Entry.ExplorationType := TGameExplorationType.Base;
            Entry.Nickname := FindKeyValue(FileStrings.Strings, BlockStart, BlockEnd, 'nickname');
            if Entry.Nickname.IsEmpty then
              Continue;
            if not TryStrToUInt(FindKeyValue(FileStrings.Strings, BlockStart, BlockEnd, 'strid_name'), Id) or (Id <= 1) then
              Continue;
            SetLength(Entry.Ids, 1);
            Entry.Ids[0] := Id;
          end;
          else
            Continue;
        end;
        try
          Result.Add(Entry.Nickname, Entry);
        except
          On EListError do Log.Append('Nickname duplicated! ' + Entry.Nickname);
        end;
      end
      else
        Break;
    end;
  end;
end;

procedure BuildKnowledgeMap(const FilesStrings: TFileStringsArray; const IdOffset: Uint32; const Log: TStrings);
const
  KnowDbIdentifier = ';knowdb ';
var
  GameExplorationEntities: TGameExplorationMap;
  Entity: TGameExploration;
  FileStrings: TFileStrings;
  Id: Uint32;
  VisitFlag: UInt8;
  Index: ValSInt;
  Line: String;       
  LineParts: TStringArray;
  ValueParts: TStringArray;
  Nicknames: TStringArray;
  Nickname: String;
  Entry: String;
begin
  GameExplorationEntities := CollectAllExplorationEntities(FilesStrings, IdOffset, Log);

  KnowledgeMap.Strings.Clear;
  KnowledgeMap.Strings.Append('[KnowledgeMapTable]');
  for Entity in GameExplorationEntities.Values do
  begin
    case Entity.ExplorationType of
      TGameExplorationType.SpaceObject:
        VisitFlag := 1;
      TGameExplorationType.Base:
        VisitFlag := 31;
      TGameExplorationType.Zone:
        VisitFlag := 33;            
      TGameExplorationType.Group:
        VisitFlag := 65;        
      TGameExplorationType.StarSystem:
        VisitFlag := 1;
    end;
    for Id in Entity.Ids do
      KnowledgeMap.Strings.Append('map = ' + UIntToStr(Id) + ', ' + Entity.Nickname + ', ' + UIntToStr(VisitFlag));
  end;

  for FileStrings in FilesStrings do
    for Index := 0 to FileStrings.Strings.Count - 1 do
    begin
      Id := 0;
      Line := FileStrings.Strings.Strings[Index].ToLower;
      if Line.Contains(KnowDbIdentifier) then
        Nicknames := Line.Substring(Line.IndexOf(KnowDbIdentifier) + Length(KnowDbIdentifier)).Split(',')
      else
        Continue;
      LineParts := Line.Split(';')[0].Split('=');
      if Length(LineParts) < 2 then
        Continue;
      case LineParts[0].Trim of
        'rumor',
        'rumor_type2':
        begin
          ValueParts := LineParts[1].Split(',');
          if Length(ValueParts) > 3 then
            TryStrToUInt(ValueParts[3].Trim, Id);
        end;      
        'know':
        begin
          ValueParts := LineParts[1].Split(',');
          if Length(ValueParts) > 1 then
            TryStrToUInt(ValueParts[1].Trim, Id);
        end;
      end;
      if Id = 0 then
        Continue;
      for Nickname in Nicknames do
      begin
        Nickname.Trim;
        if GameExplorationEntities.TryGetValue(Nickname.Trim, Entity) then
        begin
          case Entity.ExplorationType of
            TGameExplorationType.SpaceObject:
              VisitFlag := 1;
            TGameExplorationType.Base:
              VisitFlag := 31;
            TGameExplorationType.Zone:
              VisitFlag := 33;
            TGameExplorationType.Group:
              VisitFlag := 65;
            TGameExplorationType.StarSystem:
              VisitFlag := 1;
          end;
          Entry := 'map = ' + UIntToStr(Id) + ', ' + Entity.Nickname.Trim + ', ' + UIntToStr(VisitFlag);
          if KnowledgeMap.Strings.IndexOf(Entry) < 0 then
            KnowledgeMap.Strings.Append('map = ' + UIntToStr(Id) + ', ' + Entity.Nickname.Trim + ', ' + UIntToStr(VisitFlag));
        end;
      end;
    end;

  GameExplorationEntities.Free;
end;

function LoadAllValidIniFiles(const DirectoryPath: String; const IdOffset: Uint32): TFileStringsArray;
var
  FilePaths: TStringList;
  Index: ValSInt;
  IniFile: TStringList;
begin
  Result := nil;
  // Load all files into memory.
  FilePaths := FindAllFiles(DirectoryPath, '*.ini', True);
  for Index := 0 to FilePaths.Count - 1 do
  begin
    IniFile := TStringList.Create;
    IniFile.TextLineBreakStyle := TTextLineBreakStyle.tlbsCRLF;
    IniFile.LoadFromFile(FilePaths[Index]);
    // Ignore BINI files.
    if (IniFile.Count > 0) and not IniFile.Strings[0].StartsWith('BINI') then
    begin
      if FilePaths[Index].ToLower.EndsWith('infocardmap.ini') then
      begin
        ClearInfocardMapOfNonVanillaEntries(IniFile, IdOffset);
        InfocardMap.FileName := FilePaths[Index];
        InfocardMap.Strings := IniFile;
        Continue;
      end;

      if FilePaths[Index].ToLower.EndsWith('knowledgemap.ini') then
      begin
        KnowledgeMap.FileName := FilePaths[Index];
        KnowledgeMap.Strings := IniFile;
        Continue;
      end;

      SetLength(Result, Length(Result) + 1);
      Result[High(Result)].FileName := FilePaths[Index];
      Result[High(Result)].Strings := IniFile;
    end
    else
    begin
      IniFile.Free;
    end;
  end;
  FilePaths.Free;
end;

procedure FreeAllLoadedIniFiles(const FilesStrings: TFileStringsArray);
var
  FileStrings: TFileStrings;
begin
  for FileStrings in FilesStrings do
    FileStrings.Strings.Free;
end;

procedure Process(const DirectoryPath: String; const IdOffset: Uint32; const OutputFileName: String; const Log: TStrings);
var
  IniFilesStrings: TFileStringsArray;
  FileStrings: TFileStrings;
  FrcStrings: TStringList;
  FileResourceLink: TFileResourceLink;
begin
  Log.Append('Reading .ini files in ' + DirectoryPath);
  IniFilesStrings := LoadAllValidIniFiles(DirectoryPath, IdOffset);

  for FileStrings in IniFilesStrings do
    FindResources(FileStrings.Strings);

  Log.Append('Creating IDs from ' + IntToStr(Length(Resources)) + ' resource blocks...');
  LinkResourcesWithIds(Resources, IdOffset, Log);

  Log.Append('Writing IDs into .ini files...');
  ApplyIdsToFiles(Resources);

  for FileResourceLink in Resources do
    if (FileResourceLink.ResourceType = TResourceType.StringType) or (FileResourceLink.ResourceType = TResourceType.HtmlType) then
      ReplaceResourcePlaceholders(FileResourceLink.FileStrings, FileResourceLink.FileStringsLineNumber, FileResourceLink.Resource);

  Log.Append('Saving all modified .ini files...');
  SaveAllFiles(IniFilesStrings);
  if Assigned(InfocardMap.Strings) then
  begin
    Log.Append('Saving modified infocardmap.ini file...');
    InfocardMap.Strings.SaveToFile(InfocardMap.FileName);
    InfocardMap.Strings.Free;
  end;
  if Assigned(KnowledgeMap.Strings) then
  begin
    BuildKnowledgeMap(IniFilesStrings, IdOffset, Log);
    Log.Append('Saving modified knowledgemap.ini file...');
    KnowledgeMap.Strings.SaveToFile(KnowledgeMap.FileName);
    KnowledgeMap.Strings.Free;
  end;

  Log.Append('Saving "' + OutputFileName + '"...');
  FrcStrings := CreateFrcStrings(Resources);
  FrcStrings.WriteBOM := True;
  FrcStrings.SaveToFile(OutputFileName, TEncoding.Unicode);
  FrcStrings.Free;

  for FileResourceLink in Resources do
    FileResourceLink.Resource.Free;
  SetLength(Resources, 0);

  FreeAllLoadedIniFiles(IniFilesStrings);
  SetLength(IniFilesStrings, 0);

  Log.Append('Done!');
end;

end.
