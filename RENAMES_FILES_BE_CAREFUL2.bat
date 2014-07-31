@echo off
Setlocal enabledelayedexpansion

Set "Pattern=LSMod"
Set "Replace=MYMODNAME"

For %%a in (*.*) Do (
    Set "File=%%~a"
    Ren "%%a" "!File:%Pattern%=%Replace%!"
)

Pause&Exit