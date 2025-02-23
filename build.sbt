enablePlugins(ScalaJSPlugin)

name := "cellular"
scalaVersion := "2.13.3"
version := "0.1.0-SNAPSHOT"

resolvers += Resolver.sonatypeRepo("snapshots")
libraryDependencies += "org.scala-js" %%% "scalajs-dom" % "1.1.0"
libraryDependencies += "com.github.ahnfelt" %%% "react4s" % "0.10.0-SNAPSHOT"

scalaJSUseMainModuleInitializer := true
mainClass in Compile := Some("cellular.frontend.Factory")

lazy val compileAndCopy = taskKey[File]("Run fastOptJS and copy the output to web/ directory")
compileAndCopy := {
    val jsFile = (Compile / fastOptJS).value.data
    val targetDir = baseDirectory.value / "web"
    IO.copyFile(jsFile, targetDir / jsFile.getName)
    streams.value.log.info(s"Copied $jsFile to ${targetDir.getAbsolutePath}")
    jsFile
}