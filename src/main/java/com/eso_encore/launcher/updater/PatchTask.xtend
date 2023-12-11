package com.eso_encore.launcher.updater

import com.eso_encore.launcher.service.WebsiteService
import java.io.FileOutputStream
import java.io.RandomAccessFile
import java.net.HttpURLConnection
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
class PatchTask extends Task<Void> {

	static val log = LogManager.getLogger(PatchTask)

	val WebsiteService website
	val Updater updater

	override protected call() throws Exception {
		try {
			val latestVersion = website.version
			while (updater.currentVersion != latestVersion) {
				println("Upgrading " + updater.currentVersion + " to " + latestVersion)

				updateTitle("Setting up")
				val saveFile = Paths.get(properties.saveFile)
				val installationDirectory = Paths.get(properties.installationDirectory)
				val patchDirectory = Paths.get(properties.patchDirectory)

				updateMessage("Getting download size")
				val size = website.size
				val sizeString = FileUtils.byteCountToDisplaySize(size)
				updateMessage("Getting version")
				val version = website.version

				updateTitle('''Downloading update «version» to «saveFile»''')
				updateMessage("")
				val url = website.getUrl('''/api/patch?installedVersion=«updater.currentVersion»''')
				val conn = url.openConnection as HttpURLConnection
				conn.requestMethod = "GET"

				println("downloading")
				updater.downloadWithProgress(conn, saveFile.toFile) [ bytesRead |
					updateProgress(bytesRead, size)
					updateMessage(
						FileUtils.byteCountToDisplaySize(bytesRead) + "/" + sizeString + "\t(" + bytesRead + "b/" +
							size + "b)\t" + (bytesRead.doubleValue / size * 100).floatValue + "%")
				]
				println("Downloaded")

				updateTitle("Extracting patch")
				updateMessage("")
				updateProgress(-1, 1)
				println("Extracting")
				FileUtils.deleteDirectory(patchDirectory.toFile())
				patchDirectory.toFile.mkdirs()
				val randomAccessFile = new RandomAccessFile(saveFile.toFile, "r")
				val archive = SevenZip.openInArchive(ArchiveFormat.SEVEN_ZIP,
					new RandomAccessFileInStream(randomAccessFile))
				val simpleArchive = archive.simpleInterface
				val itemCount = simpleArchive.numberOfItems
				simpleArchive.archiveItems.forEach [ it, index |
					val outPath = Paths.get(properties.patchDirectory, it.path)
					updateMessage("Extracting " + it.path)
					if (it.isFolder) {
						outPath.toFile().mkdirs()
					} else {
						try(val out = new FileOutputStream(outPath.toFile)) {
							it.extractSlow [ data |
								out.write(data)
								return data.length
							]
						}
					}
					updateProgress(index + 1, itemCount)
				]
				
				
				println("Extracted")

				updateTitle("Applying patch")
				updateMessage("")
				updateProgress(-1, 1)
				Patcher.patch(installationDirectory, patchDirectory)
				
				updateTitle("Finished updating to "+updater.currentVersion)
			}
		} catch (Exception e) {
			e.printStackTrace
			updateTitle('''Failed''')
			updateMessage(e.message)
		}

		return null
	}

	override protected updateTitle(String title) {
		super.updateTitle(title)
		Platform.runLater [
			log.info("PatchTask: Title: {}", title)
		]
	}

	override protected updateMessage(String message) {
		super.updateMessage(message)
		Platform.runLater [
			log.info("PatchTask: Msg: {}", message)
		]
	}

}
