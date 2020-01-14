@echo off
echo.
echo.                                         MANUTENCAO PREVENTIVA
echo                                          Escolha uma das opcoes:
echo.
echo.
:menu
time /t
date /t
echo                                   ************************************************
echo                                   *  [1] ALTERACAO DE NOME E DOMINIO             *
echo                                   *  [2] MOSTRAR NUMERO SERIE                    *
echo                                   *  [3] OCULTAR SERVICOS MICROSOFT              *
echo                                   *  [4] LIMPAR ARQUIVOS TEMORARIOS              *					
echo                                   *  [5] APAGAR USUARIOS(DEIXAR USUARIO RECENTE) *	
echo                                   *  [6] REMOVER PROGRAMAS NAO PERTINENTES       *
echo                                   *  [7] GERENCIADOR DE TAREFAS                  *
echo                                   *  [8] ICONE PEQUENO                           *
echo                                   *  [9] LIMPEZA DE DISCO                        *
echo                                   *  [10] SALVE BLOCK (DESKTOP)                  *           
echo                                   *  [13] CHECK DISK                             *
echo                                   *  [14] DELETE PROFILE LIST(TEMP)              * 
echo                                   *  [15] REINICIAR                              *
echo                                   *  [16] CANCELAR E SAIR                        *
echo                                   ************************************************
echo.
echo.
echo.
set /p opcao=
if "%opcao%"== "1" goto op1
if "%opcao%"== "2" goto op2
if "%opcao%"== "3" goto op3
if "%opcao%"== "4" goto op4
if "%opcao%"== "5" goto op5
if "%opcao%"== "6" goto op6
if "%opcao%"== "7" goto op7
if "%opcao%"== "8" goto op8
if "%opcao%"== "9" goto op9
if "%opcao%"== "10" goto op10
if "%opcao%"== "13" goto op13
if "%opcao%"== "14" goto op14
if "%opcao%"== "15" goto op15
if "%opcao%"== "16" goto op16

:op1
sysdm.cpl
cls
goto menu


:op2
wmic bios get serialnumber
pause
cls
goto menu


:op3
msconfig.exe
cls
goto menu


:op4
@echo off
start C:\\Windows\Prefetch
start C:\Users\%username%\AppData\Local\Temp
start C:\Users\%username%\Recent
cls
goto menu


:op5
explorer C:\Users
cls
goto menu


:op6
appwiz.cpl
cls
goto menu


:op7
taskmgr
pause
cls
goto menu



:op8
REG ADD "HKCU\SOFTWARE\Microsoft\Windows\Shell\Bags\1\Desktop" /V IconSize /T REG_DWORD /D 30 /F
REG ADD "HKCU\SOFTWARE\Microsoft\Windows\Shell\Bags\1\Desktop" /V Mode /T REG_DWORD /D 1 /F
REG ADD "HKCU\SOFTWARE\Microsoft\Windows\Shell\Bags\1\Desktop" /V LogicalViewMode /T REG_DWORD /D 3 /F
taskkill /f /im explorer.exe
start explorer.exe
pause
cls
goto menu



:op9
Cleanmgr
cls
goto menu


:op10
Echo Y| cacls %userprofile%\desktop /P %username%:R
pause
cls
goto menu



:op13
chkdsk c:
pause
cls
goto menu


:op14
Start regedit
Start explorer "Especificar arquivos com os camiho do Regedit para Facilitar para o Tecnico"
cls
goto menu

:op15
shutdown /r
cls
goto menu


:op16
EXIT
cls
goto menu


:goto menu 

echo.
echo.
echo.
echo.
echo Pressione qualquer tecla para continuar...
pause >null