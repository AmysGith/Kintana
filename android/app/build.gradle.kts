plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin") // Flutter Gradle plugin
    id("com.google.gms.google-services")    // Firebase
}

android {
    namespace = "com.amy.kintana"
    compileSdk = 34 // ou flutter.compileSdkVersion si défini dans gradle.properties
    ndkVersion = "25.1.8937393" // ou flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.amy.kintana"
        minSdk = 21 // ou flutter.minSdkVersion
        targetSdk = 34 // ou flutter.targetSdkVersion
        versionCode = 1
        versionName = "1.0.0"
    }

    signingConfigs {
        create("release") {
            storeFile = file("kintana_keystore.jks")
            storePassword = "EUs4BN%K6cPM"
            keyAlias = "kintana_key"
            keyPassword = "EUs4BN%K6cPM"
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        getByName("debug") {
            signingConfig = signingConfigs.getByName("release")
        }
    }

    // Optionnel : déplace le build folder si tu veux
    val newBuildDir = rootProject.layout.buildDirectory.dir("../../build").get()
    rootProject.layout.buildDirectory.value(newBuildDir)

    subprojects {
        val newSubprojectBuildDir = newBuildDir.dir(project.name)
        project.layout.buildDirectory.value(newSubprojectBuildDir)
    }

    subprojects {
        project.evaluationDependsOn(":app")
    }
}

flutter {
    source = "../.."
}
