@echo off
tasm\tasm /m3 %1.asm
if errorlevel 1 goto end
tasm\tlink /3 %1
if errorlevel 1 goto end
del %1.obj
%1.exe
:end