#include <iostream>
#include <vector>
#include <time.h>
#include <stdlib.h>

using namespace std;

int main()
{
	srand(time(NULL));
	int x_0 = (rand() % 64) + 1;
	vector<int> x_v[x_0];
	for (int k = 0; k < 3; k++)
	{
		cout << x_v;
		//result(0x29fd400x29fd400x29fd40)
	}
}
