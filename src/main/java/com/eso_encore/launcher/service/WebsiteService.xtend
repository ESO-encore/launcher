package com.eso_encore.launcher.service

import com.eso_encore.launcher.Launcher
import java.io.BufferedReader
import java.io.IOException
import java.io.InputStreamReader
import java.net.HttpURLConnection
import java.net.URL

class WebsiteService {

	def getVersion() {
		get("/api/version")
	}

	def getChecksum() {
		get("/api/checksum")
	}

	def getSize() {
		Long.parseLong(get("/api/size"))
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

		val responseCode = conn.responseCode
		val content = new StringBuffer()
		try(val in = new BufferedReader(new InputStreamReader(conn.getInputStream()))) {
			var String inputLine
			while ((inputLine = in.readLine()) !== null) {
				content.append(inputLine)
			}
		}

		if (responseCode < 200 || responseCode > 299) {
			throw new IOException('''HTTP «responseCode» from «url»: «content.toString»''')
		}
		return content.toString()
	}

}
