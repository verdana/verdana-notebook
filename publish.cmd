@echo off

echo Deploying updates to GitHub...

REM 编译网站
hugo -t hugo-verdana

REM 进入 public 目录
cd public

REM 添加更改的文件到 Git 仓库
git add .
echo.

git commit -m "Rebuild blog at %date% %time:~0,5%"
echo.

REM 推送到 Github
git push -u origin master
echo.

REM 回到上一层目录
cd ..
