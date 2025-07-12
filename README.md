# 🛠️ Fritzing Windows **One-Shot** Builder

**`Fritzing-fast-install.bat`** 하나로 “순정 Windows 10/11” PC에서도  
필요한 모든 툴 → 소스 다운로드 → 의존 라이브러리 → 빌드 → 실행 DLL 패키징까지 **완전 자동**으로 설치 됩니다.

> ⚠️ **필수**  
> 1. **관리자 권한**으로 실행 (우클릭 → “관리자 권한으로 실행”)  
> 2. **Winget**(앱 설치 관리자) 사용 가능해야 함  
>    - Windows 11 은 기본 내장  
>    - Windows 10 은 최신 누적 업데이트 + Microsoft Store에서 “앱 설치 관리자” 설치

---

## 🔍 무엇을 자동으로 해 주나요?

| 단계 | 자동 수행 항목 | 비고 |
|------|----------------|------|
| 1 | **VS Build Tools 2022** | C++ 컴파일러, MSBuild 등 |
| 2 | **Git for Windows** | 소스 클론용 |
| 3 | **CMake** & **vswhere** | 빌드시스템 & VS 감지 |
| 4 | **Qt 5.15.2**(MSVC 64-bit) | 오프라인 설치관리자 + 무인 설치 |
| 5 | **Boost 1.86.0** | ZIP 다운로드 → 압축 → 빌드 |
| 6 | **Fritzing** 소스 & **libgit2** | Git clone |
| 7 | libgit2 → Fritzing 본체 | CMake + MSVC 빌드 |
| 8 | **Qt & libgit2 DLL** | `Fritzing.exe`와 같은 폴더로 복사 |

완료 후엔 `C:\Fritzing-source\fritzing-app\build\Release\Fritzing.exe` 하나만 더블클릭하면 바로 실행됩니다—추가 설치 불필요!  

---

## 🚀 퀵 스타트

```powershell
git clone https://github.com/HyeonsuParkembedded/Fritzing-fast-install.git
cd Fritzing-fast-install
# ❶ 우클릭 → "관리자 권한으로 실행" 으로 bat 파일을 실행하거나
# ❷ PowerShell(Admin) 창에서:
.\Fritzing-fast-install.bat
```

* **디스크** : 최소 10 GB 여유 공간
* **네트워크** : 6 \~ 8 GB 다운로드 (Qt ≈ 1.9 GB, VS Build Tools ≈ 4 GB 등)
* **소요 시간** : 인터넷 속도 & PC 성능에 따라 30 \~ 90 분

> 완료 메시지가 뜨면 `Fritzing.exe`가 있는 **Release** 폴더를 다른 PC로 복사해도 그대로 실행됩니다.

---

## 📂 디렉터리 구조

```
C:\
 └─ Fritzing-source
    ├─ boost_1_86_0           ← Boost 빌드 아웃풋
    ├─ fritzing-app
    │   ├─ build\Release      ← Fritzing.exe + DLL
    │   └─ libgit2\build
    └─ fritzing-parts         ← 부품 라이브러리
```

---

## ❗ 자주 묻는 질문

| Q                            | A                                                                   |
| ---------------------------- | ------------------------------------------------------------------- |
| Windows 10인데 winget이 없어요     | **설정 → 업데이트**에서 최신 누적 업데이트 적용 후, Microsoft Store에서 “앱 설치 관리자” 설치    |
| 이미 Qt/VS/Git이 깔려 있는데 재설치하나요? | winget이 “설치됨”으로 감지하면 **스킵**합니다. 기존 설치를 그대로 사용                       |
| Boost 버전을 바꾸거나 추가 옵션을 주려면?   | 스크립트 상단의 `BOOST_VERSION`, `BOOST_URL` 및 b2 빌드 옵션을 수정                |
| “빌드 실패” 메시지가 떴어요             | 스크립트 끝에 **❌ Fatal** 로그가 표시된 직후의 에러 출력을 확인하고, 디스크/네트워크/방화벽/권한 문제를 점검 |

---

## 📝 라이선스

본 스크립트는 MIT License 하에 배포됩니다.
Fritzing, Qt, Boost 및 기타 서드파티 라이브러리는 각자의 라이선스를 따릅니다.

---

## 🤝 기여 · 버그 리포트

* **Issues** 탭에 버그/개선 제안 등록
* Pull Request 대환영! (스크립트 개선, 버전 업데이트 등)

---

> **Maintainer** : 박현수 (Hyeonsu Park) · [@HyeonsuParkembedded](https://github.com/HyeonsuParkembedded)
