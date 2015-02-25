-- holds command-line commands to interact with sudoku --
-- mainly for debug --

local commands = {}

commands.available = {}

local sh = commands.available -- shortcut, becuase lazy

function sh.pos(sudoku, y,x)
	if tonumber(x) and tonumber(y) then 
		print((sudoku:getnum(y,x)))
	end 
end

sh.exit = function() print('bai') os.exit() end
sh.help = function() print("available commands") for i,v in pairs(sh) do print(i) end end
sh.possible = function(sudoku, y,x)
	local d = sudoku:processpossible(y,x)
	print("possible numbers in box " .. y .. "x" .. x .. ": ")
	for i,v in pairs(d) do
		if v then 
			print(i)
		end 
	end 
end

sh.pmap = function(sudoku)
	sudoku:makepmap()
	for y=1,9 do 
		for x=1,9 do 
			local use = sudoku.data[y][x][3]
			io.write(y.."x"..x..": ")
			for i,v in pairs(use) do 
				if v then 
					io.write(i..", ")
				end 
			end 
			io.write("\n")
		end 
	end
end

function sh.solve(sudoku)
	sudoku:solve()
end


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