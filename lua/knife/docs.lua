-- require("plenary.reload").reload_module("knife")

local Range = require('knife.types.range')
local query = require('knife.query')
local text = require('knife.text')
local ts = require('vim.treesitter')

local language = 'c_sharp'

local scope_query = ts.parse_query(language, [[
[
	(class_declaration
		name: (_) @name
  	)
    (record_declaration
        name: (_) @name
    )
    (enum_declaration
        name: (_) @name
    )
    (field_declaration
        (variable_declaration
            (variable_declarator
                (identifier) @name
            )
        )
    )
    (property_declaration
        name: (_) @name
    )
  	(method_declaration
		name: (_) @name
  	)
]
]])

local method_details_query = ts.parse_query(language, [[
(method_declaration
	type: (predefined_type) @return_type
    parameters: (parameter_list
		(parameter
        	name: (identifier) @parameter_names
        )
    )
    	
)
(throw_statement (
    object_creation_expression
        type: (identifier) @exception_types
    )
)?
]])

local function create_default_xmldoc()
    return {
        '/// <summary>',
        '/// ',
        '/// </summary>',
    }
end

local function create_xmldoc_for_method(parameter_names, return_type, exceptions)
    local doc = create_default_xmldoc()

    for _, name in ipairs(parameter_names) do
        table.insert(doc, string.format('/// <param name="%s">', name))
        table.insert(doc, string.format('/// '))
        table.insert(doc, string.format('/// </param>'))
    end

    if (return_type ~= 'void' and return_type ~= 'Task') then
        table.insert(doc, string.format('/// <returns>'))
        table.insert(doc, string.format('/// '))
        table.insert(doc, string.format('/// </returns>'))
    end

    for _, type in ipairs(exceptions) do
        table.insert(doc, string.format('/// <exception cref="%s">', type))
        table.insert(doc, string.format('/// '))
        table.insert(doc, string.format('/// </exception>'))
    end

    return doc
end

--- Obtains a node with entity declaration by traversing the node tree.
-- @param name_node: A TreeSitter of found name identifier node.
local function traverse_to_declaration_node(name_node)
    local parent = name_node:parent()
    if parent:type() == 'variable_declarator' then
        return parent:parent():parent()
    else
        return parent
    end
end

local M = {}

function M.generate_xmldoc_under_cursor(buffer)
    buffer = buffer or 0

    local scope = query.match(language, buffer, scope_query)
    scope = scope:intersect_with_cursor()

    if vim.tbl_isempty(scope.matches) then
        print("Can't generate xmldoc for the entity under the cursor.")
        return
    end

    assert(scope.matches.name ~= nil, 'Something wrong with the query')


    local declaration = traverse_to_declaration_node(scope.matches.name[1].node)
    local declaration_type = declaration:type()
    local declaration_range = Range.from_node(declaration)
    local indent = text.buf_get_first_n_chars_from_line(
        buffer,
        declaration_range.from.row,
        declaration_range.from.column)

    if declaration_type == 'method_declaration' then
        details = query.match(language, buffer, method_details_query, declaration)
        return_type = details.matches.return_type or ''
        parameter_names = {}
        exceptions = {}

        for _, argument in ipairs(details.matches.parameter_names or {}) do
            table.insert(parameter_names, argument.value)
        end
        for _, exception in ipairs(details.matches.exception_types or {}) do
            table.insert(exceptions, exception.value)
        end

        doc = create_xmldoc_for_method(parameter_names, return_type, exceptions)
    else
        if vim.endswith(declaration_type, '_declaration') then
            doc = create_default_xmldoc()
        else
           print('Unknown parent for the entity under the cursor')
        end
    end

    text.indent_with_prefix(doc, indent)

    -- Tree sitter indexing format is (0, 0) while vim is (1, 0)
    -- Therefore row before in vim would be just row in the TS.
    local insert_row = declaration_range.from.row
    vim.api.nvim_buf_set_lines(buffer, insert_row, insert_row, true, doc)
end

return M;
