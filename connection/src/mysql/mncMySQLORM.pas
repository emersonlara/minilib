unit mncMySQLORM;
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
  SysUtils, Classes, mnUtils, Variants,
  mncMeta, mncORM, mncMySQL;

type

  { TmncORMMySQL }

  TmncORMMySQL = class(TmncORM)
  protected
    type

      { TDatabaseMySQL }

      TDatabaseMySQL = class(TormHelper)
      public
        function ProduceSQL(AObject: TormSQLObject; SQL: TCallbackObject; vLevel: Integer): Boolean; override;
      end;

      { TSchemaMySQL }

      TSchemaMySQL = class(TormHelper)
      public
        function ProduceSQL(AObject: TormSQLObject; SQL: TCallbackObject; vLevel: Integer): Boolean; override;
      end;

      { TTableMySQL }

      TTableMySQL = class(TormHelper)
      public
        function ProduceSQL(AObject: TormSQLObject; SQL: TCallbackObject; vLevel: Integer): Boolean; override;
      end;

      { TFieldsMySQL }

      TFieldsMySQL = class(TormHelper)
      public
        function ProduceSQL(AObject: TormSQLObject; SQL: TCallbackObject; vLevel: Integer): Boolean; override;
      end;

      { TFieldMySQL }

      TFieldMySQL = class(TormHelper)
      public
        function ProduceSQL(AObject: TormSQLObject; SQL: TCallbackObject; vLevel: Integer): Boolean; override;
      end;
  protected
    class function FieldTypeToString(FieldType:TormFieldType; FieldSize: Integer): String;
    procedure Created; override;
  public
  end;

implementation

{ TmncORMMySQL.TFieldsMySQL }

function TmncORMMySQL.TFieldsMySQL.ProduceSQL(AObject: TormSQLObject; SQL: TCallbackObject; vLevel: Integer): Boolean;
var
  o: TormObject;
  i: Integer;
begin
  i := 0;
  for o in AObject do
  begin
    if i > 0 then //not first line
      SQL.Add(',', [cboEndLine]);
    (o as TormSQLObject).GenerateSQL(SQL, vLevel);
    Inc(i);
  end;
  Result := True;
end;

{ TmncORMMySQL.TFieldMySQL }

function TmncORMMySQL.TFieldMySQL.ProduceSQL(AObject: TormSQLObject; SQL: TCallbackObject; vLevel: Integer): Boolean;
begin
//  vSQL.Add(LevelStr(vLevel) + Name + ' as Integer'); bug in fpc needs to reproduce but i can
  with AObject as TField do
  begin
    SQL.Add(LevelStr(vLevel) + Name + ' as '+ FieldTypeToString(FieldType, FieldSize));
    if foSequenced in Options then
      SQL.Add(' auto_increment');
    if not VarIsEmpty(DefaultValue) then
    begin
      if VarType(DefaultValue) = varString then
        SQL.Add(' default "' + DefaultValue + '"')
      else
        SQL.Add(' default ' + VarToStr(DefaultValue));
    end;
  end;
  Result := True;
end;

{ TmncORMMySQL.TTableMySQL }

function TmncORMMySQL.TTableMySQL.ProduceSQL(AObject: TormSQLObject; SQL: TCallbackObject; vLevel: Integer): Boolean;
var
  Field: TField;
begin
  Result := True;
  with AObject as TTable do
  begin

    SQL.Add('create table ' + Name);
    SQL.Add('(', [cboEndLine]);
    SQL.Params.Values['Table'] := Name;
    Fields.GenerateSQL(SQL, vLevel + 1);
    SQL.Add('', [cboEndLine]);
    SQL.Add(')', [cboEndLine, cboEndChunk]);

    for Field in Fields do
    begin
    end;
  end;
end;

{ TmncORMMySQL.TDatabaseMySQL }

function TmncORMMySQL.TDatabaseMySQL.ProduceSQL(AObject: TormSQLObject; SQL: TCallbackObject; vLevel: Integer): Boolean;
begin
  GenerateObjects(AObject, SQL, vLevel);
  Result := True;
end;

{ TmncORMMySQL.SchemaMySQL }

function TmncORMMySQL.TSchemaMySQL.ProduceSQL(AObject: TormSQLObject; SQL: TCallbackObject; vLevel: Integer): Boolean;
begin
  GenerateObjects(AObject, SQL, vLevel);
  Result := True;
end;

{ TmncORMMySQL }

class function TmncORMMySQL.FieldTypeToString(FieldType: TormFieldType; FieldSize: Integer): String;
begin
  case FieldType of
    ftString: Result := 'varchar('+IntToStr(FieldSize)+')';
    ftBoolean: Result := 'boolean';
    ftInteger: Result := 'integer';
    ftCurrency: Result := 'decimal(12, 4)';
    ftFloat: Result := 'float';
    ftDate: Result := 'date';
    ftTime: Result := 'time';
    ftDateTime: Result := 'datetime';
    ftMemo: Result := 'text';
    ftBlob: Result := 'text';
  end;
end;

procedure TmncORMMySQL.Created;
begin
  inherited Created;
  Register(TDatabase ,TDatabaseMySQL);
  Register(TSchema, TSchemaMySQL);
  Register(TTable, TTableMySQL);
  Register(TFields, TFieldsMySQL);
  Register(TField, TFieldMySQL);
end;

end.
