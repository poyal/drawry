plugins { kotlin("jvm"); kotlin("plugin.serialization") }
kotlin { jvmToolchain(17) }
dependencies {
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.9.0")
    testImplementation(kotlin("test"))
}
tasks.test {
    environment("DRAWRY_FIXTURES", rootProject.file("../shared/fixtures/generated").absolutePath)
    environment("DRAWRY_GOLDEN", rootProject.file("../shared/fixtures/crypto-v2.json").absolutePath)
    inputs.file(rootProject.file("../shared/fixtures/crypto-v2.json"))
    inputs.files(rootProject.file("../shared/fixtures/generated/swift.drawry"))
}
