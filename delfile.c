#include <stdio.h>
#include <signal.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <dirent.h>

unsigned int g_num=0;
unsigned int g_print=0;
unsigned int g_error=0;
//unsigned int minold=1475000000u;

int delfile(const char* path)
{
	DIR *dir;
	struct dirent * prt;
	char filename[256];
	struct stat buf;
	dir = opendir(path);
	if(NULL == dir)
	{
		fprintf(stderr,"cannot open directory:%s\n",path);
		perror("what?:");
		return -1;
	}
    while(prt = readdir(dir)) 	
	{
		if(prt->d_name[0] != '.')	
		{
			sprintf(filename,"%s/%s",path,prt->d_name);	
			if(0 == stat(filename,&buf))
                    //&& buf.st_atime <= minold)
			{
				//printf("time=[%u]",buf.st_atime);	
				if(1 == g_print)	
					printf("filename=[%s],time=[%u]\n",filename,buf.st_atime);
					
                if (S_ISREG(buf.st_mode))
                {
                    if(0 == unlink(filename))
                    {
                        ++g_num;
                    }
                    else
                    {
                        ++g_error;
                    }
                }
                else if (S_ISDIR(buf.st_mode))
                {
                    if (delfile(filename) < 0)
                    {
                        printf("delete directory %s failed\n", filename);
                        exit(1);
                    }
                    else
                    {
                        if (rmdir(filename) < 0)
                        {
                            perror("rmdir: in delfile func==");
                            exit(1);
                        }
                    }
                }
			}
		}
	}
 	closedir(dir);

    return 0;
}

void printinfo(int signum)
{
	printf("g_num=[%d],g_error=[%d]\n",g_num,g_error);	
}

int main(int argc,char* argv[])
{
    int i = 0;
	if(argc > 2)
	{
		//g_print = 1;
	}
	signal(SIGUSR1,printinfo);
	for(i=1; i < argc; i++)
	{
		printf("--- init pid=[%d] ---\n",getpid());
		delfile(argv[i]);
        if (rmdir(argv[i]) < 0)
        {
            perror("rmdir: in for loop==");
            exit(1);
        }
		sleep(1);
	}
	printf("g_num=[%d],g_error=[%d]\n",g_num,g_error);	
}
