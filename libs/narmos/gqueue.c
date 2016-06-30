#include <gqueue.h>
#include <narmos.h>

#define QUEUE_TAIL_WRAP(Q)						\
	(Q->tail == Q->memory + (Q->max_capacity - 1) * Q->item_size)

#define QUEUE_HEAD_WRAP(Q)						\
	(Q->head == Q->memory + (Q->max_capacity - 1) * Q->item_size)

int queue_enqueue(volatile void *q, const void *elt, int timeout)
{
	volatile struct generic_queue *gq = q;

	if (queue_is_empty(q)) {
		/* Empty queue, just push something into the front */
		gq->head = gq->memory;
		gq->tail = gq->memory;
	} else {
		if (queue_is_full(q)) {
			/* Full queue, if we have a timeout, keep trying to
			 * insert until we're successful, or the timeout
			 * expires. If not, just yield forever */
			if (-1 == timeout) {
				while(queue_is_full(q)) {
					yield(NULL);
				}
			} else {

				const int expiration_time = get_system_time() + timeout;

				while (queue_is_full(q) && (get_system_time() < expiration_time)) {
					yield(NULL);
				}

				/* If the queue is still full, return an error */
				if (queue_is_full(gq)) {
					return -1;
				}
			}

		}

		if (QUEUE_TAIL_WRAP(gq)) {
			gq->tail = gq->memory;
		} else {
			gq->tail = (uint8_t *)gq->tail + gq->item_size;
		}
	}

	memcpy((void*)gq->tail, elt, gq->item_size);
	gq->len++;

	return 0;
}

int queue_dequeue(volatile void *q, void *elt, int timeout)
{
	volatile struct generic_queue *gq = q;

	if (queue_is_empty(q)) {
		if (-1 == timeout) {
			while (queue_is_empty(q)) {
				yield(NULL);
			}
		} else {
			const int expiration_time = get_system_time() + timeout;

			while (queue_is_empty(q) && (get_system_time() < expiration_time)) {
				yield(NULL);
			}

			/* If the queue is still full, return an error */
			if (queue_is_empty(gq)) {
				return -1;
			}
		}
	}

	memcpy(elt, (void*)gq->head, gq->item_size);

	if (QUEUE_HEAD_WRAP(gq)) {
		gq->head = gq->memory;
	} else if (gq->len > 1) {
		gq->head = (uint8_t *)gq->head + gq->item_size;
	}
	gq->len--;
	return 0;
}
