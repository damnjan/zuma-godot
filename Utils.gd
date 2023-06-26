class_name Utils

static func split_to_int_array(string: String, separator = '') -> Array[int]:
	var str_arr = string.split(separator)
	var int_arr: Array[int]
	for str in str_arr:
		int_arr.append(int(str))
	return int_arr
