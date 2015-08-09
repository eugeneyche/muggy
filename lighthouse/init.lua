-- muggy.lighthouse

--
-- This file contains the lighthouse code that binds together the prompt and 
-- entry list.
--

local capi = {
    client = client,
    mouse = mouse,
    screen = screen
}

local awful = require('awful')
local common = require('awful.widget.common')
local wibox = require ('wibox')
local keygrabber = require('awful.keygrabber')
local beautiful = require('beautiful')

local proto = require('muggy.proto')

local prompt = require('muggy.lighthouse.prompt')
local entry_list = require('muggy.lighthouse.entry_list')

local multiplex = require('muggy.lighthouse.generator.multiplex')
local app = require('muggy.lighthouse.generator.app')
local shell = require('muggy.lighthouse.generator.shell')
local kill = require('muggy.lighthouse.generator.kill')
local calc = require('muggy.lighthouse.generator.calc')


local lighthouse = { mt = {} }


function lighthouse:new(...)
    local theme = beautiful.get()
    self.fg = theme.lighthouse_fg or
              theme.fg_normal
    self.bg = theme.lighthouse_bg or
              theme.bg_normal
    self.border_color = theme.lighthouse_border_color or
                        theme.border_focus or
                        '#ff0000'
    self.border_width = theme.lighthouse_border_width or 
                        theme.border_width or 
                        1
    self.prompt = prompt()
    self.entry_list = entry_list()
    local layout = wibox.layout.fixed.vertical()
    layout:add(self.prompt.base)
    layout:add(self.entry_list.base)
    self.grabber = nil
    self.wibox = wibox({
        ontop=true,
        fg=self.fg,
        bg=self.bg,
        border_width=self.border_width,
        border_color=self.border_color
    })
    self.generator = multiplex()
    self.generator:add_mode('app' , app())
    local sys_multiplex = multiplex()
    sys_multiplex:add_mode('sh', shell())
    sys_multiplex:add_mode('kill', kill())
    self.generator:add_mode('sys', sys_multiplex)
    self.generator:add_mode('calc', calc())
    self.wibox:set_widget(layout)
    self.prompt:on_query_change(function(...)
        self:update_entries(...)
    end)
    self.entry_list:on_resize(function(...)
        self:resize()
    end)

    self.entry_list:on_hint_prompt(function(hint)
        self:update_hint(hint)
    end)
end


function lighthouse:show()
    self.prompt:show()
    self.entry_list:show()
    self:resize()
    self.wibox.visible = true
end


function lighthouse:hide()
    self.prompt:reset()
    self.entry_list:reset()
    self.wibox.visible = false
end


function lighthouse:resize()
    local scr = capi.mouse.screen 
    local scrgeom = capi.screen[scr].workarea
    local fixed_width = 480
    local expected_height = 300
    local fixed_offset = scrgeom.height / 2 - expected_height / 2
    local remaining_height = scrgeom.height - fixed_offset
    local _, prompt_height = self.prompt.base:fit(
            fixed_width, remaining_height)
    remaining_height = remaining_height - prompt_height
    local _, entry_list_height = self.entry_list.base:fit(
            fixed_width, remaining_height)
    local geom = {
        x = scrgeom.x + scrgeom.width / 2 - fixed_width / 2,
        y = scrgeom.y + fixed_offset,
        width = fixed_width,
        height = prompt_height + entry_list_height
    }
    self.wibox:geometry(geom)
end


function lighthouse:run()
    self.generator:refresh()
    self:update_entries()
    if self.grabber then
        keygrabber.stop(self.grabber)
    end
    self.grabber = keygrabber.run(
        function(modifiers, key, event)
            self:on_key(modifiers, key, event)
        end)
    self:show()
end


function lighthouse:stop()
    keygrabber.stop(self.grabber)
    self.grabber = nil
    self:hide()
end


function lighthouse:on_key(modifiers, key, event)
    if event ~= 'press' then return end
    local mod = {}
    for _,v in ipairs(modifiers) do mod[v] = true end
    if mod.Mod4 or mod.Mod2 then return end

    if      (mod.Control and key == 'c') or 
            (mod.Control and key == 'g') or 
            (not mod.Control and key == 'Escape') 
    then
        self:stop()
    end
    if      (mod.Control and key == 'b') or
            (not mod.Control and key == 'Left') 
    then
        self.prompt:cursor_left()
    end
    if      (mod.Control and key == 'f') or
            (not mod.Control and key == 'Right') 
    then
        self.prompt:cursor_right()
    end
    if mod.Control and key == 'a' then
        self.prompt:cursor_home()
    end
    if mod.Control and key == 'e' then
        self.prompt:cursor_end()
    end
    if mod.Control and key == 'j' then
        self.entry_list:cursor_down()
    end
    if mod.Control and key == 'k' then
        self.entry_list:cursor_up()
    end
    if not mod.Control and not mod.Shift and key == 'Tab' then
        self.entry_list:cursor_first_hint()
        self.prompt:finalize_hint()
    end
    if not mod.Control and key == 'BackSpace' then
        self.prompt:backspace()
    end
    if not mod.Control and key == 'Return' then
        self:execute()
    end
    if not mod.Control and key:wlen() == 1 then
        self.prompt:type_key(key)
    end
end


function lighthouse:update_entries()
    local new_entries = {}
    result = self.generator:get_entries(self.prompt.query)
    self.entry_list:cursor_reset()
    self.entry_list:update_entries(result)
    self.entry_list:show()
end


function lighthouse:update_hint(hint)
    if hint then
        self.prompt:store_hint(hint)
    else
        self.prompt:unstore_hint()
    end
end


function lighthouse:execute()
    local current_entry = self.entry_list:current_entry()
    if current_entry then
        current_entry:execute()
    else
        self.generator:fallback_execute(self.prompt.query)
    end
    self:stop()
end


function lighthouse.mt:__call(...)
    return proto.new(lighthouse, ...)
end


return setmetatable(lighthouse, lighthouse.mt)
