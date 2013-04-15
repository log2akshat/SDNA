#include<stdio.h>

main()
{
int num, div;
printf("Prime numbers are : \n"); 
for (num=2;num<=20;num++)
{
for (div=2;div<=num;div++)
{
	if ((num%div)==0)
	{
	break;
	}
}	
	if (num==div)
	{
	printf ("%d", num);
	printf ("\n");
	num++;
	}
}
}
