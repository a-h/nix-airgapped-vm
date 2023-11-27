package main

import (
	"io"
	"log/slog"
	"net/http"
	"os"
)

var log *slog.Logger

func main() {
	addr := ":8080"
	log = slog.New(slog.NewJSONHandler(os.Stdout, nil))
	log.Info("Starting", slog.String("addr", addr))

	var h Handler
	http.ListenAndServe(addr, h)

	log.Info("Exiting")
}

type Handler struct{}

func (Handler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	log.Info("Handling request")
	io.WriteString(w, "Hello, World")
}
