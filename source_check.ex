-- This program verifies that everything you have define_c_func and define_c_proc for
-- are infact available in a supplied DLL.  
-- 
-- Usage is:
-- 
-- eui source_check.ex dll_file e_file
-- 
-- dll_file is a DLL
-- e_file   is a dot-e file.
-- 
-- 


include std/console.e
include std/dll.e
include std/types.e
include euphoria/tokenize.e

if length(command_line()) != 4 then
    display("Usage:\n" &
    "\t\teui source_check.ex dll_filename e_filename")
    maybe_any_key()
    abort(3)
end if

cstring euphoria_exe, source_check_ex, dll_filename, e_filename
{euphoria_exe, source_check_ex, dll_filename, e_filename} = command_line()

constant dll_id = open_dll(dll_filename)
if dll_id = 0 then
    display("Cannot open DLL '[1]'.", {dll_filename})
    maybe_any_key()
    abort(2)
end if

sequence et_tokens
integer et_error, et_err_line, et_err_column
{et_tokens, et_error, et_err_line, et_err_column} = tokenize_file(e_filename)
if et_error != ERR_NONE then
    display("Error loading E file")
    maybe_any_key()
    abort(1)
end if

for tok_i = 1 to length(et_tokens) do
    sequence tok = et_tokens[tok_i]
    if tok[TTYPE] = T_IDENTIFIER and find(tok[TDATA], {"define_c_func", "define_c_proc"} ) then
        -- i -> define_c...
        -- +1 -> ( 
        -- +2 -> dll_library id
        -- +3 -> comma
        -- +4 -> actual routine name in C
        tok = et_tokens[tok_i+4]
        atom function_load = define_c_proc(dll_id, tok[TDATA], {})
        if function_load < 0 then
            display("Could not load '[2]' from '[1]' in '[3]' line [4], column [5].", { dll_filename, tok[TDATA], e_filename, tok[TLNUM], tok[TLPOS] })
        end if
    end if
end for
maybe_any_key()
