#include <narmos.h>

#include <platform_debug.h>

#include <errno.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/times.h>
#include <sys/unistd.h>
#include <sys/time.h>
#include <stdint.h>
#include <stdbool.h>
#include <util.h>

#include <usart.h>
#include <board.h>

#ifndef BOARD_DEBUG_USART
#warning "No board debug usart defined"
#else
  #define DEBUG_USART BOARD_DEBUG_USART
#endif

#undef errno
extern int errno;

char *__env[1] = { 0 };
char **environ = __env;

#define WRITE_BUF_SIZE 32
int _write(int file, char *ptr, int len);

int _close(int file)
{
	(void)file;
	return -1;
}

int _execve(char *name, char **argv, char **env)
{
	(void)name;
	(void)argv;
	(void)env;
	errno = ENOMEM;
	return -1;
}

int _fork()
{
	errno = EAGAIN;
	return -1;
}

__attribute__((used))
int _fstat(int file, struct stat *st)
{
	(void)file;
	(void)st;
	st->st_mode = S_IFCHR;
	return 0;
}

__attribute__((used))
int _getpid()
{
	return 1;
}

int _gettimeofday(struct timeval *tv, struct timezone *tz)
{
	(void)tv;
	(void)tz;
	return 0;
}

__attribute__((used))
int _isatty(int file)
{
	switch (file)
	{
		case STDOUT_FILENO:
		case STDERR_FILENO:
		case STDIN_FILENO:
			return 1;
		default:
			errno = EBADF;
			return 0;
	}
}

__attribute__((used))
int _kill(int pid, int sig)
{
	(void)pid;
	(void)sig;
	errno = EINVAL;
	return (-1);
}

int _link(char *old, char *new)
{
	(void)old;
	(void)new;
	errno = EMLINK;
	return -1;
}

int _lseek(int file, int ptr, int dir)
{
	(void)file;
	(void)ptr;
	(void)dir;
	return 0;
}

caddr_t _sbrk(int incr)
{
	extern char _ebss;
	static char *heap_end;
	char *prev_heap_end;

	if (heap_end == 0)
	{
		heap_end = &_ebss;
	}
	prev_heap_end = heap_end;

	char * stack = (char*) __get_MSP();
	if (heap_end + incr > stack)
	{
		_write(STDERR_FILENO, "Heap and stack collision\n", 25);
		errno = ENOMEM;
		return (caddr_t) - 1;
		//abort ();
	}

	heap_end += incr;
	return (caddr_t) prev_heap_end;

}

int _stat(const char *filepath, struct stat *st)
{
	(void)filepath;
	(void)st;
	st->st_mode = S_IFCHR;
	return 0;
}

clock_t _times(struct tms *buf)
{
	(void)buf;
	return -1;
}

int _unlink(char *name)
{
	(void)name;
	errno = ENOENT;
	return -1;
}

int _wait(int *status)
{
	(void)status;
	errno = ECHILD;
	return -1;
}
