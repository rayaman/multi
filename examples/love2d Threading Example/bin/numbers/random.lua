--[[----------------------------------------
Random
Not all of this is mine
------------------------------------------]]
--[[------------------------------------
RandomLua v0.3.1
Pure Lua Pseudo-Random Numbers Generator
Under the MIT license.
copyright(c) 2011 linux-man
--]]------------------------------------

local math_floor = math.floor

local function normalize(n)
	return n % 0x80000000
end

local function bit_and(a, b)
	local r = 0
	local m = 0
	for m = 0, 31 do
		if (a % 2 == 1) and (b % 2 == 1) then r = r + 2^m end
		if a % 2 ~= 0 then a = a - 1 end
		if b % 2 ~= 0 then b = b - 1 end
		a = a / 2 b = b / 2
	end
	return normalize(r)
end

local function bit_or(a, b)
	local r = 0
	local m = 0
	for m = 0, 31 do
		if (a % 2 == 1) or (b % 2 == 1) then r = r + 2^m end
		if a % 2 ~= 0 then a = a - 1 end
		if b % 2 ~= 0 then b = b - 1 end
		a = a / 2 b = b / 2
	end
	return normalize(r)
end

local function bit_xor(a, b)
	local r = 0
	local m = 0
	for m = 0, 31 do
		if a % 2 ~= b % 2 then r = r + 2^m end
		if a % 2 ~= 0 then a = a - 1 end
		if b % 2 ~= 0 then b = b - 1 end
		a = a / 2 b = b / 2
	end
	return normalize(r)
end

local function seed()
	return normalize(os.time())
end

--Mersenne twister
local mersenne_twister = {}
mersenne_twister.__index = mersenne_twister

function mersenne_twister:randomseed(s)
	if not s then s = seed() end
	self.mt[0] = normalize(s)
	for i = 1, 623 do
		self.mt[i] = normalize(0x6c078965 * bit_xor(self.mt[i-1], math_floor(self.mt[i-1] / 0x40000000)) + i)
	end
end

function mersenne_twister:random(a, b)
	local y
	if self.index == 0 then
		for i = 0, 623 do
			y = self.mt[(i + 1) % 624] % 0x80000000
			self.mt[i] = bit_xor(self.mt[(i + 397) % 624], math_floor(y / 2))
			if y % 2 ~= 0 then self.mt[i] = bit_xor(self.mt[i], 0x9908b0df) end
		end
	end
	y = self.mt[self.index]
	y = bit_xor(y, math_floor(y / 0x800))
	y = bit_xor(y, bit_and(normalize(y * 0x80), 0x9d2c5680))
	y = bit_xor(y, bit_and(normalize(y * 0x8000), 0xefc60000))
	y = bit_xor(y, math_floor(y / 0x40000))
	self.index = (self.index + 1) % 624
	if not a then return y / 0x80000000
	elseif not b then
		if a == 0 then return y
		else return 1 + (y % a)
		end
	else
		return a + (y % (b - a + 1))
	end
end

local function twister(s)
	local temp = {}
	setmetatable(temp, mersenne_twister)
	temp.mt = {}
	temp.index = 0
	temp:randomseed(s)
	return temp
end

--Linear Congruential Generator
local linear_congruential_generator = {}
linear_congruential_generator.__index = linear_congruential_generator

function linear_congruential_generator:random(a, b)
	local y = (self.a * self.x + self.c) % self.m
	self.x = y
	if not a then return y / 0x10000
	elseif not b then
		if a == 0 then return y
		else return 1 + (y % a) end
	else
		return a + (y % (b - a + 1))
	end
end

function linear_congruential_generator:randomseed(s)
	if not s then s = seed() end
	self.x = normalize(s)
end

local function lcg(s, r)
	local temp = {}
	setmetatable(temp, linear_congruential_generator)
	temp.a, temp.c, temp.m = 1103515245, 12345, 0x10000  --from Ansi C
	if r then
		if r == 'nr' then temp.a, temp.c, temp.m = 1664525, 1013904223, 0x10000 --from Numerical Recipes.
		elseif r == 'mvc' then temp.a, temp.c, temp.m = 214013, 2531011, 0x10000 end--from MVC
	end
	temp:randomseed(s)
	return temp
end

-- Multiply-with-carry
local multiply_with_carry = {}
multiply_with_carry.__index = multiply_with_carry

function multiply_with_carry:random(a, b)
	local m = self.m
	local t = self.a * self.x + self.c
	local y = t % m
	self.x = y
	self.c = math_floor(t / m)
	if not a then return y / 0x10000
	elseif not b then
		if a == 0 then return y
		else return 1 + (y % a) end
	else
		return a + (y % (b - a + 1))
	end
end

function multiply_with_carry:randomseed(s)
	if not s then s = seed() end
	self.c = self.ic
	self.x = normalize(s)
end

local function mwc(s, r)
	local temp = {}
	setmetatable(temp, multiply_with_carry)
	temp.a, temp.c, temp.m = 1103515245, 12345, 0x10000  --from Ansi C
	if r then
		if r == 'nr' then temp.a, temp.c, temp.m = 1664525, 1013904223, 0x10000 --from Numerical Recipes.
		elseif r == 'mvc' then temp.a, temp.c, temp.m = 214013, 2531011, 0x10000 end--from MVC
	end
	temp.ic = temp.c
	temp:randomseed(s)
	return temp
end
-- Little bind for the methods: My code starts
local randomGen={}
randomGen.__index=randomGen
function randomGen:new(s)
	local temp={}
	setmetatable(temp,randomGen)
	temp[1]=twister()
	temp[2]=lcg()
	temp[3]=mwc()
	temp.pos=1
	for i=1,3 do
		temp[i]:randomseed(s)
	end
	return temp
end
function randomGen:randomseed(s)
	self.pos=1
	self[1]:randomseed(s)
	self[2]:randomseed(s)
	self[3]:randomseed(s)
end
function randomGen:randomInt(a,b)
	local t=self[self.pos]:random(a,b)
	self.pos=self.pos+1
	if self.pos>3 then
		self.pos=1
	end
	return t
end
function randomGen:newND(a,b,s)
	if not(a) or not(b) then error('You must include a range!') end
	local temp=randomGen:new(s)
	temp.a=a
	temp.b=b
	temp.range=b-a+1
	temp.dups={no=0}
	function temp:nextInt()
		local t=self:randomInt(self.a,self.b)
		if self.dups[t]==nil then
			self.dups[t]=true
			self.dups.no=self.dups.no+1
		else
			return self:nextInt()
		end
		if self.dups.no==self.range then
			function self:nextInt()
				return 1,true
			end
			return t
		else
			return t
		end
	end
	function temp:nextIInt()
		return function() return self:nextInt() end
	end
	return temp
end
return randomGen
