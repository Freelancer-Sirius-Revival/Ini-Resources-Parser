unit UResourceParsing;

{$mode ObjFPC}{$H+}

interface

uses
  Classes,
  SysUtils;

procedure Process(const DirectoryPath: String; const IdOffset: UInt32; const OutputFileName: string; const Log: TStrings);

implementation

uses
  FileUtil,
  UPlaceholderReplacing;

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

var
  Resources: TFileResourceLinkArray = nil;
  InfocardMap: TFileStrings = (FileName: ''; Strings: nil);

procedure AddFileResource(const FileStrings: TStringList; const FileStringsLineNumber: ValSInt; const Resource: TStringList; const ResourceType: TResourceType; const MetaName: String);
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
  Entry^.Id := 0;
end;

procedure LinkResourcesWithIds(const Resources: TFileResourceLinkArray; const IdOffset: Uint32);
var
  LastId: Uint32;
  Index: ValSInt;
  MetaIndex: ValSInt;
begin
  LastId := IdOffset;

  for Index := 0 to High(Resources) do
    if Resources[Index].ResourceType = TResourceType.StringType then
    begin
      Resources[Index].Id := LastId;
      LastId := LastId + 1;
    end;

  // Simple string resources are packed in blocks of 16. For HTML resources an ID outside of those blocks should be used.
  if (LastId mod 16) <> 0 then
    LastId := 16 - (LastId mod 16) + LastId;

  for Index := 0 to High(Resources) do
    if Resources[Index].ResourceType = TResourceType.HtmlType then
    begin
      Resources[Index].Id := LastId;
      LastId := LastId + 1;
    end;

  // Link all ids that want other ids that are already existing.
  for Index := 0 to High(Resources) do
    if Resources[Index].ResourceType = TResourceType.LinkType then
      for MetaIndex := 0 to High(Resources) do
        if (Resources[MetaIndex].ResourceType <> TResourceType.LinkType) and (Resources[MetaIndex].MetaName.ToLower = Resources[Index].MetaName.ToLower) then
        begin
          Resources[Index].Id := Resources[MetaIndex].Id;
        end;
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
        Result.Append('S ' + IntToStr(Resource.Id) + ' ' + Resource.Resource.Strings[0]);
        for LineIndex := 1 to Resource.Resource.Count - 1 do
          Result.Append(' ' + Resource.Resource.Strings[LineIndex]);
      end
      else if Resource.ResourceType = TResourceType.HtmlType then
      begin
        Result.Append('H ' + IntToStr(Resource.Id));
        for LineIndex := 0 to Resource.Resource.Count - 1 do
          Result.Append(' ' + Resource.Resource.Strings[LineIndex]);
      end;
    end;
end;

procedure ApplyIdsToFiles(const Resources: TFileResourceLinkArray);
var
  Resource: TFileResourceLink;
  CurrentFileStrings: TStringList = nil;
  CurrentFileStringsLineNumber: ValSInt = -1;
  ResourcesOfCurrentLine: TFileResourceLinkArray = nil;

  procedure AssignIdToLine;
  var
    Line: String;
    LineParts: TStringArray = nil;
    ValueParts: TStringArray = nil;
  begin
    if Assigned(CurrentFileStrings) and (CurrentFileStringsLineNumber >= 0) and (Length(ResourcesOfCurrentLine) > 0) then
    begin
      Line := CurrentFileStrings.Strings[CurrentFileStringsLineNumber];
      LineParts := Line.Split(['=']);
      if Length(LineParts) = 2 then
      begin
        case LineParts[0].Trim.ToLower of
          'rumor':
          begin
            ValueParts := LineParts[1].Split([',']);
            if Length(ValueParts) > 3 then
              Line := LineParts[0] + '=' + ValueParts[0] + ',' + ValueParts[1] + ',' + ValueParts[2] + ', ' + IntToStr(ResourcesOfCurrentLine[0].Id);
          end;           
          'rumor_type2':
          begin
            ValueParts := LineParts[1].Split([',']);
            if Length(ValueParts) > 3 then
              Line := LineParts[0] + '=' + ValueParts[0] + ',' + ValueParts[1] + ',' + ValueParts[2] + ', ' + IntToStr(ResourcesOfCurrentLine[0].Id);
          end;
          'know':
          begin
            ValueParts := LineParts[1].Split([',']);     
            if Length(ValueParts) > 3 then
              Line := LineParts[0] + '=' + IntToStr(ResourcesOfCurrentLine[0].Id) + ',' + IntToStr(ResourcesOfCurrentLine[1].Id) + ',' + ValueParts[2] + ', ' + ValueParts[3];
          end;
          'firstname_male',
          'firstname_female',
          'lastname',
          'formation_desig',
          'large_ship_names':
          begin
            Line := LineParts[0] + '= ' + IntToStr(ResourcesOfCurrentLine[0].Id) + ', ' + IntToStr(ResourcesOfCurrentLine[High(ResourcesOfCurrentLine)].Id);
          end;
          'rank_desig':
          begin
            ValueParts := LineParts[1].Split([',']);
            if (Length(ValueParts) > 4) and (Length(ResourcesOfCurrentLine) > 1) then
              Line := LineParts[0] + '= ' + IntToStr(ResourcesOfCurrentLine[0].Id) + ', ' + IntToStr(ResourcesOfCurrentLine[1].Id) + ', ' + IntToStr(ResourcesOfCurrentLine[2].Id) + ',' + ValueParts[3] + ',' + ValueParts[4];
          end;
          'ids_info':
          begin
            Line := LineParts[0] + '= ' + IntToStr(ResourcesOfCurrentLine[0].Id);
            if (Length(ResourcesOfCurrentLine) > 1) and Assigned(InfocardMap.Strings) then
              InfocardMap.Strings.Append('map = ' + IntToStr(ResourcesOfCurrentLine[0].Id) + ', ' + IntToStr(ResourcesOfCurrentLine[1].Id));
          end;
          else
            Line := LineParts[0] + '= ' + IntToStr(ResourcesOfCurrentLine[0].Id);
        end;
        CurrentFileStrings.Strings[CurrentFileStringsLineNumber] := Line;
      end;
    end;
    SetLength(LineParts, 0);
    SetLength(ValueParts, 0);
  end;

begin
  // It is assumed that Resources are sorted 1. by File and 2. by Lines due the way they are generated in the program.
  for Resource in Resources do
  begin
    if (Resource.FileStrings <> CurrentFileStrings) or (Resource.FileStringsLineNumber <> CurrentFileStringsLineNumber) then
    begin
      AssignIdToLine;
      SetLength(ResourcesOfCurrentLine, 0);
      CurrentFileStrings := Resource.FileStrings;
      CurrentFileStringsLineNumber := Resource.FileStringsLineNumber;
    end;
    SetLength(ResourcesOfCurrentLine, Length(ResourcesOfCurrentLine) + 1);
    ResourcesOfCurrentLine[High(ResourcesOfCurrentLine)] := Resource;
  end;
  AssignIdToLine;
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
  ParentLineNumber: ValSInt = -1;
  FoundResourceType: TResourceType = TResourceType.NoType;
  ResourceContent: TStringList;
  FoundMetaName: String = '';
begin
  ResourceContent := TStringList.Create;

  // Search through each line of the file.
  for LineNumber := 0 to Strings.Count - 1 do
  begin
    Line := Strings.Strings[LineNumber].TrimLeft;

    // If we had found a resource and it does end, save the resource strings and reset the state.
    if (FoundResourceType <> TResourceType.NoType) and (not Line.StartsWith(';') or Line.StartsWith(StringIdentifier) or Line.StartsWith(HtmlIdentifier) or not Line.StartsWith('; ')) then
    begin
      AddFileResource(Strings, ParentLineNumber, ResourceContent, FoundResourceType, FoundMetaName);
      ResourceContent.Clear;
      FoundResourceType := TResourceType.NoType;
    end;

    // Skip all lines not starting with a ';'.
    if not Line.StartsWith(';') then
    begin
      Assert(FoundResourceType = TResourceType.NoType);
      ParentLineNumber := LineNumber;
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
      AddFileResource(Strings, ParentLineNumber, nil, TResourceType.LinkType, Line.Substring(Length(LinkIdentifier)).Trim);
      Continue;
    end;
  end;

  // If we had found a resource and the file does end, save the resource strings and reset the state.
  if (FoundResourceType <> TResourceType.NoType) then
    AddFileResource(Strings, ParentLineNumber, ResourceContent, FoundResourceType, '');

  ResourceContent.Free;
end;

procedure ClearInfocardMapOfNonVanillaEntries(const FileStrings: TStringList; const IdOffset: UInt32);
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
    LineParts := Line.Split(['=']);
    if (Length(LineParts) = 2) and (LineParts[0].Trim.ToLower = 'map') then
    begin
      ValueParts := LineParts[1].Split([',']);
      if (Length(ValueParts) > 1) and (TryStrToInt(ValueParts[0].Trim, Id) and (Id >= IdOffset)) or (TryStrToInt(ValueParts[1].Trim, Id) and (Id >= IdOffset)) then
      begin
        FileStrings.Delete(LineNumber);
        Continue;
      end;
    end;
    LineNumber := LineNumber + 1;
  end;
  SetLength(LineParts, 0);
  SetLength(ValueParts, 0);
end;

function LoadAllValidIniFiles(const DirectoryPath: String; const IdOffset: UInt32): TFileStringsArray;
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

procedure Process(const DirectoryPath: String; const IdOffset: UInt32; const OutputFileName: string; const Log: TStrings);
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
  LinkResourcesWithIds(Resources, IdOffset);

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

