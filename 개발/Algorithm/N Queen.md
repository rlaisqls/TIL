> https://www.acmicpc.net/problem/3344

> https://web.archive.org/web/20161108102345/http://penguin.ewu.edu/~trolfe/QueenLasVegas/Hoffman.pdf

- 보드판 크기를 N이라 두자.
- N을 6으로 나눈 나머지가 2 또는 3이 아니라면, 1부터 N까지의 수를 (짝수 오름차순) + (홀수 오름차순)으로 나열하도록 배치하면 된다.
- N을 6으로 나눈 나머지가 2이라면, 앞선 홀수 오름차순 리스트에서 1과 3의 위치를 바꾸고 5를 맨 뒤로 보낸다.
  - 즉 (짝수 오름차순), (3, 1, 7, 9, ...., 5) 꼴이 될 것이다.
- N을 6으로 나눈 나머지가 3이라면, 2를 짝수 오름차순 리스트의 맨 끝으로 보내고 1, 3을 홀수 오름차순 리스트의 맨 뒤로 보낸다.
  - 즉 (4, 6, 8, ..., 2), (5, 7, 9, ... , 1, 3) 꼴이 될 것이다.
- 이런 식으로 모든 N >= 4 에 대한 해 중 하나를 구할 수 있다.
  
```c
#include <iostream>
using namespace std;

int main() {
    int n;
    bool flag=0;
    cin>>n;
    if (n%2) flag=1;
    if ((!flag&&n%6!=2) || (flag&&(n-1)%6!=2)) {
        if (flag) n--;
        for (int i=1;i<=n/2;i++) cout<<2*i<<"\n";
        for (int i=1;i<=n/2;i++) cout<<2*i-1<<"\n";
        if (flag) cout<<n+1<<"\n";
    } else if ((!flag&&n/6!=0) || (flag&&(n-1)/6!= 2)) {
        if (flag) n--;
        for (int i=1;i<=n/2;i++) cout<<1+(2*i+n/2-3)%n<<"\n";
        for (int i=n/2;i>0;i--) cout<<n-(2*i+n/2-3)%n<<"\n";
        if (flag) cout<<n+1<<"\n";
    }
    return 0;
}
```