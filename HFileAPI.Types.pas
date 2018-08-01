unit HFileAPI.Types;

interface

uses
  System.Classes,
  System.Generics.Collections,
  System.SysUtils,
  HCryptoAPI.Types,
  HCryptoAPI.Commons,
  HCommonAPI.CompactBoolean,
  HCryptoAPI.Equalizer;

type
  HFile_TSetting = class(TObject)
  private
    FSettings: HCommon_TCompactBoolean;
  protected
  public
    property Settings: HCommon_TCompactBoolean read FSettings write FSettings; // 64 bits
    constructor Create(const Sets: Int64);
  end;

  HFile_TSettingsList = TObjectList<HFile_TSetting>;

  HFile_TCompactNumber_Signed = record
  private
    FContent: Int64;
    function GetByteLength: Integer;
  public
    property Content: Int64 read FContent write FContent;
    property ByteLength: Integer read GetByteLength;
    function GetBytesRaw: TBytesArray;
    function GetBytes: TBytesArray;
  end;

  HFile_TCompactNumber_Unsigned = record
  private
    FContent: UInt64;
    function GetByteLength: Integer;
  public
    property Content: UInt64 read FContent write FContent;
    property ByteLength: Integer read GetByteLength;
    function GetBytesRaw: TBytesArray;
    function GetBytes: TBytesArray;
  end;

//  HFile_CompactNumberReader_Modes = (HFCNumberUnsigned, HFCNumberSigned);
  HFile_TCompactNumberReader = record
  private
    FFileStream: TStream;
  public
    property FileStream: TStream read FFileStream write FFileStream;
    property Stream: TStream read FFileStream write FFileStream;

    function ReadSigned: HFile_TCompactNumber_Signed;
    function ReadUnsigned: HFile_TCompactNumber_Unsigned;
    procedure WriteSigned(Number: HFile_TCompactNumber_Signed); overload;
    procedure WriteSigned(Number: Int64); overload;
    procedure WriteUnsigned(Number: HFile_TCompactNumber_Unsigned); overload;
    procedure WriteUnsigned(Number: UInt64); overload;
  end;

  HFile_TStringReader = record
  private
    FFileStream: TStream;
    NumberReader: HFile_TCompactNumberReader;
  public
    property FileStream: TStream read FFileStream write FFileStream;
    property Stream: TStream read FFileStream write FFileStream;

    function ReadString: string;
    procedure WriteString(const S: String);
    function ReadString_ASCII: string;
    procedure WriteString_ASCII(const S: String);
  end;

  HFile_TBytesReader = record
  private
    NumberReader: HFile_TCompactNumberReader;
    FStream: TStream;
  public
    property Stream: TStream read FStream write FStream;

    function ReadBytes: TBytesArray;
    procedure WriteBytes(const Bytes: TBytesArray);
  end;

  HFile_TContainer = class(TObject);  (* To inherit from *)
  HFile_ReadProcedure = procedure of object;
  HFile_WriteProcedure = procedure of object;

  HFile_THeader = class(TObject)
  private
    FFileStream: TStream;
    FSettings: HFile_TSettingsList;
    FReadOther: HFile_ReadProcedure;
    FWriteOther: HFile_WriteProcedure;
    FContainer: HFile_TContainer;
    FStart: Int64;
    FFinish: Int64;
  protected
    Reader: HFile_TCompactNumberReader;
    StringReader: HFile_TStringReader;
  public
    property FileStream: TStream read FFileStream write FFileStream;
    property Settings: HFile_TSettingsList read FSettings write FSettings;
    property ReadOther: HFile_ReadProcedure read FReadOther write FReadOther;
    property WriteOther: HFile_WriteProcedure read FWriteOther write FWriteOther;
    property Container: HFile_TContainer read FContainer write FContainer;
    property Start: Int64 read FStart write FStart;
    property Finish: Int64 read FFinish write FFinish;
    constructor Create(FileToRead: TFileStream);
    procedure Read;
    procedure Write;
    destructor Destroy; override;
  end;

implementation

{ HFile_THeader }

constructor HFile_THeader.Create(FileToRead: TFileStream);
begin
  inherited Create;
  FileStream := FileToRead; (* Reference *)
  Settings := HFile_TSettingsList.Create;
  Reader.FileStream := FileToRead; (* Reference *)
  StringReader.FileStream := FileToRead; (* Reference *)
  Container := HFile_TContainer.Create;
end;

destructor HFile_THeader.Destroy;
begin
  Settings.Free;
  Container.Free;
  inherited;
end;

procedure HFile_THeader.Read;
var ContentLength, SettingsCount: UInt64;
    PositionStart, PositionFinish, i, Setting: Int64;
begin
  ContentLength := Reader.ReadUnsigned.Content;
  PositionStart := FileStream.Position;
  Start := PositionStart;
  SettingsCount := Reader.ReadUnsigned.Content;
  Settings.Clear;
  for i := 1 to SettingsCount do begin
    Setting := Reader.ReadSigned.Content;
    Settings.Add(HFile_TSetting.Create(Setting));
  end;
  if (PositionStart + ContentLength) < FileStream.Position then begin
    if not Assigned(ReadOther) then
      raise EReadError.Create('Reader procedure is not assigned: Data is lost.');
    ReadOther;
    if (PositionStart + ContentLength) <> FileStream.Position then
      raise EReadError.Create('Reader procedure size mismatch.');
  end
  else if (PositionStart + ContentLength) = FileStream.Position then begin
    { All is OK }
  end
  else
    raise EReadError.Create('Content length parameter is wrong.');
  PositionFinish := FileStream.Position;
  Finish := PositionFinish;
end;

procedure HFile_THeader.Write;
var PositionStart, PositionFinish, i: Int64;
    Rec: HFile_TCompactNumber_Unsigned;
    RecS: HFile_TCompactNumber_Signed;
begin
  PositionStart := FileStream.Position;
  Start := PositionStart;
  Rec.Content := Settings.Count;
  Reader.WriteUnsigned(Rec);
  for i := 0 to Settings.Count - 1 do begin
    RecS.Content := Settings[i].Settings.Storage;
    Reader.WriteSigned(RecS);
  end;
  if Assigned(WriteOther) then
    WriteOther;
  PositionFinish := FileStream.Position;
  Rec.Content := PositionFinish - PositionStart;
  // FileStream.Size := FileStream.Size + Rec.ByteLength + 1;
  FileStream.Position := PositionStart;
  Reader.WriteUnsigned(Rec);
  FileStream.Position := PositionFinish + Rec.ByteLength + 1;
  Finish := FileStream.Position;
end;

{ HFile_TSetting }

constructor HFile_TSetting.Create(const Sets: Int64);
begin
  FSettings.Storage := Sets;
end;

{ HFile_TCompactNumber_Signed }

function HFile_TCompactNumber_Signed.GetByteLength: Integer;
begin
  Result := Length(GetBytesRaw);
end;

function HFile_TCompactNumber_Signed.GetBytes: TBytesArray;
var i: Integer;
begin
  Result := GetBytesRaw;
  HCrypto_IncLength(Result, 1);
  for i := Length(Result) - 1 downto 1 do
    Result[i] := Result[i - 1];
  Result[0] := Length(Result) - 1;
end;

function HFile_TCompactNumber_Signed.GetBytesRaw: TBytesArray;
begin
  Result := HCrypto_StripBytes(HCrypto_TEqualizer<Int64>.ToBytes(FContent));
  if Result.Size = 0 then
    Result.Append([0]);
end;

{ HFile_TCompactNumber_Unsigned }

function HFile_TCompactNumber_Unsigned.GetByteLength: Integer;
begin
  Result := Length(GetBytesRaw);
end;

function HFile_TCompactNumber_Unsigned.GetBytes: TBytesArray;
var i: Integer;
begin
  Result := GetBytesRaw;
  HCrypto_IncLength(Result, 1);
  for i := Length(Result) - 1 downto 1 do
    Result[i] := Result[i - 1];
  Result[0] := Length(Result) - 1;
end;

function HFile_TCompactNumber_Unsigned.GetBytesRaw: TBytesArray;
begin
  Result := HCrypto_StripBytesRight(HCrypto_TEqualizer<UInt64>.ToBytes(FContent));
  if Result.Size = 0 then
    Result.Size := 1;
end;

{ HFile_TCompactNumberReader }

function HFile_TCompactNumberReader.ReadSigned: HFile_TCompactNumber_Signed;
var Len: Byte;
    ByteArr: TBytesArray;
begin
  FileStream.Read(Len, 1);
  if Len > 8 then
    raise ERangeError.Create('Cannot read more than 8 bytes');
  HCrypto_ReLength(ByteArr, Len);
  FileStream.Read(ByteArr[0], Len);
  Result.FContent := HCrypto_TEqualizer<Int64>.FromBytes(ByteArr);
end;

function HFile_TCompactNumberReader.ReadUnsigned: HFile_TCompactNumber_Unsigned;
var Len: Byte;
    ByteArr: TBytesArray;
begin
  FileStream.Read(Len, 1);
  if Len > 8 then
    raise ERangeError.Create('Cannot read more than 8 bytes');
  HCrypto_ReLength(ByteArr, Len);
  FileStream.Read(ByteArr[0], Len);
  Result.FContent := HCrypto_TEqualizer<UInt64>.FromBytes(ByteArr);
end;

procedure HFile_TCompactNumberReader.WriteSigned(Number: HFile_TCompactNumber_Signed);
var Bytes: TBytesArray;
begin
  Bytes := Number.GetBytes;
  FileStream.Write(Bytes[0], Length(Bytes));
end;

procedure HFile_TCompactNumberReader.WriteUnsigned(Number: HFile_TCompactNumber_Unsigned);
var Bytes: TBytesArray;
begin
  Bytes := Number.GetBytes;
  FileStream.Write(Bytes[0], Length(Bytes));
end;

procedure HFile_TCompactNumberReader.WriteSigned(Number: Int64);
var CompactNumber: HFile_TCompactNumber_Signed;
begin
  CompactNumber.Content := Number;
  WriteSigned(CompactNumber);
end;

procedure HFile_TCompactNumberReader.WriteUnsigned(Number: UInt64);
var CompactNumber: HFile_TCompactNumber_Unsigned;
begin
  CompactNumber.Content := Number;
  WriteUnsigned(CompactNumber);
end;

{ HFile_TStringReader }

function HFile_TStringReader.ReadString: string;
var Buffer: TBytesArray;
    StringLength: UInt64;
begin
  NumberReader.FileStream := FileStream;
  StringLength := NumberReader.ReadUnsigned.Content;
  HCrypto_ReLength(Buffer, StringLength);
  FileStream.Read(Buffer[0], StringLength);
  Result := HCrypto_BytesToString(Buffer);
end;

function HFile_TStringReader.ReadString_ASCII: string;
var Buffer: TBytesArray;
    StringLength: UInt64;
begin
  NumberReader.FileStream := FileStream;
  StringLength := NumberReader.ReadUnsigned.Content;
  HCrypto_ReLength(Buffer, StringLength);
  if FileStream.Read(Buffer[0], StringLength) <> StringLength then
    raise EReadError.Create('Read size mismatch');
  {$WARNINGS OFF}
  Result := HCrypto_BytesToString_ASCII(Buffer);
  {$WARNINGS ON}
end;

procedure HFile_TStringReader.WriteString(const S: String);
var Buffer: TBytesArray;
    Rec: HFile_TCompactNumber_Unsigned;
    Len: Integer;
begin
  NumberReader.FileStream := FileStream;
  Buffer := HCrypto_StringToBytes(S);
  Len := Length(Buffer); { Ooooptimization! }
  Rec.Content := Len;
  NumberReader.WriteUnsigned(Rec);
  FileStream.Write(Buffer[0], Len); // Slower
end;

procedure HFile_TStringReader.WriteString_ASCII(const S: String);
var Buffer: TBytesArray;
    Rec: HFile_TCompactNumber_Unsigned;
    Len: Integer;
begin
  NumberReader.FileStream := FileStream;
  {$WARNINGS OFF}
  Buffer := HCrypto_StringToBytes_ASCII(S);
  {$WARNINGS ON}
  Len := Length(Buffer); { Ooooptimization! }
  Rec.Content := Len;
  NumberReader.WriteUnsigned(Rec);
  FileStream.Write(Buffer[0], Len); // Slower
end;

{ HFile_TBytesReader }

function HFile_TBytesReader.ReadBytes: TBytesArray;
var Count: Integer;
begin
  NumberReader.Stream := Stream;
  Count := NumberReader.ReadUnsigned.Content;
  Result := TBytesArray.ReadFromStream(Stream, Count);
end;

procedure HFile_TBytesReader.WriteBytes(const Bytes: TBytesArray);
begin
  NumberReader.Stream := Stream;
  NumberReader.WriteUnsigned(Bytes.Size);
  Bytes.WriteToStream(Stream);
end;

end.

