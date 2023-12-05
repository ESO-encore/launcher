package com.eso_encore.launcher.component

import javafx.scene.image.Image
import javafx.scene.layout.Background
import javafx.scene.layout.BackgroundImage
import javafx.scene.layout.BackgroundPosition
import javafx.scene.layout.BackgroundRepeat
import javafx.scene.layout.BackgroundSize
import javafx.scene.layout.StackPane

import static javafx.scene.layout.BackgroundSize.AUTO

class Center extends StackPane {
	
	new() {
		background = new Background(
			new BackgroundImage(
				new Image("background.png"), 
				BackgroundRepeat.NO_REPEAT, 
				BackgroundRepeat.NO_REPEAT, 
				BackgroundPosition.CENTER, 
				new BackgroundSize(AUTO, AUTO, true, true, true, true)
			)
		)
	}
	
}