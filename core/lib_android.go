//go:build android && cgo

package main

import "C"
import (
	"core/platform"
	"core/state"
	t "core/tun"
	"encoding/json"
	"errors"
	"fmt"
	"github.com/metacubex/mihomo/component/dialer"
	"github.com/metacubex/mihomo/component/process"
	"github.com/metacubex/mihomo/constant"
	"github.com/metacubex/mihomo/dns"
	"github.com/metacubex/mihomo/listener/sing_tun"
	"github.com/metacubex/mihomo/log"
	"strconv"
	"strings"
	"sync"
	"sync/atomic"
	"syscall"
	"time"
)

type ProcessMap struct {
	m sync.Map
}

type FdMap struct {
	m sync.Map
}

type Fd struct {
	Id    int64 `json:"id"`
	Value int64 `json:"value"`
}

var (
	tunListener *sing_tun.Listener
	fdMap       FdMap
	fdCounter   int64 = 0
	counter     int64 = 0
	processMap  ProcessMap
	tunLock     sync.Mutex
	runTime     *time.Time
	errBlocked  = errors.New("blocked")
)

func (cm *ProcessMap) Store(key int64, value string) {
	cm.m.Store(key, value)
}

func (cm *ProcessMap) Load(key int64) (string, bool) {
	value, ok := cm.m.Load(key)
	if !ok || value == nil {
		return "", false
	}
	return value.(string), true
}

func (cm *FdMap) Store(key int64) {
	cm.m.Store(key, struct{}{})
}

func (cm *FdMap) Load(key int64) bool {
	_, ok := cm.m.Load(key)
	return ok
}

func handleStartTun(value string) string {
	tunLock.Lock()
	defer tunLock.Unlock()
	var fd int
	_ = json.Unmarshal([]byte(value), &fd)
	if fd == 0 {
		now := time.Now()
		runTime = &now
	} else {
		initSocketHook()
		tunListener, _ = t.Start(fd, currentConfig.General.Tun.Device, currentConfig.General.Tun.Stack)
		if tunListener != nil {
			log.Infoln("TUN address: %v", tunListener.Address())
		}
		now := time.Now()
		runTime = &now
	}
	return handleGetRunTime()
}

func handleStopTun() {
	tunLock.Lock()
	defer tunLock.Unlock()
	removeSocketHook()
	runTime = nil
	if tunListener != nil {
		_ = tunListener.Close()
	}
}

func handleGetRunTime() string {
	if runTime == nil {
		return ""
	}
	return strconv.FormatInt(runTime.UnixMilli(), 10)
}

func handleSetFdMap(value string) {
	var fd int64
	_ = json.Unmarshal([]byte(value), &fd)
	go func() {
		fdMap.Store(fd)
	}()
}

func handleSetProcessMap(params string) {
	var processMapItem = &ProcessMapItem{}
	err := json.Unmarshal([]byte(params), processMapItem)
	if err == nil {
		processMap.Store(processMapItem.Id, processMapItem.Value)
	}
}

func handleMarkSocket(fd Fd) {
	SendMessage(Message{
		Type: ProtectMessage,
		Data: fd,
	})
}

func initSocketHook() {
	dialer.DefaultSocketHook = func(network, address string, conn syscall.RawConn) error {
		if platform.ShouldBlockConnection() {
			return errBlocked
		}
		return conn.Control(func(fd uintptr) {
			fdInt := int64(fd)
			timeout := time.After(200 * time.Millisecond)
			id := atomic.AddInt64(&fdCounter, 1)

			handleMarkSocket(Fd{
				Id:    id,
				Value: fdInt,
			})

			for {
				select {
				case <-timeout:
					return
				default:
					exists := fdMap.Load(id)
					if exists {
						return
					}
					time.Sleep(10 * time.Millisecond)
				}
			}
		})
	}
}

func removeSocketHook() {
	dialer.DefaultSocketHook = nil
}

func init() {
	process.DefaultPackageNameResolver = func(metadata *constant.Metadata) (string, error) {
		if metadata == nil {
			return "", process.ErrInvalidNetwork
		}
		id := atomic.AddInt64(&counter, 1)

		timeout := time.After(200 * time.Millisecond)

		SendMessage(Message{
			Type: ProcessMessage,
			Data: Process{
				Id:       id,
				Metadata: metadata,
			},
		})

		for {
			select {
			case <-timeout:
				return "", errors.New("package resolver timeout")
			default:
				value, exists := processMap.Load(id)
				if exists {
					return value, nil
				}
				time.Sleep(20 * time.Millisecond)
			}
		}
	}
}

func handleGetAndroidVpnOptions() string {
	tunLock.Lock()
	defer tunLock.Unlock()
	options := state.AndroidVpnOptions{
		Enable:           state.CurrentState.Enable,
		Port:             currentConfig.General.MixedPort,
		Ipv4Address:      state.DefaultIpv4Address,
		Ipv6Address:      state.GetIpv6Address(),
		AccessControl:    state.CurrentState.AccessControl,
		SystemProxy:      state.CurrentState.SystemProxy,
		AllowBypass:      state.CurrentState.AllowBypass,
		RouteAddress:     state.CurrentState.RouteAddress,
		BypassDomain:     state.CurrentState.BypassDomain,
		DnsServerAddress: state.GetDnsServerAddress(),
	}
	data, err := json.Marshal(options)
	if err != nil {
		fmt.Println("Error:", err)
		return ""
	}
	return string(data)
}

func handleSetState(params string) {
	_ = json.Unmarshal([]byte(params), state.CurrentState)
}

func handleUpdateDns(value string) {
	go func() {
		log.Infoln("[DNS] updateDns %s", value)
		dns.UpdateSystemDNS(strings.Split(value, ","))
		dns.FlushCacheWithDefaultResolver()
	}()
}

func handleGetCurrentProfileName() string {
	if state.CurrentState == nil {
		return ""
	}
	return state.CurrentState.CurrentProfileName
}

func nextHandle(action *Action, send func([]byte)) bool {
	switch action.Method {
	case startTunMethod:
		data := action.Data.(string)
		send(action.wrapMessage(handleStartTun(data)))
		return true
	case stopTunMethod:
		handleStopTun()
		send(action.wrapMessage(true))
		return true
	case setStateMethod:
		data := action.Data.(string)
		handleSetState(data)
		send(action.wrapMessage(true))
		return true
	case getAndroidVpnOptionsMethod:
		send(action.wrapMessage(handleGetAndroidVpnOptions()))
		return true
	case updateDnsMethod:
		data := action.Data.(string)
		handleUpdateDns(data)
		send(action.wrapMessage(true))
		return true
	case setFdMapMethod:
		data := action.Data.(string)
		handleSetFdMap(data)
		send(action.wrapMessage(true))
		return true
	case setProcessMapMethod:
		data := action.Data.(string)
		handleSetProcessMap(data)
		send(action.wrapMessage(true))
		return true
	case getRunTimeMethod:
		send(action.wrapMessage(handleGetRunTime()))
		return true
	case getCurrentProfileNameMethod:
		send(action.wrapMessage(handleGetCurrentProfileName()))
		return true
	}
	return false
}
