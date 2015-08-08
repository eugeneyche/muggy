-- muggy.generator.shell

--
-- This file contains the shell generator, which allows the user to
-- auto-complete a shell entry with fuzzy search.
--

local wibox = require ('wibox')
local beautiful = require ('beautiful')

local awful = require('awful')

local proto = require('muggy.proto')
local generator = require('muggy.generator')
local entry = require('muggy.entry')
local fuzzy = require('muggy.fuzzy')

local common = require('muggy.common')


local shell_entry = { 
    super = common.hl_basic_entry, 
    mt = {} 
}


local shell = { 
    super = generator,
    mt = {} 
}


function shell_entry:new(command_name, ...)
    local theme = beautiful.get()
    local hl_color = theme.lighthouse_hl_color or
                    '#00ffff'
    proto.super(self):new(command_name, hl_color, ...)
    self.command_name = command_name
end


function shell_entry:process(query)
    local is_match, score, _, start_index, end_index = fuzzy.match(self.command_name, query)
    self:hl_range(start_index, end_index)
    return score
end


function shell_entry:hint_prompt()
    return self.command_name
end


function shell_entry:execute()
    awful.util.spawn(self.command_name)
end


function shell_entry.mt:__call(...)
    return proto.new(shell_entry, ...)
end


setmetatable(shell_entry, shell_entry.mt)


function shell:new(...)
    proto.super(self):new(...)
    self.entries = {}
    proc, err =  io.popen('compgen -c')
    if proc then
        for command_name in proc:lines() do
            local entry = shell_entry(command_name)
            table.insert(self.entries, entry)
        end
        proc.close()
    end
end


function shell:generate_entries(query)
    if not query then return end
    local entries = self.entries
    local use_prev_entries = self.prev_query and fuzzy.match(query, self.prev_query)
    if use_prev_entries then
        self:flush_entries()
        entries = self.prev_entries
    end
    for _, entry in ipairs(entries) do
        local score = entry:process(query)
        if score then
            self:yield_entry(entry, score)
        end
    end
end


function generator:fallback_execute(query) 
    awful.util.spawn(query)
end


function shell.mt:__call(...)
    return proto.new(shell, ...)
end


return setmetatable(shell, shell.mt)
