
> https://www.acmicpc.net/problem/12858

구간 업데이트(덧셈)가 있을 때 쿼리마다 구간의 gcd를 구하는 문제이다. 

각 구간별 gcd를 세그먼트 트리로 저장하는 일반적인 방법으로는 시간초과가 발생한다. 구간에 수를 더하면 gcd를 다 다시 계산해야하기 때문이다.

수를 더했을 때 gcd를 모두 재계산하는 것을 막기 위해선 `gcd(a, b) = gcd(a, a-b)`라는 성질을 활용해야한다. 이 식을 확장하면 `gcd(a, b, c, d, e) = gcd(a, |b-a|, |c-b|, |d-c|, |e-d|)`라는 것을 알 수 있다.

세그먼트 트리의 각 노드에서 `gcd(|b-a|, |c-b|, |d-c|, |e-d|)`를 관리한다고 했을 때, b, c, d에 x만큼을 더하면 `|c-b|`와 `|d-c|`의 값은 변하지 않고 양쪽 끝의 `|b-a|`, `|e-d|`만 갱신해주면 된다. 구간이 아무리 넓더라도 두 개의 리프에 대해서만 gcd를 다시 계산하면 되기 때문에 효율적이다.

구간의 시작인 a에 해당하는 값과, gcd 세그먼트 트리에서 `gcd(|b-a|, |c-b|, |d-c|, |e-d|)`에 해당하는 구간 gcd를 가져와서 gcd해주면 각 쿼리의 답을 구할 수 있다. 따라서 구간에 대한 합 연산을 lazy하게 수행하기 위한 lazy seg와, gcd를 저장하는 seg를 구현하면 된다.

```c
#include <iostream>
#include <algorithm>
#include <cmath>
#define MAX 100001
using namespace std;

long long tree[MAX*4], lazy[MAX*4];

void lazy_update(int l, int r, int x) {
    if (lazy[x]!=0) {
        tree[x]+=lazy[x];
        if (l!=r) {
            lazy[x*2]+=lazy[x];
            lazy[x*2+1]+=lazy[x];
        }
        lazy[x]=0;
    }
}

long long query_tree(int l, int r, int x, int gl, int gr) {
    lazy_update(l,r,x);
    if (r<gl||gr<l) return 0;
    else if (gl<=l&&r<=gr) return tree[x];
    else {
        int mid=(l+r)/2;
        return query_tree(l, mid, x*2, gl, gr) + query_tree(mid+1, r, x*2+1, gl, gr);
    }
}

void update_tree(int l, int r, int x, int gl, int gr, long val) {
    lazy_update(l, r, x);
    if (r<gl||gr<l) return;
    else if (gl<=l&&r<=gr) {
        tree[x]+=val*(r-l+1);
        if (l!=r) {
            lazy[x*2]+=val;
            lazy[x*2+1]+=val;
        }
    } else {
        int mid = (l+r)/2;
        update_tree(l, mid, x*2, gl, gr, val);
        update_tree(mid+1, r, x*2+1, gl, gr, val);
        tree[x]=tree[x*2]+tree[x*2+1];
    }
}

long long g_tree[MAX*4];
long long gcd(long long a, long long b) { return ((b) ? gcd(b, a%b) : a); }

long long query_gcd(int l, int r, int x, int gl, int gr) {
    if (r<gl||gr<l) return 0;
    if (gl<=l&&r<=gr) return g_tree[x];
    long long mid = (l+r)/2;
    return gcd(query_gcd(l, mid, x*2, gl, gr), query_gcd(mid+1, r, x*2+1, gl, gr));
}

void update_gcd(int l, int r, int x, int g, int d) {
    if (r<g||g<l) return;
    if (l==r) {
        g_tree[x]+=d;
        return;
    }
    long long mid = (l+r)/2;
    update_gcd(l, mid, x*2, g, d);
    update_gcd(mid+1, r, x*2+1, g, d);
    g_tree[x] = gcd(g_tree[x*2], g_tree[x*2+1]);
}

int main() {
    ios::sync_with_stdio(false);
    cin.tie(NULL);
    cout.tie(NULL);

    int n, k, p;
    cin>>n;
    for (int i=1;i<=n;i++) {
        int a;
        cin>>a;
        if (i >= 2) update_gcd(1, n, 1, i-1, a-p);
        update_tree(1, n, 1, i, i, a);
        p=a;
    }

    /* gcd(a,b,c,d,....)는 gcd(a,b-a,c-b,d-c,....)와 동일 */
    cin>>k;
    for (int i=0;i<k;i++) {
        int c,a,b;
        cin>>c>>a>>b;
        if (c==0) { // 쿼리 결과 출력
            cout<<abs(gcd(query_tree(1, n, 1, a, a), query_gcd(1, n, 1, a, b-1)))<<'\n';
        } else { // a-b 구간에 c만큼 더하기
            update_tree(1, n, 1, a, b, c);
            update_gcd(1, n, 1, a-1, c);
            update_gcd(1, n, 1, b, -c);
        }
    }
    return 0;
}
```