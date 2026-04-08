package com.amine.maeum_diary

import android.os.Bundle
import androidx.activity.enableEdgeToEdge
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Flutter 초기화(super.onCreate) 전에 호출해야 window가 edge-to-edge로 먼저 구성됨
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
    }
}
