-- muggy.prompt

--
-- This file code for the prompt, the place the user enters data.
--

local capi = {
    client = client,
    mouse = mouse,
    screen = screen
}

local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")

local proto = require('muggy.proto')

local common = require('muggy.lighthouse.common')


local prompt = { mt = {} }


function prompt:new(...)
    local theme = beautiful.get()
    self.prompt_color = theme.lighthouse_prompt_color or
                        '#ffff00'
    self.hint_prompt_color = theme.lighthouse_hint_prompt_color or
                             '#00ff00'
    self.cursor_color = theme.lighthouse_cursor_color or
                        '#00ffff'

    local target_height = theme.menu_height or beautiful.get_font_height(theme.font) * 1.5
    local padding = (target_height - beautiful.get_font_height(theme.font)) / 2

    local tb = wibox.widget.textbox()
    local m = wibox.layout.margin(tb, 4, 4, padding, padding)
    local bgb = wibox.widget.background(m)
    self.textbox = tb
    self.base = bgb

    self:reset()

    self.query_change_listeners = {}
end


function prompt:reset()
    self.query = ''
    self.cursor = 1
    self.hint = nil
end


function prompt:on_query_change(callback)
    table.insert(self.query_change_listeners, callback)
end


function prompt:emit_query_change()
    for _,callback in ipairs(self.query_change_listeners) do
        callback(self.query)
    end
end


function prompt:cursor_left()
    self:finalize_hint()
    self.cursor = math.max(1, self.cursor - 1)
    self:show()
end

function prompt:cursor_right()
    self:finalize_hint()
    self.cursor = math.min(self.query:len() + 1, self.cursor + 1)
    self:show()
end

function prompt:cursor_home()
    self:finalize_hint()
    self.cursor = 1
    self:show()
end

function prompt:cursor_end()
    self:finalize_hint()
    self.cursor = self.query:len() + 1
    self:show()
end

function prompt:backspace()
    self:finalize_hint()
    if self.cursor == 1 then return end
    local new_query = ''
    if self.cursor > 2 then
        new_query = self.query:sub(1, self.cursor - 2)
    end
    if self.cursor <= self.query:len() then
        new_query = new_query .. self.query:sub(self.cursor)
    end
    self.query = new_query
    self.cursor = math.max(1, self.cursor - 1)
    if self.query_change_callback then
        self.query_change_callback(self.query)
    end
    self:show()
    self:emit_query_change()
end

function prompt:type_key(key)
    self:finalize_hint()
    local new_query = ''
    if self.cursor > 1 then
        new_query = self.query:sub(1, self.cursor - 1)
    end
    new_query = new_query .. key
    if self.cursor <= self.query:len() then
        new_query = new_query .. self.query:sub(self.cursor)
    end
    self.query = new_query
    self.cursor = math.min(self.query:len() + 1, self.cursor + 1)
    self:show()
    self:emit_query_change()
end


function prompt:store_hint(hint)
    self.hint = hint
    self:show()
end


function prompt:unstore_hint()
    self.hint = nil
    self:show()
end


function prompt:finalize_hint()
    if self.hint then
        self.query = self.hint
        self.hint = nil
        self:emit_query_change()
        self:cursor_end()
    end
end


function prompt:show()
    if self.hint then
        local prompt_markup = '<span fgcolor="' .. self.hint_prompt_color .. 
                              '">> </span>' .. common.pango_safe_text(self.hint)
        self.textbox:set_markup(prompt_markup)
        return
    end
    local prompt_markup = '<span fgcolor="' .. self.prompt_color .. 
                          '">> </span>'
    local cursor_char = '_'
    local function cursor_highlight(c)
        return '<span fgcolor="' .. self.cursor_color  .. '">' .. c .. '</span>'
    end
    local query_markup = ''
    if self.cursor > 1 then
        query_markup = common.pango_safe_text(self.query:sub(1, self.cursor - 1))
    end
    if self.cursor <= self.query:len() then
        if self.query:sub(self.cursor, self.cursor) == ' ' then
            query_markup = query_markup .. cursor_highlight(cursor_char)
        else
            query_markup = query_markup .. cursor_highlight(
                    common.pango_safe_text(self.query:sub(self.cursor, self.cursor)))
        end
        if self.cursor < self.query:len() then
            query_markup = query_markup .. common.pango_safe_text(self.query:sub(self.cursor + 1))
        end
    else
        query_markup = query_markup .. cursor_highlight(cursor_char)
    end
    self.textbox:set_markup(prompt_markup .. query_markup)
end


function prompt.mt:__call(...)
    return proto.new(prompt, ...)
end


return setmetatable(prompt, prompt.mt)
