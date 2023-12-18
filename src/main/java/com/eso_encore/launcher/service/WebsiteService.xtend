package com.eso_encore.launcher.service

import com.eso_encore.launcher.Launcher
import java.io.BufferedReader
import java.io.IOException
import java.io.InputStreamReader
import java.net.HttpURLConnection
import java.net.URL

class WebsiteService {

	def String getVersion() {
		get("/api/version")
	}

	def String getChecksum() {
		get("/api/checksum")
	}

	def getSize() {
		Long.parseLong(get("/api/size"))
	}

	def getPatchSize(String installedVersion) {
		Long.parseLong(get('''/api/size-patch?installedVersion=«installedVersion»'''))
	}

	def getUrl(String path) {
		new URL(Launcher.properties.websiteUrl + path)
	}

	def get(String path) {
		get(path.getUrl())
	}

	def get(URL url) {
		val conn = url.openConnection as HttpURLConnection
		conn.requestMethod = "GET"

		read(conn)
	}

	def post(String path) {
		post(path.getUrl())
	}

	def post(URL url) {
		val conn = url.openConnection as HttpURLConnection
		conn.requestMethod = "POST"

		read(conn)
	}

	def String read(HttpURLConnection conn) {
		try {
			val responseCode = conn.responseCode
			val content = new StringBuffer()
			try(val in = new BufferedReader(new InputStreamReader(conn.getInputStream()))) {
				var String inputLine
				while ((inputLine = in.readLine()) !== null) {
					content.append(inputLine)
				}
			}

			if (responseCode < 200 || responseCode > 299) {
				throw new IOException('''HTTP «responseCode» from «conn.URL»: «content.toString»''')
			}
			return content.toString()
		} catch (Exception e) {
			throw new IOException("Failed to read from "+conn.URL, e)
		}
	}

}
