--[[
    global pads allow us to directly write data to threads. Each thread has a unique ID which means we can allocate space in memory for each thread to relay stats
    Below are codes, If there is more data that needs to be sent we can use byte 0 for that and byte 1,2 and 3 to define a channel
]]
local char = string.char
local cmds = {
    OK          = char(0x00), -- All is good thread is running can recieve and send data
    ERR         = char(0x01), -- This tells the system that an error has occured
    STOP        = char(0x02), -- Thread has finished
    BUSY        = char(0x03), -- Thread is busy and isn't responding to messages right now
    POST        = char(0x04), -- Important message for other threads to see, ChannelData with message MSG_TID   
}
return cmds