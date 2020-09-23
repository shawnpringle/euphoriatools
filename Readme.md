# Source Check

This program verifies that everything you have define_c_func and define_c_proc for
are infact available in a supplied DLL.

Usage is:

eui source_check.ex [--dll dll_file] e_file

dll_file is a DLL
e_file   is a dot-e file.

The dll_file is optional.  The dll filename will be collected from e_file itself.

Nota Bene: This is not a complete parser/interpreter.  So, it is easy for this program to get 
things totally wrong but if other routines are getting loaded from the same DLL through this program
and the routines are all of the form `id = open_dll(dll_num, string literal)`, then I wouldn't expect
false failures.


# CURL Import

This tool creates a dot-e file with the Header.
It is recommended that you create a wrapper using the generated dot-e file.  

update the CURL constants with:

On Windows:
```shell
eui curlimport.ex libcurl.so libcurl.dll d:\minGW\include\curl\curl.h _curl.e
```

If you are looking for where you can find libcurl.dll.  I found mine in OpenShot.  Install OpenShot for Windows and copy all the DLLs from the dll directory of OpenShot.  You might already have it somewhere on your hard drive.

**Some Dll's when loaded prompt loading of other DLLs on the system.  open_dll will return 0, but give you no other information.  Save yourself a headache and copy all of the DLLS from OpenShot or some other package that has libcurl.dll in its directory**


On Linux:
```shell
eui curlimport.ex libcurl.so libcurl.dll /usr/include/curl/curl.h _curl.e
```

## Improted Symbols

Once you have generated a file called _curl.e, you can create a manual file called curl.e.
-- in curl.e --
```
public include _curl.e

-- generator worked fine, make it more Euphoria style.
public function curl_strequal(cstring s1, cstring s2)
	atom p1 = allocate_string(s1, 1)
	atom p2 = allocate_string(s2, 1)
	return p:curl_strequal(p1, p2)
end function


-- generator didn't work for this one, let's redo this one completely
include std/dll.e
include std/machine.e
constant dll = open_dll({
  "libcurl.dll",
  "libcurl.so"
})

constant C_CURLCODE = C_POINTER
-- The generate imports this one wrong.
export constant curl_easy_setoptx = define_c_func(dll, "+curl_easy_setopt",{C_POINTER, C_INT, C_POINTER}, C_CURLCODE)
public function curl_easy_setopt(atom curl, atom option, object data)
        atom string_pointer = 0
        atom curl_code
	if sequence(data) then
	     string_pointer = allocate_string(data)
	     data = string_pointer
	end if
	curl_code =  c_func(curl_easy_setoptx, {curl, option, data})
	if string_pointer then
		free(string_pointer)
	end if
	return curl_code
end function
```





# Formateum

This program will make sure that each line of source is correctly indented.  Correctly 
means, that inside a type,function,procedure,for,loop,while,if,else,elsif,case,or switch 
statement, other statements are four spaces more to the right.

Nota Bena: This modifies source code.  It's pretty safe.

Usage is:
```
eui formateum.ex [--follow|-f] source_file1 source_file2 ....
```
* -f or --follow is optional.
* source_file1 source_file2 ...   should be at least one source file.

If you use the --follow option, the program will wait for changes and reproess the file after each
change to the file's timestamp.


# License

This software is provided as-is. There is no warranty for this software. You may not blame the author
or the Euphoria community for any wrong-doing using this software. You use this software at your own
risk. You may use this software to write Euphoria programs using the Euraylib wrapper. You may dis-
tribute software you make using this software as you please, whether gratis or for a fee. You may not claim you wrote the original Euraylib wrapper. While not required an aknowledgement of the original author would be nice.


Thanks for using Euphoria Tools!

Special thanks to the Euphoria community!

# Tips

* Bitcoin Cash bitcoincash:qqtes6cafexr00tzv9r360rd3g9l3zssuuj3mqzxpq
* Bitcoin Core bitcoin:1LT2zLt4uooLfnTFfBJGzpTY4EY1SWZxoJ
* Ethereum Tether 0x34caA5BE5e806d10CfEbC4ec293d5888bbb17Af5

# Links

[Euphoria](https://openeuphoria.org/index.wc)

[Paypal](paypal.me/sdpringle)

