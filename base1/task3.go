package main

func parseStr(s string) bool {
	stack := make([]rune, 0)

	bracketMap := map[rune]rune{
		')': '(',
		'}': '{',
		']': '[',
	}

	for _, char := range s {
		if kuohao, live := bracketMap[char]; live {
			if len(stack) == 0 || stack[len(stack)-1] != kuohao {
				return false
			}
			stack = stack[:len(stack)-1]
		} else {
			stack = append(stack, char)
		}
	}

	return true
}

/* func main() {
	s := "()[]{}"

	if parseStr(s) {
		fmt.Println("字符串s有效")
	} else {
		fmt.Println("字符串s无效")
	}
} */
