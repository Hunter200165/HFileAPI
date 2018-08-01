unit HFileAPI.Path.Commons;

interface

uses
  System.SysUtils,
  System.StrUtils,
  HCommonAPI.Commons;

function HFile_FixPath(const Way: string): string;
function HFile_ToPath(const Way: String): String;
function HFile_ToWay(const Path: string): string;

implementation

function HFile_FixPath(const Way: string): string;
begin
  Result := Way.Replace('/', '\');
  Result := HCommon_Trim(Result, ['\']);
end;

function HFile_ToPath(const Way: String): String;
begin
  Result := HFile_FixPath(Way);
  if Not (Result[Result.Length] = '\') then begin
    Result := Result + '\';
  end;
end;

function HFile_ToWay(const Path: string): string;
begin
  Result := HFile_FixPath(Path);
  if (Result[Result.Length] = '\') then
    Result := Result.Substring(1, Result.Length - 1);
end;

end.
