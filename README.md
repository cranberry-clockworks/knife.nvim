# knife.nvim

A Neovim plugin with useful tools for C# development.

# Installation
## Dependencies

```
nvim-treesitter
```

## vim-plug

Add to the startup config file:
```
Plug '
Plug 'cranberry-knight/knife.nvim'
```

On next Neovim startup:
```
:PlugInstall
```

# Features
## XML documentation comment context generation.

One can generate XML documentation for classes, methods fields, properties, etc.
For methods information about parameters, return type and possible exceptions
are used.

To use map `requre('knife').generate_xml_doc_under_cursor()` function to the key of
your choice.

# Roadmap
[x] Context XML documentation generator.
[ ] Smart entity renaming with file.
[ ] New class/interface/enum in separate file creation.
[ ] Smart replacing XML documentation comments on new generation.
