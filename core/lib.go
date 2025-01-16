//go:build cgo

package main

/*
#include <stdlib.h>
*/
import "C"
import (
	bridge "core/dart-bridge"
	"encoding/json"
	"unsafe"
)

var port int64

//export initNativeApiBridge
func initNativeApiBridge(api unsafe.Pointer) {
	bridge.InitDartApi(api)
}

//export initMessage
func initMessage(cPort C.longlong) {
	i := int64(cPort)
	port = i
}

//export freeCString
func freeCString(s *C.char) {
	C.free(unsafe.Pointer(s))
}

//export invokeAction
func invokeAction(paramsChar *C.char, port C.longlong) {
	params := C.GoString(paramsChar)
	i := int64(port)
	var action = &Action{}
	err := json.Unmarshal([]byte(params), action)
	if err != nil {
		bridge.SendToPort(i, err.Error())
		return
	}
	go handleAction(action, func(bytes []byte) {
		bridge.SendToPort(i, string(bytes))
	})
}

func send(bytes []byte) {
	bridge.SendToPort(port, string(bytes))
}
