require("Library")
local clock = os.clock
function sleep(n)  -- seconds
  local t0 = clock()
  while clock() - t0 <= n do end
end
function tester(test)
	sleep(1)
	return test*10
end
--~ require("bin")
--~ test=bin.namedBlockManager()
--~ test["name"]="Ryan"
--~ test["age"]=21
--~ test:tofile("test.dat")
--~ test2=bin.namedBlockManager("test.dat")
--~ print(test2["name"])
--~ print(test2["age"])
