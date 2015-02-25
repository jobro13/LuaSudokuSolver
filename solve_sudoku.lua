local sudoku = require "sudoku_tools"
local cmd = require "sudoku_cmd"

sudoku:putspecial("reset")

local my = sudoku:new()

my:load("easy.txt", 4)

my:makepmap()

my:print(true)

my:solve(nil,true)

while true do
	cmd(my, io.read())
end