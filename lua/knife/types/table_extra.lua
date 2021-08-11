local M = {}

--- Extends sub list of the table.
-- @param tbl table: A table of lists.
-- @param key any: A key of the sub list.
-- @param value any: A new value placed in the sub list.
function M.grow_sublist(tbl, key, value)
    if tbl[key] == nil then
        tbl[key] = { value }
    else
        table.insert(tbl[key], value)
    end
end

return M;
