create or replace package P_ByteOrderMark is

-- By paulzip 12/05/2021

-- Byte order mark kind constants
BOM_NONE     constant pls_integer := 0; -- No BOM / Unknown
BOM_UTF8     constant pls_integer := 1; -- UTF 8
BOM_UTF16_BE constant pls_integer := 2; -- UTF 16 Big Endian
BOM_UTF16_LE constant pls_integer := 3; -- UTF 16 Little Endian
BOM_UTF32_BE constant pls_integer := 4; -- UTF 32 Big Endian
BOM_UTF32_LE constant pls_integer := 5; -- UTF 32 Little Endian

-- Byte order mark raw constants
RAW_BOM_UTF8     constant raw(3) := hextoraw('EFBBBF');
RAW_BOM_UTF16_BE constant raw(2) := hextoraw('FEFF');
RAW_BOM_UTF16_LE constant raw(2) := hextoraw('FFFE');
RAW_BOM_UTF32_BE constant raw(3) := hextoraw('00FEFF');
RAW_BOM_UTF32_LE constant raw(3) := hextoraw('FFFE00');

function ByteOrderMarkKind(pBOMRaw raw) return pls_integer deterministic;
function ByteOrderMarkRaw(pBlob blob) return raw deterministic;
function FileEncoding(pBFile bfile) return pls_integer;
function FileEncoding(pOracleDir in varchar2
                    , pFilename  in varchar2) return pls_integer;

end;
/

create or replace package body P_ByteOrderMark is

MAX_BOM_LEN constant integer := 3;

function ByteOrderMarkKind(pBOMRaw raw) return pls_integer deterministic is
-- Returns the Byte Order Kind from the BOM raw bytes
begin
  return case pBOMRaw
           when RAW_BOM_UTF8     then BOM_UTF8
           when RAW_BOM_UTF16_BE then BOM_UTF16_BE
           when RAW_BOM_UTF16_LE then BOM_UTF16_LE
           when RAW_BOM_UTF32_BE then BOM_UTF32_BE
           when RAW_BOM_UTF32_LE then BOM_UTF32_LE
           else BOM_NONE
         end;
end;

function ByteOrderMarkRaw(pBlob blob) return raw deterministic is
/* Extracts the ByteOrderMark (BOM) raw contents from a blob.  BOMs tell file
   consumers what type of character set is encoded in a binary file */
  vBom raw(3);
  vResult raw(3);
begin
  vBom := dbms_lob.substr(pBlob, MAX_BOM_LEN);
  if nvl(dbms_lob.getlength(vBom), 0) > 0 then  -- if not null or empty lob
    if vBom in (RAW_BOM_UTF8, RAW_BOM_UTF32_BE, RAW_BOM_UTF32_LE) then
      vResult := vBom;
    else
      vBom := utl_raw.substr(vBom, 1, 2);
      if vBom in (RAW_BOM_UTF16_LE, RAW_BOM_UTF16_BE) then
        vResult := vBom;
      end if;
    end if;
  end if;
  return vResult;
end;

function FileEncoding(pBFile bfile) return pls_integer is
-- Determines the file encoding (BOM Kind) of a bfile
  vBlob       blob;
  vDestOffset integer := 1;
  vSrcOffset  integer := 1;
  vResult     pls_integer;
begin
  dbms_lob.createtemporary(vBlob, false);
  dbms_lob.loadblobfromfile(
    dest_lob    => vBlob
  , src_bfile   => pBFile
  , amount      => MAX_BOM_LEN
  , dest_offset => vDestOffset
  , src_offset  => vSrcOffset
  );
  vResult := ByteOrderMarkKind(ByteOrderMarkRaw(vBlob));
  dbms_lob.freetemporary(vBlob);
  return vResult;
end;

function FileEncoding(pOracleDir in varchar2
                    , pFilename  in varchar2) return pls_integer is
-- Determines the file encoding (BOM Kind) of a file in an Oracle Directory
  vBFile  bfile := bfilename(pOracleDir, pFilename);
  vResult pls_integer;
begin
  dbms_lob.open(vBFile, dbms_lob.lob_readonly);
  begin
    vResult := FileEncoding(vBFile);
    dbms_lob.close(vBFile);
  exception
    when OTHERS then
      if dbms_lob.isopen(vBFile) = 1 then
        dbms_lob.close(vBFile);
      end if;
      raise;
  end;
  return vResult;
end;

end;
/

