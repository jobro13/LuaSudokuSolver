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
	obj.cache = {} -- used for solving.
	obj.invalidcache = {}
	obj.stats = {recurse=0,invalid=0,nodes_saved=0}
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

function sudoku:print(home, prtstats)
	
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
		if row == 4 or row == 7 then 
			border()
			io.write("|"..string.rep(" ", self.whitespace))
		else
			io.write("|"..string.rep(" ", self.whitespace))
		end

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
	if prtstats  then 
		for i,v in pairs(self.stats) do 
			print(i..": "..v)
		end
	end
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
	return (x == column )
end 

function sudoku:coordinrow(y,x,row)
	return (y==row) 
end 

function sudoku:coordinbox(y,x,boxy, boxx)
	local xstart = math.floor((x-1)/3)*3+1
	local ystart = math.floor((y-1)/3)*3+1
	for yp=ystart,ystart+2 do
		for xp=xstart,xstart+2 do
			if yp == boxy and xp == boxx then 
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
	local function print() end
	local use = self:new()
	use.cache = self.cache
	use.invalidcache = self.invalidcache
	use.stats = self.stats
	print("GOING TO PUT ", num, "ON ", y,x) 
	local validmove = true
	for posy = 1, 9 do 
		for posx = 1,9 do 
			print("\n+++++++++++++++++----- ", posy, posx)
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
				print(posy,posx, origdata[2], "no possible numbers")
			else 
				-- oh noes, it is empty
				if posy == y and posx == x then 
					-- our own!?
					gntable[1] = num
					gntable[2] = "try" -- try to put da stuff in here.
					gntable[3] = {}
					print(posy,posx, origdata[2], "is new.")
				else 
					gntable[3] = {}
					gntable[1] = origdata[1]
					gntable[2] = origdata[2]
					local shwatch = true -- should watch?
					for tnum, possible in pairs(origdata[3]) do 
						gntable[3][tnum] = possible 
						print("copy", tnum,possible)
						if possible and tnum ~= num then 
							print("not shwatch")
							shwatch = false  -- no reason to watch if there is another placeholder, only watch when num is last possible number here, when that is gone: invalid move 
							--break
						end 
					end 
					if shwatch then 
						print("shwatching")
					end

					if self:coordinbox(posy,posx,y,x) then 
						-- affected+1?
						gntable[3][num] = false 
						print(posy,posx, origdata[2], "in box! removed " .. num)
						if shwatch then 
							validmove = false 
							print("INVALID MOVE")
						end
					elseif self:coordincolumn(posy, posx, x) then 
						gntable[3][num] = false 
							print(posy,posx, origdata[2], "in column! removed " .. num)
						if shwatch then 
							validmove = false 
							print("INVALID MOVE")
						end
					elseif self:coordinrow(posy, posx, y) then 
						gntable[3][num] = false 
							print(posy,posx, origdata[2], "in row, removed " .. num)
						if shwatch then 
							validmove = false 
							print("INVALID MOVE")
						end
					end
					local prtittle = false 
					for i,v in pairs(gntable[3]) do
						if v then
							if not prtittle then
								prtittle = true 
								print("STILL POSSIBLE:")
							end
							print(i)
						end
					end
									local prtittle = false 
					for i,v in pairs(origdata[3]) do
						if v then
							if not prtittle then
								prtittle = true 
								print("WAS POSSIBLE:")
							end
							print(i)
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

function sudoku:totxtstr()
	local buff = ""
	for y=1,9 do 
		for x=1,9 do
			local num = self:getnum(y,x)
			if num then
				buff=buff..tostring(num)
			else
				buff=buff.."."
			end
		end
	end
	return buff 
end

function sudoku:getknowledge(y,x)
	local data = self.data[y][x]
	for num, p in pairs(data[3]) do
		if p then 
			print(num, " can be put in coord ", y,x)
		end 
	end 
end

function sudoku:shouldcheck(newsudoku)
	local textver = newsudoku:totxtstr()
	if self.cache[textver] then 
		return false 
	else
		for _,invalid in pairs(self.invalidcache) do 
			if textver:match(invalid) then 
				return false 
			end
		end
	end
	return true 
end 

-- cleanup the cache.
-- only: only check for this, MUST BE LAST IN TABLE
function sudoku:clean(only)
	-- find all cache items which are a "deeper" version of the other; remove.
	if only then 
		local data = only
		local ind = 1
		--self.stats.invalid = "\n"
		--print(only)
		while ind < (#self.invalidcache) do -- dont check last.
			local odata = self.invalidcache[ind] 
			
			--print(odata)
			if odata:match(data) then 
				table.remove(self.invalidcache, ind)
				ind = ind - 1
			elseif data:match(odata) then 
				table.remove(self.invalidcache, #self.invalidcache)
				
				break 
			end 
			ind = ind + 1
		end
		--io.read()
	else 
		local i = 1
		while i <= (#self.invalidcache) do 
			i = i + 1
			local data = self.invalidcache[i]
			local ind = i 
			while ind <= (#self.invalidcache) do 
				local odata = self.invalidcache[i] 
				if odata:match(data) then 
					table.remove(self.invalidcache, ind)
					ind = ind - 1
				elseif data:match(odata) then 
					table.remove(self.invalidcache, i)
					i = i - 1
					break 
				end 
				ind = ind + 1
			end
		end
	end
end

function sudoku:solve(fwrite, graphics)
	local function print() end 
	local sorted, mf = self:sortpmap()
	--local function print() end
	if mf == 0 then
		self:print(true, true)
		print("SOLVED!")
		print("Press any key to continue finding another solution...")
		io.read()
		return
	end
	self.stats.recurse = self.stats.recurse+1
	-- for every possible number ...
	for i, data in pairs(sorted) do 
		local y,x, possible_numbers = unpack(data)
		for trynum,cando in pairs(possible_numbers) do 
			if cando then 
				--print(y,x,trynum)
				local news, validmove = self:gettransformed(y,x,trynum);		
				--os.exit()
				if graphics then
					
					
					print(mf)
					for i,v in pairs(sorted) do 
						print(i, v[1], v[2])
						for ind, val in pairs(v[3]) do
							print(ind,val)
						end
					end
					--print(validmove)
					--self:print()
					
					--self:getknowledge(9,8)
					--io.read()
				end

				if validmove and self:shouldcheck(news) then 
					self.stats.nodes = "\n"
					for i,v in pairs(self.invalidcache) do 
						self.stats.nodes = self.stats.nodes..v.."\n"
					end
					news:print(true, true)
					io.read()
					news:clean()
					news:solve(fwrite, graphics)
					table.insert(self.invalidcache, news:totxtstr())
					news:clean( news:totxtstr())
				elseif not validmove then 
					table.insert(self.invalidcache, news:totxtstr())
					news:clean(news:totxtstr())
					self.stats.invalid = #self.invalidcache
				end

				self.cache[news:totxtstr()] = true -- been there. [visited]
				self.stats.nodes_saved= self.stats.nodes_saved+1
			end
		end
	end 
end

return sudoku