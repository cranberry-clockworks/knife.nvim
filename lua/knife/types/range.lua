-- @class Range
--- A range of text with (0, 0) indexing.
-- @field from Postion: a start of the range.
-- @field to Position: a end of the range.
local Range = {}
local RangeImpl = {
    __index = Range,
    __eq = function(r1, r2)
        return r1.from == r2.from and r1.to == r2.to
    end
}

--- Creates a new range that represent piece of buffer.
--- Keep in mind that range is not a rectangle but sequence of characters.
-- @param from Position: A start of the range.
-- @param to Position: An end of the range.
-- @returns Position: A range with defined start and end.
function Range.new(from, to)
    return setmetatable({
        from = from,
        to = to
    }, RangeImpl)
end

function Range.from_node(node)
    local Position = require('knife.types.position')
    local row_s, col_s, row_e, col_e = node:range()
    return Range.new(Position.new(row_s, col_s), Position.new(row_e, col_e))
end

--- Checks if the range contains a certain position
-- @param position Position: A position to check.
-- @returns boolean: true if range contains position or false.
function Range:contains(position)
    -- Range is not quite rectangle. For example:
    -- First case
    -- . . # # . . .
    --
    -- Second case
    -- . . . # # # #
    -- # # # # # # #
    -- # # # . . . .
    --
    -- Keep in mind that ending column is not inclusive.

    local left = (position.row == self.from.row and position.column >= self.from.column)
        or position.row > self.from.row
    local right = (position.row == self.to.row and position.column < self.to.column)
        or position.row < self.to.row

    return left and right
end

-- Creates an LSP type Range.
-- @returns table: an LSP type Range.
function Range:to_lsp_range()
    return {
        ['start'] = {
            line = self.from.row,
            character = self.from.column,
        },
        ['end'] = {
            line = self.to.row,
            character = self.to.column,
        }
    }
end

return Range
