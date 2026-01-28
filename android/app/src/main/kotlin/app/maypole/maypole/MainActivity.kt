package app.maypole.maypole

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Install the splash screen before calling super.onCreate()
        installSplashScreen()
        
        // Enable edge-to-edge display for Android 15+ compatibility
        // This ensures proper inset handling and backward compatibility
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            WindowCompat.setDecorFitsSystemWindows(window, false)
        }
        
        super.onCreate(savedInstanceState)
        
        // Create notification channels for Android 8.0+
        createNotificationChannels()
    }
    
    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
            
            // Channel for Direct Messages
            val dmChannel = NotificationChannel(
                "dm_messages",
                "Direct Messages",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notifications for direct messages"
                enableVibration(true)
                enableLights(true)
                // Allow notifications to stack/group
                setShowBadge(true)
            }
            
            // Channel for Tag Mentions
            val tagChannel = NotificationChannel(
                "tag_mentions",
                "Tag Mentions",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notifications when you're tagged in a maypole"
                enableVibration(true)
                enableLights(true)
                setShowBadge(true)
            }
            
            // Create the channels
            notificationManager.createNotificationChannel(dmChannel)
            notificationManager.createNotificationChannel(tagChannel)
        }
    }
}
