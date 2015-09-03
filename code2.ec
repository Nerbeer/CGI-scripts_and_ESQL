#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/*обработчик ошибок*/
void error_handler(char* errname, int errnum)
{
	
	printf("Error \"%d\" in \"%s\"\n", errnum, errname);
	printf("\"%s\"\n",sqlca.sqlerrm.sqlerrmc);
}

/* Возвращает верхний регистр символа*/
char upperchar(char ch)
{
 if ((ch>='a') && (ch<='z'))
 {
     ch='A'+(ch - 'a');
     return ch;
  }
 else return ch;
};

/* Переводит из Hex в Dec*/
char gethex(char ch)
{
 ch=upperchar(ch);
 if ((ch>='0')&&(ch<= '9')) return (ch-'0');
 if ((ch>='A')&&( ch<='F')) return (ch-'A'+10);
};

/* 
 Ищет и возвращает параметр с именем name, в buffer.
 Если параметр name не найден, возвращает NULL.
 
Пример : message = getparam(post_buffer,"message=");

Замечание : символ "=" после имени параметра не удаляется
 и входит в возвращаемый результат, поэтому рекомендуется
 искать параметр вместе с символом "=".
*/

char *getparam(char *buffer,char *name)
{
if (buffer==NULL) return NULL;

char *pos;
long leng=512,i=0,j=0;
char h1,h2,Hex;

char *p=(char *)malloc(leng);
pos = strstr(buffer,name);
if (pos == NULL) return NULL;

if ((pos!=buffer) && (*(pos-1)!='&')) return NULL; 

pos+=strlen(name);

while ( (*(pos+i)!='&')&&( *(pos+i)!='\0' ))
{
 if ( *(pos+i)=='%' )
 {
   i++;
   h1=gethex(*(pos+i));
   i++;
   h2=gethex(*(pos+i));
   h1=h1<<4;
   *(p+j)=h1+h2;
 }
 else
 {
   if (*(pos+i)!='+') *(p+j)=*(pos+i);
    else *(p+j)=' ';
 };
 i++;
 j++;
 if (j >= leng) p=(char*)realloc(p,leng+20);
 leng+=20;
};
if (j < leng) p=(char*)realloc(p,j+1);
     
*(p+j)='\0';
return p;
};


int first(char *input_city)
{
	/* объявление переменных */
	EXEC SQL BEGIN DECLARE SECTION;
	char n_post[6];
	char name[20];
	int reiting;
	char town[20];
	char *in_city; 
	char *stmt = "select * from pmi1114.s where n_post in( select distinct n_post from pmi1114.spj where n_izd in (select n_izd from pmi1114.j where town = ? ) )";
	EXEC SQL END DECLARE SECTION;
	
	exec sql begin work;
	/* подготовка запроса */
	exec sql prepare  stmt1 from :stmt;
	EXEC SQL DECLARE crs_4 CURSOR FOR stmt1;

	in_city = input_city;
	exec sql open crs_4 using :in_city;

	/* если возникла ошибка при открытии курсора */
	if(sqlca.sqlcode < 0)
	{
		error_handler("openning cursor", sqlca.sqlcode);
		exec sql close crs_4;
		exec sql rollback;
		return -1;
	}

	while(sqlca.sqlcode == 0)
	{
		exec sql fetch crs_4 into :n_post, :name, :reiting, :town;
		if(sqlca.sqlcode == ECPG_NOT_FOUND)  
	 		break;
		printf("<div> %s %s %d %s </div>", n_post,name,reiting,town);
	}
	
	/* закрываем курсор */
	exec sql close crs_4;
	/* заканчиваем транзакцию */
	exec sql commit;
	return 0;

}

int main()
{
	printf("Content-type: text/html\n\n");
	printf("<meta charset=\"utf-8\">");
	exec sql connect to"students@fpm2.ami.nstu.ru" AS con USER "pmi-b1114" USING "rnzlqAD8";
	
	/* если возникла ошибка при подключении к базе */
	if(sqlca.sqlcode < 0)
	{
		error_handler("db connection",sqlca.sqlcode);
		return -1;
	}

	char *town = NULL;
	char *content = NULL;
	char *request_method = getenv("REQUEST_METHOD");
	if (strcmp(request_method,"GET")!=0)
	{
		printf("Unknown REQUEST_METHOD. Use only GET !\n");
		return -1;
	};

	content = getenv("QUERY_STRING");
	town = getparam(content,"town=");
	first(town);
	
	EXEC SQL disconnect all;
	return 0;
}