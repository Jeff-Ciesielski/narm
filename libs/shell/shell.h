/*****************************************************************/
/* Copyright (C) 2015 Jeff Ciesielski <jeffciesielski@gmail.com> */
/*                                                               */
/* shell - A simple extendable command shell library             */
/*                                                               */
/* This software may be modified and distributed under the terms */
/* of the MIT license.  See the LICENSE file for details.        */
/*****************************************************************/
#ifndef _SHELL_H_
#define _SHELL_H_

struct shell_cmd {
	char *command;
	void(*action)(int argc, char **argv);
	void(*help)(void);
};

#define SHELL_MAX_COMMANDS 10

void shell_init(void);
int shell_register_command(const struct shell_cmd *command);
#endif
