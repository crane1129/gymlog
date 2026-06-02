# GymLog — Flutter App Project Specification

> 헬스장 운동 기록 및 바디 프로필 관리 모바일 앱  
> Version: 0.1.0 (MVP)  
> Last Updated: 2026-05-08

---

## 1. 프로젝트 개요

| 항목 | 내용 |
|---|---|
| 앱 이름 | **GymLog** |
| 플랫폼 | iOS + Android (Flutter) |
| 저장소 | 온디바이스 우선 (Offline-first), 향후 클라우드 동기화 확장 예정 |
| 최소 지원 | iOS 14+, Android 7.0 (API 24)+ |

### 핵심 목표
- 헬스장에서 하는 운동의 이름, 세트, 횟수, 무게를 날짜별로 기록
- 운동별 전반적인 진행상황(최고 기록, 볼륨 추세) 시각화
- 바디 프로필 및 체중 기록/추세 관리
- 세트 완료 후 휴식 타이머를 직관적으로 실행

---

## 2. 기능 요구사항

### 2.1 운동 로그 (핵심)

- 날짜별 운동 세션 생성/수정/삭제
- 세션 내 운동 종목 추가 (기본 제공 종목 + 커스텀 종목)
- 세트별 무게(kg/lbs), 횟수(reps) 입력
- **세트 입력 UX**: 리스트 자동 확장 방식
  - 입력 완료 시 다음 세트 행 자동 생성
  - 빈 행은 저장되지 않음
  - 한 화면에서 모든 세트 확인 가능
- 선택: RPE(체감 난이도 1–10), 메모

### 2.2 스톱워치 / 타이머 (유틸리티)

- 세트와 연동되지 않는 독립적인 유틸리티
- 앱 어디서든 접근 가능 (플로팅 버튼 또는 앱바)
- **두 가지 모드 제공:**
  - **스톱워치 모드**: 경과 시간 측정, 시작/일시정지/리셋
  - **타이머 모드**: 목표 시간 설정 (예: 90초), 카운트다운 후 알림
- 앱이 백그라운드로 전환되어도 유지 (로컬 알림 활용)
- 타이머 완료 시 진동 + 알림

### 2.3 진행상황 차트

- 운동별 최고 기록(1RM 추정치 또는 최고 중량) 추세 그래프
- 운동별 총 볼륨(무게 × 횟수 × 세트) 추세 그래프
- 기간 필터: 1개월 / 3개월 / 6개월 / 전체
- **1RM 계산 공식**: Epley 공식 사용 — `1RM = weight × (1 + reps / 30)`

### 2.4 바디 프로필 / 체중

- 날짜별 체중, 체지방률(선택), 골격근량(선택) 입력
- 체중 추세 그래프 (기간 필터 동일)
- 체중 단위: kg ↔ lbs 전환 (설정에서 변경, 전체 앱에 즉시 반영)

### 2.5 운동 종목 관리 (설정)

- 기본 제공 종목 5가지 (수정 가능, 삭제 불가)
- 커스텀 종목 추가 / 이름 수정 / 삭제
- 종목별 카테고리 및 주요 근육군 설정

**기본 제공 운동 종목:**

| 이름 | 카테고리 | 주요 근육 |
|---|---|---|
| 벤치프레스 (Bench Press) | 가슴 | 대흉근, 삼두근 |
| 스쿼트 (Squat) | 하체 | 대퇴사두근, 둔근 |
| 데드리프트 (Deadlift) | 등 | 척추기립근, 햄스트링 |
| 오버헤드프레스 (OHP) | 어깨 | 삼각근, 삼두근 |
| 풀업 (Pull-up) | 등 | 광배근, 이두근 |

### 2.6 설정 (Settings)

| 설정 항목 | 상세 |
|---|---|
| 체중 단위 | kg / lbs 전환 |
| 테마 | 라이트 / 다크 / 시스템 따름 |
| 언어 | 한국어 / English |
| 운동 종목 관리 | 이름 수정, 커스텀 종목 추가/삭제 |
| 데이터 초기화 | 전체 데이터 삭제 (확인 다이얼로그 필수) |

---

## 3. 화면 구조 (Navigation)

```
Bottom Navigation Bar (4탭)
├── 🏠 홈          → 오늘 세션 요약 + [운동 시작] 버튼
├── 📅 기록        → 캘린더 + 날짜별 세션 조회
├── 📊 통계        → 운동별 진행상황 차트
└── 👤 바디        → 체중/체성분 기록 및 차트
```

### 화면 목록

| 화면 | 경로 | 설명 |
|---|---|---|
| HomeScreen | `/` | 오늘 요약, 빠른 시작 |
| WorkoutSessionScreen | `/session/:id` | 세션 내 운동 입력 |
| ExercisePickerScreen | `/exercise-picker` | 종목 선택 모달 |
| TimerOverlay | (플로팅/오버레이) | 스톱워치 + 타이머 (모드 전환) |
| HistoryScreen | `/history` | 캘린더 기록 조회 |
| ProgressScreen | `/progress` | 진행상황 차트 |
| ExerciseDetailScreen | `/progress/:exerciseId` | 종목별 상세 차트 |
| BodyScreen | `/body` | 바디 프로필 |
| BodyEntryScreen | `/body/entry` | 체중/체성분 입력 |
| SettingsScreen | `/settings` | 설정 |
| ExerciseManageScreen | `/settings/exercises` | 종목 관리 |

### 운동 기록 플로우

```
홈 화면
  └─[운동 시작] 탭
      └─ WorkoutSessionScreen (새 세션 생성)
          ├─ [+ 운동 추가] → ExercisePickerScreen (모달)
          │     └─ 종목 선택 → 세션으로 복귀
          ├─ 세트 입력 (리스트 자동 확장)
          │     ├─ Set 1: [무게] × [횟수] 입력
          │     ├─ Set 2: [무게] × [횟수] 입력 ← 자동 생성
          │     └─ Set N: [    ] × [    ] ← 빈 행 대기
          └─[운동 종료] 탭
                └─ 세션 요약 화면 → 홈으로 이동

⏱️ 스톱워치/타이머: 플로팅 버튼으로 앱 어디서든 접근 가능 (세션과 독립)
   - 스톱워치 모드: 경과 시간 측정
   - 타이머 모드: 목표 시간 설정 → 완료 시 알림
```

---

## 4. 아키텍처

### 4.1 레이어 구조

```
lib/
├── main.dart
├── app/
│   ├── app.dart                  # MaterialApp, 테마 설정
│   └── router.dart               # GoRouter 라우트 정의
│
├── core/
│   ├── database/
│   │   ├── app_database.dart     # Drift DB 인스턴스 정의
│   │   ├── tables/               # Drift 테이블 정의
│   │   │   ├── exercises_table.dart
│   │   │   ├── workout_sessions_table.dart
│   │   │   ├── workout_sets_table.dart
│   │   │   └── body_records_table.dart
│   │   └── daos/                 # Data Access Objects
│   │       ├── exercise_dao.dart
│   │       ├── workout_dao.dart
│   │       └── body_dao.dart
│   ├── sync/
│   │   └── sync_service.dart     # 클라우드 동기화 추상 인터페이스 (향후 구현)
│   ├── constants/
│   │   └── default_exercises.dart  # 기본 5종목 데이터
│   └── utils/
│       ├── weight_converter.dart   # kg ↔ lbs 변환
│       └── date_utils.dart
│
├── features/
│   ├── workout/
│   │   ├── data/
│   │   │   └── workout_repository.dart
│   │   ├── domain/
│   │   │   └── workout_models.dart
│   │   └── presentation/
│   │       ├── home_screen.dart
│   │       ├── session_screen.dart
│   │       └── history_screen.dart
│   ├── exercise/
│   │   ├── data/
│   │   │   └── exercise_repository.dart
│   │   ├── domain/
│   │   │   └── exercise_models.dart
│   │   └── presentation/
│   │       ├── exercise_picker_screen.dart
│   │       └── exercise_manage_screen.dart
│   ├── timer/
│   │   ├── timer_service.dart        # 스톱워치 + 타이머 로직, 알림 관리
│   │   └── presentation/
│   │       └── timer_overlay.dart    # 모드 전환 UI (스톱워치 ↔ 타이머)
│   ├── progress/
│   │   ├── data/
│   │   │   └── progress_repository.dart
│   │   └── presentation/
│   │       ├── progress_screen.dart
│   │       └── exercise_detail_screen.dart
│   ├── body/
│   │   ├── data/
│   │   │   └── body_repository.dart
│   │   ├── domain/
│   │   │   └── body_models.dart
│   │   └── presentation/
│   │       ├── body_screen.dart
│   │       └── body_entry_screen.dart
│   └── settings/
│       └── presentation/
│           └── settings_screen.dart
│
└── shared/
    ├── widgets/
    │   ├── weight_input_widget.dart   # kg/lbs 자동 변환 입력 필드
    │   ├── set_row_widget.dart        # 세트 행 UI
    │   └── chart_card_widget.dart     # 공통 차트 카드
    └── theme/
        ├── app_theme.dart             # 라이트/다크 테마 정의
        └── app_colors.dart
```

### 4.2 상태 관리: Riverpod

- `StateNotifierProvider` / `AsyncNotifierProvider` 사용
- Repository 패턴으로 데이터 레이어 추상화
- 클라우드 확장 시 `LocalRepository` → `CloudRepository` 교체만으로 대응

### 4.3 로컬 DB: Drift (SQLite)

- 타입 세이프 ORM, Flutter 네이티브 SQLite 위에 동작
- 모든 테이블에 `syncStatus`, `updatedAt` 컬럼 포함 → Offline-first 동기화 준비

---

## 5. 데이터베이스 스키마

### exercises

```sql
CREATE TABLE exercises (
  id           TEXT PRIMARY KEY,      -- UUID v4
  name         TEXT NOT NULL,
  category     TEXT NOT NULL,         -- '가슴'|'등'|'하체'|'어깨'|'팔'|'유산소'|'기타'
  muscle_group TEXT,
  is_default   INTEGER NOT NULL DEFAULT 0,  -- 1 = 기본 제공 종목 (삭제 불가)
  is_active    INTEGER NOT NULL DEFAULT 1,
  created_at   TEXT NOT NULL,         -- ISO 8601
  updated_at   TEXT NOT NULL,
  sync_status  TEXT NOT NULL DEFAULT 'pending'  -- 'synced'|'pending'|'deleted'
);
```

### workout_sessions

```sql
CREATE TABLE workout_sessions (
  id         TEXT PRIMARY KEY,
  date       TEXT NOT NULL,           -- YYYY-MM-DD
  note       TEXT,
  duration   INTEGER,                 -- 분 단위, 세션 종료 시 기록
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  sync_status TEXT NOT NULL DEFAULT 'pending'
);
```

### workout_sets

```sql
CREATE TABLE workout_sets (
  id          TEXT PRIMARY KEY,
  session_id  TEXT NOT NULL REFERENCES workout_sessions(id) ON DELETE CASCADE,
  exercise_id TEXT NOT NULL REFERENCES exercises(id),
  set_number  INTEGER NOT NULL,
  reps        INTEGER NOT NULL,
  weight_kg   REAL NOT NULL,          -- 항상 kg으로 저장, 표시 시 변환
  rpe         INTEGER,                -- 1~10, 선택
  rest_seconds INTEGER,               -- 실제 쉰 시간 (선택, 수동 입력 또는 향후 확장용)
  created_at  TEXT NOT NULL,
  updated_at  TEXT NOT NULL,
  sync_status TEXT NOT NULL DEFAULT 'pending'
);
```

> ⚠️ **설계 결정:** 무게는 항상 kg으로 DB에 저장. UI 표시/입력 시에만 lbs 변환 적용.  
> 단위 변경 시 DB 마이그레이션 불필요, 변환 로직 한 곳에서 관리.

### body_records

```sql
CREATE TABLE body_records (
  id           TEXT PRIMARY KEY,
  date         TEXT NOT NULL,         -- YYYY-MM-DD
  weight_kg    REAL NOT NULL,         -- 항상 kg으로 저장
  body_fat_pct REAL,                  -- 체지방률 %, 선택
  muscle_mass_kg REAL,                -- 골격근량 kg, 선택
  note         TEXT,
  created_at   TEXT NOT NULL,
  updated_at   TEXT NOT NULL,
  sync_status  TEXT NOT NULL DEFAULT 'pending'
);
```

---

## 6. 주요 패키지

| 용도 | 패키지 | 버전 (초기 기준) |
|---|---|---|
| 상태 관리 | `flutter_riverpod` | ^2.x |
| 로컬 DB | `drift` + `drift_flutter` | ^2.x |
| 라우팅 | `go_router` | ^13.x |
| 차트 | `fl_chart` | ^0.68.x |
| 캘린더 | `table_calendar` | ^3.x |
| 로컬 알림 (타이머) | `flutter_local_notifications` | ^17.x |
| UUID 생성 | `uuid` | ^4.x |
| 날짜/시간 + i18n | `intl` + `flutter_localizations` | ^0.19.x |
| 공유 설정 저장 | `shared_preferences` | ^2.x |

---

## 7. 향후 클라우드 동기화 확장 전략

### 설계 원칙 (지금부터 적용)

1. **Repository 인터페이스 추상화**
   ```dart
   abstract class WorkoutRepository {
     Future<List<WorkoutSession>> getSessions();
     Future<void> saveSet(WorkoutSet set);
     // ...
   }
   
   class LocalWorkoutRepository implements WorkoutRepository { ... }
   // 향후: class CloudWorkoutRepository implements WorkoutRepository { ... }
   ```

2. **`sync_status` 컬럼으로 변경 추적**
   - `pending` → 로컬에만 있음, 동기화 필요
   - `synced` → 클라우드와 일치
   - `deleted` → 소프트 삭제 (클라우드 삭제 전까지 유지)

3. **UUID 사용** → 서버 측 ID 충돌 없음

4. **향후 고려 백엔드 옵션**
   - Firebase Firestore (빠른 구현, 소규모 적합)
   - Supabase (오픈소스, PostgreSQL 기반)

---

## 8. 개발 우선순위 (MVP 단계)

### Phase 1 — 핵심 기능
- [ ] 프로젝트 초기 세팅 (Drift DB, Riverpod, GoRouter)
- [ ] DB 스키마 + 기본 종목 시드 데이터
- [ ] 운동 세션 생성 및 세트 입력 화면 (리스트 자동 확장 UX)
- [ ] 스톱워치 / 타이머 (플로팅 버튼, 모드 전환, 알림)

### Phase 2 — 조회 및 분석
- [ ] 캘린더 기반 기록 조회
- [ ] 진행상황 차트 (fl_chart)
- [ ] 바디 프로필 + 체중 추세

### Phase 3 — 설정 및 마무리
- [ ] 설정 화면 (단위 전환, 테마, 종목 관리)
- [ ] 다크모드 완성
- [ ] 데이터 초기화 기능
- [ ] UI/UX polish + 접근성

### Phase 4 — 확장 (MVP 이후)
- [ ] 루틴 템플릿 기능
- [ ] 데이터 내보내기 (CSV/JSON)
- [ ] 클라우드 동기화

---

## 9. 주요 설계 결정 및 근거

| 결정 | 근거 |
|---|---|
| 무게를 항상 kg으로 저장 | 단위 전환 시 DB 마이그레이션 불필요, 변환 로직 단일화 |
| UUID를 PK로 사용 | 오프라인 생성 후 클라우드 동기화 시 충돌 없음 |
| `sync_status` 컬럼 도입 | 향후 Offline-first 동기화 구현 시 변경 추적 기반 |
| Riverpod 선택 | Provider보다 명확한 의존성, 테스트 용이, 비동기 처리 우수 |
| Drift 선택 | 타입 세이프, 마이그레이션 관리, Stream 지원으로 UI 자동 갱신 |
| 스톱워치/타이머를 시작 시각 기록 방식으로 구현 | 앱 종료/재시작 후에도 경과/남은 시간 계산 가능 |
| 스톱워치/타이머를 세트와 분리 | 유틸리티로 언제든 접근 가능, UX 유연성 확보 |
| 세트 입력을 리스트 자동 확장 방식으로 구현 | 구글 시트와 유사한 UX, 탭 최소화, 한눈에 확인 가능 |
| Epley 공식으로 1RM 계산 | 가장 보편적, 계산 단순, 10회 이하에서 정확도 높음 |
| 통합 테스트 중심 | 실제 사용 시나리오 검증에 집중 |

---

## 10. 입력값 유효성 검사

| 항목 | 규칙 |
|---|---|
| 무게 (weight) | 소수점 허용, 상한 300kg / 660lbs, 하한 0 |
| 횟수 (reps) | 정수, numeric 검증 |
| 세트 번호 | 정수, numeric 검증 |
| RPE | 1~10 정수, 선택 입력 |
| 체중 | 소수점 허용, 상한 300kg / 660lbs |
| 체지방률 | 0~100%, 소수점 허용 |

---

## 11. 테스트 전략

- **통합 테스트 (Integration Test)** 중심으로 진행
- 주요 사용자 플로우별 테스트 시나리오:
  - 운동 세션 생성 → 세트 입력 → 타이머 → 세션 종료
  - 체중 기록 → 추세 차트 확인
  - 설정 변경 (단위 전환, 테마)
- 테스트 위치: `integration_test/`

---

## 12. 다국어 지원 (i18n)

- **지원 언어**: 한국어 (ko), English (en)
- **기본 언어**: 시스템 언어 따름, 설정에서 변경 가능
- **구현 방식**: `flutter_localizations` + ARB 파일
- **파일 구조**:
  ```
  lib/l10n/
  ├── app_ko.arb    # 한국어
  └── app_en.arb    # English
  ```

---

## 13. Claude Code 프로젝트 시작 가이드

### 프로젝트 생성
```bash
flutter create gymlog --org com.haksoo.kim.gymlog --platforms ios,android
cd gymlog
```

### 초기 패키지 추가 (`pubspec.yaml`)
```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5
  drift: ^2.18.0
  drift_flutter: ^0.2.1
  go_router: ^13.2.0
  fl_chart: ^0.68.0
  table_calendar: ^3.1.2
  flutter_local_notifications: ^17.2.2
  uuid: ^4.4.0
  intl: ^0.19.0
  shared_preferences: ^2.2.3

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.9
  drift_dev: ^2.18.0
  riverpod_generator: ^2.4.0
  custom_lint: ^0.6.4
  riverpod_lint: ^2.3.9
```

### Claude Code 권장 작업 순서
1. `GYMLOG_PROJECT_SPEC.md` 를 프로젝트 루트에 추가
2. `core/database/` 레이어부터 구현 (테이블 → DAO → Repository)
3. `build_runner`로 Drift 코드 생성 확인
4. Feature별로 Repository → Provider → Screen 순서로 구현
5. 각 Phase 완료 후 실기기/시뮬레이터 테스트
