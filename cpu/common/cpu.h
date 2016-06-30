#ifndef _CPU_H_
#define _CPU_H_

#include <stdint.h>

int system_init(void);
uint64_t get_system_time(void);
void system_sleep(void);

#endif	/* _CPU_H_ */
