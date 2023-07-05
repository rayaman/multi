function love.conf(t)
	t.identity = nil -- The name of the save directory (string)
	t.version = "11.4" -- The LOVE version this game was made for (string)
	t.console = true -- Attach a console (boolean, Windows only)

	t.window = false

	t.modules.audio = false -- Enable the audio module (boolean)
	t.modules.event = false -- Enable the event module (boolean)
	t.modules.graphics = false -- Enable the graphics module (boolean)
	t.modules.image = false -- Enable the image module (boolean)
	t.modules.joystick = false -- Enable the joystick module (boolean)
	t.modules.keyboard = false -- Enable the keyboard module (boolean)
	t.modules.math = false -- Enable the math module (boolean)
	t.modules.mouse = false -- Enable the mouse module (boolean)
	t.modules.physics = false -- Enable the physics module (boolean)
	t.modules.sound = false -- Enable the sound module (boolean)
	t.modules.system = false -- Enable the system module (boolean)
	t.modules.timer = false -- Enable the timer module (boolean)
	t.modules.window = false -- Enable the window module (boolean)
	t.modules.thread = true -- Enable the thread module (boolean)
end
--1440 x 2560
