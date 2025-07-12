# Fritzing Windows 자동 빌드 스크립트

Windows 환경에서 Fritzing과 관련 라이브러리(Boost, libgit2 등)를 **자동으로** 다운로드·설치·빌드해 주는 배치 스크립트입니다.

## 🔍 개요
- `Fritzing-fast-install.bat` 하나로 Fritzing 소스 클론, Boost 다운로드·빌드, libgit2 빌드, Fritzing 애플리케이션 빌드를 순차적으로 수행  
- Qt DLL, libgit2 DLL 등 실행에 필요한 모든 파일을 자동 복사

## 📋 사전 요구사항
1. **운영체제**: Windows 10 이상  
2. **Visual Studio**: 2019 또는 2022  
   - “C++를 사용한 데스크톱 개발” 워크로드 포함  
3. **Qt**: 5.15.2 (MSVC 64-bit 컴포넌트 포함)  
4. **CMake**: 설치 시 “Add CMake to PATH” 옵션 선택  
5. **Git for Windows**  
6. **PowerShell**(Windows 기본 제공)  

## ⚙️ 사용자 설정
스크립트 상단의 설정 부분을 **본인 환경에 맞게** 수정하세요.

```bat
REM 1. 소스 코드가 생성될 최상위 폴더
SET "SOURCE_DIR=C:\Fritzing-source"

REM 2. Qt 5.15.2 설치 경로
SET "QT_DIR=C:\Qt\5.15.2\msvc2019_64"

REM 3. CMake용 Visual Studio 생성기
SET "VS_GENERATOR=Visual Studio 16 2019"  REM 또는 "Visual Studio 17 2022"

REM 4. Boost 빌드 툴셋 (msvc-14.2 또는 msvc-14.3)
SET "BOOST_TOOLSET=msvc-14.2"
```

## 🚀 사용 방법

1. 이 저장소를 클론하거나 ZIP으로 내려받습니다.
2. `Fritzing-fast-install.bat` 파일을 **관리자 권한**으로 실행합니다.
3. 화면에 표시되는 메시지에 따라 잠시 대기하면,
4. 최종 완성된 `Fritzing.exe`는

   ```
   %SOURCE_DIR%\fritzing-app\build\Release\Fritzing.exe
   ```

   위치에서 확인할 수 있습니다.

## 🛠️ 빌드 단계

1. Boost 라이브러리 다운로드 및 압축 해제
2. Fritzing 소스(clone): `fritzing-app`, `fritzing-parts`
3. Boost 라이브러리 빌드 (`b2.exe`)
4. libgit2 라이브러리 빌드 (CMake → build)
5. Fritzing 애플리케이션 빌드 (CMake → build)
6. Qt 및 libgit2 DLL 파일 자동 복사

## ❗ 문제 해결

* **경로 설정 오류**: `SOURCE_DIR`, `QT_DIR` 값을 정확히 입력했는지 확인
* **사전 요구사항 미설치**: Visual Studio, Qt, CMake, Git 설치 여부 확인
* **권한 문제**: 관리자 권한으로 다시 실행

## 📄 라이선스

MIT License

## 🤝 기여하기

버그 제보·기능 제안은 GitHub [Issues](https://github.com/HyeonsuParkembedded/Fritzing-fast-install/issues)로 언제든 환영합니다.

---

> **작성자**: 박현수 (Hyeonsu Park)
> **GitHub**: [@HyeonsuParkembedded](https://github.com/HyeonsuParkembedded)

```
::contentReference[oaicite:0]{index=0}
```
