#!/usr/bin/env lua5.3

-- 5.3 to support native 64bit hex to int conversion "tonumber"

-- install: lua5.3 ntpdate mosquitto-util wget

-- require 'dbg'

local SER_DEV = '/dev/ttyUSB0'
local MSG_LEN_HEX = 460
local MSG_LEN_BIN = 288

local SML_START_SEQUENCE = '1B1B1B1B0101010176'

local M180_KWH_OFFSET = 18180

--                 
                                        
function StringBytesToNumber(str)
 local hextxt = ''
 local len = #str
 for i = 1,len do
   ttt = string.byte(str,i)
   hextxt = hextxt .. string.format("%02X",ttt) 
 end
 return hextxt
end
 

--

print('easymeter SML')
     
assert(os.execute('stty -F ' .. SER_DEV .. ' raw 9600'))

wdh=0

repeat

  rserial=io.open(SER_DEV,"r")

  print('read serial...')

  rserial:flush()
  local t = ''

  msg = rserial:read(MSG_LEN_BIN,10)
  if msg then 
    txt = StringBytesToNumber(msg)
    -- print(txt)
    t = txt:sub(0,#SML_START_SEQUENCE)
  end
  wdh=wdh+1
  
  if wdh > 6 then
        print('read serial 6 wdh failed!')
  	os.exit(1)
  end

  rserial:flush()
  rserial:close()
  
until t == SML_START_SEQUENCE


-- decode

print(txt)

lenMsg=string.byte(msg,10)-1
lenMsg=6
modell = msg:sub(10+1,10+lenMsg)
print( "modell " .. modell )

lenMsg=string.byte(msg,31)
lenMsg=3
hersteller = msg:sub(31+1,31+1+lenMsg)
print( "hersteller " .. hersteller )


PP=299
L=54
A=txt:sub(PP,PP+L-1)
 print (A)
meas_key = 'M' .. string.format( "%d", tonumber( A:sub(9,10) ,16) ) .. '.' .. string.format( "%d", tonumber( A:sub(11,12) ,16) ) .. '.' .. string.format( "%d", tonumber( A:sub(13,14) ,16) )
local M180 = tonumber(A:sub(31+6,31+6+16-1), 16) / 10000000
print( meas_key .. ' wirkarbeit zaehler sum: ' .. string.format( "%.3f", M180 ) .. " kWh" )

M180=M180 + M180_KWH_OFFSET
print( meas_key .. ' wirkarbeit zaehler sum: ' .. string.format( "%.3f", M180 ) .. " kWh" )

PP=PP+L
L=48
A=txt:sub(PP,PP+L-1)
 print ( A )
meas_key = 'M' .. string.format( "%d", tonumber( A:sub(9,10) ,16) ) .. '.' .. string.format( "%d", tonumber( A:sub(11,12) ,16) ) .. '.' .. string.format( "%d", tonumber( A:sub(13,14) ,16) )
local M170 = tonumber(A:sub(31,31+16-1), 16) / 100
print( meas_key .. ' 16.7.0 wirkleistung summe L1 + L2 + L3 ' .. string.format( "%.3f", M170 ) .. " W " )

PP=PP+L
L=48
A=txt:sub(PP,PP+L-1)
 print ( A )
meas_key = 'M' .. string.format( "%d", tonumber( A:sub(9,10) ,16) ) .. '.' .. string.format( "%d", tonumber( A:sub(11,12) ,16) ) .. '.' .. string.format( "%d", tonumber( A:sub(13,14) ,16) )
local M3670 = tonumber(A:sub(31,31+16-1), 16) / 100
print( meas_key .. ' 36.7.0 wirkleistung L1 ' .. string.format( "%.3f", M3670 ) .. " W" )

PP=PP+L
L=48
A=txt:sub(PP,PP+L-1)
 print ( A )
meas_key = 'M' .. string.format( "%d", tonumber( A:sub(9,10) ,16) ) .. '.' .. string.format( "%d", tonumber( A:sub(11,12) ,16) ) .. '.' .. string.format( "%d", tonumber( A:sub(13,14) ,16) )
local M5670 = tonumber(A:sub(31,31+16-1), 16) / 100
print( meas_key .. ' 56.7.0 wirkleistung L2 ' .. string.format( "%.3f", M5670 ) .. " W" )

PP=PP+L
L=48
A=txt:sub(PP,PP+L-1)
 print ( A )
meas_key = 'M' .. string.format( "%d", tonumber( A:sub(9,10) ,16) ) .. '.' .. string.format( "%d", tonumber( A:sub(11,12) ,16) ) .. '.' .. string.format( "%d", tonumber( A:sub(13,14) ,16) )
local M7670 = tonumber(A:sub(31,31+16-1), 16) / 100
print( meas_key .. ' 76.7.0 wirkleistung L3 ' .. string.format( "%.3f", M7670 ) .. " W" )



-- plausibel?

if ( M180 > 999999 or M180 < 1000 ) then
	print( "M180 wirkarbeit zaehler sum: not plausible" )
	os.exit(1)
end
if ( M170 > 99999 or M170 < 0 ) then
	print( "M170 wirkleistung: not plausible" )
	os.exit(1)
end



-- datum

myYear = tonumber(os.date("%Y"))
if ( myYear > 2032 or myYear < 2014 ) then
	print("date not set")
	print(".")                                                         
	os.execute( '/usr/sbin/ntpdate ptbtime1.ptb.de' )
	print(".")       
end
	
myYear = tonumber(os.date("%Y"))
if ( myYear > 2032 or myYear < 2014 ) then
	print("date not set")
	os.exit(1)
end
 
myDatum = os.date("%Y-%m-%d")

--	os.exit(1)


-- store tageswert extern on database
--print( myDatum )

local cmd = "wget http://conil/strom/eingabe.php?datum=" .. myDatum .. "\\&licht=" .. string.format( "%.3f", M180 ) .. "\\&heiz= -q  "
print(' speicher tageswert ' .. cmd)
assert(os.execute( cmd ))


-- send values via mqtt to openhab

local mqtt_topic = "hw/easymeter"
local mqtt_host = "localhost"
local mqtt_msg = "{\"w180\":\"" .. string.format( "%.3f", M180 ) .. "\",\"w170\":\"" ..  string.format( "%.3f", M170 )  .. "\"" 
  .. ",\"model\":\"" .. modell  .. "\"" .. "}"
local mqtt_pub = "mosquitto_pub -h " .. mqtt_host .. " -m '" .. mqtt_msg .. "' -t " .. mqtt_topic
print(" mqtt pub")
assert(os.execute( mqtt_pub ))

-- hw/easymeter {"w180":"12500.535","w170":"278.670"}

print("fini.")
                
