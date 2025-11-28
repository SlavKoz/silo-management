@echo off
REM Quick launcher for main Silo app with Placements browser integrated
echo Starting Silo App...
"C:\Users\slawomirkozielec\AppData\Local\Programs\R\R-4.5.1\bin\Rscript.exe" -e "shiny::runApp(port=6789, launch.browser=TRUE)"
