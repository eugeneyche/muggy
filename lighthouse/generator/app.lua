-- muggy.generator.app

--
-- This file contains the app generator, which allows the user to
-- auto-complete an app entry and execute it.
--

local wibox = require ('wibox')
local beautiful = require ('beautiful')

local awful = require('awful')
local menu_gen = require('menubar.menu_gen')

local proto = require('muggy.proto')
local fuzzy = require('muggy.fuzzy')

local generator = require('muggy.lighthouse.generator')
local entry = require('muggy.lighthouse.entry')

local common = require('muggy.lighthouse.common')


local app_entry = { 
    super = common.hl_basic_entry,
    mt = {}
}


local app = { 
    super = generator,
    mt = {} 
}


function app_entry:new(app_name, app_command, app_icon, ...)
    local theme = beautiful.get()
    local hl_color = theme.lighthouse_hl_color or
                     '#00ffff'
    proto.super(self):new(app_name, hl_color, app_icon, ...)
    self.app_name = app_name
    self.app_command = app_command
    self.app_icon = app_icon
end


function app_entry:process(query)
    local is_match, score, _, start_index, end_index = fuzzy.match(self.app_name, query, true)
    self:hl_range(start_index, end_index)
    return score
end


function app_entry:hint_prompt()
    return self.app_name
end


function app_entry:execute()
    awful.util.spawn(self.app_command)
end


function app_entry.mt:__call(...)
    return proto.new(app_entry, ...)
end


setmetatable(app_entry, app_entry.mt)


function app:new(...)
    proto.super(self):new(...)
    self.entries = {}
    apps = menu_gen.generate()
    for _, app in ipairs(apps) do
        local entry = app_entry(app.name, app.cmdline, app.icon)
        table.insert(self.entries, entry)
    end
end


function app:generate_entries(query)
    if not query then return end
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


function app.mt:__call(...)
    return proto.new(app, ...)
end


return setmetatable(app, app.mt)
