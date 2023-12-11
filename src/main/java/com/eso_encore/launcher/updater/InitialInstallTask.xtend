package com.eso_encore.launcher.updater

import com.eso_encore.launcher.service.WebsiteService
import java.io.FileOutputStream
import java.io.RandomAccessFile
import java.net.HttpURLConnection
import java.nio.file.Files
import java.nio.file.Paths
import javafx.application.Platform
import javafx.concurrent.Task
import net.sf.sevenzipjbinding.ArchiveFormat
import net.sf.sevenzipjbinding.SevenZip
import net.sf.sevenzipjbinding.impl.RandomAccessFileInStream
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
		try {
			updateTitle("Setting up")
			val saveFile = Paths.get(properties.saveFile)
			val installationDirectory = Paths.get(properties.installationDirectory)

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

			if(Files.exists(saveFile)) {
				Files.delete(saveFile)
			}
			updater.downloadWithProgress(conn, saveFile.toFile) [ bytesRead |
				updateProgress(bytesRead, size)
				updateMessage(
					FileUtils.byteCountToDisplaySize(bytesRead) + "/" + sizeString + "\t(" + bytesRead + "b/" + size +
						"b)\t" + (bytesRead.doubleValue / size * 100).floatValue + "%")
			]
			println("Downloaded")

			updateTitle("Extracting new installation")
			updateMessage("")
			updateProgress(-1, 1)
			println("Extracting")
			installationDirectory.toFile.mkdirs()
			
			val randomAccessFile = new RandomAccessFile(saveFile.toFile, "r")
			val archive = SevenZip.openInArchive(ArchiveFormat.SEVEN_ZIP, new RandomAccessFileInStream(randomAccessFile))
			val simpleArchive = archive.simpleInterface
			val itemCount = simpleArchive.numberOfItems
			simpleArchive.archiveItems.forEach[it,index|
				val outPath = Paths.get(properties.installationDirectory, it.path)
				updateMessage("Extracting " + it.path)
				if(it.isFolder) {
					outPath.toFile().mkdirs()
				} else {
					try(val out = new FileOutputStream(outPath.toFile)) {
						it.extractSlow[data|
							out.write(data)
							return data.length
						]
					}
				}
				updateProgress(index+1, itemCount)
			]
			
			updateTitle("Finished installing")
			updateMessage("")
		} catch (Exception e) {
			log.error("Failed to install initial", e)
			updateTitle('''Failed''')
			updateMessage(e.message)
		}

		return null
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
