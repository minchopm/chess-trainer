pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}
rootProject.name = "BrassPawn"
// The rules of chess and everything the trainer knows: plain Kotlin, no Android.
include(":core")
// -PcoreOnly leaves the app out, so the rules can be tested on a machine with no Android SDK.
if (!providers.gradleProperty("coreOnly").isPresent) include(":app")
