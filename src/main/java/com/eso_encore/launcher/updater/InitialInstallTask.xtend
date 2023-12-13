package com.eso_encore.launcher.updater

import com.eso_encore.launcher.Action
import com.eso_encore.launcher.Launcher
import com.eso_encore.launcher.service.WebsiteService
import java.net.HttpURLConnection
import java.nio.file.Files
import java.nio.file.Paths
import java.time.Duration
import java.time.ZonedDateTime
import java.time.temporal.ChronoUnit
import javafx.application.Platform
import javafx.concurrent.Task
import net.sf.sevenzipjbinding.ExtractOperationResult
import org.apache.commons.io.FileUtils
import org.apache.logging.log4j.LogManager
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

import static com.eso_encore.launcher.Launcher.properties

@FinalFieldsConstructor
class InitialInstallTask extends Task<Void> {

	static val log = LogManager.getLogger(InitialInstallTask)

	val WebsiteService website
	val Updater updater

	override protected call() throws Exception {
		val start = ZonedDateTime.now()
		try {
			updateTitle("Setting up")
			val saveFile = Paths.get(properties.saveFile)
			val installationDirectory = Paths.get(properties.installationDirectory)

			if (properties.currentAction != Action.INITIAL_EXTRACT) {
				Launcher.save(properties.withCurrentAction(Action.INITIAL_DOWNLOAD))
				updateMessage("Getting download size")
				val size = website.size
				println("size " + size)
				val sizeString = FileUtils.byteCountToDisplaySize(size)
				updateMessage("Getting version")
				val version = website.version

				updateTitle('''Downloading update «version» to «saveFile»''')
				updateMessage("")
				val url = website.getUrl("/api/download")
				val conn = url.openConnection as HttpURLConnection
				conn.requestMethod = "GET"

				if (Files.exists(saveFile)) {
					Files.delete(saveFile)
				}
				updater.downloadWithProgress(conn, saveFile.toFile) [ bytesRead |
					updateProgress(bytesRead, size)
					updateMessage(
						FileUtils.byteCountToDisplaySize(bytesRead) + "/" + sizeString + "\t(" + bytesRead + "b/" +
							size + "b)\t" + (bytesRead.doubleValue / size * 100).floatValue + "%")
				]
				println("Downloaded")
			}

			updateTitle("Extracting new installation")
			updateMessage("")
			updateProgress(-1, 1)
			Launcher.save(properties.withCurrentAction(Action.INITIAL_EXTRACT))
			println("Extracting")
			installationDirectory.toFile.mkdirs()

			SevenZipExtractor.extract(saveFile, Paths.get(properties.installationDirectory)) [index, total, path, result|
				if(result == ExtractOperationResult.OK) {
					updateMessage("Extracted "+path+"\t"+index+"/"+total)
					updateProgress(index, total)
				}
			]

			Launcher.save(properties.withCurrentAction(Action.NONE))
			val duration = ChronoUnit.SECONDS.between(start, ZonedDateTime.now)
			updateTitle("Finished installing in " + Duration.ofSeconds(duration).humanReadableFormat)
			updateMessage("")
		} catch (Exception e) {
			log.error("Failed to install initial", e)
			updateTitle('''Failed''')
			updateMessage(e.message)
		}

		return null
	}

	def static String humanReadableFormat(Duration duration) {
		return duration.toString().substring(2).replaceAll("(\\d[HMS])(?!$)", "$1 ").toLowerCase()
	}

	override protected updateTitle(String title) {
		super.updateTitle(title)
		Platform.runLater [
			log.info("InitialInstallTask: Title: {}", title)
		]
	}

	override protected updateMessage(String message) {
		super.updateMessage(message)
		Platform.runLater [
			log.info("InitialInstallTask: Msg: {}", message)
		]
	}

}
