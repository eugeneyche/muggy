-- muggy.generator.multiplex

--
-- This file contains the multiplex generator, which allows the user to select
-- between other generators with a single keyword or name.
--

local wibox = require ('wibox')
local beautiful = require('beautiful')

local proto = require('muggy.proto')
local entry = require('muggy.entry')
local fuzzy = require('muggy.fuzzy')
local common = require('muggy.common')

local generator = require('muggy.generator')


local multiplex = { mt = {} }
local multiplex_mode_entry = { mt = {} }
local multiplex_subentry = { mt = {} }


function multiplex_subentry:new(mode, subentry, ...)
    proto.super(entry, self, ...)
    self.mode = mode
    self.subentry = subentry
end


function multiplex_subentry:get_score()
    return self.subentry:get_score()
end


function multiplex_subentry:get_widget()
    return self.subentry:get_widget()
end


function multiplex_subentry:hint_prompt()
    local hint = self.subentry:hint_prompt()
    if hint then
        return self.mode.mode_name .. ' ' .. hint
    end
end


function multiplex_subentry:show()
    self.subentry:show()
end


function multiplex_subentry:execute()
    self.subentry:execute()
end


function multiplex_subentry.mt:__call(...)
    return proto.new(multiplex_subentry, ...)
end


setmetatable(multiplex_subentry, multiplex_subentry.mt)


function multiplex_mode_entry:new(name, generator, ...)
    local theme = beautiful.get()
    local hl_color = theme.lighthouse_hl_color or
                    '#00ffff'
    proto.super(common.hl_text_entry, self, name, hl_color, ...)
    self.mode_name = name
    self.generator = generator
end


function multiplex_mode_entry:process(query)
    local mode = string.match(query, '^([^ ]*)')
    local subquery = string.match(query, '^[^ ]* (.*)$')
    if mode == self.mode_name and subquery then
        return score, subquery
    end
    local is_match, score, _, start_index, end_index = fuzzy.match(self.mode_name, mode)
    self:hl_range(start_index, end_index)
    return score
end


function multiplex_mode_entry:hint_prompt()
    return self.mode_name
end


function multiplex_mode_entry.mt:__call(...)
    return proto.new(multiplex_mode_entry, ...)
end


setmetatable(multiplex_mode_entry, multiplex_mode_entry.mt)


function multiplex:new(...)
    proto.super(generator, self, ...)
    self.modes = {}
end


function multiplex:add_mode(name, generator)
    table.insert(self.modes, multiplex_mode_entry(name, generator))
end


function multiplex:expand_mode(mode, subquery)
    local generator = mode.generator
    local gen_entries = coroutine.wrap(generator.generate_entries)
    while true do
        local subentry, subscore = gen_entries(generator, subquery)
        if not subentry then break end
        self:yield_entry(multiplex_subentry(mode, subentry), subscore)
    end
end


function multiplex:generate_entries(query)
    local shown_modes
    for _,mode in ipairs(self.modes) do
        local score, subquery = mode:process(query)
        if subquery then
            self:expand_mode(mode, subquery)
            return
        end
    end
    local use_prev_modes = self.prev_query and fuzzy.match(query, self.prev_query)
    local modes = self.modes
    if use_prev_modes then
        self:flush_entries()
        modes = self.prev_entries
    end
    for _,mode in ipairs(self.modes) do
        local score = mode:process(query)
        self:yield_entry(mode, score)
    end
end


function multiplex:fallback_execute(query) 
    local enabled_mode = nil
    local subquery = nil
    for _,mode in ipairs(self.modes) do
        local expr = '^' .. mode.mode_name .. ' (.*)$'
        local match = string.match(query, expr)
        if match then
            subquery = match
            enabled_mode = mode
            break
        end
    end
    if enabled_mode and subquery then
        local generator = enabled_mode.generator
        generator:fallback_execute(subquery)
    end
end


function multiplex.mt:__call(...)
    return proto.new(multiplex, ...)
end


return setmetatable(multiplex, multiplex.mt)
