FROM golang AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .

# Use BuildKit secrets to access the config JSON
RUN --mount=type=secret,id=config_json_string \
    CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo \
    -ldflags "-X 'github.com/thanksduck/alias-api/cfconfig.allowedDomains=1as.in,20032003.xyz' -X 'github.com/thanksduck/alias-api/cfconfig.configJSON=$(cat /run/secrets/config_json_string)'" \
    -o main .

FROM alpine:latest
WORKDIR /root/
COPY --from=builder /app/main .

# Fix: Use apk instead of apt-get for Alpine
RUN apk update && apk add --no-cache ca-certificates tzdata

ENV TZ=Asia/Kolkata
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

EXPOSE 6777
CMD ["./main"]