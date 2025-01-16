package main

func SendMessage(message Message) {
	res, err := message.Json()
	if err != nil {
		return
	}

	send(Action{
		Method: messageMethod,
	}.wrapMessage(res))
}
