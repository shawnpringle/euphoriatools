-- This program modifies your source code.  It will make sure that each line of source is correctly
-- indented.  Correctly means, that inside a type,function,procedure,for,loop,while,if,else,elsif,
-- case,or switch statement, other statements are four spaces more to the right.
-- 
-- Usage is:
-- 
-- eui formateum.ex [--follow|-f] source_file1 source_file2 ....
-- 
-- -f or --follow is optional.
-- source_file1 source_file2 ...   should be at least one source file.
-- 
-- If you use the --follow option, the program will wait for changes and reproess the file after each
-- change to the file's timestamp.
-- 

include euphoria/tokenize.e
include std/io.e
include std/filesys.e
include std/types.e         
include std/math.e
include std/search.e
include std/os.e

constant cl = command_line()
boolean follow_flag = 0
constant args = cl[3..$]
keep_whitespace(1)
keep_comments(1)
string_strip_quotes(0)
string_numbers(1)
keep_keywords(1)

type token_sequence(object x)
    if atom(x) then
        return 0
    end if
    for i = 1 to length(x) do
        if length(x[i]) != 5 then
            return 0
        end if
    end for
    return 1
end type

constant block_starters = { "if", "loop", "while", "for", "switch", "function", "procedure", "type", "ifdef" }
constant left_shifter   = { "else", "elsif", "entry", "until" }


enum ERR_CANNOT_WRITE_TEMPORARY_FILE = ERR_HEX_STRING+1, ERR_TOO_FAR_LEFT, ERR_END_WITH_NO_BLOCK, ERR_WRONG_END, ERR_INTERNAL_ERROR

-- Takes Euphoria code from in_filename and writes the formatted Euphoria to out_filename
-- A pair is returned.  The first member of the pair is a set of errors.  When no errors occur this is an empty sequence.
-- The second member is the tokens that come out.
export function format_tokens(sequence tokens)
    sequence errors = {}
    sequence block_stack = {}
    sequence out_tokens = {}
    
    boolean new_line_starts = 1
    integer start_column = 0
    integer this_line_shift = 0
    integer token_start = 1
    token_sequence current_line = {}
    integer switch_column     = 0
    boolean last_keyword_case = 0
    boolean last_keyword_end  = 0
    sequence last_keyword = ""
    for tokeni = 1 to length(tokens) do
        sequence t = tokens[tokeni]
        sequence v = t[TDATA]
        switch t[TTYPE] do
            case T_NEWLINE then
            case T_WHITE then 
                if find('\n', v) then
                    new_line_starts = 1
                    t[TDATA] = "\n"
                    current_line = current_line & t
                    if this_line_shift < 0 then
                        errors = append(errors, sprintf("Error processing at %d:%d\n",  t[TLNUM..TLPOS]))
                        this_line_shift = 0
                    end if
                    current_line = {{T_WHITE, repeat(' ', this_line_shift * 4), t[TLNUM], 0, 0}} & current_line
                    out_tokens = out_tokens & current_line
                    --show_tokens(outfn, tokens[token_start..tokeni])
                    token_start = tokeni + 1
                    current_line = ""
                    this_line_shift = start_column
                elsif new_line_starts then
                    -- nothing
                else
                    current_line = current_line & v
                end if
            case T_KEYWORD then
                new_line_starts = 0
                if equal(last_keyword,"end") then
                    if length(block_stack) = 0 then
                        errors = append(errors, sprintf("Unbalanced keyword %s: Block stack empty\n", {v}) )
                    elsif compare(v, block_stack[$][1]) then
                        errors = append(errors, sprintf("End statement should be for %s but it is for %s", {block_stack[$][TDATA], v}))
                    else
                        start_column = block_stack[$][2]
                        this_line_shift = block_stack[$][2]
                        block_stack = block_stack[1..$-1]
                    end if
                elsif equal(v, "case") then  
                    this_line_shift = switch_column + 1
                    start_column = switch_column + 2
                elsif find(v, block_starters) then
                    block_stack = append(block_stack, {v, start_column})
                    if equal(v,"switch") then
                        switch_column = start_column
                        start_column += 1
                    end if
                    start_column += 1 
                elsif find(v, left_shifter) then
                    if compare(v,"else") or compare(last_keyword,"case") then
                        this_line_shift = this_line_shift-1
                        if this_line_shift < 0 then
                            errors = append(errors, sprintf("Cannot place %s", {v}))
                        end if
                    end if            
                end if
                last_keyword = v
                fallthru
                
            case else
                new_line_starts = 0
                current_line = current_line & v
        end switch
        
        -- show_tokens(outfn, {t})
        --printf(outfn, "%d %d %d\n", {new_line_starts, start_column, this_line_shift})
    end for     
    
    return errors
end function


-- Takes Euphoria code from in_filename and writes the formatted Euphoria to out_filename
-- A set of errors is always returned.  When no errors occur this is an empty sequence.
export function format_file(sequence in_filename, sequence out_filename)
    sequence errors = {}
    sequence block_stack = {}
    
    sequence out = tokenize_file(in_filename,, io:TEXT_MODE)
    sequence tokens
    object error_code       , error_line, error_column
    {tokens, error_code, error_line, error_column} = out    
    
    if compare({error_code,error_line,error_column},{0,0,0}) then
        errors = append(errors, sprintf("Error processing %s: %s  Line %d, Column %d    \n", {in_filename, error_string(error_code), error_line, error_column}))
        return errors
    end if
    
    integer outfn = open(out_filename, "w")
    if outfn = -1 then
        errors = append(errors, sprintf("Cannot open %s for writing", {out_filename}))
        return errors
    end if
    
    boolean new_line_starts = 1
    integer start_column = 0
    integer this_line_shift = 0
    integer token_start = 1
    sequence current_line = ""
    integer switch_column     = 0
    boolean last_keyword_case = 0
    boolean last_keyword_end  = 0
    sequence last_keyword = ""
    for tokeni = 1 to length(tokens) do
        sequence t = tokens[tokeni]
        sequence v = t[TDATA]
        switch t[1] do
            case T_NEWLINE then
            case T_WHITE then 
                if find('\n', v) then
                    new_line_starts = 1
                    if this_line_shift < 0 then
                        errors = append(errors, sprintf("Error processing at %d:%d\n", {in_filename} & t[TLNUM..TLPOS]))
                        this_line_shift = 0
                    end if
                    current_line = repeat(' ', this_line_shift * 4) & current_line
					 -- remove trailing white
                    while length(current_line) > 0 and find(current_line[$], " \r\t") do
                    	current_line = remove(current_line, length(current_line))
                    end while
                    current_line = append(current_line, '\n')
                    puts(outfn, current_line)
                    --show_tokens(outfn, tokens[token_start..tokeni])
                    token_start = tokeni + 1
                    current_line = ""
                    this_line_shift = start_column
                elsif new_line_starts then
                    -- nothing
                else
                    current_line = current_line & v
                end if
            case T_KEYWORD then
                new_line_starts = 0
                if equal(last_keyword,"end") then
                    if length(block_stack) = 0 then
                        errors = append(errors, sprintf("Unbalanced keyword %s: Block stack empty\n", {v}) )
                    elsif compare(v, block_stack[$][1]) then
                        errors = append(errors, sprintf("End statement should be for %s but it is for %s", {block_stack[$][TDATA], v}))
                    else
                        start_column = block_stack[$][2]
                        this_line_shift = block_stack[$][2]
                        block_stack = block_stack[1..$-1]
                    end if
                elsif equal(v, "case") then  
                    this_line_shift = switch_column + 1
                    start_column = switch_column + 2
                elsif find(v, block_starters) then
                    block_stack = append(block_stack, {v, start_column})
                    if equal(v,"switch") then
                        switch_column = start_column
                        start_column += 1
                    end if
                    start_column += 1 
                elsif find(v, left_shifter) then
                    if compare(v,"else") or compare(last_keyword,"case") then
                        this_line_shift = this_line_shift-1
                        if this_line_shift < 0 then
                            errors = append(errors, sprintf("Cannot place %s", {v}))
                        end if
                    end if            
                end if
                last_keyword = v
                fallthru
                
            case else
                new_line_starts = 0
                current_line = current_line & v
        end switch
        
        -- show_tokens(outfn, {t})
        --printf(outfn, "%d %d %d\n", {new_line_starts, start_column, this_line_shift})
    end for    
    
    close(outfn)
    
    return errors
end function

if length(args) = 0 then
	printf(io:STDERR, "usage:\n"&
	                     "\t\teui formateum.ex [--follow] filename1 filename2 ...\n")
end if


sequence dents = {}

for argi = 1 to length(args) do
    sequence arg = args[argi]
    
    if equal(arg,"-") then
        printf(io:STDERR, "Invalid option -\n", {})
    elsif begins("-", arg) then
        if length(arg) > 2 and begins(arg, "--follow") then
            follow_flag = 1
            continue
        elsif begins("--", arg ) then
            printf(io:STDERR, "Invalid argument %s\n", {arg})
            abort(1)
        end if
        for argij = 2 to length(arg) do
            atom option = arg[argij]
            switch option do
                case 'f' then
                    follow_flag = 1
                    exit
                case else
                    printf(io:STDERR, "Invalid option '%s'\n", {option})
                    abort(1)
            end switch
        end for
        continue
    end if
    
    sequence new_filename = dirname(arg) & SLASH & filebase(arg) & "-new." & fileext(arg)
    
    if equal(dirname(arg),"") then
        new_filename = filebase(arg) & "-new." & fileext(arg)
    end if
    
    sequence errors = format_file(arg, new_filename)
    
    for ei = 1 to length(errors) do
        puts(io:STDERR, errors[ei])
    end for
    
    if length(errors) = 0 then
        move_file(new_filename, arg, 1)
    end if
    
    object dstat = dir(arg)
    if sequence(dstat) and length(dstat) = 1 and not find('d', dstat[1][D_ATTRIBUTES]) then
        dstat[1][D_NAME] = arg
        dents = append(dents, dstat[1])
    end if
end for




while follow_flag do
    for ti = 1 to length(dents) do
        sequence ts = dents[ti]
        object dstat = dir(ts[D_NAME])
        if atom(dstat) then
            printf(io:STDERR, "Unable to get directory information for '%s'\n", {ts[D_NAME]})
            continue
        end if
        dstat = dstat[1]
        if compare(ts[D_YEAR..D_SECOND],dstat[D_YEAR..D_SECOND]) < 0 then
            -- timestamp has changed
            sequence path = dirname(ts[D_NAME])
            sequence new_filename
            
            if equal(path,"") then
                
                new_filename = filebase(ts[D_NAME]) & "-new." & fileext(ts[D_NAME])
            else
                new_filename = path & SLASH & filebase(ts[D_NAME]) & "-new." & fileext(ts[D_NAME])
            end if
            
            sequence errors = format_file(ts[D_NAME], new_filename)
            
            for ei = 1 to length(errors) do
                puts(io:STDERR, errors[ei])
            end for
            
            -- give the OS time to update the records
            sleep(5)
            
            dstat = dir(new_filename)
            if atom(dstat) then
                -- do again
                continue
            end if
            
            if length(dstat) != 1 or find('d', dstat[1][D_ATTRIBUTES]) then
                printf(io:STDERR, "Unusual file exception: %s\n", {new_filename})
            end if
            
            
            if length(errors) = 0 then
                move_file(new_filename, ts[D_NAME], 1)
            end if
            
            dstat = dstat[1]
            
            -- needs the old filename and the whole path.
            dstat[D_NAME] = ts[D_NAME]
            dents[ti] = dstat
        end if
    end for
    sleep(5)
end while


