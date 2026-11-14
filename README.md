# 여울목 iOS

계곡·하천의 홍수 위험을 감지해 실시간으로 알려 주는 서비스 **여울목**의 iOS 앱입니다.

- 서버: [yeoulmok/server](https://github.com/yeoulmok/server)
- 기획·문서: Notion 프로젝트 페이지 (기능 정의서, API 명세서, 개발 협업 가이드, AI 협업 가이드)
- 화면 설계: Figma "여울목 화면설계"

## 개발 규칙 요약

이슈 · 브랜치 · 커밋 · PR 규칙은 Notion의 **개발 협업 가이드**를 따릅니다.

- 기능 ID(예: `APP-HOME-01`)가 Notion 기능 목록, 이슈 제목, PR 제목을 잇는 키입니다.
- 브랜치: `유형/이슈번호-짧은-설명` (예: `feat/12-subscribed-list`)
- 커밋: `유형: 무엇을 했는지 (#이슈번호)` — 메시지는 한국어, 코드 주석은 영어
- PR: 제목 `[기능 ID] 작업 요약`, 본문에 `Closes #이슈번호`, 화면 스크린샷 첨부
- `main`은 직접 push할 수 없고 PR → Squash merge로만 반영됩니다.

## 실행 방법

요구 사항: Xcode 27 이상, 최소 지원 iOS 17.0

1. 설정 파일을 만듭니다 (아래 "환경 변수").
2. `yeoulmok/yeoulmok.xcodeproj`를 Xcode로 열고 `yeoulmok` 스킴을 시뮬레이터에서 실행합니다 (⌘R).
3. 빌드와 테스트를 한 번에 확인하려면 저장소 루트에서 `./scripts/check.sh`를 실행합니다.

## 환경 변수

서버 주소 등 환경별 값은 `yeoulmok/Config.xcconfig`에 두고 저장소에 올리지 않습니다 (`.gitignore` 처리됨).

```bash
cp yeoulmok/Config.example.xcconfig yeoulmok/Config.xcconfig
```

| 키 | 설명 |
| --- | --- |
| `API_BASE_URL` | 서버 API 주소 (끝에 `/api` 포함). xcconfig에서는 `//`가 주석이라 `https:/$()/` 형태로 씁니다 |

값은 빌드할 때 `Info.plist`를 거쳐 앱의 `AppConfig`가 읽습니다. 코드에 서버 주소를 직접 쓰지 않습니다.

비밀 값(APNs 키 `.p8`, 토큰 등)은 절대 커밋하지 않습니다.
