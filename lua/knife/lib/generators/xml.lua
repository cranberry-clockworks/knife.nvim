local M = {}

--- Appends strings with XML tag.
-- @param to table: A table of strings. Each item in the table represents a document line.
-- @param name string: A name of the XML tag.
-- @param parameters dictionary: A table with XML tag parameters in the key-value format.
-- @param format string: A format of the generated tag as follows:
--      "sparse":
--          <sample a="a" b="b">
--
--          </sample>
--      "compact":
--          <sample a="a" b="b">
--          </sample>
--      "minimal":
--          <sample a="a" b="b"></sample>
function M.write_tag(to, name, parameters, format)
    format = format or 'sparse'

    params_str = ''
    for k, v in pairs(parameters or {}) do
        params_str = params_str .. string.format(' %s="%s"', k, v)
    end

    if format == 'sparse' then
        table.insert(to, string.format('<%s%s>', name, params_str))
        table.insert(to, '')
        table.insert(to, string.format('</%s>', name))
        return
    end

    if format == 'compact' then
        table.insert(to, string.format('<%s%s>', name, params_str))
        table.insert(to, string.format('</%s>', name))
        return
    end

    if format == 'minimal' then
        table.insert(to, string.format('<%s%s></%s>', name, params_str, name))
        return
    end

    error(
        string.format(
            'Unknown format: %s. Use one of the following: "sparse", "compact", "minimal"',
            format
        )
    )
end

return M
