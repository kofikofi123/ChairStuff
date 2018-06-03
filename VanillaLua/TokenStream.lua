local TypesModule = require(("ConstantType"))
local warn = print

assert(TypesModule ~= nil, "Unable to load types module")
local types = TypesModule.Token

local typeToString = function(_type_) 
	local name, value 
		
	for name, value in pairs(types) do 
		if (value == _type_) then 
			return name
		end
	end
		
	return "[NONE]"
end

return function(tokens)
	local index = 1
	local savedIndex = 1
	return {
		currentLine = function(self)
			local line = 1
			local tTok = self.getCurrentToken()
			self.save()
			self.reset()
			while (not self.isEnd()) do
				local token = self.getCurrentToken()
				if (token == nil) then return nil end
				if (token == tTok) then 
					return line
				end
				
				if (token.Source == '\n' or token.Source == '\r') then
					line = line + 1
				end
				
				self.next()
			end
			return nil
		end,
		checkType = function(self, t)
			if (not self.isEnd()) then return false end
			return (tokens[index].Type == t)
		end,
		check = function(self, src)
			if (self.isEnd()) then return false end
			return (tokens[index].Source ==  src)
		end,
		mustCheck = function(self, src, msgA)
			if (not self:check(src)) then 
				return self:generateExpectedError(src, msgA)
			end
			
			return true
		end,
		mustCheckType = function(self, _type_, msgA)
			if (not self:checkType(_type_)) then 
				return self:generateExpectedError(string.format("<%s>", string.lower(typeToString(_type_))), msgA)
			end
			
			return true
		end,
		getCurrentToken = function()
			return tokens[index]
		end,
		getCurrentSource = function(self)
			return self:getCurrentToken().Source
		end,
		checkNextType = function(self, _type_, a)
			self.save()
			self.next(a)
			local typ =  false
			if (not self.isEnd()) then 
				typ = self:checkType(_type_)
			end
			self.restore()
			print(index)
			return typ
		end,
		checkNext = function(self, src, a)
			self.save()
			self.next(a)
			local typ = false
			if (not self.isEnd()) then
				typ = self:check(src)
			end
			self.restore()
			print(index)
			return typ
		end,
		next = function(a)
			a = a or 1
			
			index = index + a


		end,
		prev = function(a)
			a = a or 1

			index = index - a
		end,
		generateExpectedError = function(self, expectedSrc, nearSrc)
			error(string.format("Error in script: '%s' expected near '%s'", expectedSrc, nearSrc or self:getCurrentSource()), 0)
		end,
		isEnd = function()
			return (index > #tokens)
		end,
		reset = function(a)
			index = 1
		end,
		save = function()
			savedIndex = index
		end,
		restore = function()
			index = savedIndex
		end
	}
end
