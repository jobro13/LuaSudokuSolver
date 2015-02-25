-- holds command-line commands to interact with sudoku --
-- mainly for debug --

local commands = {}

commands.available = {}

local sh = commands.available -- shortcut, becuase lazy

function sh.pos(sudoku, x,y)
	if tonumber(x) and tonumber(y) then 
		print((sudoku:getnum(x,y)))
	end 
end

sh.exit = function() print('bai') os.exit() end
sh.help = function() print("available commands") for i,v in pairs(sh) do print(i) end end

function commands.execute(sudoku, cmdline)
	local arg,rest = cmdline:match(("(%w+)(.*)"))
	if commands.available[arg] then
		local split = {}
		-- start splitting args by spaces
		for str in string.gmatch(rest, "%S+") do
			table.insert(split,str)
		end 
		ok, str= pcall(commands.available[arg], sudoku, unpack(split))
		if not ok then 
			print("command error", str)
		end
	else 
		print(arg .. " does not exist")
	end
end


return commands.execute