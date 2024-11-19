cas -tRV9E -l main.asm -o .\build\main.o
@if %ERRORLEVEL% NEQ 0 goto end
move .\main.lst .\build\main.lst
cln  .\build\main.o -o .\build\main.bin -m .\build\main.map
copy .\build\main.lst ..\SIM
copy .\build\main.bin ..\SIM
:end