plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.compose)
    alias(libs.plugins.kotlin.serialization)
}

android {
    namespace = "com.artesoft.brasspawn"
    compileSdk = 37
    ndkVersion = "27.1.12297006"

    defaultConfig {
        applicationId = "com.artesoft.brasspawn"
        minSdk = 26
        targetSdk = 36
        versionCode = 1
        versionName = "1.5.0"

        ndk {
            // arm64 phones, tablets and the Apple-silicon emulator. Add x86_64 with -Pabis=arm64-v8a,x86_64.
            abiFilters += (providers.gradleProperty("abis").orNull ?: "arm64-v8a").split(",")
        }
        externalNativeBuild {
            cmake {
                arguments += listOf("-DANDROID_STL=c++_static", "-DCMAKE_BUILD_TYPE=Release")
            }
        }
    }

    // Debug builds made on another machine can keep the same signature (and so update an installed app):
    //   ./gradlew assembleDebug -PdebugKeystore=/path/to/debug.keystore
    providers.gradleProperty("debugKeystore").orNull?.let { path ->
        signingConfigs.getByName("debug").storeFile = file(path)
    }

    buildTypes {
        debug {
            // Online play. The development server (CloudRush: cmd/brasspawn-dev) on the machine running the
            // emulator is the default; override with -PonlineBaseUrl=https://host:port
            val online = providers.gradleProperty("onlineBaseUrl").orNull ?: "http://10.0.2.2:8787"
            buildConfigField("String", "ONLINE_BASE_URL", "\"$online\"")
            buildConfigField("boolean", "INTERNAL_TOOLS", "true")
        }
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            buildConfigField("String", "ONLINE_BASE_URL", "\"https://chat-api.wonek.com:5433\"")
            buildConfigField("boolean", "INTERNAL_TOOLS", "false")
        }
    }

    externalNativeBuild {
        cmake {
            path = file("src/main/cpp/CMakeLists.txt")
            version = "3.22.1"
        }
    }

    buildFeatures {
        compose = true
        buildConfig = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    androidResources {
        // Networks are copied out with openFd, and the big JSON libraries are parsed straight from the APK.
        noCompress += listOf("nnue", "json")
    }
}

dependencies {
    implementation(project(":core"))
    implementation(libs.androidx.core.ktx)
    implementation(libs.androidx.activity.compose)
    implementation(libs.androidx.lifecycle.viewmodel.compose)
    implementation(libs.androidx.lifecycle.runtime.compose)
    implementation(libs.androidx.lifecycle.process)
    implementation(platform(libs.compose.bom))
    implementation(libs.compose.ui)
    implementation(libs.compose.ui.tooling.preview)
    implementation(libs.compose.material3)
    debugImplementation(libs.compose.ui.tooling)
    implementation(libs.kotlinx.serialization.json)
    implementation(libs.kotlinx.coroutines.android)
    implementation(libs.kotlinx.coroutines.play.services)
    implementation(libs.play.services.cronet)
    testImplementation("junit:junit:4.13.2")
}

// Everything the app shows that already exists in this repository is taken from where it lives — the
// puzzle libraries in /data, the photographed pieces, sounds, fonts and networks of the iOS app, and its
// string catalog — rather than copied into android/. One task gathers it as generated assets.
abstract class GatherAssets : DefaultTask() {
    @get:Internal abstract val repo: DirectoryProperty
    @get:InputFiles @get:PathSensitive(PathSensitivity.RELATIVE) abstract val sources: ConfigurableFileCollection
    @get:InputFile @get:PathSensitive(PathSensitivity.NONE) abstract val stringsScript: RegularFileProperty
    @get:InputDirectory @get:PathSensitive(PathSensitivity.RELATIVE) abstract val androidStrings: DirectoryProperty
    @get:OutputDirectory abstract val outputDir: DirectoryProperty
    @get:Inject abstract val files: FileSystemOperations
    @get:Inject abstract val processes: ExecOperations

    @TaskAction
    fun gather() {
        val root = repo.get()
        val ios = root.dir("ios")
        val out = outputDir.get()
        files.sync {
            into(out)
            from(root.dir("data")) {
                include("tactics.json", "positions.json", "endgames.json", "classics.json", "games.json")
                into("data")
            }
            // Asset catalogs keep each image in a folder of its own; the app wants them side by side.
            for ((catalog, folder) in listOf(
                "Resources/BoardAssets.xcassets/Pieces" to "pieces",
                "Resources/BoardAssets.xcassets/Board" to "board",
                "Resources/Assets.xcassets/BrassIcons" to "icons",
            )) {
                from(ios.dir(catalog)) {
                    include("*/*.png")
                    eachFile { path = "$folder/$name" }
                    includeEmptyDirs = false
                }
            }
            // The photograph behind the title: the app icon's, which has no lettering in it.
            from(ios.dir("Resources/AppIcon.icon/Assets")) {
                include("brasspawnAppicon-iOS-Default-1024x1024@1x.png")
                rename { "pawn.png" }
                into("art")
            }
            from(ios.dir("Resources/Sounds")) { include("*.wav"); into("sounds") }
            from(ios.dir("Resources/Fonts")) { include("*.ttf"); into("fonts") }
            from(ios.dir("Resources/Legal")) { into("legal") }
            // Stockfish's two networks; Reckless is not in the Android build.
            from(ios.dir("Resources/Networks")) { include("nn-*.nnue"); into("networks") }
        }
        val networks = out.dir("networks").asFile.listFiles().orEmpty().count { it.name.endsWith(".nnue") }
        if (networks < 2) throw GradleException("The engine networks are missing. Run: sh ios/scripts/fetch-networks.sh")
        processes.exec {
            commandLine(
                "python3", stringsScript.get().asFile.path, ios.file("App/Localizable.xcstrings").asFile.path,
                androidStrings.get().asFile.path, out.dir("l10n").asFile.path,
            )
        }
    }
}

val gatherAssets = tasks.register<GatherAssets>("gatherAssets") {
    val root = rootProject.layout.projectDirectory.dir("..")
    repo.set(root)
    sources.from(
        root.dir("data").asFileTree.matching { include("tactics.json", "positions.json", "endgames.json", "classics.json", "games.json") },
        root.dir("ios/Resources/BoardAssets.xcassets"), root.dir("ios/Resources/Assets.xcassets/BrassIcons"),
        root.dir("ios/Resources/AppIcon.icon/Assets"),
        root.dir("ios/Resources/Sounds"), root.dir("ios/Resources/Fonts"), root.dir("ios/Resources/Legal"),
        root.dir("ios/Resources/Networks").asFileTree.matching { include("nn-*.nnue") },
        root.file("ios/App/Localizable.xcstrings"),
    )
    stringsScript.set(rootProject.layout.projectDirectory.file("tools/strings.py"))
    androidStrings.set(rootProject.layout.projectDirectory.dir("localization"))
}

androidComponents {
    onVariants { variant ->
        variant.sources.assets?.addGeneratedSourceDirectory(gatherAssets, GatherAssets::outputDir)
    }
}
