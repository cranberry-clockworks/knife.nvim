local M = {}

--- Requests an input from user.
-- @param message_template string: A template for the request message.  
-- @returns The string inputed by user.
function M.ask_user(message_template, ...)
    return vim.call('input', string.format(message_template', ...))
end

return M
