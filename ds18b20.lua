--------------------------------------------------------------------------------
-- Modified Erni Tron ernitron@gmail.com to work with httpserver
--------------------------------------------------------------------------------
-- Module name as parameter of require 
-- it will be called with require('ds18b20')
local modname = ...
local M = {}
_G[modname] = M

-- Limited to local environment
local string = string
local ow = ow
local tmr = tmr
local wifi = wifi
local node = node
local file = file

setfenv(1, M)

-- Implementation --------------------------------------------------------------
read_count = 0
sensor = 'DS18b20'
place = 'ESP-8266'

function readtemptable(pin)
    local temptable = {}
    local temp = 'null'
    local count = 0

    if file.open('place.txt', 'r') then
      place = file.read()
      place = string.gsub(place, '\n', '')
      file.close()
    end

    -- Std
    temptable["place"] = place
    temptable["chipid"] = node.chipid()
    temptable["date"] = string.format('%d', tmr.time())
    temptable["server"] = wifi.sta.getip()
    temptable["mac"] = wifi.sta.getmac()
    temptable["temp"] = temp
    temptable["count"] = count
    temptable["sensor"] = ''

    ow.setup(pin)
    repeat
      count = count + 1
      addr = ow.reset_search(pin)
      addr = ow.search(pin)
      tmr.wdclr()
    until((addr ~= nil) or (count > 100))
    if (addr == nil) then
      return temptable
    end

    -- Found a sensor 
    sensor = string.format("%x-", addr:byte(1))
    for i=7,2,-1 do
       sensor = sensor..string.format("%02x", addr:byte(i))
    end
    temptable["sensor"] = sensor

    crc = ow.crc8(string.sub(addr,1,7))
    if (crc == addr:byte(8)) then
        if ((addr:byte(1) == 0x10) or (addr:byte(1) == 0x28)) then
          -- DS18S20 family device detected
          -- repeat
              ow.reset(pin)
              ow.select(pin, addr)
              ow.write(pin, 0x44, 1)
              tmr.delay(1000000)
              present = ow.reset(pin)
              ow.select(pin, addr)
              ow.write(pin,0xBE,1)
              --print("P="..present)  
              data = nil
              data = string.char(ow.read(pin))
              for i = 1, 8 do
                data = data..string.char(ow.read(pin))
              end
              --print(data:byte(1,9))
              crc = ow.crc8(string.sub(data,1,8))
              --print("CRC="..crc)
              if (crc == data:byte(9)) then
                 t = (data:byte(1) + data:byte(2) * 256)
                 -- handle negative temperatures
                 if (t > 0x7fff) then
                    t = t - 0x10000
                 end
                 if (addr:byte(1) == 0x28) then
                    t = t * 625  -- DS18B20, 4 fractional bits
                 else
                    t = t * 5000 -- DS18S20, 1 fractional bit
                 end
                 local sign = ""
                 if (t < 0) then
                     sign = "-"
                     t = -1 * t
                 end
                 -- Separate integral and decimal portions, for integer firmware only
                 local t1 = string.format("%d", t / 10000)
                 local t2 = string.format("%04u", t % 10000)
                 temp = sign .. t1 .. "." .. t2
                 read_count = read_count + 1
                 temptable["temp"] = temp
                 temptable["count"] = read_count
                 return temptable
              end                   
              tmr.wdclr()
          --until false
        else
          -- Temperature
          temptable["temp"] = temp
          temptable["count"] = read_count
          return temptable
        end
    else
        return temptable
    end
end

-- Return module 
return M
