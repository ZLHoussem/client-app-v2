plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "bladi_go_client"
    compileSdk = 34 // Mettez à jour si nécessaire

    defaultConfig {
        applicationId = "bladi_go_client"
        minSdk = 21 // Gardez cette valeur
        targetSdk = 34 // Mettez à jour si nécessaire
        versionCode = 2
        versionName = "2.0.0"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17 // Mettez à jour ici
        targetCompatibility = JavaVersion.VERSION_17 // Mettez à jour ici
    }

    kotlinOptions {
        jvmTarget = "17" // Mettez à jour ici
    }

    signingConfigs {
        create("release") {
            storeFile = file("C:\\upload-keystore.jks")
            storePassword = "android"
            keyAlias = "upload"
            keyPassword = "android"
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}