# ByteOrderMark
An Oracle package to determine the file encoding Byte Order Mark (BOM) of a File or BFile

### Available Functions
```SQL
-- Returns a constant representing the BOM for the BOM raw characters
function ByteOrderMarkKind(pBOMRaw raw) return pls_integer deterministic;

-- Extracts the BOM from a blob source or null if no BOM found
function ByteOrderMarkRaw(pBlob blob) return raw deterministic;

-- Determines the file encoding (BOM Kind) of a bfile
function FileEncoding(pBFile bfile) return pls_integer;

-- Determines the file encoding (BOM Kind) of a file in an Oracle Directory
function FileEncoding(pOracleDir in varchar2
                    , pFilename  in varchar2) return pls_integer;
```

### Example Usage

```SQL
declare
  vOracleDir varchar2(30) := 'PAULZIP_DIR';
  vFilename  varchar2(30) := 'P_ByteOrder.sql';
begin
  if P_ByteOrderMark.FileEncoding(vOracleDir, vFilename) = P_ByteOrderMark.BOM_UTF8 then
    dbms_output.put_line('UTF-8 File detected!');
  end if; 
end;
/

UTF-8 File detected!
```
