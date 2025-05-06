FROM golang:1.23.8 as go
ENV GO111MODULE=on
ENV CGO_ENABLED=0
ENV GOBIN=/bin
ARG BUILDARCH=amd64
RUN go install github.com/go-delve/delve/cmd/dlv@v1.8.2
ADD https://github.com/spiffe/spire/releases/download/v1.8.0/spire-1.8.0-linux-${BUILDARCH}-musl.tar.gz .
RUN tar xzvf spire-1.8.0-linux-${BUILDARCH}-musl.tar.gz -C /bin --strip=2 spire-1.8.0/bin/spire-server spire-1.8.0/bin/spire-agent

FROM go as build
WORKDIR /build
COPY go.mod go.sum ./
COPY pkg ./pkg
RUN go build ./pkg/imports
COPY . .
RUN go build -o /bin/registry-proxy-dns .

FROM build as test
CMD go test -test.v ./...

FROM test as debug
CMD dlv -l :40000 --headless=true --api-version=2 test -test.v ./...

FROM alpine as runtime
COPY --from=build /bin/registry-proxy-dns /bin/registry-proxy-dns
ENTRYPOINT ["/bin/registry-proxy-dns"]