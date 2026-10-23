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

// Algunos plugins (p.ej. another_telephony) traen su propio bloque `kotlinOptions`
// fijado a Java 1.8, lo que choca con el `sourceCompatibility`/`targetCompatibility`
// que Gradle/AGP infieren por defecto (Java 11) para módulos Android library y
// provoca el error "Inconsistent JVM-target compatibility detected for tasks
// 'compileDebugJavaWithJavac' and 'compileDebugKotlin'". Forzamos aquí, después
// de evaluar cada subproyecto, que Java y Kotlin usen el mismo target (17, igual
// que el módulo :app) para evitar la inconsistencia.
subprojects {
    // El módulo :app ya se evalúa antes de llegar aquí (por el
    // evaluationDependsOn(":app") de arriba), así que llamar afterEvaluate
    // sobre él de nuevo lanza "project already evaluated". Lo excluimos:
    // su propio build.gradle.kts ya fija Java/Kotlin 17 de forma consistente.
    if (project.name != "app") {
        afterEvaluate {
            extensions.findByName("android")?.let { androidExt ->
                if (androidExt is com.android.build.gradle.BaseExtension) {
                    // Algunos plugins (p.ej. file_picker) compilan con un SDK menor
                    // al que exigen sus dependencias; se unifica en 36.
                    androidExt.compileSdkVersion(36)
                    androidExt.compileOptions {
                        sourceCompatibility = JavaVersion.VERSION_17
                        targetCompatibility = JavaVersion.VERSION_17
                    }
                }
            }
            tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
                compilerOptions {
                    jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
