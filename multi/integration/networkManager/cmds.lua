--[[
MIT License

Copyright (c) 2020 Ryan Ward

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sub-license, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]
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