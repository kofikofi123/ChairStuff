--local ScriptParent = script.Parent
local TypesModule = require(("ConstantType"))
local AST = require(("AST"))
local Tokenizer = require(("Tokenizer"))
local TokenStream = require(("TokenStream"))

local ttypes = TypesModule.Token
local ptypes = TypesModule.Parser
local warn = print

assert(AST ~= nil and Tokenizer ~= nil and TypesModule ~= nil, "Unable to parse, missing dependants")

do 
	--forward dec list
	local parseExp
	local parseBlock
	local parseIf
	--forward dec list
	local generateSyntaxError = function(msg, line)
		line = line or 1
		
		error(string.format("In line %d: %s", line, msg), 0)
	end
	local createProcTree = function(name)
		local tree = AST.createTree()
		
		tree.Type = ptypes.PROC
		tree.Name = name
		return tree
	end
	
	local createValueTree = function(value, _type_)
		local tree = AST.createTree()
		
		tree.Type = _type_
		tree.Value = value
		return tree
	end
	
	local createVariableTree = function(isLocal, nameList, expList)
		local tree = AST.createBinaryTree()
		
		tree.Type = ptypes.VARIABLE
		tree.isLocal = isLocal
		tree:linkLeftChild(nameList)
		tree:linkRightChild(expList)
		
		return tree
	end
	
	local createKeyPairTree = function(key, pair)
		local tree = AST.createBinaryTree()
		
		tree.Type = ptypes.FIELD
		tree.index = key
		tree.value = pair 
		
		return tree
	end
	
	local createRepeatTree = function(block, exp) 
		local tree = AST.createBinaryTree()
		
		tree.Type = ptypes.REPEAT
		tree.block = block
		tree.expression = exp
		
		return tree
	end
	
	local createBlockTree = function()
		local tree = AST.createTree()
		
		tree.Type = ptypes.BLOCK
		
		return tree
	end
	
	local createFunctionTree = function(name, extendedNameField, methodExtension, parameters, block, isLocal)
		local tree = AST.createTree()
		
		tree.Type = ptypes.FUNCTION
		tree.Name = name
		tree.ExtendedName = extendedNameField
		tree.ExtendedMethod = methodExtension
		tree.Parameters = parameters
		tree.Block = block
		tree.isLocal = isLocal
		
		
		return tree
	end
	local parseNameList = function(stream)
		local list = {}
		--[[
		if (not stream:checkType(ttypes.NAME)) then 
			generateSyntaxError(string.format("<name> expected near '%s'", stream:getCurrentSource()))
		end]]
		
		stream:mustCheckType(ttypes.NAME)
		table.insert(list, stream:getCurrentSource())
		
		stream.next()
		
		while stream:check(",") do 
			stream.next()
			if (not stream:checkType(ttypes.NAME)) then 
				stream.prev()
				break				
			end
			table.insert(list, stream:getCurrentSource())
			stream.next()
		end
		table.foreach(list, warn)
		return list
	end
	
	local createIfBlock = function(ifExpression, ifBlock, isMain, elseifs, elseBlock)
		local tree = AST.createTree()
		
		tree.Expression = ifExpression
		tree.Block = ifBlock
		
		if (not isMain) then return tree end
		tree.elseBlock = elseBlock
		tree.Children = elseifs
		return tree
	end
	
	local createWhileTree = function(expression, block)
		local tree = AST.createTree(expression, block)
		
		
		tree.Type = ptypes.WHILE
		tree.Expression = expression
		tree.Block = block
		
		return block
	end
	
	local parseVarList = function(stream)
		
	end
	
	local parseBinOperator = function(stream)
		local expA = parseExp(stream, true)
		
		local operator = stream:getCurrentSource()
		
		stream.next()
		
		local expB = parseExp(stream)
		
		local tree = AST.createBinaryTree()
		tree.Type = ptypes.BINOPS
		
		tree.linkLeftChild(expA)
		tree.linkRightChild(expB)
		table.foreach(expA.Children, print)
		tree.operator = operator
		
		return tree
	end
	
	local isBoolean = function(stream)
		return stream:check("true") or stream:check("false")
	end
	
	local toBoolean = function(stream)
		if (stream:check("true")) then
			return true
		else
			return false
		end
	end
	
	local toNumber = function(stream)
		return tonumber(stream:getCurrentSource())
		
	end
	
	local parseBasicValue = function(stream)
		local val
		local _type_
		local tree
		if (isBoolean(stream))  then
			val = toBoolean(stream)
			_type_ = ptypes.BOOLEAN
		elseif (stream:checkType(ttypes.NUMBER)) then
			val = toNumber(stream)
			_type_ = ptypes.NUMBER
		elseif (stream:checkType(ttypes.STRING)) then
			val = stream:getCurrentSource()
			_type_ = ptypes.STRING
		elseif (stream:check("nil")) then
			val = nil
			_type_ = ptypes.NIL
		else
			return nil
		end
		
		stream.next()
		
		return createValueTree(val, _type_)
	end
	
	local parseFunction = function(stream, isAnon)
		stream.next()
		local name, field, method = nil, {}, nil
		if (isAnon) then--[[
			if (not stream:check("(")) then 
				generateSyntaxError(string.format("Error in script: '(' expected near %s", stream:getCurrentSource()), stream:currentLine())
			end]]
			stream:mustCheck("(")
		else--[[
			if (not stream:checkType(ttypes.NAME)) then
				generateSyntaxError(string.format("Error in script: '<name>' expected near %s", stream:getCurrentSource()), stream:currentLine())
		end]]
			stream:mustCheckType(ttypes.NAME)
			
			name = stream:getCurrentSource()
			stream.next()
			
			while (stream:check(".")) do 
				stream.next()
				stream:mustCheckType(ttypes.NAME)
				table.insert(field, stream:getCurrentSource())
				stream.next()					
			end
			
			if (stream:check(":")) then
				stream.next()
				stream:mustCheckType(ttypes.NAME)
				method = stream:getCurrentSource()
				stream.next()
			end
			--[[
			if (not stream:check("(")) then 
				generateSyntaxError(string.format("Error in script: '(' expected near %s", stream:getCurrentSource()), stream:currentLine())
			end]]
			stream:mustCheck("(")
		
		end
				
		stream.next()
		
		local param
		if (stream:check(")")) then 
			param = {}
			stream.next()
		elseif (stream:check("...")) then 
			local param = {"..."}
			stream.next()
			--[[
			if (not stream:check(")")) then
				generateSyntaxError(string.format("Error in script: ')' expected near '%s'", stream:getCurrentSource()), stream:currentLine())
			end]]
			stream:mustCheck(")")
			
			stream.next()
		else
			param = parseNameList(stream)
			
			if (stream:check(",") and stream:checkNext("...")) then 
				table.insert(param, "...")
				stream.next(2)
			end			
			--[[
			if (not stream:check(")")) then
				generateSyntaxError(string.format("Error in script: ')' expected near '%s'", stream:getCurrentSource()), stream:currentLine())
			end]]
			stream:mustCheck(")")
			
			stream.next()
		end 
		
		local block = parseBlock(stream)--[[
		if (not stream:check("end")) then
			generateSyntaxError("Error in script: 'end' expected near '<eof>'", stream:currentLine())
		end]]
		stream:mustCheck("end", "<eof>")
		
		stream.next()
		
		return createFunctionTree(name, field, method, param, block, isLocal)
	end
	
	local parseField = function(stream)
		local key, value, item
		if (stream:check("[")) then
			key = parseExp(stream)
			--[[
			if (not stream:check("]")) then
				generateSyntaxError(string.format("Error in string: ']' expected near '%s'", stream:getCurrentSource()), stream:currentLine())
			end]]
			stream:mustCheck("]")
			stream.next()
			--[[
			if (not stream:check("=")) then
				generateSyntaxError(string.format("Error in string: '=' expected near '%s'", stream:getCurrentSource()), stream:currentLine())
			end]]
			stream:mustCheck("=")
			stream.next()
			
			value = parseExp(stream)
			
			item = createKeyPairTree(key, value)
		elseif (stream:checkType(ttypes.NAME)) then
			key = stream:getCurrentSource()
			--[[
			if (not stream:check("=")) then
				generateSyntaxError(string.format("Error in string: '=' expected near '%s'", stream:getCurrentSource()), stream:currentLine())
			end]]
			stream:mustCheck("=")
			stream.next()
			value = parseExp(stream)
			item = createKeyPairTree(key, value)			
		else
			
			item = parseExp(stream)
		end
		return item
	end
	
	local parseFieldList = function(stream)
		local field = {}
		
		field[1] = parseField(stream)
		
		while (stream:check(",") or stream:check(";")) do
			stream.next()
			
			table.insert(field, parseExp(stream))
		end
		
		
		return field
	end
	
	local parseTableConstructor = function(stream)
		stream.next()
		
		local list = parseFieldList(stream)
		--[[
		if (not stream:check("}")) then
			generateSyntaxError(string.format("Error in string: '}' expected near '%s'", stream:getCurrentSource()), stream:currentLine())
		end]]
		
		stream:mustCheck("}")
		stream.next()
	end
	
	local isFunctionCall = function(stream)
		stream.save()
		
		stream.next()
		
		
	end
	
	local isPrefix = function(stream)
		
	end

	parseExp = function(stream, othops)
		if (stream:check("function")) then
			return parseFunction(stream, true)
		elseif (stream:check("{")) then
			return parseTableConstructor(stream)
		elseif (stream:checkType(ttypes.UNIOPS)) then
			--return parseUniOperator(stream)
		elseif (stream:check("...")) then
			--
		elseif (stream:checkNextType(ttypes.BINOPS) and (not othops)) then
			return parseBinOperator(stream)
		--elseif (isPrefix(stream)) then
			--return parsePrefix(stream)
		else 
			return parseBasicValue(stream)
		end
		return nil
	end
	
	local parseExpList = function(stream)
		local exp = {}
		
		local val
		while (true) do 
			val = parseExp(stream)
			table.insert(exp, val)
			
			if (stream:check(",")) then 
				stream.next()
			else
				break
			end
		end
		
		local tree = AST.createTree()
		tree.Type = ptypes.EXPLIST
		tree.Children = exp
		
		
		return tree
	end
	
	local parseVariable = function(stream)
		local isLocal = false
		
		if (stream:check("local")) then
			isLocal = true
		end		
		
		stream.next()
		
		local name_list
		local exp_list
		
		if (isLocal) then 
			name_list = parseNameList(stream)
		else
			name_list = parseVarList(stream)
		end
		
		if (stream:check("=")) then 
			stream.next()
			exp_list = parseExpList(stream)
			
		end
		
	end
	
	
	
	local parseDo = function(stream)
		stream.next()
		local block = parseBlock(stream)--[[
		if (not stream:check("end")) then 
			generateSyntaxError("Error in script: 'end' expected near <eof>", stream:currentLine())
		end]]
		stream:mustCheck("end", "<eof>")
		stream.next()
	end
	
	local parseRepeat = function(stream)
		stream.next()
		local block = parseBlock(stream)
		--[[
		if (not stream:check("until")) then
			generateSyntaxError(string.format("Error in script: 'until' expected near %s", stream:getCurrentSource()), stream:currentLine())
		end]]
		stream:mustCheck("until")
		
		stream.next()
		
		local exp = parseExp(stream)
		
		return createRepeatTree(block, exp)
	end
	
	parseIf = function(stream, branch)
		stream.next()
		
		local exp = parseExp(stream)
		
		stream:mustCheck("then")
		stream.next()
		
		print(stream:getCurrentSource())
		
		local block = parseBlock(stream)
		local elseBlock = nil
		
		local elseifs = {}
		
		if (branch == true) then 
			
			return createIfBlock(exp, block, false) 
		end
		
		while (stream:check("elseif")) do 
			table.insert(elseifs, parseIf(stream, true))
		end
		
		if (stream:check("else")) then
			elseBlock = parseBlock(stream)
		end
		
		stream:mustCheck("end", "<eof>")
		stream.next()
		
		return createIfBlock(exp, block, true, elseifs, elseBlock)
	end

	local parseWhile = function(stream)
		stream.next()
		
		local expression = parseExp(stream)
		
		stream:mustCheck("do")
		stream.next()
		
		local block = parseBlock(stream)
		
		stream:mustCheck("end", "<eof>")
		stream.next()
		
		return createWhileTree(expression, block)
	end	
	
	local parseKeyword = function(stream)
		if (stream:check("local")) then
			warn(1)
			return parseVariable(stream)
		elseif (stream:check("do")) then
			warn(2)
			return parseDo(stream)
		elseif (stream:check("function")) then
			warn(3)
			return parseFunction(stream, false)
		elseif (stream:check("repeat")) then 
			warn(4)
			return parseRepeat(stream)
		elseif (stream:check("if")) then
			warn(5)
			return parseIf(stream)
		elseif (stream:check("while")) then
			warn(6)
			return parseWhile(stream)
		end
		warn(7)
		return nil
	end
	
	parseBlock = function(stream)
		local block = createBlockTree()
		local tree = nil
		while (not stream.isEnd() and (not stream:check("end"))) do
			if (stream:checkType(ttypes.KEYWORD)) then
				tree = parseKeyword(stream)
			elseif (stream:check('\n') or stream:check('\r')) then
				stream.next()
			else 
				break
			end
			
			if (tree ~= nil) then	
				table.insert(block.Children, tree)
			end
		end
		
		return block
	end
	
	
	function parser(tokens, name) 
		name = name or ""
		local stream = TokenStream(tokens)
		local mainProgram = createProcTree(name)
		local mainTree = parseBlock(stream)
		
	end
end

return parser
