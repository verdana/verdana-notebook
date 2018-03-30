@echo off

echo Deploying updates to GitHub...

REM 编译网站
hugo -t hugo-verdana

REM 进入 public 目录
cd public

REM 添加更改的文件到 Git 仓库
git add .
echo.

REM 如果小时数小于10，在时间前面加上前置 0
set time=%time:~0,5%
if "%time:~0,1%" == " " set time=0%time:~1,5%

git commit -m "Rebuild blog at %date% %time%"
echo.

REM 推送到 Github
git push -u origin master

REM 回到上一层目录
cd ..
