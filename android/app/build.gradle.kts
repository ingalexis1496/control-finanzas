plugins {
    id("com.android.application")
    // El Flutter Gradle Plugin debe ir después de los plugins de Android y Kotlin
    id("dev.flutter.flutter-gradle-plugin")
    // ELIMINA la línea de 'version ... apply false' de aquí y déjala solo en la raíz. Aquí solo va:
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.control_gastos_pareja"
    compileSdk = flutter.compileSdkVersion
    
    ndkVersion = "30.0.16138531"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.example.control_gastos_pareja"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
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

// Añade este bloque de dependencias al final de todo el archivo:
dependencies {
    implementation(platform("com.google.firebase:firebase-bom:33.9.0"))
    implementation("com.google.firebase:firebase-firestore")
}