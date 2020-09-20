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

```shell
eui curlimport.ex < /usr/include/curl/curl.h > primitive_curl.e
```

Then run curlimport_test.ex.  If you don't have curl libraries installed it wont work but it would be great if you have them.


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

