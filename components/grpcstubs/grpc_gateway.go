package grpcstubs

import (
	"context"
	stdLog "log"
	"net/http"
	"strings"

	"github.com/grpc-ecosystem/grpc-gateway/runtime"
	"github.com/jony4/go-template/config"
	log "github.com/sirupsen/logrus"
)

type HTTPRegister func(ctx context.Context, mux *runtime.ServeMux, config *config.Endpoint) error

func HTTPServe(cfg *config.Config, endpoints []*config.Endpoint, registers []HTTPRegister) {
	serveMux := runtime.NewServeMux(
		runtime.WithMarshalerOption(
			runtime.MIMEWildcard,
			defaultJb,
		),
		runtime.WithIncomingHeaderMatcher(func(key string) (string, bool) {
			switch key {
			case "X-Request-Id":
				return "request_id", true
			case "X-Request-ID":
				return "request_id", true
			case "X-Request-Timeout":
				return "timeout", true
			case "X-Request-Ak":
				return "ak", true
			default:
				return runtime.DefaultHeaderMatcher(key)
			}
		}),
	)

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	for _, register := range registers {
		if err := register(ctx, serveMux, cfg.GrpcServerEndpoint); err != nil { // 务必是 grpc server endpoint
			log.Fatal("register handler failed: ", err)
		}
	}

	mux := http.NewServeMux()
	mux.Handle("/", serveMux)

	for _, endpoint := range endpoints {
		go func(endpoint *config.Endpoint) {
			httpServer := http.Server{
				Addr:     endpoint.String(),
				Handler:  handlerFunc(CORS(mux)),
				ErrorLog: stdLog.Default(),
			}

			defer func() {
				if err := httpServer.Shutdown(ctx); err != nil {
					log.Warn(err)
				}
			}()

			log.Info("Try http server serve at ", endpoint.String())
			if err := httpServer.ListenAndServe(); err != nil {
				log.Fatal("http server serve failed: ", err)
			}
		}(endpoint)
	}
}

// handlerFunc returns a http.Handler that delegates to grpcServer on incoming gRPC
// connections or otherHandler otherwise. Copied from cockroachdb.
// func grpcHandlerFunc(grpcServer *grpc.Server, otherHandler http.Handler) http.Handler {
func handlerFunc(otherHandler http.Handler) http.Handler {
	return http.HandlerFunc(
		func(w http.ResponseWriter, r *http.Request) {
			if r.ProtoMajor == 2 && strings.Contains(r.Header.Get("Content-Type"), "application/grpc") {
				w.WriteHeader(http.StatusHTTPVersionNotSupported)
				_, err := w.Write([]byte("HTTP/2 is not supported"))
				if err != nil {
					w.WriteHeader(http.StatusInternalServerError)
				}
				// grpcServer.ServeHTTP(w, r)
			} else {
				otherHandler.ServeHTTP(w, r)
			}
		},
	)
}

func CORS(h http.Handler) http.Handler {
	return http.HandlerFunc(
		func(w http.ResponseWriter, r *http.Request) {
			w.Header().Set("Access-Control-Allow-Origin", "*")
			w.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS, PUT, PATCH, DELETE")
			w.Header().Set(
				"Access-Control-Allow-Headers",
				"Accept, Content-Type, Content-Length, Accept-Encoding, Authorization, ResponseType",
			)
			w.Header().Set("Vary", "Accept-Encoding, Origin")
			if r.Method == "OPTIONS" {
				w.WriteHeader(http.StatusOK)
				return
			}
			h.ServeHTTP(w, r)
		},
	)
}
