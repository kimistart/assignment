package main

func find(strs []string) string {

	//找到最短的
	minStr := strs[0]
	for _, s := range strs {
		if len(s) < len(minStr) {
			minStr = s
		}
	}

	pub := minStr

	for _, s := range strs {
		for len(pub) > 0 && !isPrefix(s, pub) {
			pub = pub[:len(pub)-1]
		}
		if pub == "" {
			break
		}
	}
	return pub
}

func isPrefix(s, prefix string) bool {
	if len(prefix) > len(s) {
		return false
	}
	// 取 s 的前 len(prefix) 个字符，和 prefix 对比，相等就是前缀
	return s[:len(prefix)] == prefix
}

/* func main() {
	strs := []string{"flower", "flow", "flight"}
	fmt.Println("最长公共前缀是： ", find(strs))
} */
