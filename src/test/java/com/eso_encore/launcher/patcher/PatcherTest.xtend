package com.eso_encore.launcher.patcher

import org.junit.jupiter.api.Test
import com.eso_encore.launcher.updater.Patcher
import java.nio.file.Paths
import java.nio.file.Files
import java.io.IOException
import java.nio.file.Path
import java.nio.file.StandardCopyOption
import org.apache.commons.io.FileUtils
import static org.junit.jupiter.api.Assertions.assertEquals

class PatcherTest {

	@Test
	def void testPatch() {
		val original = Paths.get("src/test/resources/patch-test/original")
		val originalCopy = Paths.get("src/test/resources/patch-test/original-copy")
		val patchFile = Paths.get("src/test/resources/patch-test/patch")
		
		FileUtils.deleteDirectory(originalCopy.toFile)
		copyFolder(original, originalCopy)
		
		assertEquals("this file is not yet touched", Files.readAllLines(originalCopy.resolve("touched.txt")).join())
		assertEquals("this file is not yet deeply touched", Files.readAllLines(originalCopy.resolve("deep/deep.txt")).join())
		assertEquals("this file is untouched", Files.readAllLines(originalCopy.resolve("untouched.txt")).join())
		Patcher.patch(originalCopy, patchFile)
		assertEquals("this file is touched", Files.readAllLines(originalCopy.resolve("touched.txt")).join())
		assertEquals("this file is deeply touched", Files.readAllLines(originalCopy.resolve("deep/deep.txt")).join())
		assertEquals("this file is untouched", Files.readAllLines(originalCopy.resolve("untouched.txt")).join())
	}

	def void copyFolder(Path src, Path dest) throws IOException {
		try (val stream = Files.walk(src)) {
			stream.forEach[source|copy(source, dest.resolve(src.relativize(source)))];
		}
	}

	def void copy(Path source, Path dest) {
		try {
			Files.copy(source, dest, StandardCopyOption.REPLACE_EXISTING)
		} catch (Exception e) {
			throw new RuntimeException(e.getMessage(), e)
		}
	}

}
