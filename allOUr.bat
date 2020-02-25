del c:\Temp\allOUres.txt
for /F "tokens=*" %%A in (C:\Temp\allOUr.txt) do (
echo %%A >> c:\temp\allOUres.txt
dsacls "%%A" >> c:\Temp\allOUres.txt
echo - >> c:\Temp\allOUres.txt
echo ------------------------------------------------------------------------------------------------------- >> c:\Temp\allOUres.txt
echo - >> c:\Temp\allOUres.txt
)