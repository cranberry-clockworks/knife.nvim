local table_extra = require('knife.lib.types.table_extra')
local Position = require('knife.lib.types.position')
local Range = require('knife.lib.types.range')

local ts = require('vim.treesitter')
local tsq = require('vim.treesitter.query')

local QueryResult = {}
local QueryResultImpl = {__index = QueryResult}

function QueryResult.new(buffer, matches)
    return setmetatable({
        buffer = buffer,
        matches = matches,
    }, QueryResultImpl)
end

function QueryResult:intersect_with_cursor()
    local cursor = Position.from_cursor(self.buffer)

    local intersection = {}

    for name, capture in pairs(self.matches) do
        for _, m in ipairs(capture) do
            if m.range:contains(cursor) then
                table_extra.grow_sublist(intersection, name, m)
            end
        end
    end
    return self.new(self.buffer, intersection)
end

--- Performs tree-sitter query on AST in given buffer
-- @param language string: Used language to parse AST.
-- @param buffer int: A buffer handle where perform search.
-- @param query: A parsed tree-sitteer query.
-- @param node tsnode or nil: A tree-sitter node where search is performed.
-- @returns QueryResult: A table with matches.
local function match(language, buffer, query, node)
    local function not_present(matches, capture, range, value)
        for _, c in ipairs(matches[capture] or {}) do
            if c.range == range and c.value == value then
                return false;
            end
        end
        return true;
    end

    local root = node or ts.get_parser(buffer, language):parse()[1]:root()

    local matches = {}
    local from, _, to, _ = root:range()
    for id, n, _ in query:iter_captures(root, buffer, from, to) do
        local capture = query.captures[id]

        range = Range.from_node(n)
        value = tsq.get_node_text(n, buffer)

        if not_present(matches, capture, range, value) then
            table_extra.grow_sublist(matches, capture, {
                type = n:type(),
                range = range,
                value = value,
                node = n
            })
        end
    end
    return QueryResult.new(buffer, matches)
end

return {
    match = match,
}
