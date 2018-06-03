local compiler = require("Compiler")

assert(not not compiler, "Compiler could not load")
function readFile(filename)
	local file = io.open(filename, "r")

	if (file == nil) then return nil end

	local content = file:read()

	io.close(file)

	return content 

end


local content = readFile(arg[1])

if (content == nil) then
	print("Why though")
	return -1
end

compiler.compile(content)