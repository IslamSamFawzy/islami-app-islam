import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing is read from android/key.properties (kept out of git — see
// .gitignore and docs/release/signing.md). A release build without it used to
// fall back to the debug key, which produces an artifact that looks fine and
// can never be uploaded; now it fails instead.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

/** Reads a required entry, naming the file and the key when it is missing. */
fun keystoreProperty(name: String): String {
    val value = keystoreProperties[name] as String?
    require(!value.isNullOrBlank()) {
        "android/key.properties is missing \"$name\". " +
            "See docs/release/signing.md."
    }
    return value
}

android {
    namespace = "com.thecofounderstudio.islami"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Required by flutter_local_notifications (Java 8+ time APIs).
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.thecofounderstudio.islami"
        // flutter.minSdkVersion resolves to 24 on this toolchain (>= the 23 that
        // geolocator + flutter_local_notifications need), so no explicit pin.
        minSdk = flutter.minSdkVersion
        // Play requires 36 for new apps. The toolchain default is 36 today;
        // pinning it means a Flutter downgrade cannot quietly lower it.
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        // Only defined when a real keystore is configured. Without one the
        // release build fails (see the check below) rather than quietly
        // producing a debug-signed artifact.
        if (hasReleaseKeystore) {
            create("release") {
                storeFile = file(keystoreProperty("storeFile"))
                storePassword = keystoreProperty("storePassword")
                keyAlias = keystoreProperty("keyAlias")
                keyPassword = keystoreProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            if (hasReleaseKeystore) {
                signingConfig = signingConfigs.getByName("release")
            }

            // Shrink & obfuscate with R8. proguard-rules.pro keeps the classes
            // that plugins reach by reflection (flutter_local_notifications/Gson).
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

// A release artifact signed with the debug key looks fine and can never be
// uploaded, so stop the build instead of producing one. Debug builds are
// unaffected.
gradle.taskGraph.whenReady {
    val buildingRelease = allTasks.any {
        it.name == "assembleRelease" || it.name == "bundleRelease"
    }
    if (buildingRelease && !hasReleaseKeystore) {
        throw GradleException(
            "Release builds need android/key.properties, which is missing. " +
                "See docs/release/signing.md for how to create the upload " +
                "keystore and what to put in that file.",
        )
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
