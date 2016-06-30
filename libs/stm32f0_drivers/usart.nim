include rtos

type

  # TODO: Should the RCC/GPIO setup types be moved into some sort of
  # helper module since they'll likely be used for other drivers?

  ClockCmd = (proc(periph: uint32, state: bool): void)

  RccSetup = object
    cmd: ClockCmd
    periph: uint32

  GpioSetup = object
    port: GpioTypeDef
    pin: uint16
    pinSrc: uint8
    rcc: RccSetup

  Usart = object
    periph: USART_TypeDef
    initialized: bool

    # TODO: Replace queues with custom locked circular buffer, we'll
    # need these all over the place, might as well do it once
    rxBuf: QueueHandle
    txBuf: QueueHandle
    rcc: RccSetup
    eventLock: EventGroup

    rxGpio: GpioSetup
    txGpio: GpioSetup
    irqNo: uint32

    rxOverflow: bool

proc init*(u: Usart, baud: uint32): int =

  u.txBuf = createQueue(UartBufferSize, sizeof(uint8))

  if u.txBuf == nil:
    return -1

  u.rxbuf = createQueue(UartBufferSize, sizeof(uint8))
  if u.rxbuf == nil:
    return -2

  # TODO: Check for these guys

  # Initialize all required clocks
  rxGpio.rcc.init()
  txGpio.rcc.init()
  u.rcc.init()

  # Enable NVIC Channels

  # Enable the GPIOs
  for io in [u.rxGpio, u.txGpio]:
    gpioConf.GPIO_Pin = io.pin
    gpioConf.GPIO_Mode = GPIO_Mode_AF
    gpioConf.GPIO_OType = GPIO_OType_PP
    GPIO_Init(io.port, gpioConf.addr)
    GPIO_SetBits(io.port, io.pin)
    GPIO_PinAFConfig(io.port, io.pinSrc, GPIO_AF_1)

  uartConf.USART_BaudRate = baud
  uartConf.USART_WordLength = USART_WordLength_8b
  uartConf.USART_StopBits = USART_StopBits_1
  uartConf.USART_Parity = USART_Parity_No
  uartConf.USART_HardwareFlowControl = USART_HardwareFlowControl_None
  uartConf.USART_Mode = USART_Mode_Rx | USART_Mode_Tx

  USART_Init(u.periph, uartConf.addr);
  
  USART_Cmd(u.periph, ENABLE);

  USART_ITConfig(u.periph. USART_IT_RXNE, ENABLE)
  u.initialized = true

  return 0
  

proc write*(u: Usart, source: cstring, length: int): int =
  if not u.initialized:
    return -1

  # TODO: Wait for event: Usart TX Free
  
  while result < length:
    let qRet = self.txBuf.send(source[result].addr, MaxDelay)

    inc(result)

    if not qRet:
      return -2

    USART_ITConfig(u.periph, USART_IT_TXE, ENABLE);

  # TODO: set event usart tx free

proc read*(u: Usart, dest: cstring, length, timeout: int): int =
  if not u.initialized:
    return -1

  # TODO: Wait for event: Usart RX Free

  while result < length:
    let qRet = self.rxBuf.receive(dest[result].addr, timeout)

    if not qRet:
      return

    inc(result)

  # TODO: Set event usart Rx free

template getchar(u: Usart, timeout: int): char =
  u.read(result.addr, 1, timeout)

template putchar(u: Usart, c: char): int =
  result = u.write(c.addr, 1)

proc usartCommonIrqHandler(): void =

  var txTaskWoken, rxTaskWoken: uint32
  var c: char

  if USART_GetITStatus(u.periph, USART_IT_TXE) != RESET:
    if u.txBuf.receiveFromIsr(c.addr, txTaskWoken.addr):
      Usart_SendData(u.periph, cast[uint16](c))
    else:
      USART_ITConfig(u.periph, USART_IT_TXE, DISABLE)

  if UsartGetITStatus(u.periph, USART_IT_RXNE) != RESET:
    c = cast[char](USART_ReceiveData(u.periph))
    let qRet = u.rxBuf.sendFromIsr(c.addr, rxTaskWoken.addr)
    if qRet:
      u.rxOverflow = true

  endSwitchingIsr(txTaskWoken | rxTaskWoken)

proc usart1IrqHandler(): void {.exportc:"USART1_IRQHandler", cdecl.} =
  usartCommonIrqHandler()

proc usart2IrqHandler(): void {.exportc:"USART2_IRQHandler", cdecl.} =
  usartCommonIrqHandler()
  
