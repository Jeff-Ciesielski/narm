{.compile: "gqueue.c".}

type
  Queue {.importc: "generic_queue", header: "gqueue.h".} = object

  QueueWrap[T, L] = object
    gq: Queue
    elements: array[L, T]
  
  QueueHandle* = ptr QueueWrap

template declareQueue*[T,L](): QueueHandle =
  var ret = QueueWrap[T,L]()
  ret.addr
