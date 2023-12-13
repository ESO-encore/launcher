package com.eso_encore.launcher.updater

import java.nio.file.Path
import java.io.RandomAccessFile
import net.sf.sevenzipjbinding.SevenZip
import net.sf.sevenzipjbinding.impl.RandomAccessFileInStream
import net.sf.sevenzipjbinding.IArchiveExtractCallback
import net.sf.sevenzipjbinding.ExtractAskMode
import net.sf.sevenzipjbinding.SevenZipException
import net.sf.sevenzipjbinding.ExtractOperationResult
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import net.sf.sevenzipjbinding.IInArchive
import java.io.FileOutputStream
import net.sf.sevenzipjbinding.PropID
import net.sf.sevenzipjbinding.ISequentialOutStream

class SevenZipExtractor {
	
	def static void extract(Path sevenZip, Path destination, (int, int, Path, ExtractOperationResult) => void onExtracted) {
		val randomAccessFile = new RandomAccessFile(sevenZip.toFile, "r")
		val archive = SevenZip.openInArchive(null, new RandomAccessFileInStream(randomAccessFile))
		
		val indices = newIntArrayOfSize(archive.numberOfItems)
		for(var i = 0; i < indices.length; i++) {
			indices.set(i, i)
		}
		
		archive.extract(indices, false, new ExtractCallback(archive, destination, indices.length, onExtracted))
	}
	
	@FinalFieldsConstructor
	static class ExtractCallback implements IArchiveExtractCallback {
		
		val IInArchive archive
		val Path destination
		val int total
		val (int, int, Path, ExtractOperationResult) => void onExtracted
		var int index
		var Path outPath
		var FileOutputStream out
		var boolean isFolder
		
		override getStream(int index, ExtractAskMode extractAskMode) throws SevenZipException {
			this.index = index
			isFolder = archive.getProperty(index, PropID.IS_FOLDER) as Boolean
			val path = archive.getStringProperty(index, PropID.PATH)
			outPath = destination.resolve(path)
			
			if(isFolder || extractAskMode != ExtractAskMode.EXTRACT) {
				return null
			}
			
			outPath.parent.toFile.mkdirs()
			out = new FileOutputStream(outPath.toFile)
			return new ISequentialOutStream() {
				override write(byte[] data) throws SevenZipException {
					out.write(data)
					return data.length
				}
			}
		}
		
		override prepareOperation(ExtractAskMode extractAskMode) throws SevenZipException {
		}
		
		override setOperationResult(ExtractOperationResult extractOperationResult) throws SevenZipException {
			if(isFolder) {
				return
			}
			out.close()
			onExtracted.apply(index, total, outPath, extractOperationResult)
		}
		
		override setCompleted(long complete) throws SevenZipException {
		}
		
		override setTotal(long total) throws SevenZipException {
		}
		
	}
	
}