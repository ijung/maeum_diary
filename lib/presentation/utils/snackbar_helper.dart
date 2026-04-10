import 'package:flutter/material.dart';

/// 플로팅 스낵바를 표시한다. 기존 스낵바를 먼저 제거 후 표시한다.
void showFloatingSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
            SnackBar(
                content: Text(message),
                behavior: SnackBarBehavior.floating,
            ),
        );
}
