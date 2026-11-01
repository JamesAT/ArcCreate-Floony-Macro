--Utils.lua
--Author: floofer++
--Version: 2.0 (cleanup + bug fixes)

require 'floony.lib.color'

------------------------------------------------------------------
-- Time division
------------------------------------------------------------------

---Return an iterator of the best divisions of the given range by the given step. The iterator will return the start and end of each division.
---@param tStart number
---@param tEnd number
---@param tSplit number
---@return fun():number?, number?
function bestDivisions(tStart, tEnd, tSplit)

    -- A non-positive step would never advance; fall back to one single division.
    if type(tSplit) ~= 'number' or tSplit <= 0 then
        tSplit = math.max(tEnd - tStart, 1)
    end

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

    if type(tSplit) ~= 'number' or tSplit <= 0 then
        tSplit = math.max(tEnd - tStart, 1)
    end

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

------------------------------------------------------------------
-- math
------------------------------------------------------------------

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

--- Return where `v` sits between `a` and `b` (0 at a, 1 at b). Returns 0 when a == b.
---@param a number
---@param b number
---@param v number
---@return number
function math.invlerp(a, b, v)
    if a == b then return 0 end
    return (v - a) / (b - a)
end

--- Clamp a value between a minimum and a maximum.
---@param v number
---@param lo number
---@param hi number
---@return number
math.clamp = math.clamp or function(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

--- Round to the nearest integer (halves round up).
---@param x number
---@return integer
math.round = math.round or function(x)
    return math.floor(x + 0.5)
end

------------------------------------------------------------------
-- table
------------------------------------------------------------------

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
        for _, n in ipairs(tbl[x] or {}) do
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
    local args = {...}
    local ret = {}
    for _, x in ipairs(args) do
        for k, n in pairs(tbl[x] or {}) do
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

--- Create a new list of all the elements which match with the given function.
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
---@param tbl T[]
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

--- Return the key of the first element equal to `val` (any key, unordered), or nil.
function table.find(tbl, val)
    for i, v in pairs(tbl) do
        if v == val then
            return i
        end
    end
    return nil
end

--- Return the key of the first element for which `pred(v)` is true (any key, unordered), or nil.
function table.search(tbl, pred)
    for i, v in pairs(tbl) do
        if pred(v) then
            return i
        end
    end
    return nil
end

--- Return the index of the first element equal to `val` (in list order), or nil.
function table.ifind(tbl, val)
    for i, v in ipairs(tbl) do
        if v == val then
            return i
        end
    end
    return nil
end

--- Return the index of the first element for which `pred(v)` is true (in list order), or nil.
function table.isearch(tbl, pred)
    for i, v in ipairs(tbl) do
        if pred(v) then
            return i
        end
    end
    return nil
end

------------------------------------------------------------------
-- arctaps
------------------------------------------------------------------

--- Get a table which contains the count of arctaps on each arc (key).
--- Looking up an arc object that is not the exact same Lua object as the key
--- (e.g. the arc was queried again) still works, by falling back to instanceEquals.
---@param notes LuaArcTap[]
---@return {[LuaArc]:integer}
function arctapCounts(notes)

    local entries = {}
    local counts = {}

    local function find(arc)
        for _, e in ipairs(entries) do
            if e.arc == arc then return e end
            if e.arc.instanceEquals and arc.instanceEquals and e.arc.instanceEquals(arc) then
                return e
            end
        end
        return nil
    end

    for _, n in ipairs(notes) do
        if n.is 'arctap' then
            local e = find(n.arc)
            if not e then
                e = { arc = n.arc, n = 0 }
                entries[#entries + 1] = e
            end
            e.n = e.n + 1
            counts[n.arc] = e.n
        end
    end

    return setmetatable(counts, {
        __index = function(_, arc)
            if arc == nil then return nil end
            local e = find(arc)
            return e and e.n or nil
        end
    })

end

------------------------------------------------------------------
-- string
------------------------------------------------------------------

--- Return the version of the given text which would be displayed in the given color with Unity's richtext engine.
---@param str string
---@param color Color? @default = Colors.white
---@return string
function string.richcolor(str, color)
    return '<color=' .. (color or Colors.white) .. '>' .. (str == nil and '[nil]' or tostring(str)) .. '</color>'
end

--- Remove whitespace from both ends of a string.
---@return string
function string.trim(str)
    return (str:gsub('^%s+', ''):gsub('%s+$', ''))
end

--- Split a string into an iterator, using the given separator (a Lua pattern).
--- Yields: start index of the piece, the piece, index where the separator starts.
---@param delim string
---@return fun():(integer, string, integer)?
function string:split(delim)
    local s = self
    local idx = 1
    return function()

        if idx == 0 then return nil end

        local sepStart, sepEnd = s:find(delim, idx)
        if sepStart and sepEnd >= sepStart then
            local i = idx
            local piece = s:sub(idx, sepStart - 1)
            idx = sepEnd + 1
            return i, piece, sepStart
        else
            local i = idx
            idx = 0
            return i, s:sub(i), #s
        end

    end
end

--- Split a string into an iterator, by lines.
---@return fun():integer start, string content, integer end
function string:lines()
    return self:split '\r?\n'
end

------------------------------------------------------------------
-- iteration
------------------------------------------------------------------

--- Wrap an iterator so it also yields a running index: for i, a, b in enumerate(iter) do
---@param x fun(...):...
---@return fun(...):...
function enumerate(x)
    local i = 0
    return function(...)
        local r = table.pack(x(...))
        if r[1] == nil then return nil end
        i = i + 1
        return i, table.unpack(r, 1, r.n)
    end
end

------------------------------------------------------------------
-- sandboxed evaluation
------------------------------------------------------------------

--- Environment given to user-typed expressions: only math (also reachable without the `math.` prefix).
local function makeMathEnv()
    local env = { math = math }
    for k, v in pairs(math) do env[k] = v end
    return env
end

--- Compile a chunk of Lua code with a restricted environment.
---@param code string
---@param name string? @chunk name used in error messages
---@param env table? @defaults to the math-only environment
---@return function? fn, string? err
function safeLoad(code, name, env)
    return load(code, name or 'input', nil, env or makeMathEnv())
end

--- Evaluate a numeric expression typed by the user (e.g. "120*2", "bpm/2" is NOT available).
--- Returns the number, or false when the text is not a valid numeric expression.
---@param expression string|number
---@return number|boolean
function evaluateMathExpression(expression)
    if type(expression) == 'number' then return expression end
    if type(expression) ~= 'string' or expression:match('^%s*$') then return false end

    local fn = safeLoad('return ' .. expression, 'expression')
    if not fn then return false end

    local ok, result = pcall(fn)
    if ok and type(result) == 'number' and result == result then
        return result
    end
    return false
end
