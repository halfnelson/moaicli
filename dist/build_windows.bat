cd ..
call rake rawr:clean
call rake rawr:jar
mkdir package\windows
xcopy /S package\jar\*.* package\windows
xcopy /S config package\windows\config\
xcopy /S hosts package\windows\hosts\
xcopy /S templates package\windows\templates\
xcopy /S plugins package\windows\plugins\
xcopy dist\windows\moaicli.bat package\windows\
xcopy /S dist\windows\jre package\windows\jre\
