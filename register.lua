local function register(content, url)
    local header = 'Content-Type: application/json\r\n'
    header = header ..'Authorization: Basic ZXQ6VHJl\r\n'
    http.post(url, header, content,
    function(code, data)
        if (code < 0) then
            print("HTTP register err ", code)
        end
    end)
end

t = require('ds18b20')
     
return function()
    local register_server = 'http://tempserver.ypketron.eu:8805/rt'
    if file.open('register.txt', 'r') then
        register_server = file.readline()
        register_server = string.gsub(register_server, '\n', '')
    end
    -- Every 5 minutes (= 300 secs)
    tmr.alarm(1, 300000, 1, function ()
      local table = t.readtemptable(6)
      local content = cjson.encode(table)
      print ('Reg', register_server, content)
      register(content, register_server)
     
    end)
end

