@ECHO OFF
SETLOCAL

:: ===================================================================================
:: Fritzing Windows Build Script (Boost 자동 다운로드 버전)
:: ===================================================================================
:: 이 스크립트는 Fritzing 및 관련 라이브러리의 다운로드와 빌드 과정을 자동화합니다.
:: PowerShell을 사용하여 Boost를 자동으로 다운로드하고 압축 해제합니다.
::
:: 사전 요구사항:
:: 1. Visual Studio 2019 또는 2022 ("C++를 사용한 데스크톱 개발" 워크로드 포함)
:: 2. Qt 5.15.2 (MSVC 64-bit 컴포넌트 포함)
:: 3. CMake (설치 시 "Add CMake to PATH" 옵션 선택)
:: 4. Git for Windows
:: ===================================================================================

:: ===================================================================================
:: 사용자 설정 (!!!반드시 자신의 환경에 맞게 수정하세요!!!)
:: ===================================================================================

REM -- 1. 빌드할 최상위 폴더를 지정하세요. 모든 소스 코드가 이 폴더 아래에 생성됩니다.
SET "SOURCE_DIR=C:\Fritzing-source"

REM -- 2. Qt 5.15.2 설치 경로를 지정하세요.
SET "QT_DIR=C:\Qt\5.15.2\msvc2019_64"

REM -- 3. 사용할 Visual Studio 버전에 맞는 CMake 생성기를 지정하세요.
REM    Visual Studio 2019: "Visual Studio 16 2019"
REM    Visual Studio 2022: "Visual Studio 17 2022"
SET "VS_GENERATOR=Visual Studio 16 2019"

REM -- 4. Boost 빌드에 사용할 MSVC 툴셋 버전을 지정하세요.
REM    Visual Studio 2019: msvc-14.2
REM    Visual Studio 2022: msvc-14.3
SET "BOOST_TOOLSET=msvc-14.2"

:: ===================================================================================
:: 스크립트 본문 (수정하지 마세요)
:: ===================================================================================

SET "BOOST_VERSION=1_86_0"
SET "BOOST_URL=https://archives.boost.io/release/1.86.0/source/boost_1_86_0.zip"
SET "BOOST_ZIP_FILE=boost_%BOOST_VERSION%.zip"
SET "BOOST_ROOT=%SOURCE_DIR%\boost_%BOOST_VERSION%"

ECHO.
ECHO ###############################################
ECHO # Fritzing 빌드를 시작합니다.
ECHO # 설정된 경로:
ECHO #  - 소스 폴더: %SOURCE_DIR%
ECHO #  - Qt 경로: %QT_DIR%
ECHO #  - Boost 버전: %BOOST_VERSION% (자동 다운로드)
ECHO ###############################################
ECHO.
PAUSE

:: 디렉터리 생성 및 이동
IF NOT EXIST "%SOURCE_DIR%" (
    MKDIR "%SOURCE_DIR%"
)
cd /d "%SOURCE_DIR%"

:: -------------------------------------------------
:: 1. Boost 라이브러리 다운로드 및 압축 해제
:: -------------------------------------------------
ECHO.
ECHO [1/6] Boost 라이브러리 준비 중...

REM 다운로드
IF EXIST "%BOOST_ZIP_FILE%" (
    ECHO   - Boost zip 파일이 이미 존재합니다. 다운로드를 건너뜁니다.
) ELSE (
    ECHO   - Boost %BOOST_VERSION% 다운로드 중...
    powershell -Command "Invoke-WebRequest -Uri '%BOOST_URL%' -OutFile '%BOOST_ZIP_FILE%'"
    IF ERRORLEVEL 1 GOTO error
)

REM 압축 해제
IF EXIST "%BOOST_ROOT%" (
    ECHO   - Boost 폴더가 이미 존재합니다. 압축 해제를 건너뜁니다.
) ELSE (
    ECHO   - Boost zip 파일 압축 해제 중... (시간이 걸릴 수 있습니다)
    powershell -Command "Expand-Archive -Path '%BOOST_ZIP_FILE%' -DestinationPath '%SOURCE_DIR%'"
    IF ERRORLEVEL 1 GOTO error
)
ECHO.

:: -------------------------------------------------
:: 2. Fritzing 소스 코드 다운로드
:: -------------------------------------------------
ECHO.
ECHO [2/6] Fritzing 소스 코드 다운로드 중...
IF NOT EXIST "%SOURCE_DIR%\fritzing-app" ( git clone https://github.com/fritzing/fritzing-app.git )
IF ERRORLEVEL 1 GOTO error
IF NOT EXIST "%SOURCE_DIR%\fritzing-parts" ( git clone https://github.com/fritzing/fritzing-parts.git )
IF ERRORLEVEL 1 GOTO error
ECHO.

:: -------------------------------------------------
:: 3. Boost 라이브러리 빌드
:: -------------------------------------------------
ECHO.
ECHO [3/6] Boost 라이브러리 빌드 확인 및 실행...
IF EXIST "%BOOST_ROOT%\stage\lib\libboost_filesystem-*.lib" (
    ECHO   - Boost 라이브러리가 이미 빌드된 것으로 보입니다. 건너뜁니다.
) ELSE (
    ECHO   - Boost 빌드를 시작합니다. 시간이 오래 걸릴 수 있습니다...
    cd /d "%BOOST_ROOT%"
    call bootstrap.bat
    IF ERRORLEVEL 1 GOTO error
    call b2.exe --with-filesystem --with-program_options --with-regex --with-serialization --with-system --with-thread address-model=64 toolset=%BOOST_TOOLSET%
    IF ERRORLEVEL 1 GOTO error
)
ECHO.

:: -------------------------------------------------
:: 4. libgit2 라이브러리 빌드
:: -------------------------------------------------
ECHO.
ECHO [4/6] libgit2 라이브러리 빌드 중...
cd /d "%SOURCE_DIR%\fritzing-app"
IF NOT EXIST "libgit2" ( git clone https://github.com/libgit2/libgit2.git )
IF ERRORLEVEL 1 GOTO error
cd libgit2
IF NOT EXIST "build" ( mkdir build )
cd build
cmake .. -G "%VS_GENERATOR%" -A x64 -DBUILD_SHARED_LIBS=ON
IF ERRORLEVEL 1 GOTO error
cmake --build . --config Release
IF ERRORLEVEL 1 GOTO error
ECHO.

:: -------------------------------------------------
:: 5. Fritzing 애플리케이션 빌드
:: -------------------------------------------------
ECHO.
ECHO [5/6] Fritzing 애플리케이션 빌드 중... (시간이 오래 걸립니다)
cd /d "%SOURCE_DIR%\fritzing-app"
IF NOT EXIST "build" ( mkdir build )
cd build
cmake .. -G "%VS_GENERATOR%" -A x64 ^
 -DQt5_DIR="%QT_DIR%/lib/cmake/Qt5" ^
 -DBOOST_ROOT="%BOOST_ROOT%" ^
 -DLibGit2_ROOT="../libgit2/build" ^
 -DPARTS_DIR="../../fritzing-parts"
IF ERRORLEVEL 1 GOTO error
cmake --build . --config Release
IF ERRORLEVEL 1 GOTO error
ECHO.

:: -------------------------------------------------
:: 6. DLL 파일 복사
:: -------------------------------------------------
ECHO.
ECHO [6/6] 실행에 필요한 DLL 파일들 복사 중...
SET "TARGET_DIR=%SOURCE_DIR%\fritzing-app\build\Release"
XCOPY /Y /Q "%QT_DIR%\bin\Qt5Core.dll" "%TARGET_DIR%\"
XCOPY /Y /Q "%QT_DIR%\bin\Qt5Gui.dll" "%TARGET_DIR%\"
XCOPY /Y /Q "%QT_DIR%\bin\Qt5Svg.dll" "%TARGET_DIR%\"
XCOPY /Y /Q "%QT_DIR%\bin\Qt5Widgets.dll" "%TARGET_DIR%\"
XCOPY /Y /Q "%QT_DIR%\bin\Qt5Xml.dll" "%TARGET_DIR%\"
XCOPY /Y /Q "%QT_DIR%\bin\Qt5SerialPort.dll" "%TARGET_DIR%\"
XCOPY /Y /Q "%QT_DIR%\bin\Qt5Network.dll" "%TARGET_DIR%\"
XCOPY /Y /Q "%SOURCE_DIR%\fritzing-app\libgit2\build\Release\git2.dll" "%TARGET_DIR%\"

REM Qt platform plugin 복사
IF NOT EXIST "%TARGET_DIR%\platforms" ( mkdir "%TARGET_DIR%\platforms" )
XCOPY /Y /Q "%QT_DIR%\plugins\platforms\qwindows.dll" "%TARGET_DIR%\platforms\"
ECHO.

:: -------------------------------------------------
:: 완료
:: -------------------------------------------------
ECHO ####################################################################
ECHO # 빌드 성공!
ECHO #
ECHO # Fritzing.exe 실행 파일은 아래 폴더에 있습니다:
ECHO # %TARGET_DIR%
ECHO #
ECHO # Fritzing.exe 를 더블클릭하여 실행하세요.
ECHO ####################################################################
ECHO.
GOTO:EOF

:error
ECHO.
ECHO #############################################################
ECHO #  오류 발생! 스크립트를 중단합니다.
ECHO #
ECHO #  위쪽의 로그 메시지를 확인하여 원인을 파악하세요.
ECHO #  - 경로 설정이 올바른지 확인하세요.
ECHO #  - 사전 요구사항이 모두 설치되었는지 확인하세요.
ECHO #############################################################
ECHO.
EXIT /B 1

ENDLOCAL