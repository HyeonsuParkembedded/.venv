@ECHO OFF
SETLOCAL ENABLEDELAYEDEXPANSION
TITLE Fritzing Windows One-Shot Builder

:: ================================================================================
:: 0. 사전 점검 - 관리자 권한 & winget 존재 여부
:: ================================================================================
:: 관리자 권한 확인
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
IF NOT "%ERRORLEVEL%"=="0" (
    ECHO [오류] 관리자 권한으로 다시 실행해 주세요.
    PAUSE & EXIT /B 1
)

:: winget 존재 여부
winget --version >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    ECHO [오류] winget(앱 설치 관리자)을 찾을 수 없습니다.^
          Windows 10이면 최신 누적 업데이트 또는 Microsoft Store '앱 설치 관리자'를 먼저 설치해야 합니다.
    PAUSE & EXIT /B 1
)

:: ================================================================================
:: 1. 디렉터리/버전 변수
:: ================================================================================
SET "SOURCE_DIR=C:\Fritzing-source"
SET "BOOST_VERSION=1_86_0"
SET "BOOST_URL=https://archives.boost.io/release/1.86.0/source/boost_1_86_0.zip"
SET "BOOST_ZIP=boost_%BOOST_VERSION%.zip"
SET "BOOST_ROOT=%SOURCE_DIR%\boost_%BOOST_VERSION%"
SET "QT_OFFLINE_URL=https://download.qt.io/official_releases/qt/5.15/5.15.2/qt-opensource-windows-x86_64-5.15.2.exe"
SET "QT_INSTALL_ROOT=C:\Qt"
SET "QT_DIR=%QT_INSTALL_ROOT%\5.15.2\msvc2019_64"

:: ================================================================================
:: 2. 필수 툴 자동 설치 (winget)
:: ================================================================================
CALL :WingetInstall "Microsoft.VisualStudio.2022.BuildTools" "VS Build Tools"
CALL :WingetInstall "Git.Git"                          "Git for Windows"
CALL :WingetInstall "Kitware.CMake"                    "CMake"
CALL :WingetInstall "Microsoft.VisualStudio.Vswhere"   "vswhere"

:: ================================================================================
:: 3. Qt 5.15.2(64-bit, MSVC2019) 자동 설치
::    - winget에 Qt 5.15.2 패키지가 없으므로 오프라인 설치관리자를 내려받아
::      무인 설치(--silent --directory ...) 진행
:: ================================================================================
IF EXIST "%QT_DIR%\bin\Qt5Core.dll" (
    ECHO ▶ Qt 5.15.2 already installed: %QT_DIR%
) ELSE (
    ECHO ▶ Qt 5.15.2 이(가) 설치되어 있지 않습니다. 오프라인 설치관리자를 내려받습니다…
    SET "QT_EXE=%TEMP%\qt5152_offline.exe"
    powershell -Command "Invoke-WebRequest -Uri '%QT_OFFLINE_URL%' -OutFile '%QT_EXE%'"
    IF ERRORLEVEL 1 GOTO Fatal

    REM ── 무인 설치용 임시 config 파일 생성 ────────────────────────────────────────
    SET "QT_CONF=%TEMP%\qt_config.qs"
    >"%QT_CONF%" ECHO function Controller() {}
    >>"%QT_CONF%" ECHO function Component() {}
    >>"%QT_CONF%" ECHO Component.prototype.createOperations = function() {}
    >>"%QT_CONF%" ECHO installer.setInstallationDirectory("%QT_INSTALL_ROOT%");
    >>"%QT_CONF%" ECHO installer.addMetaPath("qt.qt5.5152.win64_msvc2019_64");

    REM ── Qt 무인 설치 실행 ────────────────────────────────────────────────────────
    "%QT_EXE%" --silent --script "%QT_CONF%" || GOTO Fatal
)

:: ================================================================================
:: 4. Visual Studio Generator / Boost Toolset 자동 판별 (vswhere)
:: ================================================================================
FOR /F "usebackq tokens=*" %%V IN (`vswhere -latest -property installationVersion`) DO SET "VS_VER=%%V"
FOR /F "delims=." %%A IN ("%VS_VER%") DO SET "VS_MAJOR=%%A"
IF "%VS_MAJOR%"=="17" (
    SET "VS_GENERATOR=Visual Studio 17 2022"
    SET "BOOST_TOOLSET=msvc-14.3"
) ELSE (
    SET "VS_GENERATOR=Visual Studio 16 2019"
    SET "BOOST_TOOLSET=msvc-14.2"
)

:: ================================================================================
:: 5. 프로젝트 폴더 준비
:: ================================================================================
IF NOT EXIST "%SOURCE_DIR%" MKDIR "%SOURCE_DIR%"
CD /D "%SOURCE_DIR%"

:: ================================================================================
:: 6. Boost 다운로드 + 압축 해제 + 빌드
:: ================================================================================
ECHO.
ECHO [1/6] Boost %BOOST_VERSION% 다운로드 / 압축 해제…
IF NOT EXIST "%BOOST_ZIP%" (
    powershell -Command "Invoke-WebRequest -Uri '%BOOST_URL%' -OutFile '%BOOST_ZIP%'"
    IF ERRORLEVEL 1 GOTO Fatal
)
IF NOT EXIST "%BOOST_ROOT%" (
    powershell -Command "Expand-Archive -Path '%BOOST_ZIP%' -DestinationPath '%SOURCE_DIR%'"
    IF ERRORLEVEL 1 GOTO Fatal
)

ECHO [2/6] Boost 빌드…
CD /D "%BOOST_ROOT%"
IF NOT EXIST "b2.exe" CALL bootstrap.bat
IF NOT EXIST "stage\lib\libboost_filesystem-*.lib" (
    b2.exe --with-filesystem --with-program_options --with-regex --with-serialization --with-system --with-thread ^
    address-model=64 toolset=%BOOST_TOOLSET% || GOTO Fatal
)

:: ================================================================================
:: 7. Fritzing 소스 + libgit2 클론
:: ================================================================================
CD /D "%SOURCE_DIR%"
IF NOT EXIST "fritzing-app"   git clone https://github.com/fritzing/fritzing-app.git || GOTO Fatal
IF NOT EXIST "fritzing-parts" git clone https://github.com/fritzing/fritzing-parts.git || GOTO Fatal
IF NOT EXIST "fritzing-app\libgit2" (
    git clone https://github.com/libgit2/libgit2.git fritzing-app\libgit2 || GOTO Fatal
)

:: ================================================================================
:: 8. libgit2 빌드
:: ================================================================================
ECHO [3/6] libgit2 빌드…
CD /D "%SOURCE_DIR%\fritzing-app\libgit2"
IF NOT EXIST "build" MKDIR build
CD build
cmake .. -G "%VS_GENERATOR%" -A x64 -DBUILD_SHARED_LIBS=ON || GOTO Fatal
cmake --build . --config Release || GOTO Fatal

:: ================================================================================
:: 9. Fritzing 빌드
:: ================================================================================
ECHO [4/6] Fritzing 애플리케이션 빌드…
CD /D "%SOURCE_DIR%\fritzing-app"
IF NOT EXIST "build" MKDIR build
CD build
cmake .. -G "%VS_GENERATOR%" -A x64 ^
 -DQt5_DIR="%QT_DIR%\lib\cmake\Qt5" ^
 -DBOOST_ROOT="%BOOST_ROOT%" ^
 -DLibGit2_ROOT="../libgit2/build" ^
 -DPARTS_DIR="../../fritzing-parts" || GOTO Fatal
cmake --build . --config Release || GOTO Fatal

:: ================================================================================
:: 10. Qt / libgit2 DLL 자동 복사
:: ================================================================================
ECHO [5/6] DLL 복사…
SET "TARGET=%SOURCE_DIR%\fritzing-app\build\Release"
FOR %%D IN (Qt5Core Qt5Gui Qt5Svg Qt5Widgets Qt5Xml Qt5SerialPort Qt5Network) DO (
    COPY /Y "%QT_DIR%\bin\%%D.dll" "%TARGET%" >nul
)
COPY /Y "%SOURCE_DIR%\fritzing-app\libgit2\build\Release\git2.dll" "%TARGET%" >nul
IF NOT EXIST "%TARGET%\platforms" MKDIR "%TARGET%\platforms"
COPY /Y "%QT_DIR%\plugins\platforms\qwindows.dll" "%TARGET%\platforms" >nul

:: ================================================================================
:: 11. 완료
:: ================================================================================
ECHO.
ECHO ###########################################################
ECHO ✅  빌드 완료!  실행 파일: %TARGET%\Fritzing.exe
ECHO     더블클릭하여 Fritzing을 실행해 보세요.
ECHO ###########################################################
PAUSE
GOTO :EOF


:: ================================================================================
::  서브루틴: winget 설치 보조
:: ================================================================================
:WingetInstall <PackageID> <FriendlyName>
REM   %1 = winget ID,  %2 = 표시용 이름
winget list --id %1 >nul 2>&1
IF %ERRORLEVEL% EQU 0 (
    ECHO ▶ %2 이미 설치됨
) ELSE (
    ECHO ▶ %2 설치 중…
    winget install --id %1 -e --silent --accept-package-agreements --accept-source-agreements
    IF %ERRORLEVEL% NEQ 0 (
        ECHO [오류] %2 설치 실패
        PAUSE & EXIT /B 1
    )
)
EXIT /B 0


:: ================================================================================
::  오류 처리
:: ================================================================================
:Fatal
ECHO.
ECHO ❌ 빌드 중 오류가 발생했습니다. 위 로그를 확인하세요.
PAUSE
EXIT /B 1

ENDLOCAL
