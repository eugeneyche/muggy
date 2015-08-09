-- muggy.widget.battwidget

--
-- Simple battery widget that utilizes cairo to display information
--


local wibox = require('wibox')
local beautiful = require('beautiful')
local vicious = require('vicious')

local cairo = require('lgi').cairo
local gears = require('gears')

local proto = require('muggy.proto')


battwidget = { mt = {} }


function battwidget:new(...)
    local theme = beautiful.get()
    self.height = theme.menu_height
    self.width =  1.2 * theme.menu_height
    self.img = cairo.ImageSurface(cairo.Format.ARGB32, self.width, self.height)
    self.base = wibox.widget.imagebox(self.img, false)
    vicious.register(self, vicious.widgets.bat, function(widget, args)
        widget:update(args[1], tonumber(args[2]))
    end, 1, 'BAT0')
end


function battwidget:update(state, percent, time)
    percent = percent or 0
    local theme = beautiful.get()
    local cr = cairo.Context(self.img)
    local width = self.width
    local height = self.height
    local full_color = theme.battwidget_full_color
    local charging_color = theme.battwidget_charging_color
    local high_color = theme.battwidget_high_color
    local low_color = theme.battwidget_low_color
    cr:set_source(gears.color(theme.bg_normal))
    cr:paint()
    cr:set_line_width(1)
    cr:set_source(gears.color(theme.fg_normal))
    cr:rectangle(4.5, 7.5, width - 11.5, height - 14)
    cr:stroke()
    cr:set_line_width(3)
    cr:move_to(width - 6, 9)
    cr:line_to(width - 6, height - 9)
    cr:stroke()
    cr:set_line_width(1)
    cr:set_source(gears.color(theme.bg_normal))
    cr:rectangle(5.5, 8.5, width - 16, height - 16)
    cr:fill()
    if percent >= 90 then
        cr:set_source(gears.color(full_color))
    elseif state == '+' then
        cr:set_source(gears.color(charging_color))
    elseif percent > 50 then
        cr:set_source(gears.color(high_color))
    else
        cr:set_source(gears.color(low_color))
    end
    local stat_width = percent / 100 * (width - 13.5)
    cr:rectangle(5.5, 8.5, stat_width, height - 16)
    cr:fill()
    self.base:set_image(self.img)
end


function battwidget.mt:__call(...)
    return proto.new(battwidget, ...)
end


return setmetatable(battwidget, battwidget.mt)
