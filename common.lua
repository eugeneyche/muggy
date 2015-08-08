-- muggy.common

--
-- This file aggregates common code to be used by submodules.
--

local wibox = require ('wibox')

local proto = require('muggy.proto')
local entry = require('muggy.entry')


local text_entry = { mt = {} }
local hl_text_entry = { mt = {} }


function text_entry:new(text, ...)
    proto.super(entry, self, ...)
    self.text = text
    self.textbox = wibox.widget.textbox(text)
    self.base = wibox.layout.margin(self.textbox, 4, 4, 4, 4)
end


function text_entry:set_text(text)
    self.text = text
end


function text_entry:get_widget()
    return self.base
end


function text_entry:show()
    self.textbox:set_text(self.text)
end


function text_entry.mt:__call(...)
    proto.new(text_entry, ...)
end


setmetatable(text_entry, text_entry.mt)


function hl_text_entry:new(text, hl_color, ...)
    proto.super(text_entry, self, text, ...)
    self.hl_color = hl_color
    self.hl_start_index = nil
    self.hl_end_index = nil
end


function hl_text_entry:hl_range(start_index, end_index)
    self.hl_start_index = start_index
    self.hl_end_index = end_index
end


function hl_text_entry:show()
    if not self.hl_start_index or not self.hl_end_index then
        text_entry.show(self)
        return
    end
    local markup_text = ''
    local start_index = self.hl_start_index
    local end_index =  self.hl_end_index
    if start_index > 1 then
        markup_text = markup_text .. self.text:sub(1, start_index - 1)
    end
    markup_text = markup_text .. '<span fgcolor="' .. self.hl_color .. '">'
    markup_text = markup_text .. self.text:sub(start_index, end_index)
    markup_text = markup_text .. '</span>'
    if end_index < self.text:len() then
        markup_text = markup_text .. self.text:sub(end_index + 1)
    end
    self.textbox:set_markup(markup_text)
end


function hl_text_entry.mt:__call(...)
    proto.new(hl_text_entry, ...)
end


setmetatable(hl_text_entry, hl_text_entry.mt)


local common = { 
    text_entry = text_entry,
    hl_text_entry = hl_text_entry
}


return common
