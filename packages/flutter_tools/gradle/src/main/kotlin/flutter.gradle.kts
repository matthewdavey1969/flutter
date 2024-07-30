// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import com.android.build.api.dsl.ApplicationExtension;


// This buildscript block supplies dependencies for this file's own import
// declarations above. It exists solely for compatibility with projects that
// have not migrated to declaratively apply the Flutter Gradle Plugin;
// for those that have, FGP's `build.gradle.kts`  takes care of this.
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // When bumping, also update:
        //  * ndkVersion in FlutterExtension in packages/flutter_tools/gradle/src/main/groovy/flutter.groovy
        //  * AGP version in the buildscript block in packages/flutter_tools/gradle/src/main/kotlin/dependency_version_checker.gradle.kts
        //  * AGP version constants in packages/flutter_tools/lib/src/android/gradle_utils.dart
        //  * AGP version in dependencies block in packages/flutter_tools/gradle/build.gradle.kts
        classpath("com.android.tools.build:gradle:7.3.0")
    }
}

apply<FlutterPluginKts>()

class FlutterPluginKts : Plugin<Project> {
    override fun apply(project: Project) {
        print(project.extensions)
        val androidExtension = project.extensions.findByType(com.android.build.api.dsl.ApplicationExtension::class.java)

        androidExtension?.let { android ->
            android.defaultConfig.let { defaultConfig ->
                val baseApplicationName = project.findProperty("base-application-name")?.toString() ?: "android.app.Application"
                // Setting to android.app.Application is the same as omitting the attribute.
                defaultConfig.manifestPlaceholders["applicationName"] = baseApplicationName
            }
        }
    }
}
