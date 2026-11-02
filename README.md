# asm-server

A small static-file HTTP server written in x86-64 assembly without libc for Linux.

```
[+] Listening on: 0.0.0.0:8000
[+] Serving: /home/user/site

GET / HTTP/1.1
Host: localhost:8000
User-Agent: curl/8.21.0
Accept: */*
```

## Features

- No libc and no dependencies: just NASM and `ld`
- One process per connection, created with `fork`
- Logs each incoming request to stdout

## Requirements

- Linux on x86-64
- [NASM](https://www.nasm.us/)
- GNU `ld` (binutils)
- `make`

On Debian/Ubuntu:

```sh
sudo apt install nasm binutils make
```

## Building

```sh
make          # produces build/asm-server
make clean    # removes build artifacts
```

## Usage

```sh
./build/asm-server [-d dir] [-p port]
```

| Flag | Description | Default |
| --- | --- | --- |
| `-d dir` | Directory to serve files from | Current directory |
| `-p port` | Port to listen on (1-65535) | `8000` |
| `-h` | Show the help message | |

The server listens on all interfaces. For example:

```sh
./build/asm-server -d ./site -p 8080
```

Ports below 1024 require root, or the capability to bind them:

```sh
sudo setcap cap_net_bind_service=+ep build/asm-server
```

## How it works

```
parse args ─► chdir(dir)
                  │
                  ▼
socket ─► setsockopt(SO_REUSEADDR) ─► bind ─► listen
                                                 │
            ┌────────────────────────────────────┘
            ▼
   ┌──► accept ─► fork ─┬─ parent: close(client) ───┐
   │                    │                           │
   │                    └─ child:  read request     │
   │                               parse path       │
   │                               open + fstat     │
   │                               write headers    │
   │                               read/write loop  │
   │                               exit             │
   └────────────────────────────────────────────────┘
```

- **`src/main.asm`**: the entry point (`_start`), socket setup, the accept loop and the request handling in the child process.
- **`src/args.asm`**: `parse_args`, which reads the `-d`, `-p` and `-h` flags, and `parse_port`, which converts the port string to a number and validates it.
- **`src/parse.asm`**: `parse_filename`, which extracts the method and the requested path from the request line, strips leading slashes, and validates the path.

The child reads the file in 8 KB chunks and writes each chunk directly to the
client socket. The response ends when the connection is closed.

## Limitations

This is a learning project, not a production server.

- IPv4 only
- The HTTP method is ignored: every request is treated as a `GET`
- No `Content-Type` or `Content-Length` headers
- Query strings (`?a=1`) and percent-encoding (`%20`) aren't handled
- The request is read with a single `read` of up to 1023 bytes
- Symlinks inside the served directory are followed

## License

[GPL-3.0](LICENSE)
