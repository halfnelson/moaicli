#include <stdio.h>
extern "C" {
	#include "lua.h"
	#include "lauxlib.h"
}

extern "C" {
	int luaopen_myhello (lua_State *L);
}

static int helloworld (lua_State *L) {
	printf("hello world!\n");
	return 0;
}

int LUA_API luaopen_myhello (lua_State *L) {
	struct luaL_reg driver[] = {
		{"helloworld", helloworld},		
		{NULL, NULL},
	};
	luaL_openlib (L, "myhello", driver, 0);
	return 1;
}