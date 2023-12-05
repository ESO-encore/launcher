package com.eso_encore.launcher

import com.eso_encore.launcher.service.WebsiteService
import com.twmacinta.util.MD5
import java.io.BufferedReader
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.io.InputStreamReader
import java.net.HttpURLConnection
import java.nio.file.FileVisitResult
import java.nio.file.FileVisitor
import java.nio.file.Files
import java.nio.file.Path
import java.nio.file.Paths
import java.nio.file.attribute.BasicFileAttributes
import javafx.concurrent.Task
import org.apache.commons.compress.archivers.sevenz.SevenZFile
import org.apache.commons.io.FileUtils
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

import static com.eso_encore.launcher.Launcher.properties
import org.eclipse.jgit.storage.file.FileRepositoryBuilder
import org.eclipse.jgit.api.Git

@FinalFieldsConstructor
class Updater {

	val WebsiteService website

	def Boolean shouldUpdate() {
		return properties.savedVersion != website.version ||
			MD5.asHex(MD5.getHash(new File(properties.saveFile))) != website.checksum
	}

	def getTask() {
		return new UpdateTask(website, this)
	}
	
	def getVersion() {
		new Git(repository).
	}
	
	def createRepository(String path) {
		FileRepositoryBuilder.create(getGitFolder())
	}
	
	def getRepository() {
		new FileRepositoryBuilder()
		.setGitDir(getGitFolder())
		.build()
	}
	
	def getGitFolder() {
		new File(properties.installationDirectory, ".git")
	}

	@FinalFieldsConstructor
	static class UpdateTask extends Task<Void> {

		val WebsiteService website
		val Updater updater

		override protected call() throws Exception {
			try {
				updateTitle("Setting up")
				val backupLocation = Paths.get(properties.backupLocation)
				val saveFile = Paths.get(properties.saveFile)
				val installationDirectory = Paths.get(properties.installationDirectory)
				
				updateMessage("Getting download size")
				val size = website.size
				val sizeString = FileUtils.byteCountToDisplaySize(size)
				updateMessage("Getting version")
				val version = website.version

				updateTitle("Processing backup")
				updateMessage("")
				if (Files.exists(backupLocation)) {
					updateMessage("Removing old backup")
					Files.delete(backupLocation)
				}

				if (Files.exists(saveFile)) {
					updateMessage("Backing up current installation")
					Files.move(saveFile, backupLocation)
				}

				updateTitle('''Downloading update «version» to «saveFile»''')
				updateMessage("")
				val url = website.getUrl("/api/download")
				val conn = url.openConnection as HttpURLConnection
				conn.requestMethod = "GET"
				val bufferSize = 1024
				val buffer = newCharArrayOfSize(bufferSize)
				val bytes = newByteArrayOfSize(bufferSize)

				try(val in = new BufferedReader(new InputStreamReader(conn.getInputStream()))) {
					try(val out = new FileOutputStream(saveFile.toFile)) {
						var bytesRead = 0l
						while (in.read(buffer) != -1) {
							for (var i = 0; i < bufferSize; i++)
								bytes.set(i, buffer.get(i) as byte)
							out.write(bytes)

							updateProgress(bytesRead, size)
							bytesRead += bufferSize
							updateMessage(
								FileUtils.byteCountToDisplaySize(bytesRead) + "/" + sizeString + "\t(" + bytesRead +
									"b/" + size + "b)\t"+(bytesRead.doubleValue / size*100).floatValue+"%")
						}
					}
				}

				if (Files.exists(installationDirectory)) {
					updateTitle("Deleting old installation")
					Files.walkFileTree(installationDirectory, new FileVisitor<Path> {

						override postVisitDirectory(Path dir, IOException exc) throws IOException {
							updateMessage("Deleting " + dir.fileName)
							Files.delete(dir)
							FileVisitResult.CONTINUE
						}

						override preVisitDirectory(Path dir, BasicFileAttributes attrs) throws IOException {
						}

						override visitFile(Path file, BasicFileAttributes attrs) throws IOException {
							updateMessage("Deleting " + file.fileName)
							Files.delete(file)
							FileVisitResult.CONTINUE
						}

						override visitFileFailed(Path file, IOException exc) throws IOException {
							throw new RuntimeException("Failed to delete " + file, exc)
						}
					})
				}

				updateTitle("Extracting new installation")
				installationDirectory.toFile.mkdirs()
				try(val zipFile = new SevenZFile(saveFile.toFile)) {
					zipFile.entries.forEach [
						updateMessage("Extracting " + it.name)
						val path = Paths.get(properties.installationDirectory, it.name)
						try(val out = new FileOutputStream(path.toFile)) {
							val contents = newByteArrayOfSize(it.size.intValue)
							var off = 0
							while (off < contents.length) {
								val bytesRead = zipFile.read(contents, off, contents.length - off)
								out.write(contents, off, bytesRead)
								off += bytesRead
								updateMessage('''Extracting «it.name» «FileUtils.byteCountToDisplaySize(off)»/«FileUtils.byteCountToDisplaySize(it.size)»''')
							}
						}
					]
				}
			} catch (Exception e) {
				e.printStackTrace
				updateTitle('''Failed''')
				updateMessage(e.message)
			}

			return null
		}
	}

}
