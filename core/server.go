//go:build !cgo

package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"net"
	"strconv"
)

var conn net.Conn

func send(bytes []byte) {
	_, _ = conn.Write(append(bytes, []byte("\n")...))
}

func startServer(arg string) {

	_, err := strconv.Atoi(arg)

	if err != nil {
		conn, err = net.Dial("unix", arg)
	} else {
		conn, err = net.Dial("tcp", fmt.Sprintf("127.0.0.1:%s", arg))
	}
	if err != nil {
		panic(err.Error())
	}

	defer func(conn net.Conn) {
		_ = conn.Close()
	}(conn)

	reader := bufio.NewReader(conn)

	for {
		data, err := reader.ReadString('\n')
		if err != nil {
			return
		}
		var action = &Action{}

		err = json.Unmarshal([]byte(data), action)

		if err != nil {
			return
		}

		go handleAction(action, func(bytes []byte) {
			send(bytes)
		})
	}
}
