@echo off
set PATH=C:\digitals\RailsInstaller\Ruby2.1.0\lib\ruby\gems\1.9.1\bin;C:\digitals\RailsInstaller\DevKit\bin;%PATH%
cd c:\sites\wassup
echo %PATH% >> log.log
call security\identity.cmd
echo %nname% >> log.log
call dashing start >> log.log

