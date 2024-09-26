LOGO = [[
     __       __   ______   ________  ______   __    __   ______  
    /  \     /  | /      \ /        |/      \ /  |  /  | /      \ 
    $$  \   /$$ |/$$$$$$  |$$$$$$$$//$$$$$$  |$$ |  $$ |/$$$$$$  |
    $$$  \ /$$$ |$$ |__$$ |   $$ |  $$ |  $$/ $$ |__$$ |$$ ___$$ |
    $$$$  /$$$$ |$$    $$ |   $$ |  $$ |      $$    $$ |  /   $$< 
    $$ $$ $$/$$ |$$$$$$$$ |   $$ |  $$ |   __ $$$$$$$$ | _$$$$$  |
    $$ |$$$/ $$ |$$ |  $$ |   $$ |  $$ \__/  |$$ |  $$ |/  \__$$ |
    $$ | $/  $$ |$$ |  $$ |   $$ |  $$    $$/ $$ |  $$ |$$    $$/ 
    $$/      $$/ $$/   $$/    $$/    $$$$$$/  $$/   $$/  $$$$$$/  

    (c) 2024 Nikita Troshin
    This code is licensed under MIT license 
    (see https://opensource.org/license/mit for details)
--]]

-- Clamps a number to within a certain range, with optional rounding
function math.clamp(n, low, high) return math.min(math.max(n, low), high) end

-- Gem class
Gem = {}
function Gem:new(char)
    local obj = {}
    obj.type = char
    obj.__eq = function(a, b)
        return a.type == b.type
    end

    setmetatable(obj, self)
    self.__index = self; return obj
end

-- basic gems set used on a board
local gems_set = {
    Gem:new('A'),
    Gem:new('B'),
    Gem:new('C'),
    Gem:new('D'),
    Gem:new('E'),
    Gem:new('F')
};

-- Board class
Board = {}

function Board:new(rows, cols, gems) 
    local board_size_min  = 5
    local board_size_max  = 10

    -- size
    local obj = {}
    obj.rows = math.tointeger(rows) or board_size_max
    obj.cols = math.tointeger(cols) or board_size_max
    obj.rows = math.clamp(obj.rows, board_size_min, board_size_max)
    obj.cols = math.clamp(obj.cols, board_size_min, board_size_max)

    -- gems
    obj.gems = gems or gems_set

    -- init 
    function obj:init()
        self.grid = {}
        for y = 0, self.rows-1 do
            self.grid[y] = {}
            for x = 0, self.cols-1 do
                self.grid[y][x] = self.gems[math.random(1, #self.gems)]
            end
        end
    end

    -- Dump (visualize board)
    function obj:dump()
        -- column numbers
        local num_cols = "    "
        for x = 0, self.cols-1 do
            num_cols = num_cols .. x .. " "
        end
        local line = "    " .. string.rep("--", self.cols)
        print(num_cols)
        print(line)
        
        --  row numbers and grid values
        for y = 0, self.rows-1 do
            local margin = y < 10 and " " or ""
            io.write(y .. margin .. "| ")
            for x = 0, self.cols-1 do
                local _gem = self.grid[y][x]
                io.write(_gem.type .. " ")
            end
            print()
        end
    end

    -- Get gem matches
    function obj:get_matches()
        local matches = {}
        -- Check rows (horizontal)
        for y = 0, self.rows-1 do
            for x = 0, self.cols - 3 do
                if self.grid[y][x] == self.grid[y][x+1] and self.grid[y][x+1] == self.grid[y][x+2] then
                    matches[#matches+1] = {x, y}
                    matches[#matches+1] = {x+1, y}
                    matches[#matches+1] = {x+2, y}
                end
            end
        end

        -- Check cols (vertical)
        for x = 0, self.cols-1 do
            for y = 0, self.rows - 3 do
                if self.grid[y][x] == self.grid[y+1][x] and self.grid[y+1][x] == self.grid[y+2][x] then
                    matches[#matches+1] = {x, y}
                    matches[#matches+1] = {x, y+1}
                    matches[#matches+1] = {x, y+2}
                end
            end
        end

        return matches
    end

    -- Has gem matches
    function obj:has_matches()
        for y = 0, self.rows-1 do
            for x = 0, self.cols - 3 do
                if self.grid[y][x] == self.grid[y][x+1] and self.grid[y][x+1] == self.grid[y][x+2] then
                    return true
                end
            end
        end

        -- Check cols (vertical)
        for x = 0, self.cols-1 do
            for y = 0, self.rows - 3 do
                if self.grid[y][x] == self.grid[y+1][x] and self.grid[y+1][x] == self.grid[y+2][x] then
                    return true
                end
            end
        end

        return false
    end

    -- Tick
    function obj:tick()
        local changes_made = false
        local to_remove = self.get_matches(self)

        -- Remove gems
        for _, pos in ipairs(to_remove) do
            local x, y = pos[1], pos[2]
            self.grid[y][x] = nil
            changes_made = true
        end

        -- Move gems down
        if changes_made then
            for x = 0, self.cols-1 do
                local empty_row = self.rows-1 -- 9
                for y = self.rows-1, 0, -1 do
                    if self.grid[y][x] == nil then
                        for yy = y-1, 0, -1 do
                            if self.grid[yy][x] ~= nil then
                                self.grid[y][x] = self.grid[yy][x]
                                self.grid[yy][x] = nil
                                break
                            end
                        end
                    end
                end
                -- Add new gems at empty spots
                for y = 0, self.rows-1 do
                    if self.grid[y][x] == nil then
                        self.grid[y][x] = self.gems[math.random(1, #self.gems)]
                    end
                end
            end
        end

        return changes_made
    end

    -- Swap gems
    function obj:move(x_from, y_from, x_to, y_to)
        -- check out of bound
        if x_from < 0 or x_from >= self.cols or y_from < 0 or y_from >= self.rows or x_to < 0 or x_to >= self.cols or y_to < 0 or y_to >= self.rows then
            return false
        end

        -- Swap
        self.grid[y_from][x_from], self.grid[y_to][x_to] = self.grid[y_to][x_to], self.grid[y_from][x_from]
        return true
    end

    -- Mix gems
    function obj:mix()
        repeat
            -- mix until there are some matches, then check if there are some moves
            -- local matches;
            repeat
                for y = 0, self.rows-1 do
                    for x = 0, self.cols-1 do
                        local swap_x = math.random(0, self.cols-1)
                        local swap_y = math.random(0, self.rows-1)
                        self.grid[y][x], self.grid[swap_y][swap_x] = self.grid[swap_y][swap_x], self.grid[y][x]
                    end
                end
                -- matches = #(self.get_matches(self))
                -- print("mix matches: " .. matches)
            until(not self.has_matches(self))
            -- self.dump(self)
        until(self.has_moves(self))
    end

    -- has moves
    function obj:has_moves()
        local function creates_matches(x1,y1,x2,y2)
            self.move(self, x1,y1, x2, y2)
            local match_found = self.has_matches(self)
            self.move(self, x2, y2, x1, y1)
            return match_found
        end

        for y = 0, self.rows-1 do
            for x = 0, self.cols-1 do
                 -- Check right move
                if x < self.cols-1 and creates_matches(x, y, x+1, y) then
                    return true
                end
                -- Check down move
                if y < self.rows-1 and creates_matches(x, y, x, y+1) then
                    return true
                end
            end
        end

        -- no moves
        return false
    end

    setmetatable(obj, self)
    self.__index = self; return obj
end

-- MAIN
function MAIN()
    -- LOGO
    -- Note: It's kinda useless, but I really like such things
    -- Remove if required
    print(LOGO)
    print()

    -- INIT
    local board = Board:new(10,10)
    board:init()
    board:mix()
    board:dump()

    -- LOOP
    while true do
        print("@: Enter the command (m x y [l/r/d/u] to move gem, q to quit):")
        local input = io.read()
    
        -- Quit the game
        if input == 'q' then
            print("@: Bye bye!")
            break
        end

        -- note: a - all char, s - space, d - digits
        local cmd, x, y, dir = input:match("(%a)%s*(%d)%s*(%d)%s*(%a)")
        if cmd == 'm' then
            x = tonumber(x)
            y = tonumber(y)
            local x_to, y_to = x, y

            if dir == 'l' then x_to = x - 1
            elseif dir == 'r' then x_to = x + 1
            elseif dir == 'u' then y_to = y - 1
            elseif dir == 'd' then y_to = y + 1
            end

            if board:move(x, y, x_to, y_to) then
                local success_move = false
                while board:tick() do
                    success_move = true
                    board:dump()
                end

                -- swap gems back if no matched anything
                if not success_move then
                    board:move(x_to, y_to, x, y)
                    print("@: Argh! Try to move other gems.")
                else
                -- check available moves
                    if not board:has_moves() then
                        print("@: No available moves, mix the board...")
                        board:mix()
                        board:dump()
                    end
                end

            else
                print("@: Impossible to move gem outside the board.")
            end
        else
            print("@: Unknown command.")
        end
    end
end

MAIN()



