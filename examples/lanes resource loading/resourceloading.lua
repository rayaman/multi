local GLOBAL,sThread=require("multi.integration.lanesManager").init()
require("proAudioRt") -- an audio library
-- The hosting site with precompiled binaries is down, but here is a link to a archive
-- https://web.archive.org/web/20160907180559/http://viremo.eludi.net:80/proteaAudio/proteaaudiolua.html documentation and downloads are availiable... I also have saved copies just in case :D
-- Music by: myuuji
-- His youtube channel can be found here: https://www.youtube.com/channel/UCiSKnkKCKAQVxMUWpZQobuQ
proAudio.create()
multi:newThread("test",function()
	-- simple playlist
	sThread.waitFor("song")
	print("Playing song 1!")
	proAudio.soundPlay(GLOBAL["song"])
	sThread.waitFor("song2")
	thread.hold(function() sThread.sleep(.001) return proAudio.soundActive()==0 end)
	print("Playing song 2!")
	proAudio.soundPlay(GLOBAL["song2"])
	sThread.waitFor("song3")
	thread.hold(function() sThread.sleep(.001) return proAudio.soundActive()==0 end)
	print("Playing song 3!")
	proAudio.soundPlay(GLOBAL["song3"])
end)
-- loading the audio in another thread is way faster! So lets do that
multi:newSystemThread("test1",function() -- spawns a thread in another lua process
	require("proAudioRt")
	GLOBAL["song"]=proAudio.sampleFromFile("test.ogg",1,1)
	print("Loaded song 1!")
	GLOBAL["song2"]=proAudio.sampleFromFile("test2.ogg",1,1)
	print("Loaded song 2!")
	GLOBAL["song3"]=proAudio.sampleFromFile("test3.ogg",1,1)
	print("Loaded song 3!")
end)
multi:mainloop()
