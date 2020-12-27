import testes

import cps/core
import cps/schedulers

testes:
  var r = 0

  proc adder(x: var int) =
    inc x

  block noop_magic:
    var j = 2
    proc foo() {.cps: Cont.} =
      var i = 3
      j = 4
      noop()
      check i == 3
    trampoline foo()
    check j == 4

when false:
  block trampoline:
    r = 0
    proc foo() {.cps: Cont.} =
      r = 1
    trampoline foo()
    check r == 1

  block:
    ## declaration via tuple deconstruction
    proc foo() {.cps: Cont.} =
      var (i, j, k) = (1, 2, 3)
      let (x, y, z) = (4, 5, 6)
      noop()
      check:
        i == 1
        j == 2
        k == 3
    trampoline foo()

when false:
  block assignment_shim:
    r = 0
    proc bar(a: int): int {.cps: Cont.} =
      jield()
      return a * 2

    proc foo() {.cps: Cont.} =
      let w = 4
      let x = bar(w).int
      let z = 5
      discard x + z

    trampoline foo()
    check r == 13

  block yield_magic:
    proc foo() {.cps: Cont.} =
      jield()
    trampoline foo()

  block sleep_magic:
    proc foo() {.cps: Cont.} =
      var i: int = 0
      while i < 3:
        sleep(i + 1)
        adder(i)
      r = i
      check r == 3
    foo_clyybber()

  block:
    ## shadowing and proc param defaults
    ## https://github.com/disruptek/cps/issues/22
    when true:
      skip("broken until scopes are improved")
    else:
      proc foo(a, b, c: int = 3) {.cps: Cont.} =
        ## a=1, b=2, c=3
        var a: int = 5
        ## a=5, b=2, c=3
        noop()
        ## a=5, b=2, c=3
        var b: int = b + a
        ## a=5, b=7, c=3
        noop()
        ## a=5, b=7, c=3
        check:
          a == 5
          b == 7
          c == 3
      foo_clyybber(1, 2)

  block:
    ## reassignment of var proc params
    ## https://github.com/disruptek/cps/issues/22 (2nd)
    proc foo(a, b, c: var int) {.cps: Cont.} =
      a = 5
      noop()
      b = b + a
      noop()
      check:
        a == 5
        b == 7
        c == 3
    var (x, y, z) = (1, 2, 3)
    foo_clyybber(x, y, z)

  block:
    ## multiple variable declaration
    ## https://github.com/disruptek/cps/issues/16
    ## this is the test of `var i, j, k: int = 0`
    proc foo() {.cps: Cont.} =
      var i, j, k: int = 0
      j = 5
      var p: int
      var q: int = 0
      var r: int = j
      jield()
      inc i
      inc j
      inc k
      inc p
      inc q
      inc r
    foo_clyybber()

  block:
    ## declaration without type
    when true:
      skip("broken until cps macro is typed")
    else:
      proc foo() {.cps: Cont.} =
        var j = 2
        noop()
        check j == 2
      foo_clyybber()

  block:
    ## simple block with break
    proc foo() {.cps: Cont.} =
      r = 1
      block:
        if true:
          inc r
          break
        check false
      inc r
    foo_clyybber()
    if r != 3:
      checkpoint "r wasn't 3: ", r
      check false

  block:
    ## block with break
    proc foo() {.cps: Cont.} =
      r = 1
      block:
        if true:
          noop()
          inc r
          break
        check false
      inc r
    foo_clyybber()
    if r != 3:
      checkpoint "r wasn't 3: ", r
      check false

  block:
    ## semaphores
    var sem = newSemaphore()
    var success = false

    proc signalSleeper(ms: int) {.cps: Cont.} =
      sleep(ms)
      signal(sem)

    proc signalWaiter() {.cps: Cont.} =
      wait(sem)
      success = true

    signalSleeper_clyybber(10)
    signalWaiter_clyybber()

    run()

    if not success:
      raise newException(AssertionDefect, "signal failed")

  block:
    ## break statements without cps 🥴
    proc foo() =
      r = 1
      check r == 1
      while true:
        if true:
          break
        inc r
        check r <= 2
        return
    foo()
    check r == 1, "r was " & $r

  block:
    ## a fairly tame cps break
    proc foo() {.cps: Cont.} =
      r = 1
      while true:
        jield()
        if true:
          break
        inc r
        if r > 2:
          check false
        return
    foo_clyybber()
    check r == 1, "r was " & $r

  block:
    ## break in a nested else (don't ask)
    proc foo() {.cps: Cont.} =
      r = 1
      while true:
        noop()
        if true:
          inc r
          if r > 2:
            check false
          else:
            break
      inc r
    foo_clyybber()
    check r == 3, "r was " & $r

  block:
    ## named breaks
    proc foo() {.cps: Cont.} =
      r = 1
      block found:
        while true:
          noop()
          if r > 2:
            break found
          noop()
          inc r
        check false
      r = r * -1
    foo_clyybber()
    check r == -3, "r was " & $r

  block:
    ## while statement
    proc foo() {.cps: Cont.} =
      var i: int = 0
      while i < 2:
        let x: int = i
        adder(i)
        check x < i
      r = i
      check r == 2
    foo_clyybber()

  block:
    ## while with break
    proc foo() {.cps: Cont.} =
      var i: int = 0
      while true:
        let x: int = i
        adder(i)
        if i >= 2:
          break
        check x < i
      r = i
      check r == 2
    foo_clyybber()

  block:
    ## while with continue
    proc foo() {.cps: Cont.} =
      var i: int = 0
      while i < 2:
        let x: int = i
        adder(i)
        if x == 0:
          continue
        check x > 0
      r = i
      check r == 2
    foo_clyybber()

  block:
    ## simple name shadowing test
    proc b(x: int) {.cps: Cont.} =
      check x > 0
      let x: int = 3
      check x == 3
      var y: int = 8
      block:
        var x: int = 4
        inc x
        dec y
        check x == 5
        check y == 7
      check x == 3
      check y == 7

    proc a(x: int) {.cps: Cont.} =
      check x > 0
      check x == 1
      let x: int = 2
      check x == 2
      b(x)
      check x == 2

    a(1)
    run()

  block:
    ## for loop with continue, break
    proc foo() {.cps: Cont.} =
      r = 1
      while true:
        for i in 0 .. 3:
          if i == 0:
            continue
          if i > 2:
            break
          r = r + i
        inc r
        if r == 5:
          break
      inc r
    foo_clyybber()
    check r == 6, "r is " & $r

  block:
    ## fork
    when not declaredInScope(fork):
      skip("fork() not declared")
    else:
      proc foo() {.cps: Cont.} =
        fork()
        inc r

      foo_clyybber()
      if r != 2:
        raise newException(Defect, "uh oh")

  block:
    ## the famous tock test
    proc foo(name: string; ms: int) {.cps: Cont.} =
      var count: int = 10
      while count > 0:
        dec count
        sleep(ms)
        checkpoint name, " ", count

    foo_clyybber("tick", 3)
    foo_clyybber("foo", 7)
    run()

  block:
    ## shadow mission impossible
    when true:
      skip("will not work until new scopes go in")
    else:
      proc b(x: int) {.cps: Cont.} =
        noop()
        check x > 0
        noop()
        let x: int = 3
        noop()
        check x == 3
        noop()
        var y: int = 8
        block:
          noop()
          var x: int = 4
          noop()
          inc x
          noop()
          dec y
          noop()
          check x == 5
          check y == 7
        noop()
        check x == 3
        noop()
        check y == 7

      proc a(x: int) {.cps: Cont.} =
        noop()
        check x > 0
        noop()
        check x > 0
        noop()
        var x: int = 2
        noop()
        check x == 2
        noop()
        spawn b(x)
        noop()
        check x == 2
        noop()
        check x == 2

      spawn a(1)
      run()

  block:
    ## the sluggish yield test
    when defined(release):
      skip("too slow for release mode")
    const
      start = 2
      tiny = 0
      big = start * 2
    var count = start

    proc higher(ms: int) {.cps: Cont.} =
      while count < big and count > tiny:
        inc count
        sleep(ms)
        jield()
        jield()
        jield()
        jield()
        jield()
        jield()

    proc lower(ms: int) {.cps: Cont.} =
      while count < big and count > tiny:
        dec count
        sleep(ms)
        jield()

    higher(1)
    lower(1)
    run()

    if count != tiny:
      raise newException(ValueError, "you're a terrible coder")

when false:
  import epoll
  import posix
  import tables
  import deques
  import os

  testes:
    block:
      ## zevv's echo service

      proc timerfd_create(clock_id: ClockId, flags: cint): cint
         {.cdecl, importc: "timerfd_create", header: "<sys/timerfd.h>".}

      proc timerfd_settime(ufd: cint, flags: cint,
                            utmr: ptr Itimerspec, otmr: ptr Itimerspec): cint
         {.cdecl, importc: "timerfd_settime", header: "<sys/timerfd.h>".}

      type

        Cont = ref object of RootObj
          fn*: proc(c: Cont): Cont {.nimcall.}

        Evq = ref object
          epfd: cint
          work: Deque[Cont]
          fds: Table[cint, Cont]
          running: bool

        Timer = proc()

      ## Event queue implementation

      proc newEvq(): Evq =
        new result
        result.epfd = epoll_create(1)

      proc stop(evq: Evq) =
        evq.running = false

      proc addWork(evq: Evq, cont: Cont) =
        evq.work.addLast cont

      proc addFd(evq: Evq, fd: SocketHandle | cint, cont: Cont) =
        evq.fds[fd.cint] = cont

      proc delFd(evq: Evq, fd: SocketHandle | cint) =
        evq.fds.del(fd.cint)

      proc io(evq: Evq, c: Cont, fd: SocketHandle | cint, event: int): Cont =
        var epv = EpollEvent(events: event.uint32)
        epv.data.u64 = fd.uint
        discard epoll_ctl(evq.epfd, EPOLL_CTL_ADD, fd.cint, epv.addr)
        evq.addFd(fd, c)

      proc sleep(evq: Evq, c: Cont, timeout: int): Cont =
        let fd = timerfd_create(CLOCK_MONOTONIC, 0)
        var ts: Itimerspec
        ts.it_interval.tv_sec = Time(timeout div 1_000)
        ts.it_interval.tv_nsec = (timeout %% 1_000) * 1_000_000
        ts.it_value.tv_sec = ts.it_interval.tv_sec
        ts.it_value.tv_nsec = ts.it_interval.tv_nsec
        check timerfd_settime(fd.cint, 0.cint, ts.addr, nil) != -1
        evq.io(c, fd, POLLIN)

      proc run(evq: Evq) =
        evq.running = true
        while true:

          # Pump the queue until empty
          while evq.work.len > 0:
            let c = evq.work.popFirst
            let c2 = c.fn(c)
            if c2 != nil:
              evq.addWork c2

          if not evq.running:
            break

          # Wait for all registered file descriptors
          var events: array[8, EpollEvent]
          let n = epoll_wait(evq.epfd, events[0].addr, events.len.cint, 1000)

          # Put continuations for all ready fds back into the queue
          for i in 0..<n:
            let fd = events[i].data.u64.cint
            evq.addWork evq.fds[fd]
            evq.delFd(fd)
            discard epoll_ctl(evq.epfd, EPOLL_CTL_DEL, fd.cint, nil)

      ## Some convenience functions to hide the dirty socket stuff, this
      ## keeps the CPS functions as clean and readable as possible

      proc sockBind(port: int): SocketHandle =
        let fds = posix.socket(AF_INET, SOCK_STREAM, 0)
        var sas: Sockaddr_in
        sas.sin_family = AF_INET.uint16
        sas.sin_port = htons(port.uint16)
        sas.sin_addr.s_addr = INADDR_ANY
        var yes: int = 1
        check setsockopt(fds, SOL_SOCKET, SO_REUSEADDR, yes.addr, sizeof(yes).SockLen) != -1
        check bindSocket(fds, cast[ptr SockAddr](sas.addr), sizeof(sas).SockLen) != -1
        check listen(fds, SOMAXCONN) != -1
        return fds

      proc sockAccept(fds: SocketHandle): SocketHandle =
        var sac: Sockaddr_in
        var sacLen: SockLen
        let fdc = posix.accept(fds, cast[ptr SockAddr](sac.addr), sacLen.addr)
        check fcntl(fdc, F_SETFL, fcntl(fdc, F_GETFL, 0) or O_NONBLOCK) != -1
        return fdc

      proc sockRecv(fd: SocketHandle): string =
        result = newString(1024)
        let n = posix.recv(fd, result[0].addr, result.len, 0)
        if n >= 0:
          result.setlen(n)
        else:
          result.setlen(0)

      proc sockSend(fd: SocketHandle, s: string) =
        let n = posix.send(fd, s[0].unsafeAddr, s.len, 0)
        check(n == s.len)

      proc sockConnect(address: string, port: int): SocketHandle =
        discard
        let fd = posix.socket(AF_INET, SOCK_STREAM, 0)
        var sas: Sockaddr_in
        sas.sin_family = AF_INET.uint16
        sas.sin_port = htons(port.uint16)
        sas.sin_addr.s_addr = inet_addr(address)
        var yes: int = 1
        check connect(fd, cast[ptr SockAddr](sas.addr), sizeof(sas).SockLen) != -1
        return fd

      var evq = newEvq()
      var count = 0
      var clients = 0

      ## CPS server session hander
      proc handleClient(fdc: SocketHandle) {.cps: Cont.} =

        inc clients

        while true:
          evq.io(fdc, POLLIN)
          let s: string = sockRecv(fdc)
          if s.len == 0: break
          inc count
          evq.io(fdc, POLLOUT)
          sockSend(fdc, s)

        dec clients
        discard fdc.close()


      ## CPS server listener handler
      proc doEchoServer(port: int) {.cps: Cont.} =
        let fds: SocketHandle = sockBind(port)
        checkpoint "listening fd: ", fds.int
        while true:
          evq.io(fds, POLLIN)
          let fdc: SocketHandle = sockAccept(fds)
          #checkpoint "accepted fd:", fdc.int
          # Create new client and add to work queue
          evq.addWork handleClient(fdc)


      ## CPS client handler
      proc doEchoClient(address: string, port: int, n: int, msg: string) {.cps: Cont.} =
        let fd: SocketHandle = sockConnect(address, port)
        #checkpoint "connected fd: ", fd.int

        var i: int = 0
        while i < n:
          evq.io(fd, POLLOUT)
          sockSend(fd, msg)
          evq.io(fd, POLLIN)
          let msg2: string = sockRecv(fd)
          check msg2 == msg
          inc i

        discard fd.close()
        #checkpoint "disconnected fd: ", fd.int

      ## Progress reporting
      proc doTicker() {.cps: Cont.} =
        while true:
          evq.sleep(1000)
          checkpoint "tick. clients: ", clients, " echoed ", count, " messages"
          if clients == 0:
            evq.stop()

      ## Spawn workers
      evq.addWork doTicker()
      evq.addWork doEchoServer(8000)
      for i in 1..100:
        evq.addWork doEchoClient("127.0.0.1", 8000,
                                 2000, "The quick brown fox jumped over the lazy dog")

      ## Forever run the event queue
      evq.run()
