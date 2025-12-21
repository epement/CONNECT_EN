////////////////////////////////////////////////////////////////
// Simple program demonstrates why operator= returns a reference
// To compile type:
//
//    cl foo.cpp
//
#include <stdio.h>

class A {
public:
	int x;
	A(int xx=0) { x=xx; }
	A& operator=(A& a) {
		x=a.x;
		return *this;
	}
};

int main()
{
	A a,b,c(6);
	(a=b) = c;  // explicit grouping overrides normal right-associativity!
	printf ("a=%d\n", a.x);
	printf ("b=%d\n", b.x);
	printf ("c=%d\n", c.x);
	return 0;
}
