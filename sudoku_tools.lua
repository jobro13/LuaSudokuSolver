-- This file is used to represent a sudoku structure. It isn't used to actually solve them --

-- Only 9x9 sudokus

pcall(function() return require("color") end) 

local sudoku = {}

sudoku.prettyprint = (color ~= nil)
sudoku.whitespace = 2;

sudoku.data = {}

local cmd_cache = {}

function sudoku:putspecial(what)
	local cmd = cmd_cache[what] or io.popen("tput "..what):read()
	cmd_cache[what] = cmd_cache[what] or cmd 
	io.write(cmd or "")
end

function sudoku:new()
	local obj = {}
	obj.data = {}
	for i = 1, 9 do
		obj.data[i] = {}
	end
	return setmetatable(obj, {__index=self, __tostring=self.print}) -- Just make a new sudoku.
end

function sudoku:load(fname,sudokunum)
	local sudokunum = sudokunum or 1; 
	local file,err  = io.open(fname)
	if file then
		local line
		for i = 1, sudokunum do 
			-- there might be a better solution to get a file line;
			line = file:read("*l")
		end
		if line:len() ~= 81 then 
			error("cannot open sudoku " .. fname .. ": not 81 characters")
		end 
		for i = 1,81 do 
			local row = math.ceil(i/9)
			local column = i - (row*9) + 9
			local char = line:sub(i,i)
			if tonumber(char) then 
				self.data[row][column] = {tonumber(char), "nonempty"}
			else
				self.data[row][column] = {nil, "empty"}
			end
		end
	else
		print(err)
	end
end

-- row, column -> following matrix notation
function sudoku:getnum(y,x)
	local data = self.data[tonumber(y)][tonumber(x)]
	return data[1], data[2]
end 

function sudoku:print(home)
	if home then
		self:putspecial("home")
	end
	local pos=0
	-- start printing te border

	local function border()
		io.write("+")
		for box = 1,3 do 
			for num = 1,3 do 
				io.write(string.rep("-", self.whitespace))
				io.write("-") -- number place;
			end
			io.write(string.rep("-", self.whitespace))
			if box ~= 3 then 
				io.write("-")
			end
		end
		io.write("+\n")
	end
	border()

	for row = 1,9 do 
		io.write("|"..string.rep(" ", self.whitespace))
		for column = 1,9 do 
			local num, dtype = self:getnum(row, column)
			local tcolor = "green"
			if dtype == "empty" then 
				tcolor = "red"
			elseif dtype == "try" then 
				tcolor = "yellow"
			end
			if self.prettyprint then
				color("%{"..tcolor.."}"..(num or ".") .. "%{reset}")
			else 
				io.write(num or ".")
			end
			io.write(string.rep(" ", self.whitespace))
			if math.floor(column/3) == (column/3) and (column ~= 9) then 
				io.write("|" .. string.rep(" ", self.whitespace))
			end
		end
		io.write("|\n")
	end
	border()
end

return sudoku