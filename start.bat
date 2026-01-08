@echo off
echo Make sure to start docker
pause
wsl bash -c "cd ~/toolkit && bin/up"
start http://localhost/launchpad
pause
