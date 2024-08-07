#define __LIBRARY__ // _syscalln 才有效
#include <unistd.h> // 编译器才能获知自定义的系统调用的编号

_syscall1(int, iam, const char *, name);

int main(int argc, char **argv)
{
  iam(argv[1]);
  return 0;
}