package com.eso_encore.launcher

import org.eclipse.xtend.lib.annotations.Data

@Data
class Properties {
	
	val String websiteUrl
	val String installationDirectory
	val String patchDirectory
	val String saveFile
	val String backupLocation
	val int launchCount
	
	def withLaunchCount(int launchCount) {
		return new Properties(websiteUrl, installationDirectory, patchDirectory, saveFile, backupLocation, launchCount)
	}
	
}