local ScriptParent = script
local Tokenizer = require(("Tokenizer"))
local TokenStream = require(("TokenStream"))
local Parser = require(("Parser"))
local warn = print

assert(Tokenizer ~= nil and TokenStream ~= nil and Parser ~= nil, "Unable to parse, missing dependants")


local module = {
	compile = function(source)
		local tokens = Tokenizer(source)
	
		local tree = Parser(tokens)
	end
}

return module
