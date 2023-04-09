package grpcstubs

import (
	"context"
	"fmt"
	"time"

	grpc_logrus "github.com/grpc-ecosystem/go-grpc-middleware/logging/logrus"
	log "github.com/sirupsen/logrus"
	"google.golang.org/grpc"
)

func Conn(endpoint string, timeout time.Duration) (*grpc.ClientConn, error) {
	ctx, cancel := context.WithTimeout(context.Background(), timeout)
	defer cancel()

	logrusEntry := log.NewEntry(log.StandardLogger())
	// grpc_logrus.ReplaceGrpcLogger(logrusEntry)

	dialOptions := []grpc.DialOption{
		grpc.WithBlock(), // 确认连接后返回
		grpc.WithInsecure(),
		grpc.WithChainUnaryInterceptor(
			// grpc_logrus.UnaryClientInterceptor(
			// 	logrusEntry, []grpc_logrus.Option{
			// 		grpc_logrus.WithLevels(grpc_logrus.DefaultClientCodeToLevel),
			// 		grpc_logrus.WithCodes(grpc_logging.DefaultErrorToCode),
			// 		grpc_logrus.WithDecider(
			// 			func(fullMethodName string, err error) bool {
			// 				return true
			// 			},
			// 		),
			// 	}...,
			// ),
			grpc_logrus.PayloadUnaryClientInterceptor(
				logrusEntry, func(ctx context.Context, fullMethodName string) bool {
					return true
				},
			),
			// grpc_opentracing.UnaryClientInterceptor(grpc_opentracing.WithTraceHeaderName(OpenTracingName)),
		),
		grpc.WithChainStreamInterceptor(
			// grpc_logrus.StreamClientInterceptor(
			// 	logrusEntry, []grpc_logrus.Option{
			// 		grpc_logrus.WithLevels(grpc_logrus.DefaultClientCodeToLevel),
			// 		grpc_logrus.WithCodes(grpc_logging.DefaultErrorToCode),
			// 		grpc_logrus.WithDecider(
			// 			func(fullMethodName string, err error) bool {
			// 				return true
			// 			},
			// 		),
			// 	}...,
			// ),
			grpc_logrus.PayloadStreamClientInterceptor(
				logrusEntry, func(ctx context.Context, fullMethodName string) bool {
					return true
				},
			),
			// grpc_opentracing.StreamClientInterceptor(grpc_opentracing.WithTraceHeaderName(OpenTracingName)),
		),
		grpc.WithDefaultCallOptions(
			grpc.MaxCallRecvMsgSize(1024*1024*1024),
			grpc.MaxCallSendMsgSize(1024*1024*1024),
		),
	}

	conn, err := grpc.DialContext(ctx, endpoint, dialOptions...)
	if err != nil {
		return nil, fmt.Errorf("connect to gRPC service(%s) failed, err: %v", endpoint, err)
	}

	return conn, nil
}
