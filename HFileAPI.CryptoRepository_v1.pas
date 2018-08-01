unit HFileAPI.CryptoRepository_v1;

interface

uses
  System.Generics.Collections,
  System.SysUtils,
  System.Classes,
  System.StrUtils,
  HFileAPI.Types,
  HFileAPI.Commons,
  HFileAPI.FileStream,
  HFileAPI.Path.Commons,
  HCommonAPI.LinkedStream,
  HCommonAPI.CompactBoolean,
  HCryptoAPI.Types,
  HCryptoAPI.Commons,
  HCryptoAPI.Hash.KHA_v1,
  HCryptoAPI.Cipher.EncryBIT_v12,
  HCryptoAPI.Cipher.EncryBIT_v2;

 {TODO -oHunter200165 -cTCryptoRepository_v1 : Bring support to new Streams: TLinkedStream}

type
  HFile_EEncryptionManagerException = Exception;
  HFile_TCryptoRepository_v1 = class(TObject)
  public
   { Classes }
   type
    TRepositoryIndexRecord_Paths = class(TObject)
    private
      FPath: String;
      FUUId: UInt64;
        function GetPathFL: string;
    public
      property Path: String read FPath write FPath;
      property PathFixedLowered: string read GetPathFL;
      property UUId: UInt64 read FUUId write FUUId;
      function ToBytes: TBytesArray;
      constructor Create(Bytes: TBytesArray); overload;
      constructor Create(const Path: string; Const UUId: UInt64); overload;
    end;

    TRepositoryIndexRecord_PathsList = TObjectList<TRepositoryIndexRecord_Paths>;

    TRepositoryIndex = class(TObject)
    private
      FIndexHeader: TRepositoryIndexRecord_PathsList;
      FStream: TStream;
      FParent: HFile_TCryptoRepository_v1;
      FUUId: UInt64;
    public
      property UUId: UInt64 read FUUId write FUUId;
      property IndexHeader: TRepositoryIndexRecord_PathsList read FIndexHeader write FIndexHeader;
      property Stream: TStream read FStream write FStream;
      property Parent: HFile_TCryptoRepository_v1 read FParent write FParent;
      procedure Write;
      procedure Read;

      function ToBytes: TBytesArray;
      function ResolvePathId(const Id: UInt64): Int64;
      function ResolvePathName(const Name: string): Int64;
      function AddPath(const Name: String): Int64; overload;
      function AddPath(const Id: UInt64; const Name: String = ''): Int64; overload;

      procedure AssignToPosition(Path: TRepositoryIndexRecord_Paths; const Position: Int64);
      procedure NextId;

      constructor Create(Stream: TStream);
      destructor Destroy; override;
    end;

    TFile = class;

    TFileHeader = class(TObject)
    private
      FName: String;
      FSize: UInt64;
      FPath: UInt64;
      FPathResolved: String;
      FParent: HFile_TCryptoRepository_v1;
      FParentFile: TFile;
    public
      property Name: String read FName write FName;
      property Size: UInt64 read FSize write FSize;
      property Path: UInt64 read FPath write FPath;

      { Non neccessary attributes }
      property PathResolved: String read FPathResolved write FPathResolved;
      property Parent: HFile_TCryptoRepository_v1 read FParent write FParent;
      property ParentFile: TFile read FParentFile write FParentFile;

      function ToBytes: TBytesArray;
      procedure FromBytes(const Bytes: TBytesArray);

      constructor Create(Parent: HFile_TCryptoRepository_v1; const Name: String; const Path, Size: UInt64); overload;
      constructor Create(Parent: HFile_TCryptoRepository_v1; const Path: String; const Size: UInt64); overload;
      constructor Create(Parent: HFile_TCryptoRepository_v1; const Bytes: TBytesArray); overload;
    end;

    TFile = class(TObject)
    private
      FStream: TStream;
      FHeader: TFileHeader;
      FParent: HFile_TCryptoRepository_v1;
      FHeaderPosition: Int64;
      FFilePosition: Int64;
      FFileStream: HCommon_TLinkedStream;
    public
      property Stream: TStream read FStream write FStream;
      property Header: TFileHeader read FHeader write FHeader;
      property Parent: HFile_TCryptoRepository_v1 read FParent write FParent;
      property HeaderPosition: Int64 read FHeaderPosition write FHeaderPosition;
      property FilePosition: Int64 read FFilePosition write FFilePosition;
      property FileStream: HCommon_TLinkedStream read FFileStream write FFileStream;

      procedure Write;
      procedure Read;

      destructor Destroy; override;
    end;

    TFileList_Low = TObjectList<TFile>;
    TFileList = class(TObject)
    private
      FFiles: TFileList_Low;
      FStream: TStream;
      FParent: HFile_TCryptoRepository_v1;
      function GetFile(const Id: Integer): TFile;
      procedure SetFile(const Id: Integer; const Value: TFile);
    public 
      property Stream: TStream read FStream write FStream;
      property Files: TFileList_Low read FFiles write FFiles;
      property Parent: HFile_TCryptoRepository_v1 read FParent write FParent;
      property Indexed[const Id: Integer]: TFile read GetFile write SetFile;

      procedure Write;
      procedure Read;

      constructor Create;
      destructor Destroy; override;
    end;

    TEncryptionManager = class(TObject)
    private
      FSignatureKey: TBytesArray;
      FStream: TStream;
      FParent: HFile_TCryptoRepository_v1;
      FEncrypted: Boolean;
      FDigest: TBytesArray;
      FEncryptionKey: TBytesArray;
    public
      const SignatureKeySize: Integer = 256;
      const DigestSize: Integer = 256;
      property Stream: TStream read FStream write FStream;
      property Parent: HFile_TCryptoRepository_v1 read FParent write FParent;

      { We need to check, if the Digest is valid. }
      property EncryptionKey: TBytesArray read FEncryptionKey write FEncryptionKey;
      property SignatureKey: TBytesArray read FSignatureKey write FSignatureKey;
      property Digest: TBytesArray read FDigest write FDigest;

      property Encrypted: Boolean read FEncrypted write FEncrypted;

      procedure WriteNewSignatureKey;
      procedure WriteSignatureKey;
      procedure ReadSignatureKey;

      procedure WriteNewDigest;
      procedure WriteDigest;
      procedure ReadDigest;

      constructor Create(Stream: TStream);
    end;

    TDigest = class(TObject)
    private
      FStream: TStream;
      FParent: HFile_TCryptoRepository_v1;
    public
      property Stream: TStream read FStream write FStream;
      property Parent: HFile_TCryptoRepository_v1 read FParent write FParent;
    end;

  { Repositorium }
  private
    FRepositoryIndex: TRepositoryIndex;
    FFiles: TFileList;
    [Weak] FStream: TStream;
    FSettings: HCommon_TCompactBoolean;
    FEncryptionManager: TEncryptionManager;
  public
    property Stream: TStream read FStream write FStream;
    property RepositoryIndex: TRepositoryIndex read FRepositoryIndex write FRepositoryIndex;
    property Files: TFileList read FFiles write FFiles;

    property Settings: HCommon_TCompactBoolean read FSettings write FSettings;
    property EncryptionManager: TEncryptionManager read FEncryptionManager write FEncryptionManager;

    procedure CreateNew;
    procedure CreateToolbox; { Creates toolbox of Repositorium }

    procedure LoadFromStream;
    procedure SaveToStream(OutStream: TStream);
    
    constructor Create(const FileName: String); overload;
    constructor Create(Stream: TStream); overload;
    destructor Destroy; override;
  end;

implementation

{ HFile_TCryptoRepository_v1.TRepositoryIndexRecord_Paths }

constructor HFile_TCryptoRepository_v1.TRepositoryIndexRecord_Paths.Create(Bytes: TBytesArray);
var MemStr: TMemoryStream;
    Reader: HFile_TCompactNumberReader;
    Count: Int64;
    Buffer: TBytesArray;
begin
  MemStr := Bytes.ToMemoryStream;
  Reader.FileStream := MemStr; // You can do what you want to do
  Count := Reader.ReadUnsigned.Content;
  Buffer := Buffer.ReadFromStream(MemStr, Count);
  Path := Buffer.ToString;
  UUId := Reader.ReadUnsigned.Content;
  MemStr.Free;
end;

constructor HFile_TCryptoRepository_v1.TRepositoryIndexRecord_Paths.Create(const Path: string; const UUId: UInt64);
begin
  Self.Path := Path;
  Self.UUId := UUId;
end;

function HFile_TCryptoRepository_v1.TRepositoryIndexRecord_Paths.GetPathFL: string;
begin
  Result := HFile_FixPath(Path);
  Result := LowerCase(Path);
end;

function HFile_TCryptoRepository_v1.TRepositoryIndexRecord_Paths.ToBytes: TBytesArray;
var Len: Integer;
    Buffer: TBytesArray;
    Compact: HFile_TCompactNumber_Unsigned;
begin
  Result.ReLength(0);
  Buffer := Path.ToBytes;
  Len := Buffer.Size;
  Compact.Content := Int64(Len);
  Result.Append(Compact.GetBytes);
  Result.Append(Buffer);
  Compact.Content := UUId;
  Result.Append(Compact.GetBytes);
end;

{ HFile_TCryptoRepository_v1.TRepositoryIndex }

function HFile_TCryptoRepository_v1.TRepositoryIndex.AddPath(const Name: String): Int64;
var Index: Int64;
    Path: TRepositoryIndexRecord_Paths;
begin
  Result := ResolvePathName(Name);
  if Result < 0 then begin
    NextId;
    Index := UUId;
    Path := HFile_TCryptoRepository_v1.TRepositoryIndexRecord_Paths.Create(Name, Index);
    Result := IndexHeader.Add(Path);
  end;
end;

function HFile_TCryptoRepository_v1.TRepositoryIndex.AddPath(const Id: UInt64; const Name: String = ''): Int64;
var Index: Int64;
    Path: TRepositoryIndexRecord_Paths;
begin
  Result := ResolvePathId(Id);
  if Result < 0 then
    Result := ResolvePathName(Name);
  if Result < 0 then begin
    NextId;
    Index := UUId;
    Path := HFile_TCryptoRepository_v1.TRepositoryIndexRecord_Paths.Create(Name, Index);
    Result := IndexHeader.Add(Path);
  end;
end;

{ Useless procedure }
procedure HFile_TCryptoRepository_v1.TRepositoryIndex.AssignToPosition(Path: TRepositoryIndexRecord_Paths; const Position: Int64);
begin
  if Position in [0 .. IndexHeader.Capacity - 1] then
    IndexHeader[Position] := Path
  else begin
    IndexHeader.Capacity := Position + 1;
    IndexHeader[Position] := Path;
  end;
end;

constructor HFile_TCryptoRepository_v1.TRepositoryIndex.Create(Stream: TStream);
begin
  inherited Create;
  Self.Stream := Stream;
  IndexHeader := HFile_TCryptoRepository_v1.TRepositoryIndexRecord_PathsList.Create;
end;

destructor HFile_TCryptoRepository_v1.TRepositoryIndex.Destroy;
begin
  IndexHeader.Free;
  inherited;
end;

procedure HFile_TCryptoRepository_v1.TRepositoryIndex.NextId;
begin
  while ResolvePathId(UUId) <> -1 do
    UUId := UUId + 1;
end;

procedure HFile_TCryptoRepository_v1.TRepositoryIndex.Read;
var CompactReader: HFile_TCompactNumberReader;
    Count, i, Len: Int64;
begin
  CompactReader.FileStream := Stream;
  Count := CompactReader.ReadUnsigned.Content;
  IndexHeader.Clear;
  for i := 0 to Count - 1 do begin
    Len := CompactReader.ReadUnsigned.Content;
    IndexHeader.Add(HFile_TCryptoRepository_v1.TRepositoryIndexRecord_Paths.Create(TBytesArray.ReadFromStream(Stream, Len)));
  end;
end;


function HFile_TCryptoRepository_v1.TRepositoryIndex.ResolvePathId(const Id: UInt64): Int64;
var i: Integer;
begin
  Result := -1;
  for i := 0 to IndexHeader.Count - 1 do begin
    if IndexHeader[i].UUId = Id then begin
      Result := i;
      Break;
    end;
  end;
end;

function HFile_TCryptoRepository_v1.TRepositoryIndex.ResolvePathName(const Name: string): Int64;
var Copied: String;
    i: Integer;
begin
  Copied := HFile_FixPath(Name);
  Copied := LowerCase(Copied);
  Result := -1;
  for i := 0 to IndexHeader.Count - 1 do begin
    if Copied = IndexHeader[i].PathFixedLowered then begin
      Result := i;
      Break;
    end;
  end;
end;

function HFile_TCryptoRepository_v1.TRepositoryIndex.ToBytes: TBytesArray;
var Buffer: TBytesArray;
    CompactTransformer: HFile_TCompactNumber_Unsigned;
    i: Integer;
begin
  Result.ReLength(0);
  for i := 0 to IndexHeader.Count - 1 do begin
    Buffer := IndexHeader[i].ToBytes;
    CompactTransformer.Content := Buffer.Size;
    Result.Append(CompactTransformer.GetBytes);
    Result.Append(Buffer);
  end;
end;

procedure HFile_TCryptoRepository_v1.TRepositoryIndex.Write;
var CompactWriter: HFile_TCompactNumberReader;
    Number: HFile_TCompactNumber_Unsigned;
    Count: Int64;
begin
  Count := IndexHeader.Count;
  CompactWriter.FileStream := Stream;
  Number.Content := Count;
//  CompactWriter.GetBytes.WriteToStream(Stream);
  CompactWriter.WriteUnsigned(Number);
  ToBytes.WriteToStream(Stream);
end;

{ HFile_TCryptoRepository_v1.TFileHeader }

constructor HFile_TCryptoRepository_v1.TFileHeader.Create(Parent: HFile_TCryptoRepository_v1; const Name: String; const Path, Size: UInt64);
begin
  if Parent.RepositoryIndex.ResolvePathId(Path) < 0 then
    raise Exception.Create('Unable attach file to unknown path.');
  Self.Name := Name;
  Self.Path := Path;
  Self.PathResolved := Parent.RepositoryIndex.IndexHeader[Parent.RepositoryIndex.ResolvePathId(Path)].Path;
  Self.Size := Size;
end;

constructor HFile_TCryptoRepository_v1.TFileHeader.Create(Parent: HFile_TCryptoRepository_v1; const Path: String; const Size: UInt64);
begin
  Self.Parent := Parent;
  Self.Name := ExtractFileName(Path);
  Self.PathResolved := ExtractFilePath(Path);
  Parent.RepositoryIndex.AddPath(PathResolved);
  Self.Size := Size;
end;

constructor HFile_TCryptoRepository_v1.TFileHeader.Create(Parent: HFile_TCryptoRepository_v1; const Bytes: TBytesArray);
begin
  Self.Parent := Parent;
  FromBytes(Bytes);
end;

procedure HFile_TCryptoRepository_v1.TFileHeader.FromBytes(const Bytes: TBytesArray);
var MemStr: TMemoryStream;
    CompactNumberReader: HFile_TCompactNumberReader;
    StringReader: HFile_TStringReader;
begin
  MemStr := Bytes.ToMemoryStream;
  CompactNumberReader.Stream := MemStr;
  StringReader.Stream := MemStr;
  { Reading }
  Name := StringReader.ReadString;
  Path := CompactNumberReader.ReadUnsigned.Content;
  if Parent.RepositoryIndex.ResolvePathId(Path) < 0 then
    raise Exception.Create('Cannot attach file to unknown path.');
  PathResolved := Parent.RepositoryIndex.IndexHeader[Parent.RepositoryIndex.ResolvePathId(Path)].Path;
  Size := CompactNumberReader.ReadUnsigned.Content;

  MemStr.Free;
end;

function HFile_TCryptoRepository_v1.TFileHeader.ToBytes: TBytesArray;
var CompactNumberReader: HFile_TCompactNumberReader;
    StringReader: HFile_TStringReader;
    MemStr: TMemoryStream;
begin
  MemStr := TMemoryStream.Create;
  StringReader.FileStream := MemStr;
  CompactNumberReader.FileStream := MemStr;
  { Writing custom data }
  StringReader.WriteString(Name);
  CompactNumberReader.WriteUnsigned(Path);
  CompactNumberReader.WriteUnsigned(Size);
  Result := TBytesArray.FromMemoryStream(MemStr);

  MemStr.Free;
end;

{ HFile_TCryptoRepository_v1.TFile }

destructor HFile_TCryptoRepository_v1.TFile.Destroy;
begin
  Header.Free;
  if Assigned(FileStream) then
    FileStream.Free;
  inherited;
end;

procedure HFile_TCryptoRepository_v1.TFile.Read;
var Size: UInt64;
    NumberReader: HFile_TCompactNumberReader;
    Buffer: TBytesArray;
begin
  NumberReader.Stream := Self.Stream;
  { Size of header }
  Size := NumberReader.ReadUnsigned.Content;
  Buffer := TBytesArray.ReadFromStream(Stream, Size);
  if Assigned(Header) then
    Header.Free;
  HeaderPosition := Stream.Position;
  Header.ParentFile := Self;
  Header := TFileHeader.Create(Parent, Buffer);
  FilePosition := Stream.Position;
  { Create Linked stream to FilePosition in Repository. }
  { Do not be scared, it is just a convinient solve of the problem }
  FileStream := HCommon_TLinkedStream.Create(Stream, FilePosition);
  FileStream.Size := Size;
end;

procedure HFile_TCryptoRepository_v1.TFile.Write;
var Buffer: TBytesArray;
    NumberReader: HFile_TCompactNumberReader;
begin
  if Parent.RepositoryIndex.ResolvePathId(Header.Path) < 0 then
    { Directory has been lost. We do not need to write this file. }
    Exit;
  Buffer := Header.ToBytes;
  NumberReader.Stream := Self.Stream;
  NumberReader.WriteUnsigned(Buffer.Size);
  Buffer.WriteToStream(Stream);
  { Writing all this shi... file! }
  FileStream.Position := 0;
  FileStream.WriteToStream(Stream, FileStream.Size);
end;

{ HFile_TCryptoRepository_v1 }

constructor HFile_TCryptoRepository_v1.Create(const FileName: String);
var FileStream: TFileStream;
begin
  { It will detect if archive is not exist }
  if FileExists(FileName) then begin
    FileStream := TFileStream.Create(FileName, fmOpenReadWrite or fmShareDenyWrite);
    Self.Stream := FileStream;
    CreateToolbox;
    Create(FileStream);
  end
  else begin
    FileStream := TFileStream.Create(FileName, fmCreate or fmShareDenyWrite);
    Self.Stream := FileStream;
    CreateToolbox;
    CreateNew;
  end;
end;

constructor HFile_TCryptoRepository_v1.Create(Stream: TStream);
begin
  Self.Stream := Stream;
  LoadFromStream;
end;

procedure HFile_TCryptoRepository_v1.CreateNew;
var NumbersReader: HFile_TCompactNumberReader;
begin
  NumbersReader.Stream := Stream;

  { Blank settings }
  NumbersReader.WriteSigned(Int64(0)); 
  { Encryption management }
  EncryptionManager.WriteNewSignatureKey;
  EncryptionManager.WriteNewDigest;
  { Header (Index) }
  RepositoryIndex.IndexHeader.Clear;
  RepositoryIndex.IndexHeader.Add(TRepositoryIndexRecord_Paths.Create('\', 0));
  RepositoryIndex.Write;
  { Files }
  Files.Write;
end;

procedure HFile_TCryptoRepository_v1.CreateToolbox;
begin
  EncryptionManager := TEncryptionManager.Create(Stream);
  RepositoryIndex := TRepositoryIndex.Create(Stream);
  Files := TFileList.Create;
  Files.Parent := Self;
  Files.Stream := Stream;
end;

destructor HFile_TCryptoRepository_v1.Destroy;
begin
  EncryptionManager.Free;
  RepositoryIndex.Free;
  Files.Free;
  inherited;
end;

procedure HFile_TCryptoRepository_v1.LoadFromStream;
var NumberReader: HFile_TCompactNumberReader;
begin
  NumberReader.Stream := Stream;
  NumberReader.ReadUnsigned;
  { Encryption Manager }
  EncryptionManager.ReadSignatureKey;
  EncryptionManager.ReadDigest; { Will throw an error, if digest validation failed }
  { Index }
  RepositoryIndex.IndexHeader.Clear;
  RepositoryIndex.Read;
  { Files }
  Files.Read;
end;

procedure HFile_TCryptoRepository_v1.SaveToStream(OutStream: TStream);
var NumberReader: HFile_TCompactNumberReader;
begin
  { It will be hard to implement }
  NumberReader.Stream := OutStream;
  NumberReader.WriteUnsigned(0);
  { Encryption Manager }
  EncryptionManager.Stream := OutStream;
  EncryptionManager.WriteSignatureKey;
  EncryptionManager.WriteDigest;
  { Header }
  RepositoryIndex.Stream := OutStream;
  RepositoryIndex.Write;
  { Files }
  Files.Stream := OutStream;
  Files.Write;
end;

{ HFile_TCryptoRepository_v1.TEncryptionManager }

constructor HFile_TCryptoRepository_v1.TEncryptionManager.Create(Stream: TStream);
begin
  Self.Stream := Stream;
end;

procedure HFile_TCryptoRepository_v1.TEncryptionManager.ReadDigest;
var EncryptedDigest, EDRead: TBytesArray;
    BytesReader: HFile_TBytesReader;
begin
  BytesReader.Stream := Stream;
//  Digest := TBytesArray.ReadFromStream(Stream, DigestSize);
  Digest := BytesReader.ReadBytes;
  EncryptedDigest := HCrypto_CopyBytes(Digest);
  if Encrypted then
    HCrypto_HEncryBIT_v12_Cipher.EncryptBuffer(EncryptedDigest, EncryptionKey);
  EncryptedDigest := HCrypto_HKHA_v1_Hash(EncryptedDigest, SignatureKey, DigestSize, 256);
//  EDRead := TBytesArray.ReadFromStream(Stream, DigestSize);
  EDRead := BytesReader.ReadBytes;
  if not HCrypto_AreEqualBytes(EncryptedDigest, EDRead) then
    raise HFile_EEncryptionManagerException.Create('Digest validation is wrong. Encryption key is not valid.');
end;

procedure HFile_TCryptoRepository_v1.TEncryptionManager.ReadSignatureKey;
var BytesReader: HFile_TBytesReader;
begin
  BytesReader.Stream := Stream;
  SignatureKey := BytesReader.ReadBytes;
end;

procedure HFile_TCryptoRepository_v1.TEncryptionManager.WriteDigest;
var BytesReader: HFile_TBytesReader;
    EncryptedDigest: TBytesArray;
begin
  BytesReader.Stream := Stream;
  EncryptedDigest := HCrypto_CopyBytes(Digest);
  if Encrypted then
    HCrypto_HEncryBIT_v12_Cipher.EncryptBuffer(EncryptedDigest, EncryptionKey);
  EncryptedDigest := HCrypto_HKHA_v1_Hash(EncryptedDigest, SignatureKey, DigestSize, 256);
  BytesReader.WriteBytes(Digest);
  BytesReader.WriteBytes(EncryptedDigest);
end;

procedure HFile_TCryptoRepository_v1.TEncryptionManager.WriteNewDigest;
begin
  Digest := HCrypto_RandomBuffer(DigestSize);
  WriteDigest;
end;

procedure HFile_TCryptoRepository_v1.TEncryptionManager.WriteNewSignatureKey;
begin
  { Note, that Encryption Manager will manage signature key, even if CryptoRepository do not include encryption of data }
  SignatureKey := HCrypto_RandomBuffer(SignatureKeySize); { 256 byte - extremely secure }
  WriteSignatureKey;
end;

procedure HFile_TCryptoRepository_v1.TEncryptionManager.WriteSignatureKey;
var BytesReader: HFile_TBytesReader;
begin
  BytesReader.Stream := Stream;
  BytesReader.WriteBytes(SignatureKey);
end;

{ HFile_TCryptoRepository_v1.TFileList }

constructor HFile_TCryptoRepository_v1.TFileList.Create;
begin
  FFiles := TFileList_Low.Create;
end;

destructor HFile_TCryptoRepository_v1.TFileList.Destroy;
begin
  Files.Free;
  inherited;
end;

function HFile_TCryptoRepository_v1.TFileList.GetFile(const Id: Integer): TFile;
begin
  Result := Files[Id];
end;

procedure HFile_TCryptoRepository_v1.TFileList.Read;
var NumberReader: HFile_TCompactNumberReader;
    i, Count, Index: Integer;
begin
  NumberReader.Stream := Stream;
  Count := NumberReader.ReadUnsigned.Content;
  Files.Clear;
  for i := 1 to Count do begin 
    Index := Files.Add(TFile.Create);
    Files[Index].Stream := Stream;
    Files[Index].Parent := Parent;
    Files[Index].Read;
  end;
end;

procedure HFile_TCryptoRepository_v1.TFileList.SetFile(const Id: Integer; const Value: TFile);
begin
  Files[Id] := Value;
end;

procedure HFile_TCryptoRepository_v1.TFileList.Write;
var NumberReader: HFile_TCompactNumberReader;
    i: Integer;
    TempStream: TStream;
begin
  NumberReader.Stream := Stream;
  NumberReader.WriteUnsigned(Files.Count);
  for i := 0 to Files.Count - 1 do begin 
    TempStream := Files[i].Stream;
    { We may temporary override this Stream }
    Files[i].Stream := Stream;
    Files[i].Write;
    Files[i].Stream := TempStream;
  end;
end;

end.
