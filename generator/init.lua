-- muggy.generator

--
-- This file contains the base generator code, used by all other generators.
--

proto = require('muggy.proto')
heap = require('muggy.heap')


local generator = { mt = {} }


function generator:new(...)
    self.prev_query = nil
    self.prev_entries = {}
    self.prev_entry_generator = nil
    self.entry_limit = 60
end


function generator:yield_entry(entry, score)
    coroutine.yield(entry, score)
end


function generator:generate_entries(query) end


function generator:fallback_execute(query) end


function generator:get_entries(query, limit)
    limit = limit or self.entry_limit
    local entry_generator  = coroutine.create(function () 
        self:generate_entries(query) 
    end)
    local entry_heap = {}
    while coroutine.status(entry_generator) ~= 'dead' do
        local st, entry, score = coroutine.resume(entry_generator)
        if not st then break end
        if entry and type(score) == 'number' then
            heap.push(entry_heap, entry, score)
            if #entry_heap >= limit then break end
        end
    end
    self.prev_query = query
    self.prev_entries = {}
    self.prev_entry_generator = entry_generator
    while #entry_heap > 0 do
        local entry = heap.pop(entry_heap)
        table.insert(self.prev_entries, entry)
    end
    return self.prev_entries
end


function generator:flush_entries()
    if not self.prev_entry_generator then return end
    local entry_generator = self.prev_entry_generator
    while coroutine.status(entry_generator) ~= 'dead' do
        local st, entry, score = coroutine.resume(entry_generator)
        if not st then break end
        if entry and type(score) == 'number' then
            table.insert(self.prev_entries, entry)
        end
    end
end


function generator.mt:__call(...)
    return proto.new(generator, ...)
end


return setmetatable(generator, generator.mt)
