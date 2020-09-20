public include primitive_curl.e as p
include std/machine.e
include std/types.e
public function curl_strequal(cstring s1, cstring s2)
	atom p1 = allocate_string(s1, 1)
	atom p2 = allocate_string(s2, 1)
	return p:curl_strequal(p1, p2)
end function

--CURL_EXTERN CURLcode curl_mime_name(curl_mimepart *part, const char *name)
public function curl_mime_name(atom part, cstring name)
    atom name_ptr = allocate_string(name, 1)
    atom ret = p:curl_mime_name(part, name_ptr)
    return ret
end function