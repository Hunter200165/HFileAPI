unit HFileAPI.EncryptedFileStream;

interface

uses
  HFileAPI.FileStream,
  HCommonAPI.Intercept,
  HCryptoAPI.Types,
  HCryptoAPI.Commons,
  HCryptoAPI.Cipher.LEncryBIT_v2;

type
  HFile_TEncryptionIntercept = class(HCommon_TInterceptObject)
  private
    FParentStream: HFile_TFileStream;
    FEncryptionEngine: HCrypto_TLEncryBITv2;
  public
    property ParentStream: HFile_TFileStream read FParentStream write FParentStream;
    property EncryptionEngine: HCrypto_TLEncryBITv2 read FEncryptionEngine write FEncryptionEngine;

    procedure EncryptionProc_Encrypt(var Buffer: TBytesArray; Sender: TObject);
    procedure EncryptionProc_Decrypt(var Buffer: TBytesArray; Sender: TObject);

    constructor Create(Stream: HFile_TFileStream);
    destructor Destroy; override;
  end;

type
  HFile_TEncryptedFileStream = class(HFile_TFileStream)
  private
    FEncryptionIntercept: HFile_TEncryptionIntercept;
  public
    property EncryptionIntercept: HFile_TEncryptionIntercept read FEncryptionIntercept write FEncryptionIntercept;
    constructor Create(const FileName: String; const Mode: Word);
    destructor Destroy; override;
  end;

implementation

{ HFile_EncryptionIntercept }

constructor HFile_TEncryptionIntercept.Create(Stream: HFile_TFileStream);
begin
  inherited Create;
  ParentStream := Stream;
  EncryptionEngine := HCrypto_TLEncryBITv2.Create;
  Self.OnRead := EncryptionProc_Decrypt;
  Self.OnWrite := EncryptionProc_Encrypt;
end;

destructor HFile_TEncryptionIntercept.Destroy;
begin
  EncryptionEngine.Free;
  inherited;
end;

procedure HFile_TEncryptionIntercept.EncryptionProc_Decrypt(var Buffer: TBytesArray; Sender: TObject);
begin
  { I hope it will be enough fast for big Buffer }
  EncryptionEngine.Position := ParentStream.Position - Buffer.Size;
  EncryptionEngine.DecryptBuffer(Buffer);
end;

procedure HFile_TEncryptionIntercept.EncryptionProc_Encrypt(var Buffer: TBytesArray; Sender: TObject);
begin
  { I hope it will be enough fast for big Buffer }
  EncryptionEngine.Position := ParentStream.Position;
  EncryptionEngine.EncryptBuffer(Buffer);
end;

{ HFile_TEncryptedFileStream }

constructor HFile_TEncryptedFileStream.Create(const FileName: String; const Mode: Word);
begin
  inherited;
  EncryptionIntercept := HFile_TEncryptionIntercept.Create(Self);
  Intercept := EncryptionIntercept;
end;

destructor HFile_TEncryptedFileStream.Destroy;
begin
  { You do not need to dispose Intercept, as it will be disposed in Parent class }
  inherited;
end;

end.
