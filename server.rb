#Simple Minecraft skin server for use with OpenMCSkins (https://github.com/zatrit/openmcskins). This project is not affiliated with OpenMCSkins
# Copyright (c) 2022, KerbalNo15 (github.com/KerbalNo15)
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

#Many thanks to https://blog.appsignal.com/2016/11/23/ruby-magic-building-a-30-line-http-server-in-ruby.html for the ruby web server basics
require 'socket'
require 'json'
require 'pathname'

skinHashMap = {} # hash->file path
hashSkinMap = {} # player name->hash

skinFiles = Dir["skins/*.png"] #get all the files in the skins/ directory

#hash each file and store the results in two maps: one that maps the name to the hash, and another that goes the other direction
skinFiles.each do |filename|
thisHash = File.read(filename).hash.to_s
hashSkinMap[filename.split("/")[1].split(".")[0]] = thisHash
skinHashMap[thisHash] = filename
end

addr = ARGV[0] #The listening address of the server
server = TCPServer.new(addr, 80) #Create TCP server
puts "Listening on address " + addr

while session = server.accept #Continually listen for connections
	requestdata = session.gets #Get the request from the client

	if requestdata.split('/')[1] == "textures" #Stage 1 is to request the skin URL from the server. Connections like this will be in the format "https://<address>:<port>/textures/<username>"
		playerName = requestdata.split('/')[2].split(' ')[0].scan(/[\w*]/).join

		if hashSkinMap[playerName] != nil #check the map for a matching name
			responseData = {SKIN: {url: "null"}} #Set up a basic response template
			responseData[:SKIN][:url] = "http://" + addr + "/skins/" + hashSkinMap[playerName] #Include the url for that skin in the response
			session.print "HTTP/1.1 200\r\n" #Headers
			session.print "Content-type: application/json\r\n"
			session.print "\r\n" #Signifies the end of the headers
			session.print JSON.generate(responseData) #Send the response data
		else #we don't have a skin for this player
			session.print "HTTP/1.1 200\r\n" #Headers
			session.print "Content-type: application/json\r\n"
			session.print "\r\n" #Signifies the end of the headers
			session.print("{}")
		end

		session.close #Close the connection

	else #The client most likely wants a skin texture
		requestHash = requestdata.split('/')[2].split(' ')[0].scan(/[\d\-*]/).join

		if skinHashMap[requestHash] != nil #check the skin map for a matching hash

			filedata = File.read(skinHashMap[requestHash]) #skinHashMap converts a hash to a file path
			session.print "HTTP/1.1 200\r\n" # 1
			session.print "Content-type: image/png\r\n" # 2
			session.print "\r\n" # 3
			session.print filedata

		else #we don't have this skin on the server
			session.print "HTTP/1.1 404\r\n" # 1
			session.print "Content-type: text/html\r\n" # 2
			session.print "\r\n" # 3
			session.print("<body><H1>404- File Not Found</H1></body>\n")
			STDERR.puts "Failed to serve file: Not found on this server\n"
		end

		session.close #Close the connection

end

end
