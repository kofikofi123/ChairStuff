local TypesModules = require(script.Parent:FindFirstChild("ConstantType"))

assert(TypesModules ~= nil, "Unable to load types")

local types = TypesModules.Token
do
	local keywords = {"and", "break", "do", "else", "elseif",
					  "end", "false", "for", "function", "if",
					  "in", "local", "nil", "not", "or",
					  "repeat", "return", "then", "true", "until", "while"}
	
	local binaryoperators = {'+', '-', '*', '/', '^', '%', "..",
							 '<', "<=", '>', ">=", "==", "~=", 
							"and", "or"}
	local uniaryoperators = {'-', "not", '#'}
	local otheroperators = {',', ';', '{', '}', '(', ')', '=', '\n', '\r', "...", "."}

	local newToken = function() 
		return {
			Type = 0,
			Source = ""
		}
	end
	
	local fowardString = function(str, length, no_result)
		local stub = string.sub(str, length + 1, -1)
		if (no_result == true) then return stub end
			
		local new_str = string.sub(str, 1, length)
		return stub, new_str
	end
	
	local inRange = function(v, min, max)
		return (v >= min) and (v <= max)
	end
	
	local getC = function(str, s, a)
		a = a or 1
		return string.sub(str, a, s)
	end
	
	local isNumber = function(source)
		return inRange(string.byte(getC(source, 1)), 0x30, 0x39)
	end
	
	local isLetter = function(source)
		local n = string.byte(getC(source, 1))
		
		return inRange(n, 0x41, 0x5A) or inRange(n, 0x61, 0x7A) or (n == 0x5F)
	end
	
	local searchTables = function(tbl, source)
		
		local tempA, tempB
		for i = 1, #tbl do 
			tempA = tbl[i]
			tempB = getC(source, #tempA)
			
			if (tempA == tempB) then 
				return true, i, tempA
			end
		end
		return false, -1, nil
	end
	
	local isString = function(source)
		local c = string.byte(getC(source, 1))
		return (c == 0x22) or (c == 0x27)
	end
	
	local isWhitespace = function(source)
		local n = string.byte(getC(source, 1))
		
		return (n == 0x0D) or (n == 0x20) or (n == 0x0A) or (n == 0x09)
	end
	
	local isSymbol = function(source)
		local result, tempA, tempB
	
		local tbls = {binaryoperators, uniaryoperators, otheroperators}
		
		local temp2 = source
		local size_temp=  nil
		
		
		for i = 1, #tbls do 
			result, tempA, tempB = searchTables(tbls[i], temp2)
			
			if (result == true) then
				size_temp = #tempB
			end
		end
	
		if (size_temp == nil) then
			return false
		else
			return true
		end
	end
	
	local typeToString = function(_type_) 
		local name, value 
		
		for name, value in pairs(types) do 
			if (value == _type_) then 
				return name
			end
		end
		
		return "[NONE]"
	end
	
	local tokenizeNumber = function(source)
		local temp2 = fowardString(source, 1, true)
		local dec = false
		local a = 1
		while (true) do 
			if (isNumber(temp2)) then 
				temp2 = fowardString(temp2, 1, true)
				a = a + 1
			elseif (getC(temp2, 1) == ".") then
				assert(not dec, "malformed number")
				dec = true
				temp2 = fowardString(temp2, 1, true)
				a = a + 1
			elseif (getC(temp2, 1) == "e") then 
				local pom = getC(temp2, 1, 2)
				
				temp2 = fowardString(temp2, 1, true)
				a = a + 1
				
				if (pom == "+" or pom == "-") then
					temp2 = fowardString(temp2, 1, true)
					a = a + 1
				end				

				dec = true
				a = a + 1
				
			else
				assert(not isLetter(temp2), "malformed number")
				break
			end
		end
		
		local token = newToken()
		token.Type = types.NUMBER
		token.Source = string.sub(source, 1, a)
		
		return token, temp2
	end
	
	local tokenizeSpecialNumber = function(source) 
		
	end
	
	local tokenizeString = function(source)
		local temp = fowardString(source, 1, true)
		local temp2 = temp
		local a = 0
		local c
		while (true) do 
			assert(#temp2 ~= 0, "Unfinished string")
			c = string.byte(getC(temp2, 1))
			temp2 = fowardString(temp2, 1, true)
			
			if (c == 0x5C) then
				c = getC(temp2, 1)
				if (isString(c)) then
					temp2 = fowardString(temp2, 1, true)
					a = a + 2
				end
			elseif (c == 0x22 or c == 0x27) then 
				break
			end
			
			a = a + 1
		end
		
		local token = newToken()
		
		token.Type = types.STRING
		token.Source = string.sub(temp, 1, a)
		
		return token, temp2
	end
	
	local tokenizeOperators = function(source)
		
		local temp = source
		
		
		local tbls = {binaryoperators, uniaryoperators, otheroperators}
		local t = {types.BINOPS, types.UNIOPS, types.OTHOPS}
		local r, i, v
		
		local s_temp
		local t_temp
		local size_temp = nil
		
		
		for index = 1, #tbls do 
			r, i, v = searchTables(tbls[index], temp)
			
			if (r == true) then
				if (size_temp == nil) then
					size_temp = #v
					s_temp = v
					t_temp = index
					
				elseif (size_temp < #v) then
					size_temp = #v
					s_temp = v
					t_temp = index
					
				end			
			end
		end
		if (size_temp == nil) then print("eok");return nil, nil end
		
		
		local token = newToken()
		token.Type = t[t_temp]
		token.Source = s_temp
		
		local nsource = fowardString(source, #s_temp, true)

		
		return token, nsource
	end
	
	local isKeyword = function(source) 
		local keyword
		local temp
		for i = 1, #keywords do 
			keyword = keywords[i]
			temp = getC(source, #keyword)
			if (keyword == temp) then
				return true
			end
		end
		
		return false
	end
	
	local tokenizeName = function(source)
		local temp2 = fowardString(source, 1, true)
		local a = 1
		while (true) do 
			if (not isWhitespace(temp2) and (isNumber(temp2) or isLetter(temp2))) then 
				temp2 = fowardString(temp2, 1, true)
				a = a + 1
			else
				break
			end
		end
		
		local token = newToken()
		token.Source = string.sub(source, 1, a)
		if (isKeyword(token.Source)) then 
			token.Type = types.KEYWORD
		else
			token.Type = types.NAME
		end
		
		return token, temp2
	end
	
	function tokenizer(source)
		local tokens = {}
		local character = ''
		local temp = ""
		local token
		while (#source > 0 and source ~= nil) do
			if (isSymbol(source)) then
				token, source = tokenizeOperators(source)
			elseif (isString(source)) then 
				token, source = tokenizeString(source)
			elseif (isNumber(source)) then 
				token, source = tokenizeNumber(source)
			elseif (isLetter(source)) then
				token, source = tokenizeName(source)
			else
				token = nil 
			end
						
			if (token ~= nil) then 
				table.insert(tokens, token)
			else
				source = fowardString(source, 1, true)
			end
			
			
		end
		
		table.foreach(tokens, function(i, v) 
			print(typeToString(v.Type), v.Source)
		end)
		return tokens
	end
end


return tokenizer
