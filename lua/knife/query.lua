local table_extra = require('knife.types.table_extra')
local Position = require('knife.types.position')
local Range = require('knife.types.range')

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
    local root = node or ts.get_parser(buffer, language):parse()[1]:root()

    local matches = {}
    local from, _, to, _ = root:range()
    for id, n, _ in query:iter_captures(root, buffer, from, to) do
        local capture = query.captures[id]
        table_extra.grow_sublist(matches, capture, {
            type = n:type(),
            range = Range.from_node(n),
            value = tsq.get_node_text(n, buffer),
            node = n
        })
    end
    return QueryResult.new(buffer, matches)
end

return {
    match = match,
}
