# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 개발 규칙

1. 코드는 Hexagonal Architecture를 준수하여 작성하며, Port와 Adapter의 역할을 명확히 분리한다.
2. 하나의 클래스는 하나의 책임만 가지도록 설계한다. (SRP)
3. 클래스가 과도한 책임을 가지지 않도록 한다.
4. 주요 비즈니스 코드 작성 시 반드시 테스트 코드를 함께 작성한다.
5. 테스트 코드는 정상 흐름과 예외/실패 케이스를 모두 포함해야 한다.
6. 테스트는 구현이 아닌 동작(Behavior) 중심으로 작성한다.
7. 코드 작성 후 모든 테스트가 성공할 때까지 `flutter test`를 실행한다.
8. 코드 작성 후 lint 경고가 없을 때까지 `flutter analyze`를 실행한다.

## 개발 명령어

```bash
# 패키지 설치
flutter pub get

# 앱 실행
flutter run

# 전체 테스트
flutter test

# 단일 테스트 파일 실행
flutter test test/application/use_case/save_diary_use_case_test.dart
달
# 정적 분석
flutter analyze

# 빌드 (Android)
flutter build apk
```

## 아키텍처

Hexagonal Architecture(Ports & Adapters)를 적용했다. 의존성 방향은 항상 **바깥 → 안**이다.

```
Presentation → Application → Domain ← Infrastructure
```

### 레이어별 책임

| 레이어 | 경로 | 책임 |
|--------|------|------|
| **Domain** | `lib/domain/` | 비즈니스 규칙. 외부 의존 없음. Entity, Value Object, Repository Interface(Port) |
| **Application** | `lib/application/` | UseCase 단위 비즈니스 흐름 조율. Domain에만 의존 |
| **Infrastructure** | `lib/infrastructure/` | SQLite Adapter. DiaryRepository 구현체, DTO/Mapper |
| **Presentation** | `lib/presentation/` | Riverpod Provider + Flutter Widget. UseCase를 통해서만 데이터 접근 |
| **Core** | `lib/core/` | 전 레이어 공유 유틸. `Failure` sealed class, `isEditableDate` 유틸 |
| **DI** | `lib/core/di/providers.dart` | Riverpod Provider 정의. 전체 DI 연결 지점 |

### 핵심 도메인 규칙

- **수정 가능 날짜**: 오늘은 항상 가능, 어제 날짜는 오늘 15시 이전까지만 작성·수정 가능 (`core/utils/date_utils.dart:isEditableDate`)
- **감정 선택**: 1~3개, 중복 불허 (`domain/value_object/emotions_selection.dart`)
- **메모**: 옵셔널, 500자 제한 — 도메인과 UseCase 두 레벨에서 검증
- **날짜 비교**: 반드시 로컬 시간 기준, `toLocalDate()`로 정규화 후 비교

### 데이터 흐름

```
UI 이벤트
  → Riverpod Notifier (presentation/provider/)
    → UseCase (application/use_case/)
      → DiaryRepository interface (domain/repository/)
        ← DiaryRepositoryImpl (infrastructure/repository/)
          → DiaryLocalDataSource (infrastructure/datasource/) — sqflite
```

### SQLite 주의사항

- `DiaryLocalDataSource`는 싱글턴. DB 버전은 `_dbVersion` 상수로 관리
- `_onUpgrade`에서 테이블 drop & recreate로 마이그레이션
- sqflite가 Android에서 TEXT 컬럼을 `int`로 반환하는 경우가 있어 `DiaryEntryDto.fromMap`의 `_str()` 헬퍼를 통해 방어적으로 변환
- `emotions` 컬럼은 JSON 배열(`["happy","sad"]`) 형태로 저장

### Riverpod Provider 구조

- `selectedMonthProvider` — 현재 표시 중인 월 (StateProvider)
- `monthlyDiaryProvider` — 월별 일기 Map (FutureProvider.autoDispose). 저장 후 `ref.invalidate`로 캐시 갱신
- `saveDiaryProvider` — 저장 상태 머신 (NotifierProvider). `SaveDiaryIdle → Loading → Success/Error`
- `diaryByDateProvider` — 특정 날짜 조회 (FutureProvider.family)

## 기술 스택

- **상태관리**: flutter_riverpod 2.x
- **DB**: sqflite 2.x (경로: `path` 패키지)
- **날짜 포맷**: intl (한국어 로케일 `'ko'` 사용)
- **ID 생성**: uuid v4
- **테스트 Mock**: mocktail

## 테스트 구조

테스트는 Domain/Application 레이어 위주로 작성되어 있다. `mocktail`로 `DiaryRepository`를 Mock하며, `final class`는 `implements` 불가이므로 `registerFallbackValue`에 직접 인스턴스를 전달한다.

```
test/
├── core/utils/date_utils_test.dart
├── domain/value_object/emotions_selection_test.dart
└── application/use_case/
    ├── save_diary_use_case_test.dart        # 날짜 검증, 메모 검증, save/update 분기
    ├── get_diary_by_date_use_case_test.dart
    └── get_monthly_diary_use_case_test.dart
```
