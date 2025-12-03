package app.maypole.maypole

import android.os.Bundle
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Install the splash screen before calling super.onCreate()
        installSplashScreen()
        super.onCreate(savedInstanceState)
    }
}
