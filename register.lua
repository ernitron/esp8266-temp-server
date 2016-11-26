local function register(header, content, url)
    if url == nil then return end
    http.post(url, header, content,
     function(code, data)
        if (code < 0) then
            print("HTTP register err ", code)
        end
     end)
end

t = require('ds18b20')
     
return function()
    local register_server = nil
    local auth = ''
    if file.open('register.txt', 'r') then
        register_server = file.readline()
        register_server = register_server:sub(1, -2)
        auth = file.readline()
        auth = auth:sub(1, -2)
    end
    local header = 'Content-Type: application/json\r\nAuthorization: Basic '..auth..'\r\n'

    -- Every 5 minutes (= 300 secs)
    tmr.alarm(1, 300000, 1, function ()
      local table = t.readtemptable(6)
      local content = cjson.encode(table)
      print ('Reg', register_server, content)
      register(header, content, register_server)
    end)
end

