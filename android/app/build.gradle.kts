import java.io.File

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Provision credentials externally; never commit a keystore or print these values.
val uploadStore = providers.environmentVariable("HILDORS_UPLOAD_STORE_FILE").orNull
val uploadStorePassword = providers.environmentVariable("HILDORS_UPLOAD_STORE_PASSWORD").orNull
val uploadAlias = providers.environmentVariable("HILDORS_UPLOAD_KEY_ALIAS").orNull
val uploadKeyPassword = providers.environmentVariable("HILDORS_UPLOAD_KEY_PASSWORD").orNull
val uploadConfigured = listOf(uploadStore, uploadStorePassword, uploadAlias, uploadKeyPassword)
    .all { !it.isNullOrBlank() }
val validateReleaseSigning = tasks.register("validateReleaseSigningCredentials") {
    doLast {
        check(uploadConfigured) {
            "Release signing requires all four HILDORS_UPLOAD_* environment variables. No debug fallback is permitted."
        }
        check(File(uploadStore!!).isAbsolute && File(uploadStore!!).isFile) {
            "HILDORS_UPLOAD_STORE_FILE must identify an existing absolute external keystore path."
        }
    }
}
// Runs for direct Gradle and Flutter release invocations, including bundle and APK tasks.
tasks.configureEach {
    if (name.contains("Release", ignoreCase = true) && name != "validateReleaseSigningCredentials") {
        dependsOn(validateReleaseSigning)
    }
}

android {
    namespace = "com.hildors.hildors_cockpit"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Existing identifier retained; confirm ownership before first store registration.
        applicationId = "com.hildors.hildors_cockpit"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = 36 // Google Play new apps/updates: API 36 since 2026-08-31.
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("upload") {
            if (uploadConfigured) {
                storeFile = File(uploadStore!!)
                storePassword = uploadStorePassword
                keyAlias = uploadAlias
                keyPassword = uploadKeyPassword
            }
        }
    }

    buildTypes {
        release {
            // Missing upload credentials deliberately prevent release packaging.

            signingConfig = signingConfigs.getByName("upload")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
