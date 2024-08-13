#include <stdio.h>
#include <unistd.h>
#include <time.h>
#include <sys/times.h>

#define HZ 100 // 每1/100秒产生1次时钟中断。

void cpuio_bound(int last, int cpu_time, int io_time);

int main(int argc, char *argv[])
{
	if (!fork())
	{
		printf("I am child [%d] and my parent is [%d].\n", getpid(), getppid());
		fflush(stdout);
		cpuio_bound(10, 1, 0);
		return 0;
	}
	if (!fork())
	{
		printf("I am child [%d] and my parent is [%d].\n", getpid(), getppid());
		fflush(stdout);
		cpuio_bound(10, 0, 1);
		return 0;
	}
	if (!fork())
	{
		printf("I am child [%d] and my parent is [%d].\n", getpid(), getppid());
		fflush(stdout);
		cpuio_bound(10, 1, 9);
		return 0;
	}
	if (!fork())
	{
		printf("I am child [%d] and my parent is [%d].\n", getpid(), getppid());
		cpuio_bound(10, 9, 1);
		return 0;
	}
	// 所有子进程退出后，父进程才退出; 可在 process.log 中检验
	while (wait(NULL) != -1)
		;
	return 0;
}

/*
 * 此函数按照参数占用CPU和I/O时间
 * last: 函数实际占用CPU和I/O的总时间，不含在就绪队列中的时间，>=0是必须的
 * cpu_time: 一次连续占用CPU的时间，>=0是必须的
 * io_time: 一次I/O消耗的时间，>=0是必须的
 * 如果 last > cpu_time + io_time，则往复多次占用CPU和I/O
 * 所有时间的单位为秒
 */
void cpuio_bound(int last, int cpu_time, int io_time)
{
	struct tms start_time, current_time;
	clock_t utime, stime;
	int sleep_time;

	while (last > 0)
	{
		/* CPU Burst */
		times(&start_time);
		/* 其实只有t.tms_utime才是真正的CPU时间。但我们是在模拟一个
		 * 只在用户状态运行的 CPU 大户，就像“for(;;);”, 所以把 t.tms_stime
		 * 加上很合理。*/
		// 为啥要算上核心态的CPU时间
		// 用户 CPU 时间和系统 CPU 时间之和为 CPU 时间，即命令占用 CPU 执行的时间总和。
		do
		{
			times(&current_time);
			utime = current_time.tms_utime - start_time.tms_utime;
			stime = current_time.tms_stime - start_time.tms_stime;
		} while (((utime + stime) / HZ) < cpu_time);
		last -= cpu_time;

		if (last <= 0)
			break;

		/* IO Burst */
		/* 用sleep(1)模拟1秒钟的I/O操作 */
		sleep_time = 0;
		while (sleep_time < io_time)
		{
			sleep(1);
			sleep_time++;
		}
		last -= sleep_time;
	}
}
