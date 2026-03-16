import com.android.build.gradle.BaseExtension
import org.jetbrains.kotlin.gradle.tasks.KotlinCompile
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

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

// Global task configuration
allprojects {
    // Suppress the 'obsolete source/target value' warnings
    tasks.withType<JavaCompile>().configureEach {
        options.compilerArgs.add("-Xlint:-options")
    }
    
    // Dynamically match Kotlin's JVM target to the Java version of the project
    // to avoid 'Inconsistent JVM Target Compatibility' errors.
    tasks.withType<KotlinCompile>().configureEach {
        val javaVersion = project.extensions.findByName("android")?.let { 
            (it as? BaseExtension)?.compileOptions?.sourceCompatibility?.toString() 
        } ?: "11"
        
        compilerOptions {
            if (javaVersion == "1.8" || javaVersion == "8") {
                jvmTarget.set(JvmTarget.JVM_1_8)
            } else if (javaVersion == "17") {
                jvmTarget.set(JvmTarget.JVM_17)
            } else {
                jvmTarget.set(JvmTarget.JVM_11)
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
