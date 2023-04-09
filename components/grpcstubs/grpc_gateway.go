package grpcstubs

import (
	"context"
	"fmt"
	"io"
	stdLog "log"
	"net/http"
	"net/textproto"
	"strings"

	"github.com/golang/protobuf/proto"
	"github.com/golang/protobuf/ptypes/any"
	"github.com/grpc-ecosystem/grpc-gateway/runtime"
	"github.com/jony4/go-template/config"
	log "github.com/sirupsen/logrus"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/grpclog"
	"google.golang.org/grpc/status"
)

type GatewayHandlerFunc struct {
	Method  string
	Path    string
	Handler runtime.HandlerFunc
}

type HTTPRegister func(ctx context.Context, mux *runtime.ServeMux, config *config.Endpoint) error

func HTTPServe(cfg *config.Config, endpoints []*config.Endpoint, registers []HTTPRegister) {
	runtime.HTTPError = CustomHTTPError
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

type errorBody struct {
	// This is to make the error more compatible with users that expect errors to be Status objects:
	// https://github.com/grpc/grpc/blob/master/src/proto/grpc/status/status.proto
	// It should be the exact same message as the Error field.
	Code      int32      `protobuf:"varint,1,name=code" json:"code"`
	Message   string     `protobuf:"bytes,2,name=message" json:"message"`
	Details   []*any.Any `protobuf:"bytes,3,rep,name=details" json:"details,omitempty"`
	RequestID string     `protobuf:"bytes,4,name=request_id" json:"request_id,omitempty"`
}

func (e *errorBody) Reset()         { *e = errorBody{} }
func (e *errorBody) String() string { return proto.CompactTextString(e) }
func (*errorBody) ProtoMessage()    {}

// CustomHTTPError 自定义 grpc-gateway 的错误处理方法
func CustomHTTPError(
	ctx context.Context, mux *runtime.ServeMux, marshaller runtime.Marshaler, w http.ResponseWriter, req *http.Request,
	err error,
) {
	const fallback = `{"error": "failed to marshal error message"}`

	s, ok := status.FromError(err)
	if !ok {
		s = status.New(codes.Unknown, err.Error())
	}

	w.Header().Del("Trailer")

	contentType := marshaller.ContentType()
	// Check marshaller on run time in order to keep backwards compatability
	// An interface param needs to be added to the ContentType() function on
	// the Marshal interface to be able to remove this check
	if httpBodyMarshaller, ok := marshaller.(*runtime.HTTPBodyMarshaler); ok {
		pb := s.Proto()
		contentType = httpBodyMarshaller.ContentTypeFromMessage(pb)
	}
	w.Header().Set("Content-Type", contentType)

	md, ok := runtime.ServerMetadataFromContext(ctx)
	if !ok {
		grpclog.Infof("Failed to extract ServerMetadata from context")
	}

	handleForwardResponseServerMetadata(w, mux, md)

	body := &errorBody{
		Message:   s.Message(),
		Code:      int32(s.Code()),
		Details:   s.Proto().GetDetails(),
		RequestID: w.Header().Get("X-Request-ID"),
	}

	buf, merr := marshaller.Marshal(body)
	if merr != nil {
		grpclog.Infof("Failed to marshal error message %q: %v", body, merr)
		w.WriteHeader(http.StatusInternalServerError)
		if _, err := io.WriteString(w, fallback); err != nil {
			grpclog.Infof("Failed to write response: %v", err)
		}
		return
	}

	handleForwardResponseTrailerHeader(w, md)
	st := runtime.HTTPStatusFromCode(s.Code())
	w.WriteHeader(st)
	if _, err := w.Write(buf); err != nil {
		grpclog.Infof("Failed to write response: %v", err)
	}

	log.Errorf("http.Response: %s", string(buf))

	handleForwardResponseTrailer(w, md)
}

func handleForwardResponseTrailer(w http.ResponseWriter, md runtime.ServerMetadata) {
	for k, vs := range md.TrailerMD {
		tKey := fmt.Sprintf("%s%s", runtime.MetadataTrailerPrefix, k)
		for _, v := range vs {
			w.Header().Add(tKey, v)
		}
	}
}

func handleForwardResponseTrailerHeader(w http.ResponseWriter, md runtime.ServerMetadata) {
	for k := range md.TrailerMD {
		tKey := textproto.CanonicalMIMEHeaderKey(fmt.Sprintf("%s%s", runtime.MetadataTrailerPrefix, k))
		w.Header().Add("Trailer", tKey)
	}
}

func handleForwardResponseServerMetadata(w http.ResponseWriter, mux *runtime.ServeMux, md runtime.ServerMetadata) {
	for k, vs := range md.HeaderMD {
		if h, ok := OutgoingMatcher(k); ok {
			for _, v := range vs {
				w.Header().Add(h, v)
			}
		}
	}
}

// OutgoingMatcher ...
func OutgoingMatcher(key string) (string, bool) {
	switch key {
	case "x-request-id":
		return "X-Request-Id", true
	default:
		return runtime.DefaultHeaderMatcher(key)
	}
}
