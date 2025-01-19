--Utils.lua
--Author: floofer++
--Version: 1.0

require 'floony.lib.color'

---Return an iterator of the best divisions of the given range by the given step. The iterator will return the start and end of each division.
---@param tStart number
---@param tEnd number
---@param tSplit number
---@return fun():number?, number?
function bestDivisions(tStart, tEnd, tSplit)
    
    local t = tStart
    
    return function()

        if t >= tEnd then
            return nil
        end

        local s = t
        local e = t + tSplit

        if e >= tEnd - tSplit / 2 then
            e = tEnd
        end

        t = e
        return math.floor(s), math.floor(e)

    end

end

---Return an iterator of the best divisions of the given range by the given step. The iterator will return the edges of these divisions.
---@param tStart number
---@param tEnd number
---@param tSplit number
---@return fun():number?
function bestDivisionEdges(tStart, tEnd, tSplit)
    
    local t = tStart
    
    return function()

        if t > tEnd then
            return nil
        elseif t == tEnd then
            t = tEnd + 1
            return t - 1
        end

        local s = t
        local e = t + tSplit

        if e >= tEnd - tSplit / 2 then
            e = tEnd
        end

        t = e
        return math.floor(s)

    end

end

--- Generate a random float between the given min and max.
---@param min number @ The minimum value to generate (included)
---@param max number @ The maximum value to generate (non included)
---@return number
function math.randomf(min, max)
    return min + math.random() * (max - min)
end

--- Return the linear interpolation between two numbers with the given interpolative value
---@param a number
---@param b number
---@param t number
---@return number
function math.lerp(a, b, t)
    return a + (b - a) * t
end

---@param a number
---@param b number
---@param v number
---@return number
function math.invlerp(a, b, v)
    return (v - a) / (b - a)
end

--- Collapse the given indices of a table into a list.
---@generic T
---@generic K
---@param tbl table<K, T>
---@param ... K
---@return T[]
function table.icollapse(tbl, ...)
    local args = {...}
    local ret = {}
    for _, x in ipairs(args) do 
        for _, n in ipairs(tbl[x]) do
            table.insert(ret, n)
        end
    end
    return ret
end

--- Collapse the given indices of a table into a new table.
--- In this table, the elements are overriden with each index.
---@generic T
---@generic K
---@param tbl table<K, T>
---@param ... K
---@return T[]
function table.collapse(tbl, ...)
    local ret = {}
    for _, x in ipairs(table.pack(...)) do
        for k, n in pairs(tbl[x]) do
            ret[k] = n
        end
    end
    return ret
end

--- Create a new table with the given function applied to each given value to create a new value.
---@generic T
---@generic K
---@generic R
---@param tbl table<K, T>
---@param func fun(k:any, x:T):R
---@return table<K, R>
function table.map(tbl, func)
    local ret = {}
    for k, v in pairs(tbl) do
        ret[k] = func(k, v)
    end
    return ret
end

--- Create a new list with the given function applied to each given element to create new elements.
---@generic T
---@generic K
---@param tbl T[]
---@param func fun(i: integer, x:T):K
---@return K[]
function table.imap(tbl, func)
    local ret = {}
    for i, v in ipairs(tbl) do
        table.insert(ret, func(i, v))
    end
    return ret
end

--- Create a new table of all the keys and values which match with the given function.
---@generic T
---@generic K
---@param tbl table<K, T>
---@param func fun(k:K, v:T):boolean
---@return table<K, T>
function table.select(tbl, func)
    local ret = {}
    for k, v in pairs(tbl) do
        if func(k, v) then
            ret[k] = v
        end
    end
    return ret
end

--- Create a new list of all the indices and elements which match with the given function.
---@generic T
---@param tbl T[]
---@param func fun(i:integer, v:T):boolean
---@return T[]
function table.iselect(tbl, func)
    local ret = {}
    for i, v in ipairs(tbl) do
        if func(i, v) then
            table.insert(ret, v)
        end
    end
    return ret
end

--- Join two tables by key, with the second table taking priority over duplicate keys.
---@generic T
---@generic K
---@param tbl table<K, T>
---@param other table<K, T>
---@return table<K, T>
function table.join(tbl, other)
    local new = {}
    for k, v in pairs(tbl) do
        new[k] = v
    end
    for k, v in pairs(other) do
        new[k] = v
    end
    return new
end

--- Join two lists, placing the second after the first
---@generic T
---@param tbl T[]
---@param other T[]
---@return T[]
function table.ijoin(tbl, other)
    local new = {}
    for _, v in ipairs(tbl) do
        table.insert(new, v)
    end
    for _, v in ipairs(other) do
        table.insert(new, v)
    end
    return new
end

--- Create a shallow copy of the given table.
---@generic T
---@generic K
---@param tbl table<K, T>
---@return table<K, T>
function table.copy(tbl)
    local new = {}
    for k, v in pairs(tbl) do
        new[k] = v
    end
    return new
end

--- Check if the given table contains the given value, using (==) to determine equality.
---@generic T
---@param tbl T
---@param val T
---@return boolean
function table.contains(tbl, val)
    for _, v in pairs(tbl) do
        if v == val then
            return true
        end
    end
    return false
end

--- Get a table which contains the count of arctaps on each arc (key)
---@param notes LuaArcTap[]
---@return {[LuaArc]:integer}
function arctapCounts(notes)

    local counts = {}
    for _, n in ipairs(notes) do
        if n.is 'arctap' then
            counts[n.arc] = (counts[n.arc] or 0) + 1
        end
    end
    return counts

end

--- Return the version of the given text which would be displayed in the given color with Unity's richtext engine.
---@param str string
---@param color Color? @default = Colors.white
---@return string
function string.richcolor(str, color)
    return '<color=' .. (color or Colors.white) .. '>' .. (str or '[nil]') .. '</color>'
end

--- Split a string into an iterator, using the given separator.
---@param delim string
---@return fun():(integer, string, integer)?
function string:split(delim)
    local idx = 1
    return function()

        if idx == 0 then return nil end

        local lineEnd, sepEnd = self.find(delim, idx)
        if lineEnd then
            local line = self.sub(idx, lineEnd - 1)
            local i = idx
            idx = sepEnd + 1
            return i, line, lineEnd
        else
            local i = idx
            idx = 0
            return i, self.sub(i, #self), #self
        end

    end
end

function table.find(tbl, val)
    for i, v in pairs(tbl) do
        if v == val then
            return i
        end
    end
    return nil
end

function table.search(tbl, pred)
    for i, v in pairs(tbl) do
        if pred(v) then
            return i
        end
    end
    return nil
end

function table.ifind(tbl, val)
    for i, v in ipairs(tbl) do
        if v == val then
            return i
        end
    end
    return nil
end

function table.isearch(tbl, pred)
    for i, v in ipairs(tbl) do
        if pred(v) then
            return i
        end
    end
    return nil
end

--- Split a string into an iterator, by lines.
---@return fun():integer start, string content, integer end
function string:lines()
    return self:split '\r?\n'
end

function enumerate(x)
    local i = 0
    return function()
        i = i + 1
        local item = x()
        if item then
            return i, x()
        end
    end
end

-- NEW UTILS --
function evaluateMathExpression(expression)
    local success, result = pcall(load("return " .. expression))
    return success and result
end