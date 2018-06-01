--[[
LZW String Compression demo for Gideros
This code is MIT licensed, see http://www.opensource.org/licenses/mit-license.php
(C) 2013 - Guava7
]]
CLZWCompression = {}
function CLZWCompression:InitDictionary(isEncode)
	self.mDictionary = {}
	-- local s = " !#$%&'\"()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~"
	local s={}
	for i=1,255 do
		s[#s+1]=string.char(i)
	end
	s=table.concat(s)
	local len = #s
	for i = 1, len do
		if isEncode then
			self.mDictionary[s:sub(i, i)] = i
		else
			self.mDictionary[i] = s:sub(i, i)
		end
	end
	self.mDictionaryLen = len
end
function CLZWCompression:Encode(sInput)
	self:InitDictionary(true)
	local s = ""
	local ch
	local len = #sInput
	local result = {}
	local dic = self.mDictionary
	local temp
	for i = 1, len do
		ch = sInput:sub(i, i)
		temp = s..ch
		if dic[temp] then
			s = temp
		else
			result[#result + 1] = dic[s]
			self.mDictionaryLen = self.mDictionaryLen + 1
			dic[temp] = self.mDictionaryLen
			s = ch
		end
	end
	result[#result + 1] = dic[s]
	return result
end
function CLZWCompression:Decode(data)
	self:InitDictionary(false)
	local dic = self.mDictionary
	local entry
	local ch
	local prevCode, currCode
	local result = {}
	prevCode = data[1]
	result[#result + 1] = dic[prevCode]
	for i = 2, #data do
		currCode = data[i]
		entry = dic[currCode]
		if entry then
			ch = entry:sub(1, 1)
			result[#result + 1] = entry
		else
			ch = dic[prevCode]:sub(1, 1)
			result[#result + 1] = dic[prevCode]..ch
		end
		dic[#dic + 1] = dic[prevCode]..ch
		prevCode = currCode
	end
	return table.concat(result)
end

return CLZWCompression
