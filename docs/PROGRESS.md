# Progress

최종 갱신: 2026-11-18

## Now
- #24 프로젝트 초기 세팅(#29), #27 Mock · API 모델(#30), #1 하단 탭(#31), #2 상태 배지(#32), #3 출처 표기(#33), #4 홈 구독 목록(#34), #5 계곡 추가 진입(#35), #6 상세 이동(#36), #21 검색 결과(#37), #7 구독 토글(#38), #39 check.sh 재시도(#40), #8 기기 등록 · 실제 서버 연결(#41), #10 경보 요약(#42), #11 관측 정보(#43), #12 행동 요령(#44), #13 면책 문구(#45) 완료 (경보 상세 P0 완성), #9 새로고침 · 자료 지연(#46), #18 구독 없음 상태(#47), #17 공통 에러 화면(#48), #16 통신 불가 시 마지막 상태(#49), #14 위치 권한(#50), #15 주변 계곡 목록(#51), #22 알림 권한 요청(#52), #23 약관 · 앱 정보(#53), #19 푸시 수신 앱 쪽(#54), #20 푸시 딥링크(#55) 완료(둘 다 실기기 확인 전이라 이슈 열어 둠). #26 Apple 준비는 아이폰 등록만 남음(11/18). Push 기능(`aps-environment`) 켜기는 PR 리뷰 중.
- 앱 구조: `Shared/Models`(응답 모델), `Shared/Networking`(시각 변환 · 에러), `Shared/Repository`(데이터 약속), `Mock/`(가짜 응답 · Mock 저장소). `Shared/Device`(device_id 등록 · 보관). 화면은 `ValleyRepository`만 보고, 앱은 `ServerValleyRepository`(실제 서버), 테스트는 `MockValleyRepository`를 씁니다.
- 다음에 할 일: **아이폰을 개발 기기로 등록(#26 마지막 항목)** → #19 · #20 · #22 실기기 확인(토큰 등록, 앱이 뒤에 있을 때 · 꺼져 있을 때 탭, 야간 무음) → QA. 앱 P0 이슈는 코드 작업 끝.
- 화면 이동 규칙: 하위 화면은 "눌렸다"만 클로저로 알리고, 탭 전환은 `RootView`가 결정 (예: `HomeView(onAddValley:)`). 상세 열기는 `NavigationLink(value: ValleyRoute(valleyID:))` 하나로 통일하고, `ValleyRoute` → `ValleyDetailView` 변환은 `RootView`에 한 번만 등록 (근처 · 검색 · 푸시도 같은 방식).
- 공통 부품(`Shared/Components`): `StatusBadge`, `SourceFooter`(서버 `source`가 비거나 `"자료: "`면 기본 문구).
- 데이터 흐름: `YeoulmokApp`이 저장소를 하나 만들어 `RootView` → 각 화면 → `@Observable` ViewModel로 넘김 (기본은 `ServerValleyRepository`). 화면 상태는 `State` enum(loading · loaded · empty · failed).
- 테스트 환경: `check.sh`가 가끔 "Failed to create a bundle instance"로 실패함 (원인 모름). 이 에러일 때만 한 번 다시 돌리도록 막아 둠(#39). 시뮬레이터가 앱을 못 띄우는 "Launchd job spawn failed"도 #8 작업 중 한 번 나옴 (다시 돌리면 통과, 재시도 대상 아님).
- `check.sh` 통과만 보지 말고 실행된 테스트 수도 확인할 것: #7 작업 중 `project.xcproj`에 `"opaque-folders": ["Search"]`가 생겨 `yeoulmokTests/Search`가 빌드에서 빠졌는데도 통과로 나옴 (원인 모름, 되돌림).
- Figma `앱 / 공통 · 컴포넌트`에 배지 5종 · 출처 문구 · 자료 지연 · 토스트 · 오프라인 배너 디자인이 생김. 공통 부품은 이 화면 기준.
- 검색 탭: 키보드 "검색"을 누를 때만 요청(`?q=`), 검색창을 비우면 전체 목록. 검색창(APP-SRCH-01, P1) 일부를 #21에서 함께 구현. 검색어 없이 0건일 때 문구 "해당하는 계곡이 없어요"는 임시.
- 구독 토글(#7): 먼저 버튼을 바꾸고 요청, 실패하면 되돌림 + `Toast`(02b). 요청 중인 계곡 버튼만 비활성. 검색 행은 [이름·지역 → 상세] | [구독 버튼] 두 부분. 실패 재현: DEBUG 실행 옵션 `-mockSubscriptionFails`.
- 서버 연결(#8): `APIClient`(요청 · 에러 구분) → `DeviceRegistrar`(`device_id` 등록은 한 번만, Keychain 보관, `DEVICE_NOT_FOUND`면 다시 등록 후 한 번만 재요청, APNs 토큰은 `PATCH /devices`) → `ServerValleyRepository`. Keychain을 못 읽으면 새로 등록하지 않음(구독이 사라져 보이는 것 방지). 실제 APNs 토큰 전달은 #26 · #19에서.
- Mock 실행: DEBUG 실행 옵션 `-useMockData`(또는 `-mockSubscriptionFails`). UI 테스트는 전부 이 옵션으로 실행하고, 단위 테스트 호스트 앱도 자동으로 Mock을 씀. 새 UI 테스트도 `-useMockData`를 붙일 것.
- 서버 동작 메모(서버 담당 확인 필요): 결과가 0개면 `source`가 `"자료: "`로 옴(앱은 `SourceFooter` 기본 문구로 처리됨), `GET /me/valleys`는 모르는 `device_id`에도 `DEVICE_NOT_FOUND` 대신 빈 목록(200).
- 경보 상세(#10): `ValleyDetailViewModel` 상태는 loading · loaded · failed (빈 상태 없음, 없는 계곡은 서버 에러 문구로 에러 화면). 불러온 뒤 실패하면 기존 내용 유지. 화면은 큰 제목(계곡명) · 큰 배지 · 요약 · `SourceFooter`, 탭 막대 숨김. 맨 아래는 `DetailFooter`(면책 + 출처), 에러 화면에도 표시. 테스트 식별자: `detail.summary` (에러 화면은 #17 공통 `error.title` · `error.retry`).
- 관측 정보(#11): 관측 1개 = 테두리 상자 1개(`ObservationSection` · `ObservationBox`), 문구는 `ObservationFormat`(숫자는 `ValleyFormat`과 같음). 값이 없으면 `-`, 서버 `note`가 있으면 `- (수위 결측)`. 수위 기준값은 부호 없이 `0.10m / 30분`. 관측 0개일 때 문구 "연결된 관측소가 없어요"는 임시.
- 행동 요령(#12): 서버 `actions` 문구를 그대로 순서대로 표시(`ActionList`). 앱은 안전 문구를 만들지 않음, 앱 문구는 제목 "행동 요령"뿐. 빈 배열이면 제목까지 숨김(빈 배열이 올 수 있는지 서버 확인 요청, PR #44). 제목은 VoiceOver 머리글이지만 UI 테스트로는 확인하지 않음(공식 API 없음).
- 면책 문구(#13): `DisclaimerText.display`가 서버 `disclaimer`가 비면 기본 문구("판단 보조 정보이며 공식 재난경보를 대체하지 않습니다.", 이슈 · 서버 문구와 같음)로 대체. 면책과 출처는 `DetailFooter` 하나로 묶어 상세 · 에러 화면 모두에 표시. AI 근거 설명(APP-DTL-02, P1)만 상세에 남음.
- 새로고침 · 자료 지연(#9): 서버 `stale: true`면 공통 `StaleLabel`("🕘 자료 지연")을 홈 카드 관측 시각 옆 · 상세 배지 옆에 표시(15분 기준은 서버가 판단). 홈 · 상세는 `.refreshable`(내용 · 빈 상태 · 에러 화면 모두, 빈 · 에러 화면은 `ScrollView` + `containerRelativeFrame`). 홈 · 상세 모두 받아 둔 데이터가 있으면 새로고침 실패 시 화면 유지(안내 배너는 #16). **근처 탭 새로고침과 지연 표시는 #15에서 같은 방식으로 추가.** 시뮬레이터 제어 도구로 당기면 손 뗄 때 새로고침이 안 되는 것처럼 보임(XCUITest 드래그는 정상) — 손으로 확인 필요.
- 홈 빈 상태(#18): `HomeEmptyView`(Figma 01b 문구 그대로, `water.waves` 아이콘, '계곡 추가하기' → 검색 탭, 출처 유지). 홈의 빈 상태 · 에러 화면은 `pullable { }` 도우미(전체 화면 + 당겨서 새로고침). **안내 문구 "위험할 때 알림을 보내드려요"는 푸시(#19) 이후 QA 때 확인.**
- 공통 에러 화면(#17): `ErrorStateView`(받아 둔 데이터가 없을 때). 연결 오류는 "연결할 수 없어요" + "인터넷 연결을 확인해 주세요.", 서버 에러 코드는 서버 `message`만(`ErrorContent`). '다시 시도'는 같은 요청(홈 · 상세 `load`, 검색 `retry()` = 마지막 검색어), 진행 중 스피너 + 비활성. Figma의 "마지막으로 받은 정보는 …기준" 줄은 #16에서. 재현: DEBUG 실행 옵션 `-mockLoadFailsOnce`(첫 목록 · 상세 요청만 실패).
- 통신 불가 시 마지막 상태(#16): 실패했는데 받아 둔 정보가 있으면 화면 유지 + `OfflineBanner`("연결할 수 없어 M월 d일 HH:mm 기준 정보를 보여드려요", 시각은 응답 `updated_at`). 홈 목록 · 상세는 `ValleyCache`(Caches 폴더 JSON)에 저장해 앱을 다시 켜도 표시, 검색은 앱이 켜진 동안만. **결정(사람): 저장본은 기한 없이 보여 주고 기준 시각을 항상 표시.** 저장본은 연결 문제일 때만 사용(서버 에러 코드면 에러 화면). Mock 실행은 실행마다 빈 캐시 폴더. 재현: `-mockOfflineAfterFirstLoad`(요청마다 처음 한 번만 성공). 앱 재시작 후 저장본 표시는 손으로 확인 필요.
- 위치 권한(#14): 근처 탭에 처음 들어갈 때만 iOS 질문 창(`NSLocationWhenInUseUsageDescription`은 `yeoulmok/Info.plist`). `LocationPermission` 프로토콜 + `SystemLocationPermission`(CLLocationManager), `NearbyViewModel` 상태는 askingPermission · allowed · denied(제한됨도 거부로). 거부면 `LocationDeniedView`(Figma 03b 문구 그대로, "설정 열기" → `openSettingsURLString`).  **시뮬레이터에서 "설정 열기"가 앱 설정이 아닌 "Apps" 목록을 엶 — 실제 기기 확인 필요.** 권한 질문 창 앱 이름이 "yeoulmok"(영문)으로 나옴 — 출시 전 결정 필요. UI 테스트는 `resetAuthorizationStatus` 전에 앱을 한 번 켜야 초기화가 확실히 적용됨.
- 주변 계곡 목록(#15): 위치를 한 번 받고(`requestLocation()`, 동시 요청은 `LocationRequests`로 하나로) `GET /valleys` 전체에서 가까운 5개(`NearbyValleys`, 반경 제한 없음). 거리는 하버사인 공식으로 직접 계산 — `CLLocation.distance(from:)`가 같은 두 점에 다른 값을 줘서 새로고침 때 28.0km ↔ 28.1km로 바뀌었음. 표기는 항상 km 소수 한 자리(50m 미만은 `0.0km`, 그대로 둘지 결정 필요). 행 = 계곡명 · 거리 · 배지, 늦은 자료면 거리 옆 `StaleLabel`. 실패 규칙은 홈과 같고, 전체 목록을 `ValleyCache`(`valleys.json`)에 저장해 오프라인이어도 지금 위치로 다시 정렬(**결정(사람): 기한 없이, 기준 시각 항상 표시**). 새로고침 때 위치를 못 받으면 목록 유지(배너 없음). Figma 03의 지도는 이슈 범위 밖이라 넣지 않음. 임시 문구: "현재 위치를 확인할 수 없어요", "주변에 계곡이 없어요". 재현: DEBUG `-mockLocation`(원주 시내 고정, 순서 3 · 1 · 4 · 2 · 5).
- 알림 권한(#22): 첫 실행에만 Figma 05b 화면(`NotificationOnboardingView`)을 탭 대신 표시. '알림 허용' → iOS 질문(알림 · 소리, badge 없음) → 허용이면 토큰 요청, '나중에 하기' → 묻지 않음. 둘 다 `UserDefaults`(`notificationOnboardingDone`)에 기록해 다시 안 보임. 토큰은 `AppDelegate` → `PushTokenReceiver`(16진수) → `DeviceRegistrar.updatePushToken`, 권한이 있으면 실행마다 다시 요청(실패해도 다음 실행에 다시 보냄). Mock 실행은 화면을 건너뛰고 토큰도 서버로 보내지 않음. 재현: DEBUG `-notificationOnboarding`(Mock에서도 표시), `-resetNotificationOnboarding`(기록 삭제). `aps-environment`(Push 기능)는 #19 PR에서 켬(아래 Push 기능 줄). 알림 권한은 UI 테스트에서 초기화할 API가 없어 iOS 질문 창은 앱을 지운 뒤에만 뜸. 질문 창 앱 이름 "yeoulmok"은 #14와 같은 표시 이름 결정 대기.
- 설정(#23): 홈 오른쪽 위 톱니바퀴(`SettingsRoute`, Figma 01에는 없고 기능 정의서 IA 기준) → `SettingsView`(정보: 이용약관 · 개인정보처리방침 · 데이터 출처 · 문의하기, 앱 버전, 출처 표기, 탭 막대 숨김). 약관 · 방침 URL과 문의 이메일은 `Config.xcconfig`의 `TERMS_URL` · `PRIVACY_URL` · `CONTACT_EMAIL` → Info.plist → `AppInfo`(https만, 비면 nil). 값이 없으면 행은 보이지만 비활성. 링크는 외부 Safari · 메일 앱(`openURL`). 버전은 `MARKETING_VERSION`(빌드 번호 제외). 경보 알림 토글(APP-SET-01)은 P1이라 없음. **출시 전: 약관 · 방침 주소와 공개 문의 이메일을 정해 Config에 넣고 손으로 확인.** 임시 문구: 데이터 출처 화면 "하천 수위 — 한강홍수통제소", "강수량 — 기상청"(서버 담당 확인 필요). UI 테스트: `LabeledContent`는 두 글자를 한 요소로 읽으므로 "포함" 조건으로 찾을 것.
- 푸시 수신(#19): 앱이 꺼져 있거나 뒤에 있으면 iOS가 서버의 `aps.alert`를 그대로 표시(앱은 문구를 만들지 않음). 앱이 켜져 있을 때는 `AppDelegate`가 `UNUserNotificationCenterDelegate`(`didFinishLaunching`에서 등록)로 `willPresent` → `PushPresentation.whileOpen` = 배너 · 목록 · 소리(badge 없음). `.sound`는 페이로드에 소리가 있을 때만 울림 → **API 명세 5-3 답: 야간 `caution`은 `sound` 생략으로 무음 가능(실기기에서 소리 확인 필요).** 시뮬레이터 확인: `"Simulator Target Bundle": "com.yeoulmok.app"`을 넣은 `.apns` JSON으로 `xcrun simctl push <기기> com.yeoulmok.app <파일>` (APNs 키 · Push 기능 없이 동작). `aps-environment`(Push 기능)는 #26 때 Xcode capability로 추가.
- 푸시 딥링크(#20): 탭 → `AppDelegate.didReceive` → `PushPayload.valleyID`(숫자 · 숫자 문자열, 없으면 이동 없음) → `PushRouter`(우편함, `@Observable`) → `RootView`가 `onChange(initial: true)`로 꺼내 `TabNavigation.openDetailFromPush` = 홈 탭 + 홈 경로를 `[ValleyRoute]`로 교체(다른 탭은 유지). 탭마다 `NavigationStack(path:)`. 없는 계곡은 상세의 에러 화면(서버 문구). **알림 delegate는 completion handler 버전을 쓸 것: `async` 버전은 iOS의 완료 신호를 메인 스레드 밖에서 불러 백그라운드 탭 때 앱이 꺼졌음(#20에서 발견 · 수정, `willPresent`도 같이).** UI 테스트는 DEBUG `-mockPushValleyID <id>`(실행 직후 탭 흉내, AppDelegate 이후만 확인). 진짜 탭 확인: `simctl push`를 반복 보내면서 XCUITest로 springboard 배너(`label CONTAINS 계곡명`)를 탭 — 시뮬레이터 제어 도구의 탭은 iOS 홈 화면 배너에 안 먹음.
- Push 기능(#19): `yeoulmok/yeoulmok.entitlements`(`aps-environment` = `development`, `Info.plist` 옆 — 소스 폴더 안에 두면 리소스로 복사될 수 있음) + 앱 타깃 `CODE_SIGN_ENTITLEMENTS`. TestFlight · App Store로 내보낼 때 Xcode가 `production`으로 바꿔 줌 → Xcode 실행 = sandbox 토큰, TestFlight = production 토큰(서버 주소가 다르면 `BadDeviceToken`). Apple silicon 맥 시뮬레이터도 진짜 sandbox 토큰을 받음: 앱 삭제 후 실제 서버로 실행 → 알림 허용 → `log stream --predicate 'subsystem == "yeoulmok"'`에 `Got a push token`, `Push token is on the server`(토큰 값은 안 남김). 시뮬레이터 빌드의 선언은 `codesign`이 아니라 바이너리의 `__TEXT,__entitlements`에 들어감.
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
- 2026-11-15 — #8 머지(#41). #10: `ValleyDetailViewModel`(3-1절 상태), `ValleyDetailView`(제목 · 배지 · 요약 · 출처, 탭 막대 숨김), `StubRepository` 상세 클로저, UI 테스트 3개. 단위 120개, UI 18개. 다음: #11.
- 2026-11-15 — #10 머지(#42). #11: `ObservationFormat`(null ≠ 0, note, 모르는 종류), `ObservationBox` 상세 연결, UI 테스트 2개. 단위 130개, UI 20개. 다음: #12.
- 2026-11-15 — #11 머지(#43). #12: `ActionList`(서버 문구 그대로, 빈 배열이면 숨김), 상세 연결, UI 테스트 1개. 단위 130개, UI 21개. 다음: #13.
- 2026-11-15 — #12 머지(#44). #13: `DisclaimerText`(빈 값이면 기본 문구), `DetailFooter`(면책 + 출처, 에러 화면 포함), UI 테스트 1개. 단위 133개, UI 22개. 경보 상세 P0 완성. 다음: #9.
- 2026-11-15 — #13 머지(#45). #9: `StaleLabel`(카드 · 상세), 홈 · 상세 `.refreshable`, 홈 새로고침 실패 시 유지(단위 테스트 3개), UI 테스트 3개. 단위 136개, UI 25개. 근처 새로고침은 #15로. 다음: #18.
- 2026-11-15 — #9 머지(#46). #18: `HomeEmptyView`, 홈 `pullable` 도우미, UI 테스트 2개. 단위 136개, UI 27개. 다음: #17.
- 2026-11-15 — #18 머지(#47). #17: `ErrorStateView` · `ErrorContent`, 홈 · 검색 · 상세 연결, `SearchViewModel.retry()`, `-mockLoadFailsOnce`, UI 테스트 1개. 단위 140개, UI 28개. 다음: #16.
- 2026-11-15 — #17 머지(#48). #16: 모델 Codable + `ValleyCache`, `OfflineBanner`, 홈 · 상세 · 검색 오프라인 규칙, 검색 당겨서 새로고침, `-mockOfflineAfterFirstLoad`, UI 테스트 2개. 단위 158개, UI 30개. 다음: #14.
- 2026-11-16 — #16 머지(#49). #14: `LocationPermission` · `SystemLocationPermission`, `NearbyViewModel`(단위 테스트 5개), `NearbyView` · `LocationDeniedView`(03b), UI 테스트 3개(거부 · 허용 · 다시 묻지 않음). 단위 163개, UI 33개. 다음: #15.
- 2026-11-16 — #14 머지(#50). #15: `NearbyValleys`(하버사인), `currentLocation` · `LocationRequests`, `NearbyViewModel` 목록 · 실패 규칙, `ValleyCache.allValleys`, `NearbyRow`, `-mockLocation`, UI 테스트 3개. 단위 188개, UI 36개. 다음: #22.
- 2026-11-16 — #15 머지(#51). #22: `NotificationPermission` · `NotificationOnboardingStore` · ViewModel, `AppDelegate` · `PushTokenReceiver`(토큰 → 서버), 05b 화면 · `RootView` 첫 실행 분기, UI 테스트 3개. 단위 201개, UI 39개. 다음: #19(#26 필요) 또는 #23.
- 2026-11-16 — #22 머지(#52). #23: `AppInfo`(버전 · 링크 · 메일, Config에서), `SettingsRows` · `SettingsView` · `DataSourceView`, 홈 톱니바퀴 · `SettingsRoute`, UI 테스트 4개. 단위 212개, UI 43개. 다음: #26 → #19.
- 2026-11-16 — #23 머지(#53). #19(앱 쪽): `AppDelegate` 알림 delegate, `PushPresentation`(포그라운드 배너 · 목록 · 소리), `simctl push` 확인. 단위 215개, UI 43개. 실기기 확인은 #26 뒤. 다음: #20.
- 2026-11-16 — #19 앱 쪽 머지(#54). #20: `PushPayload` · `PushRouter` · `didReceive`, `TabNavigation` · 탭별 경로, `-mockPushValleyID`, UI 테스트 3개, 진짜 탭 확인 중 백그라운드 크래시 발견 · 수정(completion handler). 단위 226개, UI 46개. 다음: #26 → 실기기 확인 → QA.
- 2026-11-18 — #20 머지(#55). #26: 아이폰 등록 빼고 완료(App ID 푸시 · APNs 키 전달 · App Store Connect, 서연). #19 Push 기능: entitlements · `CODE_SIGN_ENTITLEMENTS`, 토큰 성공 로그, 시뮬레이터에서 실제 토큰 → 서버 등록 확인. 단위 226개, 알림 UI 6개. 다음: 아이폰 등록 → 실기기 확인.
