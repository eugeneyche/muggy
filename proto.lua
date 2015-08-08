-- muggy.proto

--
-- This file contains the code to make Lua a little more object oriented.
--


proto = { mt = {} }


function proto._setup(cls, inst)
    if not cls then return end
    local object = {
        cls = cls,
        inst = inst,
        mt = {}
    }
    function object.mt:__index(key)
        local inst = rawget(self, 'inst')
        if inst and inst[key] then
            return inst[key]
        end
        local cls = rawget(self, 'cls')
        while cls do
            if cls[key] then
                return cls[key]
            end
            cls = cls.super
        end
    end

    function object.mt:__newindex(key, value)
        local is_meta = rawget(self, key)
        assert(not is_meta)
        local inst = rawget(self, 'inst')
        if inst then
            inst[key] = value
        end
    end

    setmetatable(object, object.mt)

    return object
end


function proto.new(cls, ...)
    local inst = {}
    local object = proto._setup(cls, inst)
    if object.new then
        object:new(...)
    end
    return object
end


function proto.super(object)
    local inst = rawget(object, 'inst')
    local cls = rawget(object, 'cls')
    if cls.super then
        return proto._setup(cls.super, inst)
    end
end


return setmetatable(proto, proto.mt)
