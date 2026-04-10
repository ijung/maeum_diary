import 'package:flutter/material.dart';

/// 라이트 모드 전용 색상 상수
///
/// 다크 모드에서는 Material 3 colorScheme을 그대로 사용한다.
/// 라이트 모드 분기 시 `isDark ? colorScheme.xxx : AppColors.xxx` 패턴으로 사용한다.
abstract final class AppColors {
    /// 화면 배경
    static const Color background = Color(0xFFF5F0E8);

    /// 제목 및 주요 텍스트
    static const Color titleText = Color(0xFF5C4033);

    /// 주요 강조 (아이콘, 버튼, 선택 항목)
    static const Color primary = Color(0xFF8D6E63);

    /// 보조 텍스트
    static const Color subText = Color(0xFF6D4C41);

    /// 카드/컨테이너 테두리
    static const Color cardBorder = Color(0xFFD7C4A8);

    /// 선택된 항목 배경
    static const Color selectedBg = Color(0xFFEDE0D4);

    /// 날짜 셀 배경 (오늘)
    static const Color todayCellBg = Color(0xFFFFF8F0);

    /// 섹션 헤더 배경
    static const Color headerBg = Color(0xFFF0E6D8);
}
