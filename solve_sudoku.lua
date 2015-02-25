local sudoku = require "sudoku_tools"
local cmd = require "sudoku_cmd"

sudoku:putspecial("reset")

local my = sudoku:new()

my:load("msk_009", 1)

my:print(true)

while true do
	cmd(my, io.read())
end