unit mncORM;

{**
 *  This file is part of the "Mini Connections"
 *
 * @license   modifiedLGPL (modified of http://www.gnu.org/licenses/lgpl.html)
 *            See the file COPYING.MLGPL, included in this distribution,
 * @author    Zaher Dirkey <zaher at parmaja dot com>
 *}

{$IFDEF FPC}
{$mode delphi}
{$ENDIF}
{$H+}{$M+}

interface

uses
  Classes, SysUtils, Contnrs,
  mnClasses,mncConnections, mncCommons;

type

  TmncORM = class;
  TormObject = class;
  TormObjectClass = class of TormObject;

  { TormObject }

  TormObject = class(TmnNamedObjectList<TormObject>)
  private
    FComment: String;
    FName: String;
    FParent: TormObject;
    FRoot: TmncORM;
    FTags: String;
  protected
    procedure Added(Item: TormObject); override;
    procedure Check; virtual;
    function FindObject(ObjectClass: TormObjectClass; AName: string; RaiseException: Boolean = false): TormObject;
  public
    constructor Create(AParent: TormObject; AName: String);
    property Comment: String read FComment write FComment;
    function This: TormObject; //I wish i have templates/meta programming in pascal
    property Root: TmncORM read FRoot;
    property Parent: TormObject read FParent;

    property Name: String read FName write FName;
    property Tags: String read FTags write FTags; //etc: 'Key,Data'
  end;

  { TCallbackObject }

  TCallbackObjectOptions = set of (cboEndLine, cboEndChunk, cboMore);

  TCallbackObject = class(TObject)
  private
    FParams: TStringList;
    FCallbackObject: TObject;
  public
    Index: Integer;
    constructor Create;
    destructor Destroy; override;
    procedure Add(S: string; Options: TCallbackObjectOptions = []); virtual; abstract;
    property CallbackObject: TObject read FCallbackObject write FCallbackObject;
    property Params: TStringList read FParams;
  end;

  { TmncORM }

  TmncORM = class(TormObject)
  protected
  public
    type
    TormSQLObject = class;
    TormSQLObjectClass = class of TormSQLObject;

    { TormHelper }

    TormHelper = class(TObject)
    protected
      procedure GenerateObjects(AObject: TormSQLObject; SQL: TCallbackObject; vLevel: Integer);
      function ProduceSQL(AObject: TormSQLObject; SQL: TCallbackObject; vLevel: Integer): Boolean; virtual; abstract;
    end;

    TormHelperClass = class of TormHelper;

    { TormSQLObject }

    TormSQLObject = class(TormObject)
    protected
      HelperClass: TormHelperClass;
      procedure Created; override;
    public
      function GenName: string; virtual;
      function GenerateSQL(SQL: TCallbackObject; vLevel: Integer): Boolean;
    end;

    { TDatabase }

    TDatabase = class(TormSQLObject)
    private
      FVersion: integer;
    public
      constructor Create(AORM: TmncORM; AName: String);
      function This: TDatabase;
      property Version: integer read FVersion write FVersion;
    end;

    { TormSchema }

    TSchema = class(TormSQLObject)
    public
      constructor Create(ADatabase: TDatabase; AName: String);
      function This: TSchema;
    end;

    TField = class;
    TFields = class;
    TIndexes = class;
    TReferences = class;

    TFieldFilter = set of (ffNoSelect);

    { TTable }

    TTable = class(TormSQLObject)
    protected
      procedure Added(Item: TormObject); override;
    public
      Prefix: string; //used to added to generated field name, need more tests
      Fields: TFields;
      Indexes: TIndexes;
      References: TReferences;
      constructor Create(ASchema: TSchema; AName: String; APrefix: string = '');
      function ForSelect(AFilter: TFieldFilter; Keys: array of string; ExtraFields: array of string): string;
      function This: TTable;
    end;

    { TFields }

    TFields = class(TormSQLObject)
    public
      constructor Create(ATable: TTable);
      function This: TFields;
    end;

    { TIndexes }

    TIndexes = class(TormSQLObject)
    public
      constructor Create(ATable: TTable);
      function This: TIndexes;
    end;

    { TReferences }

    TReferences = class(TormSQLObject)
    public
      constructor Create(ATable: TTable);
      function This: TReferences;
    end;

    TormFieldOption = (
      foReferenced,
      foInternal, //Do not display for end user
      foSummed, //
      foPrimary,
      foSequenced, //or AutoInc
      foNotNull, //or required
      foIndexed
    );

    TormFieldOptions = set of TormFieldOption;
    TormFieldType = (ftString, ftBoolean, ftInteger, ftBigInteger, ftCurrency, ftFloat, ftDate, ftTime, ftDateTime, ftText, ftBlob);
    TormReferenceOptions = set of (rfoDelete, rfoUpdate, rfoRestrict);

    TReferenceInfoStr = record
      Table: string;
      Field: string;
      Options: TormReferenceOptions;
    end;

    TReferenceInfoLink = record
      Table: TTable;
      Field: TField;
      Options: TormReferenceOptions;
    end;

    { TField }

    TField = class(TormSQLObject)
    private
      FDefaultValue: Variant;
      FFieldSize: Integer;
      FFieldType: TormFieldType;
      FFilter: TFieldFilter;
      FIndex: string;
      FOptions: TormFieldOptions;
      function GetIndexed: Boolean;
      function GetPrimary: Boolean;
      function GetSequenced: Boolean;
      procedure SetIndexed(AValue: Boolean);
      procedure SetPrimary(AValue: Boolean);
      procedure SetSequenced(AValue: Boolean);
    protected
      ReferenceInfoStr: TReferenceInfoStr;
      procedure Check; override;
      function Table: TTable;
    public
      ReferenceInfo: TReferenceInfoLink;
      constructor Create(AFields: TFields; AName: String; AFieldType: TormFieldType; AOptions: TormFieldOptions = []);
      function GenName: string; override;
      function Parent: TFields;
      property Options: TormFieldOptions read FOptions write FOptions;
      property Filter: TFieldFilter read FFilter write FFilter;
      property DefaultValue: Variant read FDefaultValue write FDefaultValue;
      procedure ReferenceTo(TableName, FieldName: string; Options: TormReferenceOptions);

      property FieldType: TormFieldType read FFieldType write FFieldType;
      property FieldSize: Integer read FFieldSize write FFieldSize;

      property Indexed: Boolean read GetIndexed write SetIndexed;
      property Primary: Boolean read GetPrimary write SetPrimary;
      property Sequenced: Boolean read GetSequenced write SetSequenced;

      property Index: string read FIndex write FIndex;// this will group this field have same values into one index with that index name
    end;

    { StoredProcedure }

    TStoredProcedure = class(TormSQLObject)
    private
      FCode: String;
    public
      property Code: String read FCode write FCode;
    end;

    { Trigger }

    TTrigger = class(TormSQLObject)
    private
      FCode: String;
    public
      property Code: String read FCode write FCode;
    end;

  public
    type

    TRegObject = class(TObject)
    public
      ObjectClass: TormObjectClass;
      HelperClass: TormHelperClass;
    end;

    { TRegObjects }

    TRegObjects = class(TmnObjectList<TRegObject>)
    public
      function FindDerived(AObjectClass: TormObjectClass): TormObjectClass;
      function FindHelper(AObjectClass: TormObjectClass): TormHelperClass;
    end;

  private
    FObjectClasses: TRegObjects;
    FQuoteChar: string;
    FUsePrefexes: Boolean;

  protected
  public
    constructor Create(AName: String); virtual;
    destructor Destroy; override;
    function This: TmncORM;

    function CreateDatabase(AName: String): TDatabase;
    function CreateSchema(ADatabase: TDatabase; AName: String): TSchema;
    function CreateTable(ASchema: TSchema; AName: String): TTable;
    function CreateField(ATable: TTable; AName: String; AFieldType: TormFieldType; AOptions: TormFieldOptions = []): TField;

    function GenerateSQL(Callback: TCallbackObject): Boolean; overload;
    function GenerateSQL(vSQL: TStrings): Boolean; overload;

    procedure Register(AObjectClass: TormObjectClass; AHelperClass: TormHelperClass);
    property ObjectClasses: TRegObjects read FObjectClasses;
    property QuoteChar: string read FQuoteChar write FQuoteChar; //Empty, it will be used with GenName
    property UsePrefexes: Boolean read FUsePrefexes write FUsePrefexes; //option to use Prefex in Field names
  end;

  TmncORMClass = class of TmncORM;

function LevelStr(vLevel: Integer): String;

implementation

{ TmncORM.TReferences }

constructor TmncORM.TReferences.Create(ATable: TTable);
begin
  inherited Create(ATable, '');
  if ATable <> nil then
    ATable.References := Self;
end;

function TmncORM.TReferences.This: TReferences;
begin
  Result := Self;
end;

{ TmncORM.TIndexes }

constructor TmncORM.TIndexes.Create(ATable: TTable);
begin
  inherited Create(ATable, '');
  if ATable <> nil then
    ATable.Indexes := Self;
end;

function TmncORM.TIndexes.This: TIndexes;
begin
  Result := Self;
end;

{ TCallbackObject }

constructor TCallbackObject.Create;
begin
  inherited Create;
  FParams := TStringList.Create;
end;

destructor TCallbackObject.Destroy;
begin
  FreeAndNil(FParams);
  inherited Destroy;
end;

{ TmncORM.TormHelper }

procedure TmncORM.TormHelper.GenerateObjects(AObject: TormSQLObject; SQL: TCallbackObject; vLevel: Integer);
var
  o: TormObject;
begin
  for o in AObject do
    (o as TormSQLObject).GenerateSQL(SQL, vLevel);
end;

{ TmncORM.TormSQLObject }

procedure TmncORM.TormSQLObject.Created;
begin
  inherited Created;
  if (FRoot <> nil) then
    HelperClass := (Root as TmncORM).ObjectClasses.FindHelper(TormObjectClass(ClassType));
end;

function TmncORM.TormSQLObject.GenName: string;
begin
  Result := Name;
end;

function TmncORM.TormSQLObject.GenerateSQL(SQL: TCallbackObject; vLevel: Integer): Boolean;
var
  helper: TormHelper;
begin
  if HelperClass <> nil then
  begin
    helper := HelperClass.Create;
    Result := helper.ProduceSQL(self, SQL, vLevel);
  end
  else
    Result := False;
end;

{ TmncORM.TormHelper }

{ TmncORM.TRegObjects }

function TmncORM.TRegObjects.FindDerived(AObjectClass: TormObjectClass): TormObjectClass;
var
  o: TRegObject;
begin
  for o in Self do
  begin
    if o.ObjectClass.ClassParent = AObjectClass then
    begin
      Result := o.ObjectClass;
      break;
    end;
  end;
end;

function TmncORM.TRegObjects.FindHelper(AObjectClass: TormObjectClass): TormHelperClass;
var
  o: TRegObject;
begin
  for o in Self do
  begin
    if o.ObjectClass = AObjectClass then
    begin
      Result := o.HelperClass;
      break;
    end;
  end;
end;

{ TmncORM.TFields }

constructor TmncORM.TFields.Create(ATable: TTable);
begin
  inherited Create(ATable, '');
  if ATable <> nil then
    ATable.Fields := Self;
end;

function TmncORM.TFields.This: TFields;
begin
  Result := Self;
end;

{ TmncORM }

constructor TmncORM.Create(AName: String);
begin
  inherited Create(nil, AName);
  FRoot := Self;
  FObjectClasses := TRegObjects.Create;
end;

destructor TmncORM.Destroy;
begin
  inherited Destroy;
end;

function TmncORM.This: TmncORM;
begin
  Result := Self;
end;

function TmncORM.CreateDatabase(AName: String): TDatabase;
begin
  Result := TDatabase.Create(Self, AName);
end;

function TmncORM.CreateSchema(ADatabase: TDatabase; AName: String): TSchema;
begin
  Result := TSchema.Create(ADatabase, AName);
end;

function TmncORM.CreateTable(ASchema: TSchema; AName: String): TTable;
begin
  Result := TTable.Create(ASchema, AName);
  TFields.Create(Result); //will be assigned to Fields in TFields.Create
end;

function TmncORM.CreateField(ATable: TTable; AName: String; AFieldType: TormFieldType; AOptions: TormFieldOptions): TField;
begin
  Result := TField.Create(ATable.Fields, AName, AFieldType, AOptions);
end;

procedure TmncORM.Register(AObjectClass: TormObjectClass; AHelperClass: TormHelperClass);
var
  aRegObject: TRegObject;
begin
  aRegObject := TRegObject.Create;
  aRegObject.ObjectClass := AObjectClass;
  aRegObject.HelperClass := AHelperClass;
  ObjectClasses.Add(aRegObject);
end;

{ TField }

function TmncORM.TField.GetIndexed: Boolean;
begin
  Result := foIndexed in Options;
end;

function TmncORM.TField.GetPrimary: Boolean;
begin
  Result := foPrimary in Options;
end;

function TmncORM.TField.GetSequenced: Boolean;
begin
  Result := foSequenced in Options;
end;

procedure TmncORM.TField.SetIndexed(AValue: Boolean);
begin
  if AValue then
    Options := Options + [foIndexed]
  else
    Options := Options - [foIndexed];
end;

procedure TmncORM.TField.SetPrimary(AValue: Boolean);
begin
  if AValue then
    Options := Options + [foPrimary]
  else
    Options := Options - [foPrimary];
end;

procedure TmncORM.TField.SetSequenced(AValue: Boolean);
begin
  if AValue then
    Options := Options + [foSequenced]
  else
    Options := Options - [foSequenced];
end;

procedure TmncORM.TField.Check;
begin
  if ReferenceInfoStr.Table <> '' then
    ReferenceInfo.Table := Root.FindObject(TTable, ReferenceInfoStr.Table, true) as TTable;
  if ReferenceInfoStr.Field <> '' then
    ReferenceInfo.Field := Root.FindObject(TField, ReferenceInfoStr.Field, true) as TField;
  ReferenceInfo.Options := ReferenceInfoStr.Options;
  inherited Check;
end;

function TmncORM.TField.Table: TTable;
begin
  Result := Parent.Parent as TTable;
end;

constructor TmncORM.TField.Create(AFields: TFields; AName: String; AFieldType: TormFieldType; AOptions: TormFieldOptions);
begin
  inherited Create(AFields, AName);
  FOptions := AOptions;
  FFieldType := AFieldType;
end;

function TmncORM.TField.GenName: string;
begin
  Result := inherited GenName;
  if (Table <> nil) then
  begin
    if Root.UsePrefexes then
      Result := Table.Prefix + Result;
    if Root.QuoteChar <> '' then
      Result := Root.QuoteChar + Result + Root.QuoteChar;
  end;
end;

function TmncORM.TField.Parent: TFields;
begin
  Result := inherited Parent as TFields;
end;

procedure TmncORM.TField.ReferenceTo(TableName, FieldName: string; Options: TormReferenceOptions);
begin
  ReferenceInfoStr.Table := TableName;
  ReferenceInfoStr.Field := FieldName;
  ReferenceInfoStr.Options := Options;
end;

{ TTable }

function TmncORM.TTable.This: TTable;
begin
  Result := Self;
end;

procedure TmncORM.TTable.Added(Item: TormObject);
begin
  inherited Added(Item);
  if Item is TFields then
  begin
    if Fields = nil then
      Fields := Item as TFields
    else
      raise Exception.Create('You cannot Send Fields twice');
  end;
end;

constructor TmncORM.TTable.Create(ASchema: TSchema; AName: String; APrefix: string);
begin
  inherited Create(ASchema, AName);
  Prefix := APrefix;
  //TFields := TFields.Create(Self); //hmmmmmm :J
end;

function TmncORM.TTable.ForSelect(AFilter: TFieldFilter; Keys: array of string; ExtraFields: array of string): string;
var
  f: TField;
var
  i: Integer;
  b: Boolean;
begin
  Result := 'select ';
  b := False;
  for i := 0 to Length(ExtraFields) - 1 do
  begin
    if b then
      Result := Result + ', '
    else
      b := True;
    Result := Result + ExtraFields[i];
  end;

  for f in Fields do
  begin
    if (AFilter = []) or (AFilter = f.Filter) then
    begin
      if b then
        Result := Result + ', '
      else
        b := True;
      Result := Result + f.GenName;
    end;
  end;

  Result := Result + ' from ' + Self.GenName + ' ';
  for i := 0 to Length(Keys) - 1 do
  begin
    if i = 0 then
      Result := Result + ' where '
    else
      Result := Result + ' and ';
    Result := Result + Keys[i] + '=?' + Keys[i];
  end;

end;

{ TSchema }

function TmncORM.TSchema.This: TSchema;
begin
  Result := Self;
end;

constructor TmncORM.TSchema.Create(ADatabase: TDatabase; AName: String);
begin
  inherited Create(ADatabase, AName);
end;

{ TormObject }

function TormObject.This: TormObject;
begin
  Result := Self;
end;

procedure TormObject.Added(Item: TormObject);
begin
  inherited Added(Item);
end;

procedure TormObject.Check;
var
  o: TormObject;
begin
  for o in Self do
    o.Check;
end;

function TormObject.FindObject(ObjectClass: TormObjectClass; AName: string; RaiseException: Boolean): TormObject;
var
  o: TormObject;
begin
  Result := nil;
  for o in Self do
  begin
    if (o.ClassType = ObjectClass) and (SameText(o.Name, AName)) then
    begin
      Result := o;
      exit;
    end;
  end;
  for o in Self do
  begin
    Result := o.FindObject(ObjectClass, AName);
    if Result <> nil then
      exit;
  end;
  if RaiseException and (Result = nil) then
    raise Exception.Create(ObjectClass.ClassName + ': ' + AName +  ' not exists');
end;


function LevelStr(vLevel: Integer): String;
begin
  Result := StringOfChar(' ', vLevel * 4);
end;

constructor TormObject.Create(AParent: TormObject; AName: String);
begin
  inherited Create;
  FName := AName;
  if AParent <> nil then
  begin
    FParent := AParent;
    AParent.Add(Self);
    FRoot := AParent.Root;
  end;
end;

{ TDatabase }

function TmncORM.TDatabase.This: TDatabase;
begin
  Result := Self;
end;

constructor TmncORM.TDatabase.Create(AORM: TmncORM; AName: String);
begin
  inherited Create(AORM, AName);
end;

type

  { TSQLCallbackObject }

  TSQLCallbackObject = class(TCallbackObject)
  public
    Buffer: string;
    SQL: TStrings;
    destructor Destroy; override;
    procedure Add(S: string; Options: TCallbackObjectOptions = []); override;
  end;

{ TSQLCallbackObject }

destructor TSQLCallbackObject.Destroy;
begin
  if Buffer <> '' then
    Add('', [cboEndLine]);
  inherited Destroy;
end;

procedure TSQLCallbackObject.Add(S: string; Options: TCallbackObjectOptions);
begin
  Buffer := Buffer + S;
  if (cboEndLine in Options) or (cboEndChunk in Options) then
  begin
    if Buffer <> '' then
      SQL.Add(Buffer);
    Buffer := '';
  end;
  if (cboEndChunk in Options) and (SQL.Count > 0) then
  begin
    SQL.Add('^');
    SQL.Add(' ');
  end;
end;

function TmncORM.GenerateSQL(vSQL: TStrings): Boolean;
var
  SQLCB: TSQLCallbackObject;
begin
  SQLCB := TSQLCallbackObject.Create;
  SQLCB.SQL := vSQL;
  GenerateSQL(SQLCB);
  FreeAndNil(SQLCB);
  Result := True;
end;

function TmncORM.GenerateSQL(Callback: TCallbackObject): Boolean;
var
  AParams: TStringList;
  o: TormSQLObject;
  helper: TormHelper;
begin
  Check;
  AParams := TStringList.Create;
  try
    for o in Self do
    begin
      if o.HelperClass <> nil then
      begin
        helper := o.HelperClass.Create;
        helper.ProduceSQL(o, Callback, 0);
      end;
    end;
  finally
    FreeAndNil(AParams);
  end;
  Result := True;
end;

end.
