-- muggy.generator.kill

--
-- This file contains the kill generator, which allows the user to
-- kill current processes
--

local wibox = require ('wibox')
local beautiful = require ('beautiful')

local awful = require('awful')

local proto = require('muggy.proto')
local fuzzy = require('muggy.fuzzy')

local generator = require('muggy.lighthouse.generator')
local entry = require('muggy.lighthouse.entry')

local common = require('muggy.lighthouse.common')


local kill_entry = { 
    super = common.hl_basic_entry,
    mt = {} 
}


local kill = { 
    super = generator,
    mt = {} 
}


function kill_entry:new(command_name, ...)
    local theme = beautiful.get()
    local hl_color = theme.lighthouse_hl_color or
                    '#00ffff'
    proto.super(self):new(command_name, hl_color, ...)
    self.command_name = command_name
end


function kill_entry:process(query)
    local is_match, score, _, start_index, end_index = fuzzy.match(self.command_name, query)
    self:hl_range(start_index, end_index)
    return score
end


function kill_entry:hint_prompt()
    return self.command_name
end


function kill_entry:execute()
    awful.util.spawn('pkill -9 ' .. self.command_name, false)
end


function kill_entry.mt:__call(...)
    return proto.new(kill_entry, ...)
end


setmetatable(kill_entry, kill_entry.mt)


function kill:new(...)
    proto.super(self):new(...)
    self.entries = {}
end


function kill:refresh()
    proc, err =  io.popen('ps -u $USER -o comm=')
    local comms = {}
    if proc then
        for comm in proc:lines() do
            comms[comm] = true
        end
        proc.close()
    end
    self.entries = {}
    comms['ps'] = false
    for comm, valid in pairs(comms) do
        local entry = kill_entry(comm)
        table.insert(self.entries, entry)
    end
end


function kill:generate_entries(query)
    local entries = self.entries
    local use_prev_entries = self.prev_query and fuzzy.match(query, self.prev_query)
    if use_prev_entries then
        self:flush_entries()
        entries = self.prev_entries
    end
    for _,entry in ipairs(entries) do
        local score = entry:process(query)
        if score then
            self:yield_entry(entry, score)
        end
    end
end


function generator:fallback_execute(query) 
    awful.util.spawn('pkill -9 ' .. query, false)
end


function kill.mt:__call(...)
    return proto.new(kill, ...)
end


return setmetatable(kill, kill.mt)
