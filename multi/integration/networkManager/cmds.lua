local cmds = {
    ERROR = 0x00,
    PING = 0x01,
    PONG = 0x02,
    QUEUE = 0x03,
    TASK = 0x04,
    INITNODE = 0x05,
    INITMASTER = 0x06,
    GLOBAL = 0x07,
    LOAD = 0x08,
    CALL = 0x09,
    REG = 0x0A,
    CONSOLE = 0x0B,
}
return cmds