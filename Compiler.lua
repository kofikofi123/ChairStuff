local ScriptParent = script
local Tokenizer = require(ScriptParent:FindFirstChild("Tokenizer"))
local TokenStream = require(ScriptParent:FindFirstChild("TokenStream"))
local Parser = require(ScriptParent:FindFirstChild("Parser"))

assert(Tokenizer ~= nil and TokenStream ~= nil and Parser ~= nil, "Unable to parse, missing dependants")


local module = {
	compile = function(source)
		local tokens = Tokenizer(source)
	
		local tree = Parser(tokens)
	end
}

return module
