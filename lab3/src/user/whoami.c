#define __LIBRARY__ // _syscalln才有效
#include <unistd.h> // 编译器才能获知自定义的系统调用的编号
#include <stdio.h>

_syscall2(int, whoami, char *, name, unsigned int, size);

int main()
{
  char s[30];
  whoami(s, 30);
  printf("%s\n", s);
  return 0;
}