import macros
import stdio
{.compile: "gqueue.c".}

# Synchronization primatives for narmos

type
  Queue {.importc: "struct generic_queue", header: "gqueue.h".} = object
    head: pointer
    tail: pointer
    item_size: cint
    len: cint
    max_capacity: cint
    memory: array[0, uint8]

  QueueWrap*[T] = object
    gq: Queue
    elements: pointer

  QueueHandle*[T] = ptr QueueWrap[T]
  MutexHandle*[T] = ptr QueueWrap[T]
  SemaphoreHandle*[T] = ptr QueueWrap[T]
  LockHandle = MutexHandle or SemaphoreHandle

# Queue
template declareQueue*[T](capacity: int): QueueHandle[T] =
  var q: QueueWrap[T]
  var elts: array[capacity, T]
  q.elements = elts[0].addr
  q.gq.item_size = sizeof(T).cint
  q.gq.max_capacity = capacity.cint
  addr q

proc put*[T](q: QueueHandle[T], data: T, timeout: int = -1): bool =
  proc enqueue(q: QueueHandle[T], data: pointer, timeout: cint): bool {.importc: "queue_enqueue",
                                                                    header: "gqueue.h", cdecl.}
  var tmp = data
  q.enqueue(tmp.addr, cast[cint](timeout))

proc get*[T](q: QueueHandle[T], timeout: int = -1): (bool, T) =
  proc dequeue(q: QueueHandle, data: pointer, timeout: cint): bool {.importc: "queue_dequeue",
                                                                     header: "gqueue.h", cdecl.}
  var data: T
  var qRes = q.dequeue(data.addr, cast[cint](timeout))

  (qRes, data)

# Mutex / Semaphore
template declareMutex*: MutexHandle =
  declareQueue[bool](1)

template declareSemaphore*[T](entries: int): SemaphoreHandle =
  declareQueue[bool](entries)

proc take*[T: LockHandle](lock: T, timeout: int = -1): bool =
  lock.put(true, timeout)

proc give*[T: LockHandle](lock: T) =
  discard lock.get(0)

template withLock*[T: LockHandle](lock: T, statements: untyped) = 
  discard take(lock)
  statements
  give(lock)
