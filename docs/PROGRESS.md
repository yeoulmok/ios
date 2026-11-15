# Progress

최종 갱신: 2026-11-15

## Now
- #24 프로젝트 초기 세팅(#29), #27 Mock · API 모델(#30), #1 하단 탭(#31), #2 상태 배지(#32), #3 출처 표기(#33), #4 홈 구독 목록(#34), #5 계곡 추가 진입(#35), #6 상세 이동(#36), #21 검색 결과(#37), #7 구독 토글(#38), #39 check.sh 재시도(#40) 완료. #8 기기 등록 · 네트워킹은 PR 리뷰 중.
- 앱 구조: `Shared/Models`(응답 모델), `Shared/Networking`(시각 변환 · 에러), `Shared/Repository`(데이터 약속), `Mock/`(가짜 응답 · Mock 저장소). `Shared/Device`(device_id 등록 · 보관). 화면은 `ValleyRepository`만 보고, 앱은 `ServerValleyRepository`(실제 서버), 테스트는 `MockValleyRepository`를 씁니다.
- 다음에 할 일: **상세 #10~#13** → #9 → #18 → #17 → #16 → #14 → #15 → #22 → #19 → #20 → #23 → QA.
- 화면 이동 규칙: 하위 화면은 "눌렸다"만 클로저로 알리고, 탭 전환은 `RootView`가 결정 (예: `HomeView(onAddValley:)`). 상세 열기는 `NavigationLink(value: ValleyRoute(valleyID:))` 하나로 통일하고, `ValleyRoute` → `ValleyDetailView` 변환은 `RootView`에 한 번만 등록 (근처 · 검색 · 푸시도 같은 방식).
- 공통 부품(`Shared/Components`): `StatusBadge`, `SourceFooter`(서버 `source`가 비거나 `"자료: "`면 기본 문구). 경보 상세(#10)에도 `SourceFooter`를 붙여야 함. 지금 `ValleyDetailView`는 이름만 불러오는 빈 화면이고, 상세에서 탭 막대 숨기기(Figma 04)도 #10에서.
- 데이터 흐름: `YeoulmokApp`이 저장소를 하나 만들어 `RootView` → 각 화면 → `@Observable` ViewModel로 넘김 (기본은 `ServerValleyRepository`). 화면 상태는 `State` enum(loading · loaded · empty · failed).
- 테스트 환경: `check.sh`가 가끔 "Failed to create a bundle instance"로 실패함 (원인 모름). 이 에러일 때만 한 번 다시 돌리도록 막아 둠(#39). 시뮬레이터가 앱을 못 띄우는 "Launchd job spawn failed"도 #8 작업 중 한 번 나옴 (다시 돌리면 통과, 재시도 대상 아님).
- `check.sh` 통과만 보지 말고 실행된 테스트 수도 확인할 것: #7 작업 중 `project.xcproj`에 `"opaque-folders": ["Search"]`가 생겨 `yeoulmokTests/Search`가 빌드에서 빠졌는데도 통과로 나옴 (원인 모름, 되돌림).
- Figma `앱 / 공통 · 컴포넌트`에 배지 5종 · 출처 문구 · 자료 지연 · 토스트 · 오프라인 배너 디자인이 생김. 공통 부품은 이 화면 기준.
- 검색 탭: 키보드 "검색"을 누를 때만 요청(`?q=`), 검색창을 비우면 전체 목록. 검색창(APP-SRCH-01, P1) 일부를 #21에서 함께 구현. 검색어 없이 0건일 때 문구 "해당하는 계곡이 없어요"는 임시.
- 구독 토글(#7): 먼저 버튼을 바꾸고 요청, 실패하면 되돌림 + `Toast`(02b). 요청 중인 계곡 버튼만 비활성. 검색 행은 [이름·지역 → 상세] | [구독 버튼] 두 부분. 실패 재현: DEBUG 실행 옵션 `-mockSubscriptionFails`.
- 서버 연결(#8): `APIClient`(요청 · 에러 구분) → `DeviceRegistrar`(`device_id` 등록은 한 번만, Keychain 보관, `DEVICE_NOT_FOUND`면 다시 등록 후 한 번만 재요청, APNs 토큰은 `PATCH /devices`) → `ServerValleyRepository`. Keychain을 못 읽으면 새로 등록하지 않음(구독이 사라져 보이는 것 방지). 실제 APNs 토큰 전달은 #26 · #19에서.
- Mock 실행: DEBUG 실행 옵션 `-useMockData`(또는 `-mockSubscriptionFails`). UI 테스트는 전부 이 옵션으로 실행하고, 단위 테스트 호스트 앱도 자동으로 Mock을 씀. 새 UI 테스트도 `-useMockData`를 붙일 것.
- 서버 동작 메모(서버 담당 확인 필요): 결과가 0개면 `source`가 `"자료: "`로 옴(앱은 `SourceFooter` 기본 문구로 처리됨), `GET /me/valleys`는 모르는 `device_id`에도 `DEVICE_NOT_FOUND` 대신 빈 목록(200).
- UI 테스트(`yeoulmokUITests`)는 느려서 `check.sh`에 넣지 않음. PR 전에 따로 실행.
- 남은 일: #26 App ID 등록 · APNs 키 발급(서연), #25 이슈 정리(범위 축소로 닫을지 결정).

## 이슈 순서 (총 27개, 전부 P0)

| 주차 | 이슈 |
| --- | --- |
| Week 1 (~11/16) | #24 프로젝트 초기 세팅 · #25 AI 협업 파일 · #26 Apple/푸시 준비 · #27 Mock/API 모델 · #1 하단 탭 · #2 상태 배지 · #3 출처 표기 · #4 구독 목록(HOME-01) · #5 계곡 추가 진입 · #6 상세 이동 · #7 구독 토글 · #21 검색 결과 목록 |
| Week 2 (~11/23) | #8 기기 등록 · #9 새로고침/지연 표시 · #10 경보 요약 · #11 관측 정보 · #12 행동 요령 · #13 면책 문구 · #14 위치 권한 · #15 주변 계곡 목록 |
| Week 3 (~11/30) | #16 통신 불가 시 마지막 상태(APP-COM-07) · #17 공통 에러 화면 · #18 구독 없음 상태 · #19 푸시 수신 · #20 푸시 딥링크 · #22 알림 권한 요청 · #23 약관·앱 정보 |
| Week 4 (~12/7) | 마일스톤만 있음. 전체 QA, 버그 수정, TestFlight 배포 (이슈 미생성) |

- 권장 순서: #26(병행) → #24 → #27 → #1 · #2 → 나머지 Week 1 → Week 2 ...
- P0에 포함되지 않은 기능(이슈 없음): `APP-SRCH-01` 검색 입력창, `APP-DTL-02` AI 근거 설명, `APP-DTL-06` 상세에서 구독, `APP-NEAR-03` 지도, `APP-ONB-01` 서비스 소개, `APP-SET-01` 알림 설정(P1), `APP-NOTI-03`(P2). WEB 관리자 화면은 앱 P0가 끝난 뒤.

## 결정 기록

| 날짜 | 결정 | 이유 |
| --- | --- | --- |
| 2026-11-11 | 저장소 이름 `ios`, public | 서버 저장소(`server`)와 이름 규칙을 맞춤. 조직이 무료 플랜이라 private에서는 main 보호를 켤 수 없음 |
| 2026-11-11 | main 보호: PR 필수, 승인 0명, 관리자 포함, Squash merge만 | 협업 가이드의 24시간 셀프 머지 규칙에 맞춤 |
| 2026-11-11 | 기능 ID 중복 정리: 통신 불가 시 마지막 상태 `APP-COM-01` → `APP-COM-07` | 하단 탭과 ID가 겹쳤음 |
| 2026-11-11 | P1→P0 승격: `APP-SRCH-02`(#21), `APP-ONB-02`(#22), `APP-SET-02`(#23) | P0 구독 동선에 목록 화면 필요 / 푸시(P0)에 권한 요청 화면 필요 / App Store가 앱 안 개인정보처리방침 링크를 요구 |
| 2026-11-11 | 로딩 · 빈 상태 · 에러 처리 기준을 Notion 기능 정의서 3-1절 하나로 통일 | 화면마다 규칙이 달라지는 것을 막음 |
| 2026-11-11 | 마일스톤 마감: 11/16, 11/23, 11/30, 12/7 | 기능 정의서의 "2주차 = 11/17~23" 기준 |

## 막힌 것 · 남은 일
- **GitHub Projects 보드 없음**: `gh` 토큰에 `project` 권한이 없음. `gh auth refresh -s project` 후 보드를 만들고(컬럼: Backlog, Todo, In Progress, In Review, Done) 이슈를 올려야 함.
- **서버 저장소 설정**: `yeoulmok/server`에는 브랜치 보호, 템플릿, 라벨이 없음. 서버 담당과 협의 후 진행.
- **Notion 협업 가이드 3장**: 저장소 이름이 `yeoulmok-ios`로 적혀 있음 (실제는 `ios`).
- **서버가 기다리는 확인 요청 3건**(API 명세 5절) 미답변: `device_id` 방식, 상세 응답에 더 필요한 필드, 푸시 페이로드(야간 `caution` 무음). 답에 따라 #27 모델이 바뀔 수 있음.
- **3-1절 "서버 `error.message`를 안내 문구로 사용"** 은 서버 쪽과 아직 맞춰 보지 않음.
- **Notion 기능 목록의 낡은 비고**: `APP-SRCH-03`("기기 단위 구독인지 확인 필요" — 이미 확정), `APP-HOME-01`(정렬 기준 미정), `APP-DTL-04`(상태별 문구 확정 필요).
- **Notion 기능 정의서 6절**: "추가 화면 디자인"이 미체크지만 Figma에는 온보딩, 설정, 빈 상태, 에러, 위치 권한 거부 화면이 이미 있음.
- **읽지 못한 Notion 부분**: 개발 진행도 DB, 전체 일정 보드, 회의록, 개인 페이지.

## 세션 로그
- 2026-11-11 — Notion 문서와 Figma 읽기, 개발 프로세스 정리, 저장소 · 템플릿 · 라벨 · 마일스톤 · 이슈 #1~#27 생성, Notion 기능 목록 · 정의서 갱신, 인수인계 파일 작성 (#25 일부). 다음: #26 확인, #24 시작.
- 2026-11-14 — #24 머지(#29). #27: 목록 · 상세 모델, 한국 시간 변환, 상태별 Mock, Repository + Mock 구현(테스트 28개). 다음: #1.
- 2026-11-14 — #27 머지(#30). #1: `AppTab`, 탭별 `NavigationStack`, 빈 화면 3개, 탭 UI 테스트 3개. 다음: #2 · #3.
- 2026-11-14 — #1 머지(#31). #2: 상태별 문구 · 색 · 아이콘, `StatusBadge`(작은/큰, VoiceOver), 판정 불가≠안전 테스트. 다음: #3.
- 2026-11-14 — #2 머지(#32). #3: `SourceText` 기본값 처리, `SourceFooter`, 홈 · 근처 하단 표기 + UI 테스트, `check.sh` 시뮬레이터 부팅 대기 수정. 다음: #4.
- 2026-11-14 — #3 머지(#33). #4: 표시 형식, 위험도 정렬, `ValleyCard`, `HomeViewModel`, 저장소 주입, 홈 화면, UI 테스트. `Observation` → `ValleyObservation`(프레임워크 이름 충돌). 다음: #5 · #6.
- 2026-11-14 — #4 머지(#34). #5: `AddValleyButton`, 클로저로 검색 탭 이동, UI 테스트. 다음: #6.
- 2026-11-15 — #5 머지(#35). #6: `ValleyRoute`, `RootView` 상세 규칙, 빈 상세 화면, 홈 카드 `NavigationLink`, 이동 · 복귀 UI 테스트. 다음: #21.
- 2026-11-15 — #6 머지(#36). #21: `ErrorMessage` 분리, `SearchViewModel`(늦은 응답 무시), `SearchResultRow` · `SubscriptionPill`, `SearchView` · `SearchEmptyView`(02a), UI 테스트 4개. 다음: #7.
- 2026-11-15 — #21 머지(#37). #7: `toggleSubscription`(낙관적 업데이트, 요청 중 잠금), 공통 `Toast`, 검색 행 분리, Mock 실패 스위치, UI 테스트 2개. 다음: #8.
- 2026-11-15 — #7 머지(#38), #39 머지(#40). #8: `APIClient` · `StubURLProtocol`, `KeychainDeviceIDStore`, `DeviceRegistrar`(한 번만 등록 · 재등록 · 푸시 토큰), `ServerValleyRepository`, 앱 기본을 실제 서버로, UI 테스트 `-useMockData`, 등록 실패 시 목록 · 검색 · 상세는 ID 없이 요청. 단위 테스트 114개, UI 15개. 다음: #10.
