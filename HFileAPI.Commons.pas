unit HFileAPI.Commons;

interface

uses
  System.Classes,
  System.SysUtils,
  HCryptoAPI.Types;

function HFile_InsertToStream(Stream: TStream; const Bytes: TBytesArray; const From: Int64; const ChunkSize: Integer = 65536): Int64;
procedure HFile_RevokeFromStream(Stream: TStream; const From: Int64; const Count: Int64; const ChunkSize: Integer = 65536);

implementation

function HFile_InsertToStream(Stream: TStream; const Bytes: TBytesArray; const From: Int64; const ChunkSize: Integer = 65536): Int64;
var Len: Integer;
    Position, SSize, Offset, MPos, i, Chunks, Remain: Int64;
    Buffer: TBytesArray;
begin
  Len := Length(Bytes);
  Result := Len;
  SSize := Stream.Size;
  MPos := Stream.Position;
  with Stream do
    Size := SSize + Len;
  Stream.Position := From;
  Offset := SSize - From;
  if Offset < 0 then
    raise EArgumentException.Create('Invalid offset is provided.');
  Chunks := Offset div ChunkSize;
  Remain := Offset mod ChunkSize;
  SetLength(Buffer, ChunkSize);
  for i := 1 to Chunks do begin
    Position := SSize - i * ChunkSize;
    Stream.Position := Position;
    Stream.ReadBuffer(Buffer[0], ChunkSize);
//    with Stream do
    Stream.Position := Position + Len;
    Stream.WriteBuffer(Buffer[0], ChunkSize);
  end;
  if Remain > 0 then begin
    SetLength(Buffer, Remain);
    Position := SSize - ChunkSize * Chunks - Remain;
    Stream.Position := Position;
    Stream.ReadBuffer(Buffer[0], Remain);
    Stream.Position := Position + Len;
    Stream.WriteBuffer(Buffer[0], Remain);
  end;
  Stream.Position := From;
  Stream.WriteBuffer(Bytes[0], Len);
  Stream.Position := MPos;
end;

procedure HFile_RevokeFromStream(Stream: TStream; const From: Int64; const Count: Int64; const ChunkSize: Integer = 65536);
var Position, Offset, SSize, MPos, i, Chunks, Remain, Len: Int64;
    Buffer: TBytesArray;
begin
  MPos := Stream.Position;
  SSize := Stream.Size;
  Len := SSize - Count;
  if Len < 0 then
    raise EArgumentException.Create('Invalid Length is provided.');
  Offset := From + Count;
  Stream.Position := Offset;
  Chunks := Len div ChunkSize;
  Remain := Len mod ChunkSize;
  SetLength(Buffer, ChunkSize);
  for i := 1 to Chunks do begin
    Position := Offset + (i - 1) * ChunkSize;
    Stream.Position := Position;
    Stream.ReadBuffer(Buffer[0], ChunkSize);
    Stream.Position := Position - Count;
    Stream.WriteBuffer(Buffer[0], ChunkSize);
  end;
  if Remain > 0 then begin
    SetLength(Buffer, Remain);
    Position := Offset + Chunks * ChunkSize;
    Stream.Position := Position;
    Stream.ReadBuffer(Buffer[0], Remain);
    Stream.Position := Position - Count;
    Stream.WriteBuffer(Buffer[0], Remain);
  end;
  Stream.Size := SSize - Count;
  Stream.Position := MPos - Count;
end;

end.
