@echo off
REM Script to push Windows Setup documentation to your forked repository

echo ========================================
echo  Push Windows Setup Documentation
echo ========================================
echo.

REM Check if this is a git repo
git rev-parse --git-dir >nul 2>&1
if errorlevel 1 (
    echo Initializing git repository...
    git init
    
    echo.
    echo Enter YOUR GitHub username:
    set /p GITHUB_USER=Username: 
    
    echo.
    echo Adding remote to YOUR forked repository...
    git remote add origin https://github.com/%GITHUB_USER%/a-little-somethin-somethin-midnight-bot-fetch-mine.git
    
    echo.
    echo Fetching from remote...
    git fetch origin
    
    echo.
    echo Setting up branch...
    git branch -M main
    git branch --set-upstream-to=origin/main main
    git pull origin main --allow-unrelated-histories
)

echo.
echo Configuring git user (if not already configured)...
git config user.name >nul 2>&1
if errorlevel 1 (
    set /p GIT_NAME=Enter your name: 
    git config user.name "%GIT_NAME%"
)

git config user.email >nul 2>&1
if errorlevel 1 (
    set /p GIT_EMAIL=Enter your email: 
    git config user.email "%GIT_EMAIL%"
)

echo.
echo Adding Windows Setup documentation...
git add WINDOWS_SETUP_AND_TROUBLESHOOTING.md

echo.
echo Committing changes...
git commit -m "Add comprehensive Windows setup and troubleshooting guide

- Complete installation instructions for Windows 10/11
- Hash server connection troubleshooting
- CPU core optimization (worker threads configuration)
- Performance benchmarks and verification steps
- Service management commands
- Common issues and solutions with detailed diagnostics
- Tested on AMD Ryzen AI 9 HX 370 (24 cores)"

echo.
echo Pushing to your forked repository...
git push origin main

echo.
echo ========================================
echo  Done!
echo ========================================
echo.
echo Next steps:
echo 1. Go to your forked repository on GitHub
echo 2. Click "Pull Request" button
echo 3. Create PR to the original repository
echo 4. Describe the changes (Windows setup guide)
echo.
pause
