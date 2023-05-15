package version

import (
	"fmt"
	"time"
)

// Version information.
var (
	BuildTS   = time.Now().Format(time.RFC3339)
	GitHash   = "None"
	GitBranch = "None"
	Version   = "None"
)

// GetVersion prints build version.
func GetVersion() string {
	if GitHash == "" {
		return Version
	}
	h := GitHash
	if len(h) > 8 {
		h = h[:8]
	}
	return fmt.Sprintf("%s-%s", Version, h)
}

func PrintFullVersionInfo() {
	fmt.Println("Version:   ", GetVersion())
	fmt.Println("Git Branch:", GitBranch)
	fmt.Println("Git Commit:", GitHash)
	fmt.Println("Build Time:", BuildTS)
}
