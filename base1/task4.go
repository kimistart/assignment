package main

import (
	"fmt"
	"strings"
)

func main() {
	strs := []string{"flower", "flow", "flight"}

	fmt.Println("最长公共前缀是： ", find(strs))
}

func find(strs []string) string {
	pub := "";

	for  {
		x := 0
		if x <
		for _,s := range strs {
			if pub=="" {
				pub += s
				continue
			}else {
				chars := []rune(s)
				subChars := chars[0:len(pub)]
				if pub == string(subChars) {
					x += 1
					continue
				}else {
					return pub
				}
			}
		}
		pub += s
	}


	return pub
}
