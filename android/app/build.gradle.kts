plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.watch.otakunexa"
    compileSdk = 36 
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.watch.otakunexa"
        minSdk = 23             
        targetSdk = 35 
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

   packaging {
        jniLibs {
            // These lines prevent the native libraries from being stripped, 
            // which is necessary for media_kit (libmpv.so) to work.
            pickFirsts += setOf(
                "*/libmpv.so",
                "*/libmedia_kit_core.so",
                "*/libmedia_kit_libs.so",
                "*/libmedia_kit_plugin.so",
            )
            useLegacyPackaging = true // Recommended for older AGP versions
        }
    }
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}