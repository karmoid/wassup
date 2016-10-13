@echo Off
if "%1"=="" goto help

set dashhost=%1
ruby update_ticker.rb %2 %3 %4 %5 %6 %7 %8 %9
goto fin

:help
echo %0 HostName msg1 msg2 msg3

:fin
