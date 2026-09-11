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
    afterEvaluate {
        val android = extensions.findByName("android")
        if (android != null) {
            val atual = android.javaClass.methods
                .firstOrNull { it.name == "getCompileSdkVersion" }
                ?.invoke(android) as? String
            val versao = atual?.removePrefix("android-")?.toIntOrNull()
            if (versao != null && versao < 36) {
                android.javaClass.methods
                    .firstOrNull {
                        it.name == "compileSdkVersion" &&
                            it.parameterTypes.size == 1 &&
                            it.parameterTypes[0] == Int::class.java
                    }
                    ?.invoke(android, 36)
            }
        }
    }

    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
