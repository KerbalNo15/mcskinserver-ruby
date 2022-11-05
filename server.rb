#Simple Minecraft skin server for use with OpenMCSkins (https://github.com/zatrit/openmcskins). This project is not affiliated with OpenMCSkins
# Copyright (c) 2022, KerbalNo15 (github.com/KerbalNo15)
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

#Many thanks to https://blog.appsignal.com/2016/11/23/ruby-magic-building-a-30-line-http-server-in-ruby.html for the ruby web server basics
require 'socket'
require 'json'

addr = ARGV[0] #The listening address of the server
server = TCPServer.new(addr, 80) #Create TCP server
puts "Listening on address " + addr

while session = server.accept #Continually listen for connections
	requestdata = session.gets #Get the request from the client

	if requestdata.split('/')[1] == "textures" #Stage 1 is to request the skin URL from the server. Connections like this will be in the format "https://<address>:<port>/textures/<username>"

		skinPath = ("skins/" + requestdata.split('/')[2].split(' ')[0].scan(/[\w*]/).join + ".png") #The path for the skin

		if File.file?(skinPath) #If the skin exists for this player
			responseData = {SKIN: {url: "null"}} #Set up a basic response template
			responseData[:SKIN][:url] = "http://" + addr + "/skins/" + requestdata.split('/')[2].split(' ')[0].scan(/[\w*]/).join + ".png" #Include the url for that skin in the response
			session.print "HTTP/1.1 200\r\n" #Headers
			session.print "Content-type: application/json\r\n"
			session.print "\r\n" #Signifies the end of the headers
			session.print JSON.generate(responseData) #Send the response data
		else
			session.print "HTTP/1.1 200\r\n" #Headers
			session.print "Content-type: application/json\r\n"
			session.print "\r\n" #Signifies the end of the headers
			session.print("{}")
		end

		session.close #Close the connection

	else #The client most likely wants a skin texture

		requestedPath = ("skins/" + requestdata.split('/')[2].split(' ')[0].scan(/[\w*\.]/).join) #The path for the skin
		if File.file?(requestedPath) # the skin exists on the server
			image = File.open("skins/" + requestdata.split('/')[2].split(' ')[0].scan(/[\w*\.]/).join)
			filedata = image.read
			session.print "HTTP/1.1 200\r\n" # 1
			session.print "Content-type: image/png\r\n" # 2
			session.print "\r\n" # 3
			session.print filedata
		else #The texture does not exist
			session.print "HTTP/1.1 404\r\n" # 1
			session.print "Content-type: text/html\r\n" # 2
			session.print "\r\n" # 3
			session.print("<body><H1>404- File Not Found</H1></body>\n")
			STDERR.puts "Failed to serve file: Not found on this server\n"
		end

		session.close #Close the connection

end

end
