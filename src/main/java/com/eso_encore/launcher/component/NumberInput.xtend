package com.eso_encore.launcher.component

import javafx.beans.property.IntegerProperty
import javafx.scene.control.Button
import javafx.scene.control.TextField
import javafx.scene.layout.HBox
import org.eclipse.xtend.lib.annotations.Accessors

class NumberInput extends HBox {

	val Button minus
	val TextField count
	val Button plus
	@Accessors
	val IntegerProperty valueProperty

	new(IntegerProperty valueProperty) {
		this.valueProperty = valueProperty
		minus = new Button("-") => [
			onAction = [
				if (valueProperty.get() > 1) {
					valueProperty.set(valueProperty.get - 1)
				}
			]
		]
		count = new TextField() => [
			disable = true
			textProperty.bind(valueProperty.asString)
			maxWidth = 32 + 16
		]
		plus = new Button("+") => [
			onAction = [
				valueProperty.set(valueProperty.get + 1)
			]
		]

		children.addAll(minus, count, plus)
	}

}
