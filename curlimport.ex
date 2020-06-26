-- This tool creates a dot-e file with the Header.
-- It is recommended that you create a wrapper using the generated dot-e file.
--
-- update the CURL constants with:
-- eui curlimport.ex < /usr/include/curl/curl.h > primitive_curl.e
--
--
-- Then create a curl.e do things like:
-- <eucode>
-- public include primitive_curl.e as p
-- include std/types.e
-- include std/dll.e
--
-- --CURL_EXTERN CURLcode curl_mime_name(curl_mimepart *part, const char *name)
-- public function curl_mime_name(atom part, cstring name)
--     atom name_ptr = allocate_string(nmae, 1)
--     atom ret = p:curl_mime_name(part, name_ptr)
--     return ret
-- end function
-- </eucode>

include std/regex.e as regex
include std/io.e
include joy.e
include std/sort.e
include std/text.e
constant macroconstant     = regex:new("^ *#define +([A-Z][A-Z_]*) +([0-9]+)", MULTILINE)
constant curloptionpattern = regex:new("CINIT\\(([A-Z_0-9]+), [A-Z]+, ([0-9]+)", MULTILINE)
constant curlproto_pattern = regex:new("^ *#define (CURLPROTO_[A-Z]+) +\\(1<<([0-9]+)\\)", MULTILINE)
constant curlfunction_pattern = regex:new(`CURL_EXTERN ([A-Za-z_]+\s*(\*)?)([a-z_]+)\((.*)\);`, DOTALL & UNGREEDY)
constant argument_list_pattern = regex:new(`([a-z_]+)`, CASELESS)
constant curlfunction_argument_pattern = regex:new("(([A-Za-z_]+)( |\n|\t|[*])*)*([A-Za-z_]*)")
constant whitespace_pattern = regex:new("^[ \t\n]*$")
constant OUT = STDOUT, IN = STDIN


-- First import the constants

sequence file_data = read_file(IN)
printf(OUT, "-- This file was generated by curlimport.e.\n", {})
puts(OUT,`
include std/dll.e

constant dll = open_dll({"libcurl.dll", "libcurl.so"})

`)

object ms = regex:all_matches( curloptionpattern, file_data)
if sequence(ms) then
    for mi = 1 to length(ms) do
        object m = ms[mi]
        printf(OUT,"public constant CURLOPT_%s = %s,\n", {m[2], m[3]})
    end for
end if

ms = regex:all_matches( macroconstant, file_data)
if sequence(ms) then
    for mi = 1 to length(ms) do
        object m = ms[mi]
        printf(OUT,"public constant %s = %s\n", {m[2], m[3]})
    end for
end if

ms = regex:all_matches( curlproto_pattern, file_data)
if sequence(ms) then
    for mi = 1 to length(ms) do
        object m = ms[mi]
        printf(OUT,"public constant %s = power(2,%s)\n", m[2..3])
    end for
end if


object function_locations = regex:find_all(curlfunction_pattern, file_data)
object function_matches = regex:all_matches(curlfunction_pattern, file_data)
if atom(function_matches) then
    puts(io:STDERR, "Cannot find matches\n")
    abort(0)
end if

function c_type_to_euc_type(sequence argument, sequence argument_groups)
    if equal(argument, "void") then
        return ""
        -- do nothing
    elsif eu:find('*', argument) then
        return "C_POINTER"
        -- elsif eu:find("double", argument_groups) and eu:find("long", argument_groups) then
    elsif eu:match({"long","long"}, sort(argument_groups)) and eu:find("unsigned", argument_groups) then
        return "C_ULONGLONG"
    elsif eu:match({"long","long"}, sort(argument_groups)) then
        return "C_LONGLONG"
    elsif eu:find("long", argument_groups) and eu:find("unsigned", argument_groups) then
        return  "C_ULONG"
    elsif eu:find("int", argument_groups) and eu:find("unsigned", argument_groups) then
        return  "C_UINT"
    elsif eu:find("int", argument_groups) then
        return  "C_INT"
    elsif eu:find("bool", argument_groups) then
        return  "C_BOOL"
    else
        return  "C_" & upper(argument_groups[1])
    end if
end function

sequence types = {"C_BOOL", "C_INT", "C_UINT", "C_DOUBLE", "C_LONGLONG", "C_LONG", "C_ULONG", "C_POINTER"} -- list of declared c types in std/dll.e

for h = 1 to length(function_matches) do
    sequence m = function_matches[h]
    sequence FD = m[1]
    sequence RT = m[2]
    sequence FN = m[4]
    while RT[$] = ' ' do
        RT = RT[1..$-1]
    end while
    while RT[1] = ' ' do
        RT = RT[2..$]
    end while



    -- printf(OUT, "= %d captured groups\n", {length(m)-1})
    sequence AL = m[5] -- argument list
    sequence arg_list = ""
    sequence eu_arg_list = ""
    sequence argument_names = {}
    object argument_matches = regex:matches(argument_list_pattern, AL)
    if sequence(argument_matches) then
        -- puts(OUT, "argument groups method 2:")
        --pretty_print(OUT, argument_matches, {3})
        -- puts(OUT, 10)
    end if
    argument_matches = regex:all_matches(curlfunction_argument_pattern, AL)
    integer argument_count = 0
    if sequence(argument_matches) then
        for j = 1 to length(argument_matches) do
            sequence argument = argument_matches[j][1]

            sequence argument_name = argument_matches[j][$]
            if not equal(argument,"") and atom(regex:find(whitespace_pattern, argument)) then
                argument_count += 1
                sequence argument_groups = split(regex:new(" "), argument)

                -- printf(OUT, "argument = \'%s\'\n", {argument})
                -- pretty_print(OUT, argument_groups, {2})
                stringASCII next_type = c_type_to_euc_type(argument, argument_groups)
                if compare(next_type,"") then
                    if equal(argument_name,"") or atom(argument_name) or eu:find(argument_name, argument_names) then
                        argument_name = regex:find_replace(regex:new("\\*"), argument_groups[$], "")
                    end if
                    if equal(argument_name,"") or atom(argument_name) or eu:find(argument_name, argument_names) then
                        argument_name = sprintf("arg%d", {argument_count})
                    end if
                    argument_names = append(argument_names, argument_name)
                    if not eu:find(next_type, types) then
                        puts(OUT, "export constant " & next_type & " = C_POINTER\n")
                        types = append(types, next_type)
                    end if
                    if equal(next_type,"C_BOOL") then
                        arg_list &= next_type & ", "
                        eu_arg_list &= sprintf("integer %s, ", {argument_name})
                    elsif not equal(next_type, "") then
                        arg_list &= next_type & ", "
                        eu_arg_list &= sprintf("atom %s, ", {argument_name})
                    end if
                else
                    argument_name = ""
                end if
            end if
        end for
        if length(arg_list) > 1 then
            arg_list = arg_list[1..$-2]
            eu_arg_list = eu_arg_list[1..$-2]
        end if
    end if
    printf(OUT, "%s\n", {regex:find_replace(regex:new("^", MULTILINE), FD, "--")})
    object C_RT = c_type_to_euc_type(RT, split(regex:new(" "), RT))
    if not equal(C_RT,0) then
        RT = C_RT
    end if
    if sequence(C_RT) and length(C_RT) and not eu:find(C_RT, types) then
        printf(OUT, "constant %s = C_POINTER\n", {C_RT})
        types = append(types, C_RT)
    end if
    if equal(RT, "") then
        printf(OUT, "export constant %sx = define_c_proc(dll, \"%s\",{%s})\n", {FN, FN, arg_list})
        printf(OUT, "public procedure %s(%s)\n", {FN, eu_arg_list})
        printf(OUT, "\tc_proc(%sx, {%s})\n", {FN, join(",", argument_names)})
        printf(OUT, "end procedure\n", {})
    else
        printf(OUT, "export constant %sx = define_c_func(dll, \"%s\",{%s}, %s)\n", {FN, FN, arg_list, RT})
        printf(OUT, "public function %s(%s)\n", {FN, eu_arg_list})
        printf(OUT, "\treturn c_func(%sx, {%s})\n", {FN, join(",", argument_names)})
        printf(OUT, "end function\n", {})
    end if
end for
printf(io:STDERR, "= %d functions imported.", {length(function_matches)})
abort(0)

