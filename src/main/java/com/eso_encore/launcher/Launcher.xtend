package com.eso_encore.launcher;

import com.eso_encore.launcher.component.Center
import com.eso_encore.launcher.component.Progress
import com.eso_encore.launcher.service.WebsiteService
import com.google.gson.Gson
import java.nio.file.Files
import java.nio.file.Paths
import javafx.application.Application
import javafx.scene.Scene
import javafx.scene.control.Button
import javafx.scene.layout.BorderPane
import javafx.scene.layout.HBox
import javafx.stage.Stage

class Launcher extends Application {

	static val gson = new Gson()
	public static val properties = gson.fromJson(
		Files.readAllLines(Paths.get(System.getProperty("properties", "launcher.properties.json"))).join(),
		Properties
	)
	static val websiteService = new WebsiteService()
	static val updater = new Updater(websiteService)

	val launchButton = new Button("Launch") => [
		disable = true
	]
	val center = new Center()
	val progress = new Progress()
	val root = new BorderPane() => [
		it.center = center
		right = new HBox(
			launchButton
		)
		bottom = progress
	]

	def static void main(String[] args) {
		launch(args)
	}

	override start(Stage primaryStage) throws Exception {
		val scene = new Scene(
			root,
			1200,
			600
		)
		primaryStage.setOnCloseRequest[System.exit(0)]
		primaryStage.setScene(scene)
		primaryStage.show()

		if (updater.shouldUpdate) {
			val updateTask = updater.task
			progress.titleProperty.bind(updateTask.titleProperty)
			progress.messageProperty.bind(updateTask.messageProperty)
			progress.progressProperty.bind(updateTask.progressProperty)
			var t = new Thread(updateTask)
        	t.setDaemon(true)
        	t.start()
		} else {
			launchButton.disable = false
		}
	}

}
