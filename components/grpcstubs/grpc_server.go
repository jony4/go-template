package grpcstubs

import (
	"context"
	"fmt"
	"math"
	"net"
	"runtime/debug"
	"time"

	grpc_middleware "github.com/grpc-ecosystem/go-grpc-middleware"
	grpc_recovery "github.com/grpc-ecosystem/go-grpc-middleware/recovery"
	"github.com/grpc-ecosystem/grpc-gateway/runtime"
	"github.com/jony4/go-template/config"
	log "github.com/sirupsen/logrus"
	"google.golang.org/grpc"
	"google.golang.org/grpc/reflection"
)

// Shared options for the logger, with a custom gRPC code to log level function.
var (
	// grpc_recovery.RecoveryHandlerFunc
	grpcRecoveryOpts = []grpc_recovery.Option{
		grpc_recovery.WithRecoveryHandler(
			func(p interface{}) (err error) {
				log.Errorf("%s\n\n%s\n", p, debug.Stack())
				return fmt.Errorf("panic triggered: %v", p)
			},
		),
	}
)

func GRPCServer() *grpc.Server {
	// Logrus entry is used, allowing pre-definition of certain fields by the user.
	// logrusEntry := log.NewEntry(log.StandardLogger())
	// Make sure that log statements internal to gRPC library are logged using the logrus Logger as well.
	// grpc_logrus.ReplaceGrpcLogger(logrusEntry)
	serverOptions := []grpc.ServerOption{
		grpc.MaxRecvMsgSize(math.MaxInt32),
		grpc.MaxSendMsgSize(1e7),
		grpc_middleware.WithUnaryServerChain(
			SelfUnaryServerInterceptor(),
			grpc_recovery.UnaryServerInterceptor(grpcRecoveryOpts...),
			// grpc_opentracing.UnaryServerInterceptor(grpc_opentracing.WithTraceHeaderName(OpenTracingName)),
		),
		grpc_middleware.WithStreamServerChain(
			grpc_recovery.StreamServerInterceptor(grpcRecoveryOpts...),
			// grpc_opentracing.StreamServerInterceptor(grpc_opentracing.WithTraceHeaderName(OpenTracingName)),
			// grpc_logrus.PayloadStreamServerInterceptor(
			// 	logrusEntry, func(ctx context.Context, fullMethodName string, servingObject interface{}) bool {
			// 		return true
			// 	},
			// ),
		),
	}

	grpcServer := grpc.NewServer(serverOptions...)

	reflection.Register(grpcServer)

	return grpcServer
}

func GRPCServe(grpcServer *grpc.Server, endpoints []*config.Endpoint) {
	for _, endpoint := range endpoints {
		go func(endpoint *config.Endpoint) {
			lis, err := net.Listen("tcp", endpoint.String())
			if err != nil {
				log.Fatal("failed to listen: ", err)
			}

			log.Info("Try start to serve grpc at ", endpoint.String())
			if err := grpcServer.Serve(lis); err != nil {
				log.Fatal("failed to serve: ", err)
			}
		}(endpoint)
	}
}

// SelfUnaryServerInterceptor returns a new unary server interceptor for panic recovery.
func SelfUnaryServerInterceptor() grpc.UnaryServerInterceptor {
	return func(ctx context.Context, req interface{}, info *grpc.UnaryServerInfo, handler grpc.UnaryHandler) (_ interface{}, err error) {
		start := time.Now()
		hb := runtime.HTTPBodyMarshaler{Marshaler: defaultJb}
		reqString, err := hb.Marshal(req)
		if err != nil {
			log.Errorf("%s: respString, err:= jb.Marshal(req) %v", info.FullMethod, err)
		} else {
			log.Debugf("%s: grpc.Request: %s", info.FullMethod, string(reqString))
		}
		resp, err := handler(ctx, req)
		if err != nil {
			log.Errorf("%s: resp, err := handler(ctx, req) %v", info.FullMethod, err)
		} else if resp != nil {
			respString, err := defaultJb.Marshal(resp)
			if err != nil {
				log.Errorf("%s: respString, err:= jb.Marshal(resp) %v", info.FullMethod, err)
			}
			log.Debugf("%s: grpc.Response: %s", info.FullMethod, string(respString))
		}
		end := time.Now()
		log.Debugf("%s: request latency end: %v - start: %v = %vns", info.FullMethod, end, start, end.Sub(start).Nanoseconds())
		return resp, err
	}
}

var defaultJb = &runtime.JSONPb{
	OrigName:     true,
	EnumsAsInts:  false,
	EmitDefaults: true,
}
