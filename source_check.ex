--
-- This program verifies that everything you have define_c_func and define_c_proc for
-- are infact available in a supplied DLL.
--
-- Usage is:
--
-- eui source_check.ex [--dll dll_file] e_file
--
-- dll_file is a DLL
-- e_file   is a dot-e file.
--
-- The dll_file is optional.  The dll filename will be collected from e_file itself.
--
-- Nota Bene: This is not a complete parser/interpreter.  So, it is easy for this program to get
-- things totally wrong but if other routines are getting loaded from the same DLL through this program
-- and the routines are all of the form `id = open_dll(dll_num, string literal', then I wouldn't expect
-- false failures.
--
include std/console.e
include std/dll.e
include std/types.e
include euphoria/tokenize.e
include std/filesys.e
include std/pretty.e
include std/text.e
include std/io.e

cstring euphoria_exe, source_check_ex, dll_filename = "", e_filename = ""
procedure usage()
    puts(io:STDERR, "Usage:\n" &
    "\t\teui source_check.ex [--dll dll_filename] e_filename")
    maybe_any_key()
    abort(4)
end procedure
if length(command_line()) < 3 then
    usage()
end if
atom dll_id = 0
if 1 then
    sequence cl = command_line()
    {euphoria_exe, source_check_ex} = cl[1..2]
    integer dl_loc = find("--dll", cl)
    if dl_loc and dl_loc < length(cl) then
        dll_filename = cl[dl_loc + 1]
        dll_id = open_dll(dll_filename)
        if dll_id = 0 then
            display("Cannot open DLL '[1]'.", {dll_filename})
            maybe_any_key()
            abort(2)
        end if
    end if
    for i = 3 to length(cl) do
        if not dl_loc or (dl_loc != i and i != dl_loc + 1) then
            if compare(e_filename, "") then
                display("Extra parameters supplied are ignored")
                continue
            end if
            e_filename = cl[i]
        end if
    end for
end if
if equal(e_filename, "") then
    usage()
end if

-- returns new map
function map_new()
    return { 
                    {},
                    {0}
                }
end function

-- finds an index value for an object key x in map m.
function map_find(sequence m, object x)
	return find(x, m[1])
end function

-- access an image from an index value.  map_access(m, 0) is always 0.  Even on empty maps. 
function map_access(sequence m, integer i)
	return m[2][i + 1]
end function

-- get a value with a key into map m
function map_get(sequence m, object x)
	return map_access(m, map_find(m, x))
end function

sequence dlls = map_new()

sequence et_tokens
integer et_error, et_err_line, et_err_column
integer succeses = 0, attempts = 0
keep_whitespace(0)
{et_tokens, et_error, et_err_line, et_err_column} = tokenize_file(e_filename)
if et_error != ERR_NONE then
    display("Error loading E file")
    maybe_any_key()
    abort(1)
end if
for tok_i = 1 to length(et_tokens)-2 do
    sequence tok = et_tokens[tok_i]
    if tok[TTYPE] = T_IDENTIFIER then
        switch tok[TDATA] do
            case "define_c_func", "define_c_proc" then
                -- i -> define_c...
                -- +1 -> (
                -- +2 -> dll_library id
                -- +3 -> comma
                -- +4 -> actual routine name in C
                if tok_i + 4 > length(et_tokens) then
                    display("Syntax error at the end of the file")
                    continue
                end if
                tok = et_tokens[tok_i+2]
                cstring dll_idname = tok[TDATA]
                object r = map_get(dlls, dll_idname)
                if equal(r, 0)  then
                	display("Name Error [1] is not declared in the e file", {dll_idname})
                	if dll_id  = 0 then
                		continue
                	end if
                else
	                 {dll_filename, dll_id} = r        	
                end if
                tok = et_tokens[tok_i+4]
                atom function_load = define_c_proc(dll_id, tok[TDATA], {})
                attempts += 1
                if function_load < 0 then
                    display("Could not load '[2]' from '[1]' in '[3]' line [4], column [5].", { dll_filename, tok[TDATA], e_filename, tok[TLNUM], tok[TLPOS] })
                else
                    succeses += 1
                end if
            case "open_dll" then
                if tok_i - 2 < 1 or tok_i + 2 > length(et_tokens) then
                    display("Irrational code at the beginning of the file or syntax error at the end of the file")
                    continue
                end if
                sequence equals_tok = et_tokens[tok_i-1]
                sequence before_equals_tok = et_tokens[tok_i-2]
                
                if (equals_tok[TTYPE] != T_EQ) or (before_equals_tok[TTYPE] != T_IDENTIFIER) or et_tokens[tok_i+1][TTYPE] != T_LPAREN or et_tokens[tok_i+2][TTYPE] != T_STRING then
                    cstring e

                    if equals_tok[TTYPE] != T_EQ then
                    	e  = "No equals sign preceeding open_dll:"
                    elsif before_equals_tok[TTYPE] != T_IDENTIFIER then
                    	display("Value is not an identifier [1] [2] L: [3] C: [4]", {before_equals_tok[TDATA], e_filename, tok[TLNUM], tok[TLPOS]} )
                    	continue
                    elsif et_tokens[tok_i + 1][TTYPE] != T_LPAREN then
                    	e = "Left parenthesis did not follow open_dll."
                    elsif equal(et_tokens[tok_i+2][TDATA], "{") then
                        e = "open_dll(sequence of strings) is not supported by source_check.ex"
                    else
                    	e = "First argument to open_dll isn't a string.  It's " & et_tokens[tok_i + 2][TDATA] & " in" 
 		    end if
                    display(e & " [1] L: [2] C: [3]", { e_filename, tok[TLNUM], tok[TLPOS] })
                    continue
                end if
                cstring this_dll_filename = et_tokens[tok_i+2][TDATA]
                cstring this_dll_idname   = before_equals_tok[TDATA]
                dlls = { append(dlls[1], this_dll_idname), append(dlls[2], {this_dll_filename, open_dll({pathname(e_filename) & SLASH & this_dll_filename, this_dll_filename})}) }
        end switch
    end if
end for
display("There were [1] C-routines checked, [2] were successful, and [3] failed.", {attempts, succeses, attempts - succeses})
maybe_any_key()
