unit MsgBox;
{$mode objfpc}{$H+}
{-----------------------------------------------------------------------------
 Author:    zaher
 Purpose:
 History:
-----------------------------------------------------------------------------}
{
 TODO;
 Check if not MsgBox installed
}
interface

uses
  SysUtils, Variants, Classes, Contnrs;

type
  TmsgKind = (msgkNormal, msgkWarning, msgkError, msgkInformation, msgkConfirmation, msgkInput, msgkPassword, msgkStatus);

  TmsgChoice = (msgcUnknown, msgcYes, msgcNo, msgcOK, msgcCancel, msgcAbort, msgcRetry, msgcIgnore, msgcDiscard, msgcNone, msgcAll, msgcNoToAll, msgcYesToAll, msgcHelp);
  TmsgChoices = set of TmsgChoice;

  TmsgSelect = record
    Caption: string;
    Choice: TmsgChoice;
  end;

  { TMsgPrompt }

  TMsgPrompt = class(TObject)
  private
  protected
    FName: String;
    FTitle: String;
    //Return an index of Choise/Button
    function ShowMessage(const vText: string; Choices: array of TmsgSelect; DefaultChoice: Integer; CancelChoice: Integer; Kind: TmsgKind): Integer; virtual; abstract;
    function ShowMessage(var Answer: string; const Text: string; Choices: array of TmsgSelect; DefaultChoice: Integer; CancelChoice: Integer; Kind: TmsgKind): Integer; virtual; abstract;
    //Short style of message
    function ShowMessage(const vText: string; Choices: TmsgChoices; DefaultChoice: TmsgChoice; CancelChoice: TmsgChoice; Kind: TmsgKind): TmsgChoice;
    function ShowMessage(var Answer: string; const vText: string; Choices: TmsgChoices; DefaultChoice: TmsgChoice; CancelChoice: TmsgChoice; Kind: TmsgKind): TmsgChoice;
    //Status messages
    procedure ShowStatus(vText: string; Sender: TObject = nil); virtual; abstract;
    procedure UpdateStatus(vText: string; Sender: TObject = nil); virtual; abstract;
    procedure HideStatus(Sender: TObject); virtual; abstract;

    procedure Created; virtual; abstract;
    property Name: String read FName;
    property Title: String read FTitle write FTitle;
  public
    constructor Create; virtual;
  end;

  TMsgPromptClass = class of TMsgPrompt;

  { TMsgBox }

  TMsgBox = class(TObjectList)
  private
    FCurrent: TMsgPrompt;
    FLockCount: Integer;
    function GetItem(Index: Integer): TMsgPrompt;
    function GetLocked: Boolean;
    procedure SetCurrent(AValue: TMsgPrompt);
    procedure SetLocked(const Value: Boolean);
  protected
    function ShowMessage(const vText: string; Choices: array of TmsgSelect; DefaultChoice: Integer; CancelChoice: Integer; Kind: TmsgKind): Integer;
    function ShowMessage(var Answer: string; const vText: string; Choices: array of TmsgSelect; DefaultChoice: Integer; CancelChoice: Integer; Kind: TmsgKind): Integer;
    function ShowMessage(const vText: string; Choices: TmsgChoices; DefaultChoice: TmsgChoice; CancelChoice: TmsgChoice; Kind: TmsgKind): TmsgChoice;
    function ShowMessage(var Answer: string; const vText: string; Choices: TmsgChoices; DefaultChoice: TmsgChoice; CancelChoice: TmsgChoice; Kind: TmsgKind): TmsgChoice;

    property Current: TMsgPrompt read FCurrent write SetCurrent;
    function Find(vName: String): TMsgPrompt;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Register(MsgPromptClass: TMsgPromptClass; SwitchToCurrent: Boolean = False);
    function Switch(vName: String): TMsgPrompt;
    procedure EnumItems(vItems: TStrings);
    property Items[Index: Integer]: TMsgPrompt read GetItem;

    function Input(var Answer: string; const vText: string): boolean;
    function Password(var Answer: string; const vText: string): boolean;

    function Ask(const vText: string; Choices: TmsgChoices; DefaultChoice: TmsgChoice; CancelChoice: TmsgChoice; Kind: TmsgKind = msgkNormal): TmsgChoice;
    function Ask(const vText: string; Choices: array of TmsgSelect; DefaultChoice: Integer; CancelChoice: Integer = -1; Kind: TmsgKind = msgkNormal): Integer;
    function Ask(const vText: string; Choices: array of string; DefaultChoice: Integer = -1; CancelChoice: Integer = -1; Kind: TmsgKind = msgkNormal): Integer;

    //OK/Cancel the default OK
    function Ok(const vText: string): boolean;
    //OK/Cancel the default Cancel
    function Cancel(const vText: string): boolean;
    //Yes/No the default Yes
    function Yes(const vText: string): boolean;
    //Yes/No the default No
    function No(const vText: string): boolean;
    function YesNoCancel(const vText: string): TmsgChoice;

    function Error(const vText: string): boolean;
    function Warning(const vText: string): boolean;
    function Hint(const vText: string): boolean;

    procedure Show(vVar: Variant);
    procedure List(Strings: TStringList; Kind: TmsgKind);

    procedure ShowStatus(Sender: TObject; const vText: string);
    procedure HideStatus(Sender: TObject);

    property Locked: Boolean read GetLocked write SetLocked;
  end;

var
  ChoiceNames: array[TmsgChoice] of string = (
    'Unknown', 'Yes', 'No', 'OK', 'Cancel', 'Abort', 'Retry', 'Ignore', 'Discard', 'None',  'All', 'NoToAll',
    'YesToAll', 'Help');

  ChoiceCaptions: array[TmsgChoice] of string = (
    'Unknown', '&Yes', '&No', '&OK', '&Cancel', '&Abort', '&Retry', 'Di&scard', 'N&one', '&Ignore', '&All', 'No &To All',
    'Yes To A&ll', '&Help');

{* TMsgConsole

}
type

  { TMsgConsole }

  TMsgConsole = class(TMsgPrompt)
  private
  protected
    //function ShowMessage(const vText: string; Choices: TmsgChoices; DefaultChoice: TmsgChoice; CancelChoice: TmsgChoice; Kind: TmsgKind): Integer; override;
    //function ShowMessage(var Answer: string; const vText: string; Choices: TmsgChoices; DefaultChoice: TmsgChoice; CancelChoice: TmsgChoice; Kind: TmsgKind): Integer; override;
    procedure ShowStatus(vText: string; Sender: TObject = nil); override;
    procedure HideStatus(Sender: TObject = nil); override;
    procedure Created; override;
  public
    constructor Create; override;
    destructor Destroy; override;
  end;

function Msg: TMsgBox;
function Choice(vCaption: string; vChoice: TmsgChoice = msgcNone): TmsgSelect;

implementation

var
  FMsgBox: TMsgBox = nil;

function Msg: TMsgBox;
begin
  if FMsgBox = nil then
    FMsgBox := TMsgBox.Create;
  Result := FMsgBox;
end;

function Choice(vCaption: string; vChoice: TmsgChoice): TmsgSelect;
begin
  Result.Caption := vCaption;
  Result.Choice := vChoice;
end;

{ TMsgPrompt }

function TMsgPrompt.ShowMessage(const vText: string; Choices: TmsgChoices; DefaultChoice: TmsgChoice; CancelChoice: TmsgChoice; Kind: TmsgKind): TmsgChoice;
var
  a: TmsgChoice;
  c: array of TmsgSelect;
  i: Integer;
  DefaultIndex: Integer;
  CancelIndex: Integer;
begin
  c := nil;
  DefaultIndex := 0;
  CancelIndex := 0;
  i := 0;
  for a := low(TmsgChoices) to High(TmsgChoices) do
  begin
    if a in Choices then
    begin
      SetLength(c, i + 1);
      c[i] := Choice(ChoiceCaptions[a], a);
      if DefaultChoice = a then
        DefaultIndex := i;
      if CancelChoice = a then
        CancelIndex := i;
      i := i + 1;
    end;
  end;
  Result := C[ShowMessage(vText, c, DefaultIndex, CancelIndex, Kind)].Choice;
end;

function TMsgPrompt.ShowMessage(var Answer: string; const vText: string; Choices: TmsgChoices; DefaultChoice: TmsgChoice; CancelChoice: TmsgChoice; Kind: TmsgKind): TmsgChoice;
var
  a: TmsgChoice;
  c: array of TmsgSelect;
  i: Integer;
  DefaultIndex: Integer;
  CancelIndex: Integer;
begin
  c := nil;
  DefaultIndex := 0;
  CancelIndex := 0;
  i := 0;
  for a := low(TmsgChoices) to High(TmsgChoices) do
  begin
    if a in Choices then
    begin
      SetLength(c, i + 1);
      c[i] := Choice(ChoiceCaptions[a], a);
      if DefaultChoice = a then
        DefaultIndex := i;
      if CancelChoice = a then
        CancelIndex := i;
      i := i + 1;
    end;
  end;
  Result := C[ShowMessage(Answer, vText, c, DefaultIndex, CancelIndex, Kind)].Choice;
end;

constructor TMsgPrompt.Create;
begin
  inherited Create;
end;

constructor TMsgBox.Create;
begin
  inherited;
end;

destructor TMsgBox.Destroy;
begin
  inherited;
  FMsgBox := nil;
end;

procedure TMsgBox.Register(MsgPromptClass: TMsgPromptClass; SwitchToCurrent: Boolean);
var
  lMsgPrompt: TMsgPrompt;
begin
  lMsgPrompt := MsgPromptClass.Create;
  inherited Add(lMsgPrompt);
  if SwitchToCurrent or ((Count = 1) and (FCurrent = nil)) then
    Current := lMsgPrompt;
end;

function TMsgBox.Switch(vName: String): TMsgPrompt;
var
  aItem: TMsgPrompt;
  aCurrent: TMsgPrompt;
begin
  aCurrent := Current;

  aItem := Find(vName);
  if aItem = nil then
    Exception.Create(vName + ' not found!')
  else
    aCurrent := aItem;
  Result := aItem;
  Current := aCurrent;
end;

procedure TMsgBox.EnumItems(vItems: TStrings);
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
  begin
    vItems.AddObject(Items[i].Title, Items[i]);
  end;
end;

function TMsgBox.Cancel(const vText: string): boolean;
begin
  Result := ShowMessage(vText, [msgcOK, msgcCancel], msgcCancel, msgcOk, msgkWarning) = msgcCancel
end;

function TMsgBox.Ok(const vText: string): boolean;
begin
  Result := ShowMessage(vText, [msgcOK, msgcCancel], msgcOK, msgcCancel, msgkWarning) = msgcOK;
end;

function TMsgBox.Input(var Answer: string; const vText: string): boolean;
begin
  Result := ShowMessage(Answer, vText, [msgcOK, msgcCancel], msgcOk, msgcCancel, msgkConfirmation) = msgcOK
end;

function TMsgBox.Password(var Answer: string; const vText: string): boolean;
begin
  Result := ShowMessage(Answer, vText, [msgcOK, msgcCancel], msgcOk, msgcCancel, msgkPassword) = msgcOK
end;

function TMsgBox.Yes(const vText: string): boolean;
begin
  Result := ShowMessage(vText, [msgcYes, msgcNo], msgcYes, msgcNo, msgkConfirmation) = msgcYes;
end;

function TMsgBox.No(const vText: string): boolean;
begin
  Result := ShowMessage(vText, [msgcYes, msgcNo], msgcNo, msgcNo, msgkConfirmation) in [msgcCancel, msgcNo];
end;

function TMsgBox.YesNoCancel(const vText: string): TmsgChoice;
begin
  Result := ShowMessage(vText, [msgcYes, msgcNo, msgcCancel], msgcYes, msgcCancel, msgkConfirmation);
end;

function TMsgBox.Error(const vText: string): boolean;
begin
  Result := ShowMessage(vText, [msgcOK], msgcOK, msgcOk, msgkError) = msgcOK
end;

function TMsgBox.Hint(const vText: string): boolean;
begin
  Result := ShowMessage(vText, [msgcOK], msgcOK, msgcOK, msgkError) = msgcOK
end;

function TMsgBox.Warning(const vText: string): boolean;
begin
  Result := ShowMessage(vText, [msgcYes], msgcOK, msgcOK, msgkWarning) = msgcOK
end;

procedure TMsgBox.Show(vVar: Variant);
begin
  ShowMessage(VarToStr(vVar), [msgcOK], msgcOK, msgcOK, msgkInformation)
end;

procedure TMsgBox.List(Strings: TStringList; Kind: TmsgKind);
var
  s: string;
  i, c: Integer;
begin
  s := '';
  c := Strings.Count;
  if c > 30 then
    c := 30;
  for i := 0 to c - 1 do
  begin
    if s <> '' then
      s := s + #13;
    s := s + Strings[i];
  end;
  if c < Strings.Count then
    s := s + #13 + '...';
  ShowMessage(s, [msgcOK], msgcOK, msgcOK, Kind);
end;

procedure TMsgBox.HideStatus(Sender: TObject);
begin
  if not Locked and (FCurrent <> nil) then
    FCurrent.HideStatus(Sender);
end;

procedure TMsgBox.ShowStatus(Sender: TObject; const vText: string);
begin
  if not Locked and (FCurrent <> nil) then
    FCurrent.ShowStatus(vText, Sender);
end;

function TMsgBox.ShowMessage(var Answer: string; const vText: string; Choices: array of TmsgSelect; DefaultChoice: Integer; CancelChoice: Integer; Kind: TmsgKind): Integer;
begin
  if not Locked and (FCurrent <> nil) then
    Result := FCurrent.ShowMessage(Answer, vText, Choices, DefaultChoice, CancelChoice, Kind)
  else
    Result := DefaultChoice;
end;

function TMsgBox.ShowMessage(const vText: string; Choices: TmsgChoices; DefaultChoice: TmsgChoice; CancelChoice: TmsgChoice; Kind: TmsgKind): TmsgChoice;
begin
  if not Locked and (FCurrent <> nil) then
    Result := FCurrent.ShowMessage(vText, Choices, DefaultChoice, CancelChoice, Kind)
  else
    Result := DefaultChoice;
end;

function TMsgBox.ShowMessage(var Answer: string; const vText: string; Choices: TmsgChoices; DefaultChoice: TmsgChoice; CancelChoice: TmsgChoice; Kind: TmsgKind): TmsgChoice;
begin
  if not Locked and (FCurrent <> nil) then
    Result := FCurrent.ShowMessage(Answer, vText, Choices, DefaultChoice, CancelChoice, Kind)
  else
    Result := DefaultChoice;
end;

function TMsgBox.ShowMessage(const vText: string; Choices: array of TmsgSelect; DefaultChoice: Integer; CancelChoice: Integer; Kind: TmsgKind): Integer;
begin
  if not Locked and (FCurrent <> nil) then
    Result := FCurrent.ShowMessage(vText, Choices, DefaultChoice, CancelChoice, Kind)
  else
    Result := DefaultChoice;
end;

function TMsgBox.Find(vName: String): TMsgPrompt;
var
  i: Integer;
begin
  Result := nil;
  for i := 0 to Count - 1 do
  begin
    if SameText(Items[i].Name, vName) then
    begin
      Result := Items[i];
      break;
    end;
  end;
end;

function TMsgBox.GetLocked: Boolean;
begin
  Result := FLockCount > 0;
end;

function TMsgBox.GetItem(Index: Integer): TMsgPrompt;
begin
  Result := inherited Items[Index] as TMsgPrompt;
end;

procedure TMsgBox.SetCurrent(AValue: TMsgPrompt);
begin
  if FCurrent =AValue then Exit;
  FCurrent :=AValue;
end;

procedure TMsgBox.SetLocked(const Value: Boolean);
begin
  if Value then
    Inc(FLockCount)
  else
    Dec(FLockCount);
end;

function TMsgBox.Ask(const vText: string; Choices: TmsgChoices; DefaultChoice: TmsgChoice; CancelChoice: TmsgChoice; Kind: TmsgKind): TmsgChoice;
begin
  Result := ShowMessage(vText, Choices, DefaultChoice, CancelChoice, Kind);
end;

function TMsgBox.Ask(const vText: string; Choices: array of string; DefaultChoice: Integer; CancelChoice: Integer; Kind: TmsgKind = msgkNormal): Integer;
var
  a: TmsgChoice;
  c: array of TmsgSelect;
  i: Integer;
begin
  c := nil;
  i := 0;
  for i := 0 to Length(Choices)-1 do
  begin
    SetLength(c, i + 1);
    c[i] := Choice(Choices[i], msgcUnknown);
  end;
  Result := ShowMessage(vText, C, DefaultChoice, CancelChoice, Kind);
end;

function TMsgBox.Ask(const vText: string; Choices: array of TmsgSelect; DefaultChoice: Integer; CancelChoice: Integer = -1; Kind: TmsgKind = msgkNormal): Integer;
begin
  Result := ShowMessage(vText, Choices, DefaultChoice, CancelChoice, Kind);
end;

constructor TMsgConsole.Create;
begin
  inherited;
end;

destructor TMsgConsole.Destroy;
begin
  inherited;
end;

procedure TMsgConsole.HideStatus(Sender: TObject);
begin
  //TODO
end;

procedure TMsgConsole.Created;
begin
  FName := 'CONSOLE';
  FTitle := 'Console Messages';
end;

procedure TMsgConsole.ShowStatus(vText: string; Sender: TObject);
begin
  WriteLn(vText);
end;

{function TMsgConsole.ShowMessage(const vText: string; Choices: TmsgChoices; DefaultChoice: TmsgChoice; CancelChoice: TmsgChoice; Kind: TmsgKind): Integer;
var
  B: TmsgChoice;
  i, p: Integer;
  s: string;
  ch: Char;
begin
  //SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), FOREGROUND_RED or FOREGROUND_GREEN or FOREGROUND_BLUE);
  Write(Msg + ' [');
  i := 0;
  for B := Low(TmsgChoice) to High(TmsgChoice) do
    if B in Choices then
    begin
      if i > 0 then
        write(',');
      s := ChoiceCaptions[B];
      p := Pos('&', s);
      if p > 0 then
      begin
        write(Copy(s, 1, p - 1));
        //SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), FOREGROUND_RED or FOREGROUND_GREEN or FOREGROUND_BLUE or FOREGROUND_INTENSITY);
        write(Copy(s, p + 1, 1));
        //SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), FOREGROUND_RED or FOREGROUND_GREEN or FOREGROUND_BLUE);
        write(Copy(s, p + 2, MaxInt));
      end
      else
      begin
        write(s);
      end;
      Inc(i);
    end;
  write('] : ');
  ReadLn(ch);
  if ch = '' then
    Result := ModalResults[DefaultChoice]
  else
  begin
    Result := mrNone;
    for B := Low(TmsgChoice) to High(TmsgChoice) do
      if B in Choices then
      begin
        s := ChoiceCaptions[B];
        p := Pos('&', s);
        if p > 0 then
        begin
          if UpperCase(ch) = UpperCase(s[p + 1]) then
          begin
            Result := ModalResults[B];
            break;
          end;
        end;
      end;
  end;
end;}

{function TMsgConsole.ShowMessage(var Answer: string; const vText: string; Choices: TmsgChoices; DefaultChoice: TmsgChoice; CancelChoice: TmsgChoice; Kind: TmsgKind): Integer;
var
  OldMode: Cardinal;
begin
  if Kind = msgkPassword then
  begin
//    GetConsoleMode(GetStdHandle(STD_Input_HANDLE), OldMode);
//    SetConsoleMode(GetStdHandle(STD_Input_HANDLE), OldMode and not ENABLE_ECHO_INPUT);
  end;
  Write(Msg + ': ');
  ReadLn(Answer);
  if Kind = msgkPassword then
  begin
    WriteLn('');
//    SetConsoleMode(GetStdHandle(STD_Input_HANDLE), OldMode);
  end;
  Result := mrOK;
end;}

initialization
  Msg.Register(TMsgConsole);
finalization
  FreeAndNil(FMsgBox);
end.

