package com.eso_encore.launcher.updater

import java.nio.file.Path
import java.nio.file.Paths
import org.apache.commons.io.IOUtils
import java.nio.charset.Charset

class HPatch {
	
	def static patch(Path installationFile, Path patchFile, Path outputFile) {
		patchWindows64(installationFile, patchFile, outputFile)
	}
	
	def static patchWindows64(Path installationFile, Path patchFile, Path outputFile) {
		patch(Paths.get("lib/windows64/hpatchz.exe"), installationFile, patchFile, outputFile)
	}
	
	def static patch(Path patchz, Path installationFile, Path patchFile, Path outputFile) {
		val builder = new ProcessBuilder(
			patchz.toAbsolutePath.toString(), 
			installationFile.toAbsolutePath.toString(), 
			patchFile.toAbsolutePath.toString(), 
			outputFile.toAbsolutePath.toString()
		)
		builder.redirectErrorStream(true)
		val process = builder.start()
		println(IOUtils.readLines(process.inputStream, Charset.defaultCharset()).join("\n"))
	}
	
}
