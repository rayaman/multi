local cmds = {
    defaultManagerPort  = 0XDE2,
    defaultWait         = 0X002,
    defaultPort         = 0X000, -- We will let the OS assign us one
    standardSkip        = 0X018,
    ERROR               = 0X000,
    PING                = 0X001,
    PONG                = 0X002,
    QUEUE               = 0X003,
    TASK                = 0X004,
    INITNODE            = 0X005,
    INITMASTER          = 0X006,
    GLOBAL              = 0X007,
    LOAD                = 0X008,
    CALL                = 0X009,
    REG                 = 0X00A,
    CONSOLE             = 0X00B,
}
return cmds