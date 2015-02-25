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
				self.data[row][column] = {tonumber(char), "nonempty", {}}
			else
				self.data[row][column] = {nil, "empty", {}}
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

function sudoku:makepmap()
	for y=1,9 do
		for x=1,9 do 
			self:processpossible(y,x)
		end 
	end
end

-- process all possible numbers, putting then in the 3rd index of the data table
function sudoku:processpossible(y,x)
	local y,x = tonumber(y), tonumber(x)
	local use = self.data[y][x][3]
	local stat = self.data[y][x][2]
	if stat ~= "empty" then 
		for i = 1, 9 do 
			use[i] = false 
		end 
	else 
		local box = self:getnumbersinbox(y,x)
		local row = self:getnumbersinrow(y)
		local column = self:getnumbersincolumn(x)
		for i = 1, 9 do 
			use[i] = not(box[i] or row[i] or column[i])
		end
	end 
	return use 
end

-- list returned by following 4 funcitons:
-- [num] = true/false (meaning "is in box", "is in row", etc (conjugate NOTs them))

-- get all numbers inside a box
function sudoku:getnumbersinbox(y,x)
	local list = {}
	local xstart = math.floor((x-1)/3)*3+1
	local ystart = math.floor((y-1)/3)*3+1
	for y=ystart,ystart+2 do
		for x=xstart,xstart+2 do
			local num = self:getnum(y,x)
		
			if num then 
				list[num] = true 
			end
		end
	end
	return list
end

-- all numbers inside row
function sudoku:getnumbersinrow(y)
	local list = {}
	for x = 1, 9 do 
		local num = self:getnum(y,x)
	
		if num then 
			list[num] = true 
		end
	end
	return list 
end 

-- all numbers inside column
function sudoku:getnumbersincolumn(x)
	local list = {}
	for y = 1, 9 do 
		local num = self:getnum(y,x)
	
		if num then 
			list[num] = true 
		end
	end
	return list
end

-- following 3 functions return if coord is in column, box or row;

function sudoku:coordincolumn(y,x, column)
	return x == column 
end 

function sudoku:coordinrow(y,x,row)
	return y==row 
end 

function sudoku:coordinbox(y,x,boxy, boxx)
	local xstart = math.floor((x-1)/3)*3+1
	local ystart = math.floor((y-1)/3)*3+1
	for yp=ystart,ystart+2 do
		for xp=xstart,xstart+2 do
			if yp == y and xp == x then 
				return true 
			end 
		end 
	end 
	return false  
end 

function sudoku:sortpmap()
	local out = {}
	local total_mustfill = 0
	for y = 1, 9 do 
		for x = 1,9 do 
			local data = self.data[y][x][3]
			local got = false 
			for i,v in pairs(data) do 
				if v then 
					got = true 
					total_mustfill = total_mustfill+1
					break 
				end 
			end 
			if got then 
				table.insert(out, {y,x,data})
			end
		end 
	end
	table.sort(out, function(a,b)
		local numa = 0
		local numb = 0
		for i,v in pairs(a[3]) do 
			if v then
				numa = numa + 1
			end 
		end 
		for i,v in pairs(b[3]) do 
			if v then
				numb = numb + 1
			end 
		end
		return numa < numb
	end)
	return out, total_mustfill
end

-- returns an independent sudoku data strucutre,
-- manipulating known values, to put num inside y and x.
-- returns: sudoku, possible (possible is a test to make sure numbers are still available!)
-- and : affected, all coordinates with affected numbers.
function sudoku:gettransformed(y,x,num)
	local use = self:new()
	local validmove = true
	for posy = 1, 9 do 
		for posx = 1,9 do 
			local gntable = use.data[posy][posx]
			if not gntable then 
				use.data[posy][posx] = {}
				gntable = use.data[posy][posx]
			end
			local origdata = self.data[posy][posx]
			if origdata[2] == "nonempty" or origdata[2] == "try" then 
				-- already number in here, copy;
				gntable[1] = origdata[1]
				gntable[2] = origdata[2]
				gntable[3] = {} -- no possible numbers, as already existiing
			else 
				-- oh noes, it is empty
				if posy == y and posx == x then 
					-- our own!?
					gntable[1] = num
					gntable[2] = "try" -- try to put da stuff in here.
					gntable[3] = {}
				else 
					gntable[3] = {}
					gntable[1] = origdata[1]
					gntable[2] = origdata[2]
					local shwatch = true -- should watch?
					for tnum, possible in pairs(origdata[3]) do 
						gntable[3][tnum] = possible 
						if possible and tnum ~= num then 
							shwatch = false  -- no reason to watch if there is another placeholder, only watch when num is last possible number here, when that is gone: invalid move 
						end 
					end 
					if self:coordinbox(posy,posx,y,x) then 
						-- affected+1?
						gntable[3][num] = false 
						if shwatch then 
							validmove = false 
						end
					elseif self:coordincolumn(posy, posx, y) then 
						gntable[3][num] = false 
						if shwatch then 
							validmove = false 
						end
					elseif self:coordinrow(posy, posx, x) then 
						gntable[3][num] = false 
						if shwatch then 
							validmove = false 
						end
					end
				end 
			end
		end 
	end
	return use, validmove
end 

function sudoku:printpmap()
	for y=1,9 do 
		for x=1,9 do 
			local use = self.data[y][x][3]
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

function sudoku:solve(fwrite, graphics)
	local sorted, mf = self:sortpmap()
	print(mf)
	if mf == 0 then
		print("SOLVED!? WTF!")
		--self:print(true)
		return
	end

	-- for every possible number ...
	for i, data in pairs(sorted) do 
		local y,x, possible_numbers = unpack(data)
		for trynum,cando in pairs(possible_numbers) do 
			if cando then 
				print(y,x,trynum)
				local news, validmove = self:gettransformed(y,x,trynum);		

				if graphics then 
					news:print(true)
				end
				if validmove then 
					news:solve(fwrite, graphics)
				end
			end
		end
	end 
end

return sudoku