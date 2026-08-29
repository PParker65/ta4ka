import com.android.build.api.dsl.ApplicationExtension
import com.android.build.api.dsl.LibraryExtension

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Keep plugin modules on modern SDK to satisfy AAR metadata checks.
// afterEvaluate is skipped when evaluationDependsOn(":app") already evaluated the project.
subprojects {
    plugins.withId("com.android.application") {
        extensions.configure<ApplicationExtension>("android") {
            compileSdk = 36
        }
    }
    plugins.withId("com.android.library") {
        extensions.configure<LibraryExtension>("android") {
            compileSdk = 36
        }
    }
    fun bumpSdk() {
        extensions.findByType<ApplicationExtension>()?.compileSdk = 36
        extensions.findByType<LibraryExtension>()?.compileSdk = 36
    }
    if (state.executed) {
        bumpSdk()
    } else {
        afterEvaluate { bumpSdk() }
    }
}


tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
