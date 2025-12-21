#pragma option -ms
/*
 * Перенос слов
 * Слова поступают со стандартного ввода
 *
 * Автор: Андрей Левочкин (andrew@sinor.nsk.su)
 */


struct Qpref {
        char *pref;             /* Приставка */
        char *locks;            /* Запрещающие сочетания */
};

//static int Qsize = sizeof Qpr / sizeof ( struct Qpref );
#define Qsize 202
static char U[7] = "ГРСКСТ";

extern pascal char wordc[255];
extern pascal int wh[255];    /* Указатели на переносимые символы */
static char cp1[100];

static int hp[40];
static int lword;
extern near strlen();
extern near strncpy();
extern near strcpy();
extern near strncmp();

extern far f_strlen(char far*);
extern far f_strncmp(const char far *s1, const char far *s2, int maxlen);

extern char far *pascal near Qpr();

extern pascal near wrap()
{
        register int i,j;
        int hpp,k;

        {
                lword = strlen(wordc);
                hpp = 0;
                for(i=0; i<100; i++) wh[i] = 2;
                j = 0; i = 0;
                while((i=quasipref(wordc + j)) != 0){
                        j += i;
                        hp[hpp++] = i;
                        }
                hp[hpp] = 0;
                if(hpp == 0) goto LETTER;
                wh[j+1] = 0;    /* Второй символ в R */
                wh[lword-1] = 0;        /* Последний символ в R */
                wh[j-1] = 0;    /* Последний символ в последней квазиприставке */
                wh[j - hp[hpp-1] + 1] = 0; /* Второй символ в последней квазиприставке */
                j = 0;
                for(i=0; i<hpp; i++){   /* Цикл по квазиприставкам */
                        if(hp[i] != 1) wh[j + hp[i]] = 1;
                        j += hp[i];
                }

LETTER:
                j = 0;
                for(i=0; i<hpp; i++){   /* Цикл по квазиприставкам */
                        if(hp[i]<4){
                                for(k=0; k<hp[i]; k++)
                                        if(wh[j+k] == 2) wh[j+k] = 0;
                                j += hp[i];
                                continue;
                        }
                        strncpy(cp1, &wordc[j], hp[i]);
                        cp1[hp[i]] = '\0';
                        if(wh[j]==2) wh[j] = 0;
                        if(wh[j+1] == 2) wh[j+1] = 0;
                        for(k=3; k<hp[i]; k++)
                                if(wh[j+k-1] == 2) wh[j+k-1] = letter(cp1, k);
                        j += hp[i];
                }
                if(wh[j]==2) wh[j] = 0;
                if(wh[j+1] == 2) wh[j+1] = 0;
                strcpy(cp1, &wordc[j]);
                lword = strlen(cp1);
                for(i=3; i<lword; i++)
                        if(wh[j+i-1] == 2) wh[j+i-1] = letter(cp1, i);
                lword = strlen(wordc);
        }

}

static quasipref(wordc)
char *wordc;
{
        register struct Qpref far *s;
        register char far *cp;
        register int i, lpref;
        char *chp1;
        int  temp1;

        for(s=Qpr(),i=0; i<Qsize; i++, s++)
        {
                lpref = f_strlen( s->pref );      // [BT]
                if(lpref > lword) continue;
                if(f_strncmp(s->pref, wordc, lpref) != 0) continue;
                cp = s->locks;
                while(*cp)
                        if(f_strncmp(&wordc[lpref], cp++, 2) == 0) goto Cont;
                        else cp++;
                if(lpref > (lword-3)) return(0);
                chp1 = wordc + lpref;
                while(*chp1) if(vowel(*chp1++)) goto Yes;
                return(0);
        Yes:    if(spec(wordc[lpref])) return(lpref + 1);
                if(consonant(wordc[lpref - 1]) && vowel(wordc[lpref]))
                        return(lpref - 1);
                else return(lpref);
        Cont: continue;
        }
        return(0);

}

static letter(w, m)
char *w;
{

        if(spec(w[m-1])) return(0);
        if(!vows(w, m-1)) return(0);
        if(!vows(&w[m-1], 0)) return(0);
        if(vowel(w[m-1])){
                if(consonant(w[m-2])) return(0);
                if(vowel(w[m-2])) return(1);
        }

        if(w[m-1] == w[m]) return(0);

        if(spec(w[m-2])) return(1);

        if(vowel(w[m-2])){
                if(spec(w[m])) return(0);
                if(consonant(w[m]) && (!lock(&w[m-1]))) return(0);
                return(1);
        }

        if((w[m-3] == w[m-2]) || lock(&w[m-2])) return(0);
        else return(1);
}

static vowel(c)
char c;
{
        switch (c&0377)  {
        case 'А'&0xff: case 'а'&0xff:                   /*  А   */
        case 'Е'&0xff: case 'е'&0xff:                   /*  Е   */
        case 'И'&0xff: case 'и'&0xff:                   /*  И   */
        case 'О'&0xff: case 'о'&0xff:                   /*  О   */
        case 'У'&0xff: case 'у'&0xff:                   /*  У   */
        case 'Ы'&0xff: case 'ы'&0xff:                   /*  Ы   */
        case 'Э'&0xff: case 'э'&0xff:                   /*  Э   */
        case 'Ю'&0xff: case 'ю'&0xff:                   /*  Ю   */
        case 'Я'&0xff: case 'я'&0xff:   return(1);      /*  Я   */

        default:        return(0);
        }
}

static consonant(c)
char c;
{
        if(vowel(c)) return(0);
        if(spec(c)) return(0);
        return(1);
}

static spec(c)
unsigned char c;
{
        switch(c&0377) {
               case 'Й'&0xff: case 'й'&0xff:
               case 'Ь'&0xff: case 'ь'&0xff:
               case 'ъ'&0xff: case 'Ъ'&0xff:
               return(1);
        default: return(0);
        }
}

static vows(st, n)
char *st;
{

        register int i;
        register char *cp;

        i = n;
        cp = st;

        if(i==0)
                {while(*cp) if(vowel(*cp++)) return(1);}
        else
                {while(n--) if(vowel(*cp++)) return(1);}

        return(0);
}

static lock(st)
char *st;
{

        if(strncmp(&U[0], st, 2) == 0) return(1);
        if(strncmp(&U[2], st, 2) == 0) return(1);
        if(strncmp(&U[4], st, 2) == 0) return(1);

        return(0);
}
/*
=======================================

   Жаль, в timEd'е замены нет, так что сам с табуляциями в начале pазбиpайся ;)

   Best regards, -- Boris.

--- timEd 1.00+
*/
