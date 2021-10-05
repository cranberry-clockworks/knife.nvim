-- require("plenary.reload").reload_module("knife")

local Range = require('knife.lib.types.range')
local query = require('knife.lib.query')
local text = require('knife.lib.text')
local xml = require('knife.lib.generators.xml')
local ts = require('vim.treesitter')

local language = 'c_sharp'

local scope_query = ts.parse_query(language, [[
[
    (
        class_declaration
        name: (_) @name
    )
    (
        struct_declaration
        name: (_) @name
    )
    (
        record_declaration
        name: (_) @name
    )
    (
        enum_declaration
        name: (_) @name
    )
    (
        field_declaration
        (
            variable_declaration
            (
                variable_declarator
                (identifier) @name
            )
        )
    )
    (
        property_declaration
        name: (_) @name
    )
    (
        method_declaration
        name: (_) @name
    )
]
]])

local method_details_query = ts.parse_query(language, [[
(
    method_declaration
    type: (_) @return_type
    type_parameters:
    (
        type_parameter_list
        (
            type_parameter 
            (identifier) @generic_types
        )
    )?
    parameters: (
        parameter_list
        (
            parameter
            name: (identifier) @parameter_names
        )?
    )
)
(
    throw_statement
    (
        object_creation_expression
        type: (identifier) @exception_types
    )
)?
]])

local function create_default_xmldoc()
    doc = {}
    xml.write_tag(doc, "summary")
    return doc
end

local function create_xmldoc_for_method(
    parameter_names,
    return_type,
    generic_types,
    exception_types)

    local doc = create_default_xmldoc()

    for _, type in ipairs(parameter_names) do
        xml.write_tag(doc, 'param', { name = type })
    end

    if (return_type ~= 'void' and return_type ~= 'Task') then
        xml.write_tag(doc, 'returns')
    end

    for _, type in ipairs(generic_types) do
        xml.write_tag(doc, 'typeparam', { name = type })
    end

    for _, type in ipairs(exception_types) do
        xml.write_tag(doc, 'exception', {cref = type})
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
        local unpack_capture = function(query_result, capture_name)
            local unpacked = {}
            for _, entry in ipairs(query_result.matches[capture_name] or {}) do
                table.insert(unpacked, entry.value)
            end
            return unpacked
        end

        details = query.match(language, buffer, method_details_query, declaration)
        return_type = details.matches.return_type or ''
        parameter_names = unpack_capture(details, 'parameter_names')
        generic_types = unpack_capture(details, 'generic_types')
        exception_types = unpack_capture(details, 'exception_types')

        doc = create_xmldoc_for_method(parameter_names, return_type, generic_types, exception_types)
    else
        if vim.endswith(declaration_type, '_declaration') then
            doc = create_default_xmldoc()
        else
           print('Unknown parent for the entity under the cursor')
        end
    end

    text.prefix_with(doc, indent .. '/// ')

    -- Tree sitter indexing format is (0, 0) while vim is (1, 0)
    -- Therefore row before in vim would be just row in the TS.
    local insert_row = declaration_range.from.row
    vim.api.nvim_buf_set_lines(buffer, insert_row, insert_row, true, doc)
end

return M;
