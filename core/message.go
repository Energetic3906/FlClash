//go:build !cgo

package main

func SendMessage(message Message) {
	s, err := message.Json()
	if err != nil {
		return
	}

	send(Action{
		Method: messageMethod,
	}.wrapMessage(s))
}
