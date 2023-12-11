package com.eso_encore.launcher;

import com.eso_encore.launcher.component.Center
import com.eso_encore.launcher.component.NumberInput
import com.eso_encore.launcher.component.Progress
import com.eso_encore.launcher.service.WebsiteService
import com.eso_encore.launcher.updater.Updater
import com.google.gson.GsonBuilder
import java.io.File
import java.nio.file.Files
import java.nio.file.Paths
import javafx.application.Application
import javafx.application.Platform
import javafx.beans.property.SimpleIntegerProperty
import javafx.concurrent.Task
import javafx.scene.Scene
import javafx.scene.control.Button
import javafx.scene.layout.BorderPane
import javafx.scene.layout.VBox
import javafx.stage.Stage
import org.apache.commons.io.FileUtils

class Launcher extends Application {

	static val gson = new GsonBuilder().setPrettyPrinting().create()
	public static val properties = gson.fromJson(
		Files.readAllLines(propertiesPath).join(),
		Properties
	)
	static val websiteService = new WebsiteService()
	static val updater = new Updater(websiteService)

	val launchCount = new NumberInput(new SimpleIntegerProperty(properties.launchCount))
	val launchButton = new Button("Launch") => [
		disable = true
	]
	val redownloadButton = new Button("Redownload")
	val center = new Center()
	val progress = new Progress()
	val root = new BorderPane() => [
		it.center = center
		right = new VBox(
			launchCount,
			launchButton,
			redownloadButton
		)
		bottom = progress
	]

	def static void main(String[] args) {
		launch(args)
	}

	override start(Stage primaryStage) throws Exception {
		redownloadButton.onAction = [
			launchButton.disable = false
			FileUtils.deleteDirectory(new File(properties.installationDirectory))
			val task = updater.installationTask
			bindProgress(task)
			task.onSucceeded = [launchButton.disable = false]
			var t = new Thread(task)
			t.setDaemon(true)
			t.start()
		]
		launchCount.valueProperty.addListener [
			Files.write(
				propertiesPath,
				gson.toJson(properties.withLaunchCount(launchCount.valueProperty.get)).bytes
			)
		]
		launchButton.onAction = [
			(0 ..< launchCount.valueProperty.get).forEach [
				new Thread [
					val builder = new ProcessBuilder(
						Paths.get(properties.installationDirectory).resolve("element/elementclient.exe").toString()
					)
					builder.redirectErrorStream(true)
					builder.start()
				].start()
			]
		]
		val scene = new Scene(
			root,
			1200,
			600
		)
		primaryStage.setOnCloseRequest[System.exit(0)]
		primaryStage.setScene(scene)
		primaryStage.show()

		try {
			val shouldUpdate = updater.shouldUpdate
			if (shouldUpdate) {
				val updateTask = updater.task
				Platform.runLater [
					bindProgress(updateTask)
					updateTask.onSucceeded = [launchButton.disable = false]
				]
				var t = new Thread(updateTask)
				t.setDaemon(true)
				t.start()
			} else {
				progress.titleProperty.set(updater.currentVersion + " is the latest version")
				progress.progressProperty.set(1)
				launchButton.disable = false
			}
		} catch (Exception e) {
			e.printStackTrace
			progress.titleProperty.set(e.class.toString)
			progress.messageProperty.set(e.message)
		}
	}

	def bindProgress(Task<?> task) {
		progress.titleProperty.bind(task.titleProperty)
		progress.messageProperty.bind(task.messageProperty)
		progress.progressProperty.bind(task.progressProperty)
	}

	def static propertiesPath() {
		return Paths.get(System.getProperty("properties", "launcher.properties.json"))
	}

}
