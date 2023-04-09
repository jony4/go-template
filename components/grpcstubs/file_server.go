package grpcstubs

import (
	"net/http"
	"os"
	"path"

	log "github.com/sirupsen/logrus"
)

func FilesServe(filesAddress string, fs http.FileSystem) {
	mux := http.NewServeMux()
	mux.Handle("/", http.FileServer(fs))
	// mux.Handle("/", FileServerWithCustom404(fs))

	log.Info("Try files server serve at ", filesAddress)
	if err := http.ListenAndServe(filesAddress, mux); err != nil {
		log.Fatal("files server serve failed: ", err)
	}
}

func FileServerWithCustom404(fs http.FileSystem) http.Handler {
	fsh := http.FileServer(fs)
	return http.HandlerFunc(
		func(w http.ResponseWriter, r *http.Request) {
			_, err := fs.Open(path.Clean(r.URL.Path))
			if os.IsNotExist(err) {
				w.Header().Set("Location", "/index.html")
				w.WriteHeader(http.StatusNotModified)
				return
			}
			fsh.ServeHTTP(w, r)
		},
	)
}
