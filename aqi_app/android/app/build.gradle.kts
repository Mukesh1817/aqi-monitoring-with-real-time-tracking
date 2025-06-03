plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.aqi_app"
    compileSdk = 35
    ndkVersion = "29.0.13113456"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        
        applicationId = "com.example.aqi_app"
        minSdk = 21
        targetSdk = 35
        versionCode = 1
        versionName = "1.0"
        multiDexEnabled = true 
    }

     buildTypes {
    release {
        signingConfig = signingConfigs.getByName("debug") // Temporary
        isMinifyEnabled = false  // Keep minification off
        isShrinkResources = false  // Disable resource shrinking explicitly
        proguardFiles(
            getDefaultProguardFile("proguard-android-optimize.txt"),
            "proguard-rules.pro"
        )
    }
}
packagingOptions {
        resources.excludes += setOf(
            "/META-INF/{AL2.0,LGPL2.1}",
            "**/lib/**/libflutter.so"  // Add if you see .so file conflicts
        )
        jniLibs.useLegacyPackaging = true  // Fixes NDK library loading
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
    kotlinOptions {
        jvmTarget = "11"
    }
}

flutter {
    source = "../.."
}
