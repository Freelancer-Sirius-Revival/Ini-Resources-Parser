unit UMainForm;

{$mode objfpc}{$H+}
{$ScopedEnums on}

interface

uses
  Classes,
  SysUtils,
  Forms,
  Controls,
  Graphics,
  Dialogs,
  StdCtrls,
  Interfaces;

type
  TMainForm = class(TForm)
    SaveDialog: TSaveDialog;
    WarningsListBox: TListBox;
    SelectDirectoryDialog: TSelectDirectoryDialog;
    procedure FormCreate(Sender: TObject);
  end;

var
  MainForm: TMainForm;

implementation

{$R *.lfm}

uses
  UResourceParsing;

const
  IdOffset = 458753;

procedure TMainForm.FormCreate(Sender: TObject);
var
  InputDirectory: String = '';
begin
  if Application.HasOption('i', 'input') and DirectoryExists(Application.GetOptionValue('i', 'input')) then
    InputDirectory := Application.GetOptionValue('i', 'input');
  if InputDirectory.IsEmpty and SelectDirectoryDialog.Execute then
    InputDirectory := SelectDirectoryDialog.FileName;
  Process(InputDirectory, IdOffset, 'FLSR-Texts.frc', WarningsListBox.Items);
end;

end.
