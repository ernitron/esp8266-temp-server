-- A simple server to return temperature
local function httpheader(code, extension, title, refresh)
   local function getHTTPStatusString(code)
      local codez = {[200]="200 OK", [400]="400 Bad Request", [404]="404 Not Found", [302]="302 Redirect", [501]="501 Internal Server Error"}
      local myResult = codez[code]
      -- enforce returning valid http codes all the way throughout?
      if myResult then return myResult else return codez[501] end
   end
   local function getMimeType(ext)
      -- A few MIME types. Keep list short. If you need something that is missing, let's add it.
      local mt = {css = "text/css", gif = "image/gif", html = "text/html", ico = "image/x-icon", jpeg = "image/jpeg", jpg = "image/jpeg", js = "application/javascript", json = "application/json", png = "image/png", xml = "text/xml"}
      if mt[ext] then return mt[ext] else return "text/plain" end
   end

   local h = "HTTP/1.1 "..getHTTPStatusString(code).."\r\nServer: tempserver\r\nContent-Type: "..getMimeType(extension) 
   h = h.."\r\nCache-Control: private, no-store\r\nConnection: close\r\n\r\n"

   if extension == 'html' then
     h = h .. '<!DOCTYPE html>\n'
     h = h .. '<html lang="en">\n<head>\n<title>Temp '..title..'</title>\n'
     h = h .. refresh
     h = h .. '<meta name="generator" content="esp8266-server">\n<meta charset="UTF-8">\n'
     h = h .. '<meta name="viewport" content="width=device-width, initial-scale=1">\n'
     h = h .. '<script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/js/bootstrap.min.js"></script>\n'
     h = h .. '<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/css/bootstrap.min.css">\n'
     h = h .. '<style media="screen" type="text/css">\n'
     h = h .. 'body {font-family: Georgia, serif;} .jumbotron {padding: 10px 10px;}\n</style>\n'
     h = h .. '</head><body>\n'
     h = h .. '<div class="container-fluid">\n<div class="jumbotron">\n'
   end
   return h
end

local footer = '<footer class="footer"><div class="container">'
footer = footer..'Vers. 2.1.7 <a href="/">[ temperature</a> | '
footer = footer..'<a href="/j">json</a> | '
footer = footer..'<a href="/status">status</a> | '
footer = footer..'<a href="/setname">set place</a> | '
footer = footer..'<a href="/setwifi">set wifi</a> | '
footer = footer..'<a href="/register/?server=http://tempserver.ypketron.eu:8805/rt">register</a> | '
footer = footer..'<a href="/reinit">reinit</a> | '
footer = footer..'<a href="/help">help</a> ]'
footer = footer..'</div></footer>'
footer = footer..'</body></html>'

-- More Global
local t = require('ds18b20')
local place = t.place

return function (port)
    -- A simple http server to respond to temp requests
    local s = net.createServer(net.TCP, 10)
    s:listen(port, function(conn)
      local function onReceive(conn, payload)
        local req = dofile("request.lc")(payload)
        local content = ''
        local header = ''
        if req.methodIsValid and (req.method == "GET" or req.method == "POST" or req.method == "PUT") then
            local uri = req.uri
            if req.request == '/' or req.request == '/index' then
                local table = t.readtemptable(6)
                place = t.place
                header = httpheader('200', 'html', place, '<meta http-equiv="refresh" content="300">\n')
                content = '<h1><a href="/">'..place..': '..table["temp"]..' °C</a></h1>'
                content = content..'<p>Reading #'.. table['count'] ..' @ '
                content = content..tmr.time().. ' seconds'
                content = content..'</p></div>'
                conn:send(header..content..footer)
            elseif req.request == '/status' then
                header = httpheader('200', 'html', place, '')
                local majorVer, minorVer, devVer, chipid, flashid, flashsize, flashmode, flashspeed = node.info()
                local mode = wifi.getmode()
                local r,u,t=file.fsinfo() 
                content = '<h2><a href="/">Status #'..chipid..'</a></h2>'
                content = content.."<p>NodeMCU: "..majorVer.."."..minorVer.."."..devVer
                content = content.."<p>ChipID: "..chipid
                content = content.."<br>FlashID: "..flashid
                content = content.."<br>Flashmode: "..flashmode
                content = content.."<br>Flashsize: "..flashsize
                content = content.."<br>Heap: "..node.heap()
                content = content.."<h3>File System (in bytes)</h3>"
                content = content.."<p>Total Memory: "..t.."<br>Used: "..u.."<br>Remain: "..r
                content = content..'<h3>WiFi Mode '..mode..'</h3>'
                if (mode == wifi.STATION) then
                  content = content..'<p>STA IP '..wifi.sta.getip()..' MAC ' .. wifi.sta.getmac()
                end
                if (mode == wifi.STATIONAP) then
                  content = content..'<p>AP IP '..wifi.ap.getip()..' MAC ' .. wifi.ap.getmac()
                end
                content = content..'<p>Uptime '..tmr.time()..'"'
                content = content..'</div>'
                local status = header..content..footer
                status = status:sub(1, 1459)
                conn:send(status)
            elseif req.request == '/j' or req.request == '/json' then
                local table = t.readtemptable(6)
                header = httpheader('200', 'json', place, '')
                content = cjson.encode(table)
                conn:send(header..content)
            elseif req.request:find("/register") then
                if uri.args.server ~= '' and file.open('register.txt', 'w') then
                    file.writeline(uri.args.server)
                    file.close()
                    local table = t.readtemptable(6)
                    header = 'Content-Type: application/json\r\n'
                    header = header ..'Authorization: Basic ZXQ6VHJl\r\n'
                    content = cjson.encode(table)
                    content = http.post(uri.args.server, header,content, function(code, data) end)
                end
                header = httpheader('200', 'html', place, '')
                if content == nil then
                    content = 'OK'
                end
                conn:send(header..content)
            elseif req.request:find("/help") then
                if file.open('help.txt', 'r') then
                    content = file.read()
                    file.close()
                end
                header = httpheader('200', 'html', place, '')
                local help = header..content..footer
                help = help:sub(1, 1459)
                conn:send(help)
            elseif req.request:find("/setname") then
                if uri.args.name == nil then
                    header = httpheader('200', 'html', t.place, '')
                    content = '<p><form action="/setname">'
                    content = content..'Name <input type="text" name="name"> '
                    content = content..'<input type="submit" value="Submit">'
                    content = content..'</form>'
                    content = content..'</p></div>'
                elseif uri.args.name:len() > 2 and file.open('place.txt', 'w') then
                    t.place = uri.args.name
                    file.writeline(t.place)
                    file.close()
                    header = httpheader('302', 'html', t.place, '<meta http-equiv="refresh" content="0; url=/"/>')
                    content = 'Set to'..t.place
                end
                conn:send(header..content..footer)
            elseif req.request:find("/setwifi") then
                header = httpheader('200', 'html', t.place, '')
                if uri.args.ssid == nil then
                    content = '<p><form action="/setwifi">'
                    content = content..'SSID <input type="text" name="ssid"> '
                    content = content..'PASS <input type="text" name="pass"> '
                    content = content..'<input type="submit" value="Submit">'
                    content = content..'</form>'
                elseif uri.args.pass ~= nil and uri.args.ssid:len() > 3 and  uri.args.pass:len() > 8 then 
                    file.open('wifi.config', 'w')
                    file.writeline(uri.args.ssid)
                    file.writeline(uri.args.pass)
                    file.close()
                    content = 'WiFi set to:'..uri.args.ssid..' '..uri.args.pass
                end
                content = content..'</p></div>'
                conn:send(header..content..footer)
            elseif req.request == '/reinit' then
                header = httpheader('200', 'html', t.place, '')
                content = '<h2><a href="/">Reinit. Wait...</a></h2>'
                conn:send(header..content)
                conn:on("disconnection", function(conn) conn:close() end)
                node.restart()
            else
                header = httpheader('404', 'html', place, '')
                conn:send(header..'Error 404')
            end
        else
            header = httpheader('404', 'html', place, '<meta http-equiv="refresh" content="0; url=/"/>')
            conn:send(header..'404 - error')
        end
        collectgarbage()
      end
      conn:on("receive", onReceive)
      conn:on("sent", function(conn) conn:close() end)
      --conn:on("disconnection", function(conn) conn:close() end)
    end)
end
