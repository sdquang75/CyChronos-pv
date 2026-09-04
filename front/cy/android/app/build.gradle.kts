import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Google Maps のAPIキーは local.properties(git管理外)の MAPS_API_KEY から読む。
// 例: android/local.properties に「MAPS_API_KEY=AIza...」を1行追加する
val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.inputStream().use { localProperties.load(it) }
}
val mapsApiKey: String = localProperties.getProperty("MAPS_API_KEY") ?: ""

// キーが無くてもビルドは通ってしまい、実行して初めて「Googleロゴだけの灰色の地図」に気づく。
// 気づくのが遅れるとバグ調査に時間を取られるので、ビルド時にはっきり知らせる。
//
// flutter コマンドは Gradle を -q(QUIETレベル)で呼ぶため logger.warn は表示されない。
// QUIETレベルでも出る logger.quiet を使う
if (mapsApiKey.isBlank()) {
    logger.quiet(
        """
        |
        |============================================================
        | 警告: MAPS_API_KEY が設定されていません
        |------------------------------------------------------------
        | ルート確認・ナビ画面の地図が表示されません
        | (Googleのロゴだけが出た灰色の画面になります)
        |
        | android/local.properties に次の1行を追加してください:
        |   MAPS_API_KEY=AIza...
        |
        | キーはGoogle Cloudで「Maps SDK for Android」を有効化して発行します
        |============================================================
        |
        """.trimMargin()
    )
}

android {
    namespace = "com.cychronos.cy"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.cychronos.cy"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // AndroidManifest.xml の ${MAPS_API_KEY} をここで差し込む
        manifestPlaceholders["MAPS_API_KEY"] = mapsApiKey
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
