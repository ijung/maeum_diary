package com.amine.maeum_diary

import android.os.Bundle
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Android 15 edge-to-edge: 시스템 바 영역까지 앱 콘텐츠를 확장
        WindowCompat.setDecorFitsSystemWindows(window, false)
    }
}
