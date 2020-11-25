enablePlugins(ScalaJSPlugin)

name := "cellular"
scalaVersion := "2.13.3"
version := "0.1.0-SNAPSHOT"

resolvers += Resolver.sonatypeRepo("snapshots")
libraryDependencies += "org.scala-js" %%% "scalajs-dom" % "1.1.0"
libraryDependencies += "com.github.ahnfelt" %%% "react4s" % "0.10.0-SNAPSHOT"

scalaJSUseMainModuleInitializer := true
mainClass in Compile := Some("cellular.frontend.Factory")
