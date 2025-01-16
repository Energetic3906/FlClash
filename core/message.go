package main

func SendMessage(message Message) {
	res, _ := ActionResult{
		Method: messageMethod,
		Data:   message,
	}.Json()

	send(res)
}
