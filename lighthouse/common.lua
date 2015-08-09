-- muggy.common

--
-- This file aggregates common code to be used by submodules.
--

local wibox = require ('wibox')
local beautiful = require('beautiful')

local proto = require('muggy.proto')

local entry = require('muggy.lighthouse.entry')


local common = {}


common.basic_entry = { 
    super = entry,
    mt = {} 
}


common.hl_basic_entry = { 
    super = common.basic_entry,
    mt = {} 
}


function common.pango_safe_text(str)
    if not str then return end
    str = string.gsub(str, '<', '&lt;')
    str = string.gsub(str, '>', '&gt;')
    return str
end


function common.basic_entry:new(text, icon, ...)
    local theme = beautiful.get()

    proto.super(self):new(...)
    self.text = text
    self.textbox = wibox.widget.textbox()

    local target_height = theme.menu_height or beautiful.get_font_height(theme.font) * 1.5
    local padding = (target_height - beautiful.get_font_height(theme.font)) / 2

    local m = wibox.layout.margin(self.textbox, 4, 4, padding, padding)
    self.base = wibox.layout.align.horizontal()
    self.base:set_middle(m)
    if icon then
        local image = wibox.widget.imagebox(icon)
        local constrained = wibox.layout.constraint(image, 'exact', target_height - 4,  target_height - 4) 
        local m_image = wibox.layout.margin(constrained, 2, 2, 2, 2)
        self.base:set_right(m_image)
    end
end


function common.basic_entry:set_text(text)
    self.text = text
end


function common.basic_entry:get_widget()
    return self.base
end


function common.basic_entry:show()
    self.textbox:set_text(common.pango_safe_text(self.text))
end


function common.basic_entry.mt:__call(...)
    proto.new(basic_entry, ...)
end


setmetatable(common.basic_entry, common.basic_entry.mt)


function common.hl_basic_entry:new(text, hl_color, ...)
    proto.super(self):new(text, ...)
    self.hl_color = hl_color
    self.hl_start_index = nil
    self.hl_end_index = nil
end


function common.hl_basic_entry:hl_range(start_index, end_index)
    self.hl_start_index = start_index
    self.hl_end_index = end_index
end


function common.hl_basic_entry:show()
    if not self.hl_start_index or not self.hl_end_index then
        common.basic_entry.show(self)
        return
    end
    local markup_text = ''
    local start_index = self.hl_start_index
    local end_index =  self.hl_end_index
    if start_index > 1 then
        markup_text = markup_text .. common.pango_safe_text(self.text:sub(1, start_index - 1))
    end
    markup_text = markup_text .. '<span fgcolor="' .. self.hl_color .. '">'
    markup_text = markup_text .. common.pango_safe_text(self.text:sub(start_index, end_index))
    markup_text = markup_text .. '</span>'
    if end_index < self.text:len() then
        markup_text = markup_text .. common.pango_safe_text(self.text:sub(end_index + 1))
    end
    self.textbox:set_markup(markup_text)
end


function common.hl_basic_entry.mt:__call(...)
    proto.new(hl_basic_entry, ...)
end


setmetatable(common.hl_basic_entry, common.hl_basic_entry.mt)


return common
