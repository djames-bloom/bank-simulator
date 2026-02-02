FROM alpine:3.23 AS builder

RUN apk add --no-cache curl xz \
	&& curl -L	https://ziglang.org/download/0.14.0/zig-linux-aarch64-0.14.0.tar.xz | tar -xJ \
	&& mv zig-linux-aarch64-0.14.0 /usr/local/zig

ENV PATH="/usr/local/zig:${PATH}"

WORKDIR /app

COPY build.zig .
COPY src/ src/

RUN zig build -Doptimize=ReleaseFast

# -- Runtime
FROM alpine:3.23

COPY --from=builder /app/zig-out/bin/simulator /usr/local/bin/simulator

RUN adduser -D simulator
USER simulator

WORKDIR /home/simulator

ENTRYPOINT ["simulator"]

