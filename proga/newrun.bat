@echo off
tasm\tasm /zd /zi %1.asm
if errorlevel 1 goto end
tasm\tlink /t /x %1.obj
if errorlevel 1 goto end
del %1.obj
%1.exe
:end