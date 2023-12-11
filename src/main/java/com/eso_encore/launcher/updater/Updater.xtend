package com.eso_encore.launcher.updater

import com.eso_encore.launcher.service.WebsiteService
import java.io.File
import java.io.FileOutputStream
import java.net.URLConnection
import java.nio.file.Files
import java.nio.file.Paths
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

import static com.eso_encore.launcher.Launcher.properties

@FinalFieldsConstructor
class Updater {

	val WebsiteService website

	def Boolean shouldUpdate() {
		return !isInstalled || version() != website.version
	}

	def getTask() {
		if (isInstalled()) {
			return patchTask()
		} else {
			return installationTask()
		}
	}

	def patchTask() {
		println("Creating patch task")
		return new PatchTask(website, this)
	}

	def installationTask() {
		println("Creating initial install task")
		return new InitialInstallTask(website, this)
	}

	def getCurrentVersion() {
		Files.readAllLines(versionPath).join
	}

	def boolean isInstalled() {
		return Files.exists(installationPath) && Files.exists(versionPath)
	}

	def installationPath() {
		return Paths.get(properties.installationDirectory)
	}

	def version() {
		Files.readAllLines(versionPath).join
	}

	def versionPath() {
		return installationPath.resolve("version")
	}

	def downloadWithProgress(URLConnection conn, File outputFile, (Long)=>void onUpdate) {
		val bufferSize = 1024
		val bytes = newByteArrayOfSize(bufferSize)

		try(val in = conn.getInputStream()) {
			try(val out = new FileOutputStream(outputFile)) {
				var totalBytesRead = 0l
				var bytesRead = 0
				while ((bytesRead = in.read(bytes)) != -1) {
					out.write(bytes, 0, bytesRead)

					totalBytesRead += bytesRead
					onUpdate.apply(totalBytesRead)
				}
			}
		}
	}

}
