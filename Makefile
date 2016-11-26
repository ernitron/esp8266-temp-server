######################################################################
# User configuration
######################################################################
# Path to nodemcu-uploader (https://github.com/kmpm/nodemcu-uploader)
NODEMCU-UPLOADER=nodemcu-uploader.py
NODEMCU-UPLOADER=/usr/local/bin/nodemcu-uploader
ESPTOOL=/opt/ESP8266/esptool/esptool.py 
# Serial port
#PORT=/dev/cu.SLAB_USBtoUART
PORT=/dev/ttyUSB0
SPEED=115200

######################################################################
# End of user config
######################################################################
HTTP_FILES := $(wildcard http/*)
LUA_FILES := \
	ds18b20.lua \
	httpserver.lua \
	request.lua \
    register.lua \
	init.lua  \
    register.txt \
	wifi.config \
	help.txt \

FILE = httpserver.lua


erase:
	$(ESPTOOL) --port $(PORT) erase_flash 

# FLASH
flash:
	$(ESPTOOL) --port /dev/ttyUSB0 write_flash 0x00000 /opt/ESP8266/nodemcu-firmware/bin/0x00000.bin 0x10000 /opt/ESP8266/nodemcu-firmware/bin/0x10000.bin

# Upload all
install: $(LUA_FILES) $(HTTP_FILES)
	python $(NODEMCU-UPLOADER) -b $(SPEED) -p $(PORT) upload $(foreach f, $^, $(f))

# Print usage
usage:
	@echo "make upload FILE:=<file>  to upload a specific file (i.e make upload FILE:=init.lua)"
	@echo "make upload_http          to upload files to be served"
	@echo "make upload_server        to upload the server code and init.lua"
	@echo "make upload_all           to upload all"
	@echo $(TEST)

# Upload one files only
upload:
	@python $(NODEMCU-UPLOADER) -b $(SPEED) -p $(PORT) upload $(FILE)

# Upload HTTP files only
upload_http: $(HTTP_FILES)
	@python $(NODEMCU-UPLOADER) -b $(SPEED) -p $(PORT) upload $(foreach f, $^, $(f))

# Upload httpserver lua files (init and server module)
upload_server: $(LUA_FILES)
	@python $(NODEMCU-UPLOADER) -b $(SPEED) -p $(PORT) upload $(foreach f, $^, $(f))

