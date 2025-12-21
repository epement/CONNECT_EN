all: install

install:  rifiuti.c
	gcc -o rifiuti rifiuti.c -lm -lc;cp rifiuti ../bin

installwin:  rifiuti.c
	gcc -DCYGWIN -o rifiuti.exe rifiuti.c -lm -lc;cp rifiuti.exe ../bin

clean: 
	rm -f rifiuti.exe rifiuti
