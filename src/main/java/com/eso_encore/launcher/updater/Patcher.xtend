package com.eso_encore.launcher.updater

import java.io.IOException
import java.nio.file.FileVisitResult
import java.nio.file.FileVisitor
import java.nio.file.Files
import java.nio.file.Path
import java.nio.file.attribute.BasicFileAttributes
import java.util.Optional
import java.nio.file.Paths
import java.nio.file.StandardCopyOption

class Patcher {

	def static patch(Path installationDirectory, Path patchDirectory) {
		val tmpPatchDir = Files.createTempDirectory("eso-patch")
		Files.walkFileTree(patchDirectory, new FileVisitor<Path>() {

			override postVisitDirectory(Path dir, IOException exc) throws IOException {
				FileVisitResult.CONTINUE
			}

			override preVisitDirectory(Path dir, BasicFileAttributes attrs) throws IOException {
				FileVisitResult.CONTINUE
			}

			override visitFile(Path file, BasicFileAttributes attrs) throws IOException {
				println("Applying patch "+file)
				try {
					val relativePath = patchDirectory.relativize(file)
					if (relativePath.fileName.toString.endsWith(".patch")) {
						val originalFileName = relativePath.fileName.toString.replace(".patch", "")
						val installationFile = originalFileName.getOriginalFile(relativePath, installationDirectory)
						patchFile(installationFile, file, tmpPatchDir)
					} else if (relativePath.fileName.toString.endsWith(".deleted")) {
						val originalFileName = relativePath.fileName.toString.replace(".deleted", "")
						val installationFile = originalFileName.getOriginalFile(relativePath, installationDirectory)
						Files.delete(installationFile)
						Files.delete(file)
					} else {
						val originalFileName = relativePath.fileName.toString
						val installationFile = originalFileName.getOriginalFile(relativePath, installationDirectory)
						Files.move(file, installationFile)
					}
				} catch (Exception e) {
					throw new RuntimeException('''Failed to patch file «file»''', e)
				}
				FileVisitResult.CONTINUE
			}

			override visitFileFailed(Path file, IOException exc) throws IOException {
				exc.printStackTrace()
				FileVisitResult.CONTINUE
			}
		})
		Files.delete(tmpPatchDir)
	}

	def static getOriginalFile(String originalFileName, Path relativePath, Path installationDirectory) {
		val originalFilePath = Optional.ofNullable(relativePath.parent).map [
			it.resolve(originalFileName)
		].orElse(Paths.get(originalFileName))
		installationDirectory.resolve(originalFilePath)
	}

	def static patchFile(Path installationFile, Path patchFile, Path tmpDir) {
		val destination = tmpDir.resolve(installationFile.fileName)
		HPatch.patch(installationFile, patchFile, destination)
		Files.move(destination, installationFile, StandardCopyOption.REPLACE_EXISTING)
	}

}
