unit HFileAPI.FileStream;

interface

uses
  System.SysUtils,
  System.Classes,
  HCryptoAPI.Types,
  HCommonAPI.Intercept,
  HFileAPI.Types,
  HFileAPI.Commons;

{ Implements strong, hard and convinient FileStream. }
{ Be ready to see it in a full power.                }
{ Please note that it is a bit (long bit!) slower    }
{ than normal file stream, as it uses reallocation   }
{ of stream and data, if you did not changed mode.   }

(* Made by Hunter200165, All Code Is Preserved!     *)
(* You can use it freely in free software.          *)
(* Otherwise you are not allowed to use it without  *)
(* permissions.                                     *)

{ I strongly recommend you to use this strem with
  HFileAPI Functions, as many of them may overwrite
  your data, and it will be difficult to find this
  error                                              }

type
  HFile_FileStreamAllocateMode = (FSAlloc_Insert = 0, FSAlloc_Overwrite = 1);

type
  HFile_TFileStream = class(TFileStream)
  private
    FAllocateMode: HFile_FileStreamAllocateMode;
    FChunkSize: Integer;
    FIntercept: HCommon_TInterceptObject;
  protected
  public
    property AllocateMode: HFile_FileStreamAllocateMode read FAllocateMode write FAllocateMode;
    property ChunkSize: Integer read FChunkSize write FChunkSize;
    property Intercept: HCommon_TInterceptObject read FIntercept write FIntercept;
    function Write(Buffer: TBytesArray; Count: Integer = -1): Integer; overload; virtual;
    function Read(var Buffer: TBytesArray; Count: Integer = -1): Integer; overload; virtual;
    function Write(const Buffer; Count: LongInt): LongInt; overload; override;
    function Read(var Buffer; Count: LongInt): LongInt; overload; override;
    procedure WriteBuffer(const Buffer: TBytesArray; Count: Integer = -1); virtual;
    procedure ReadBuffer(var Buffer: TBytesArray; Count: Integer = -1); virtual;
    procedure Insert(const Buffer: TBytesArray; inPos: Int64 = -1);
    procedure Delete(const Count: Int64; From: Integer = -1);

    constructor Create(const FileName: String; const Mode: Word);
    destructor Destroy; override;
  end;

implementation

{ HFile_TFileStream }

constructor HFile_TFileStream.Create(const FileName: String; const Mode: word);
begin
  inherited Create(FileName, Mode);
  AllocateMode := FSAlloc_Insert;
  ChunkSize := 1048576; // MEGABYTE!
end;

procedure HFile_TFileStream.Delete(const Count: Int64; From: Integer);
begin
  if From < 0 then
    From := Position;
  HFile_RevokeFromStream(Self, From, Count, ChunkSize);
end;

destructor HFile_TFileStream.Destroy;
begin
  if Assigned(Intercept) then
    Intercept.Free;
  inherited;
end;

procedure HFile_TFileStream.Insert(const Buffer: TBytesArray; inPos: Int64);
begin
  if inPos < 0 then
    inPos := Position;
  HFile_InsertToStream(Self, Buffer, inPos, ChunkSize);
end;

function HFile_TFileStream.Read(var Buffer: TBytesArray; Count: Integer): Integer;
begin
  if Count < 0 then
    Count := Length(Buffer);
  Result := inherited Read(Buffer[0], Count);
  if Assigned(Intercept) then
    Intercept.Read(Buffer, Self);
end;

function HFile_TFileStream.Read(var Buffer; Count: Integer): LongInt;
var Bytes: TBytesArray;
begin
  Bytes.Size := Count;
  Result := inherited Read(Bytes[0], Count);
  if Assigned(Intercept) then
    Intercept.Read(Bytes, Self);
  Move(Bytes[0], Buffer, Count);
end;

procedure HFile_TFileStream.ReadBuffer(var Buffer: TBytesArray;
  Count: Integer);
begin
  if Count < 0 then
    Count := Length(Buffer);
  if not (Read(Buffer, Count) = Count) then
    raise EReadError.Create('Read had not prevailed.');
end;

function HFile_TFileStream.Write(Buffer: TBytesArray; Count: Integer): Integer;
begin
  if Count < 0 then
    Count := Length(Buffer);
  if Assigned(Intercept) then
    Intercept.Write(Buffer, Self);
  if (Position = Size) or (AllocateMode = FSAlloc_Overwrite) then
    Result := inherited Write(Buffer[0], Count)
  else begin
    HFile_InsertToStream(Self, Buffer, Position, ChunkSize);
    Result := Count;
  end;
end;

function HFile_TFileStream.Write(const Buffer; Count: Integer): LongInt;
var Bytes: TBytesArray;
begin
  Bytes.Size := Count;
  Move(Buffer, Bytes[0], Count);
  if Assigned(Intercept) then
    Intercept.Write(Bytes, Self);
  if (Position = Size) or (AllocateMode = FSAlloc_Overwrite) then
    Result := inherited Write(Bytes[0], Count)
  else begin
    HFile_InsertToStream(Self, Bytes, Position, ChunkSize);
    Result := Count;
  end;
end;

procedure HFile_TFileStream.WriteBuffer(const Buffer: TBytesArray; Count: Integer);
begin
  if Count < 0 then
    Count := Length(Buffer);
  if not (Write(Buffer, Count) = Count) then
    raise EWriteError.Create('Write had not prevailed.');
end;

end.
