package com.eso_encore.launcher.component

import javafx.scene.layout.VBox
import javafx.scene.control.ProgressBar
import javafx.scene.control.Label

class Progress extends VBox {
	
	val Label title
	val Label message
	val ProgressBar progressBar
	
	new() {
		title = new Label("")
		message = new Label("")
		progressBar = new ProgressBar() => [
			prefWidthProperty.bind(this.widthProperty)
		]
		
		getChildren().addAll(title, message, progressBar)
	}
	
	def titleProperty() {
		title.textProperty()
	}
	
	def messageProperty() {
		message.textProperty()
	}
	
	def progressProperty() {
		progressBar.progressProperty()
	}
	
}