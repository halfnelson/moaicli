@echo off
set JAVA_EXE=%~dp0\jre\bin\java.exe
if not exist %JAVA_EXE% set JAVA_EXE=java
%JAVA_EXE% -d32 -jar %~dp0\moaicli.jar %*
