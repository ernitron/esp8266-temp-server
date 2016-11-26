-- Reference server for NodeMCU 

-- Defaults
local wifiConfig = {}
local ssid 
local pwd

-- Read settings from file
if file.open('wifi.config', 'r') then
    ssid = file.readline()
    ssid = ssid:sub(1, -2)
    pwd  = file.readline()
    pwd  = pwd:sub(1, -2)
    file.close()
    print ('Wifi config ', ssid, pwd)
else
    -- file wifi.config MUST be present
    print ('NO Wifi config', ssid, pwd)
end


-- WiFi Config
wifiConfig.accessPointConfig = {}
wifiConfig.accessPointConfig.ssid = "YoT-"..node.chipid()   -- Name of the SSID to create
wifiConfig.accessPointConfig.pwd = "DefaultPass"   -- WiFi password - at least 8 characters
wifiConfig.accessPointIpConfig = {}
wifiConfig.accessPointIpConfig.ip = "192.168.10.1"
wifiConfig.accessPointIpConfig.netmask = "255.255.255.0"
wifiConfig.accessPointIpConfig.gateway = "192.168.10.1"
wifiConfig.stationPointConfig = {}
wifiConfig.stationPointConfig.ssid = ssid        -- Name of the WiFi network 
wifiConfig.stationPointConfig.pwd =  pwd         -- Password for the WiFi network

-- Tell the chip to connect to the access point
-- wifi.STATION         -- station: join a WiFi network
-- wifi.SOFTAP          -- access point: create a WiFi network
-- wifi.wifi.STATIONAP  -- both station and access point
-- wifiConfig.mode = wifi.STATION  -- station
wifiConfig.mode = wifi.STATION
wifi.setmode(wifiConfig.mode)

-- Print Settings
--print('Mode:', wifi.getmode())
--print('chip:', node.chipid())
--print('heap:', node.heap())

if (wifiConfig.mode == wifi.SOFTAP) or (wifiConfig.mode == wifi.STATIONAP) then
    print('AP MAC:', wifi.ap.getmac())
    wifi.ap.config(wifiConfig.accessPointConfig)
    wifi.ap.setip(wifiConfig.accessPointIpConfig)
end
if (wifiConfig.mode == wifi.STATION) or (wifiConfig.mode == wifi.STATIONAP) then
    print('Client MAC:', wifi.sta.getmac())
    wifi.sta.config(wifiConfig.stationPointConfig.ssid, wifiConfig.stationPointConfig.pwd, 1)
end


-- Garbage collection
--ssid = nil
pwd = nil
wifiConfig = nil
collectgarbage()
-- End WiFi configuration

-- Compile server code and remove original .lua files.
-- This only happens the first time afer the .lua files are uploaded.
local compileAndRemoveIfNeeded = function(f)
   if file.open(f) then
      file.close()
      --print('Compiling:', f)
      node.compile(f)
      file.remove(f)
      collectgarbage()
   end
end

local serverFiles = {
    'request.lua',
    'httpserver.lua',
    'ds18b20.lua',
    'register.lua',
}
for i, f in ipairs(serverFiles) do compileAndRemoveIfNeeded(f) end

compileAndRemoveIfNeeded = nil
serverFiles = nil
collectgarbage()

-- Connect to the WiFi access point.
-- Once the device is connected, you may start the HTTP server.
if (wifi.getmode() == wifi.STATION) or (wifi.getmode() == wifi.STATIONAP) then
    local ip = wifi.sta.getip()
    local joinCounter = 0
    local joinMaxAttempts = 10
    tmr.alarm(0, 2000, 1, function()
       local ip = wifi.sta.getip()
       if ip == nil and joinCounter < joinMaxAttempts then
          print('Connect WiFi - Try '..joinCounter)
          joinCounter = joinCounter +1
       else
          if joinCounter > joinMaxAttempts then
             print('Cant connect WiFi')
          else
             print('IP: ', ip)
          end
          tmr.stop(0)
          joinCounter = nil
          joinMaxAttempts = nil
          collectgarbage()
       end
    end)
end

dofile("register.lc")()
dofile("httpserver.lc")(8805)

