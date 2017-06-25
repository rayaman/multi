--[=[ About This Module!
	This module is server side only! (Might add client side if requested)
	Aim is to make each lane (thread) have no more than 'n' number of connections
	This module hyjacks the multi:newConnection() function to seemlessly add support for threads without you having to change much
	As long as each server-client connection is isolated you should be fine
	The chatting module however IS NOT an isolated module, so take a look at how data was handled in that module to allow for both
	threaded and non threaded use

	How?
	When this module is loaded all server creation is altered by passing a proxyServer instead of an actual server object
	for example:
		proxy=net:newTCPServer(12345)
		proxy:OnDataRecieved(function(self,data,cid,ip,port)
			self:send("My data!")
		end)
		the real server instance could be on any of the threads. Careful! While using this is seemless becareful of IO opperations!
]=]
--~ net:registerModule("threading",{1,0,0})
--~ if not(lanes) then error("Require the lanes module!") end
--~ local serverlinda = lanes.linda()
--~ net.threading.newServer=net.newServer -- store the original method
--~ net.threading.newTCPServer=net.newTCPServer -- store the original method
--~ net.threading.proxy={} -- namespace for the proxy stuff. Because of the desgin intention of both UDP/TCP servers Only one proxy is needed
lanes=require("lanes")
serverlinda = lanes.linda()
mt={
	__index=function(t,k) print("IND",t,k) end,
	__newindex=function(t,k,v) print("NewIND",t,k,v) end,
}
test={}
setmetatable(test,mt)
test.a="hi"
test.a=true
g=test['a']
print(test.b)
--~ setmetatable(net.threading.proxy,mt) -- set the proxies metatable, to prevent bleeding only create one server.

