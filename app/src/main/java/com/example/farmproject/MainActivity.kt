package com.example.farmproject

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import com.example.farmproject.ui.navigation.AppNavigation
import com.example.farmproject.ui.theme.FarmProjectTheme

class MainActivity : ComponentActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        setContent {

            FarmProjectTheme {

                AppNavigation()
            }
        }
    }
}