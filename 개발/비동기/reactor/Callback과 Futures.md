
어떻게 해야 JVM 위에서 비동기적인 코드를 작성할 수 있을까? Java는 asynchronous programming을 위해 두가지 모델을 제공한다.

- **Callbacks**: return 값을 직접 가지지 않고, 비동기 처리가 끝난 후 result 값을 가져올 수 있을때 추가 callback parameter(a lambda or anonymous class)를 가져오는 Asynchronous 메서드이다. Swing의 `EventListener`와 그 구현 클래스들이 대표적인 예시이다.

- **Futures**: `Future<T>`를 즉시 반환하는 Asynchronous 메서드이다.  The asynchronous process computes a T value, but the Future object wraps access to it. Future 값은 Callback과 마찬가지고, 실제 값을 가져오는건 비동기 처리가 끝난 뒤에야 가능하다. Future를 사용하는 예를 들자면, `Callable<T>` 태스크를 실행하는 `ExecutorService`가 있다.

하지만 이 두 모델이 항상 유용하게 사용되진 않는다. 두 접근법은 한계를 가지고 있다.

## Callbacks

`Callbacks` 코드가 늘어날 경우 가독성이 해쳐지고, 유지보수하기 힘들어진다.  (Callback Hell, 콜백 지옥이라고 부르기도 한다.)

예를 들어, UI에서 사용자가 즐겨찾기 5개, 즐겨찾기가 없는 경우에는 새 컨텐츠 제안을 띄워주는 코드를 생각해보자. 즐겨찾기 ID를 가져오고, 두 번째는 즐겨찾기 세부 정보를 가져오고, 다른 하나는 세부 정보가 포함된 제안을 제공하는 세가지 절차를 거쳐야한다.

```java
userService.getFavorites(userId, new Callback<List<String>>() { // --(1)
  public void onSuccess(List<String> list) { // --(2)
    if (list.isEmpty()) { // --(3)
      suggestionService.getSuggestions(new Callback<List<Favorite>>() { // --(4)
        public void onSuccess(List<Favorite> list) { 
          UiUtils.submitOnUiThread(() -> {  // --(5)
            list.stream()
                .limit(5)
                .forEach(uiList::show);
            });
        }

        public void onError(Throwable error) { // --(6)
          UiUtils.errorPopup(error);
        }
      });
    } else {
      list.stream() // --(7)
          .limit(5)
          .forEach(favId -> favoriteService.getDetails(favId, // --(8)
            new Callback<Favorite>() {
              public void onSuccess(Favorite details) {
                UiUtils.submitOnUiThread(() -> uiList.show(details));
              }

              public void onError(Throwable error) {
                UiUtils.errorPopup(error);
              }
            }
          ));
    }
  }

  public void onError(Throwable error) {
    UiUtils.errorPopup(error);
  }
});
```

1. 성공한 케이스와 실패한 케이스에 대한 처리를 명시하는 Callback interface를 정의한다.
2. 즐겨찾기 ID를 가져온다.
3. list가 empty인 경우 suggestionService로 이동한다.
4. suggestionService가 두번째 Callback interface를 가진다.
5. UI를 그리기 위해 UI thread에서 실행할 동작을 정의한다.
6. 각 레벨의 `onError`에서 에러 팝업 코드를 넣어줘야한다.
7. favorite ID 레벨로 돌아와서 favoriteService를 호출해준다. 결과값을 5개로 제한한다는 것을 stream으로 다시 명시해줘야한다.
8. UI를 그리기 위해 UI thread에서 실행할 동작을 또 다시 정의한다.

코드량이 굉장히 많고 중복되는 코드가 많아서 흐름 파악이 어렵다.

다음은 reactor를 사용해서 코드를 작성한 예시이다.

```java
userService.getFavorites(userId) // --(1)
           .flatMap(favoriteService::getDetails) // --(2)
           .switchIfEmpty(suggestionService.getSuggestions()) // --(3)
           .take(5) // --(4)
           .publishOn(UiUtils.uiThreadScheduler()) // --(5)
           .subscribe(uiList::show, UiUtils::errorPopup); // --(6)
```

1. favorite ID를 가져오는 flow를 시작한다.
2. Favorite의 상세 객체를 가져온다.
3. Favorite이 empty라면 `suggestionService.getSuggestions()`를 실행해서 그 결과물을 반환시킨다.
4. 5개의 element를 반환한다는 것을 딱 한번만 명시해준다.
5. UI를 그리기 위해 UI thread에서 실행할 동작을 정의한다.
6. 팝업을 띄워주는 에러 처리도 한 번만 수행한다.

코드량이 훨씬 줄어들었고, 중요한 흐름을 알아보기 쉽다.

## Future

java8에서 CompletableFuture를 지원하기 시작하면서 `Future`의 사용성이 개선되었지만, 약간의 불편한 점이 여전히 있다.

- `get()` 메서드를 호출하면 쉽게 blocking 된다.
- lazy computation을 지원하지 않는다.
- 여러 값을 가져오거나, 구체적인 에러핸들링이 필요한 상황에 대한 지원이 부족하다.

이름과 통계를 Pair로 가져오는 예제를 보자.

```java
CompletableFuture<List<String>> ids = ifhIds(); // --(1)

CompletableFuture<List<String>> result = ids.thenComposeAsync(l -> { // --(2)
	Stream<CompletableFuture<String>> zip =
			l.stream().map(i -> { 
				CompletableFuture<String> nameTask = ifhName(i); 
				CompletableFuture<Integer> statTask = ifhStat(i); 

				return nameTask.thenCombineAsync(statTask, (name, stat) -> "Name " + name + " has stats " + stat); // --(3)
			});
	List<CompletableFuture<String>> combinationList = zip.collect(Collectors.toList()); 
	CompletableFuture<String>[] combinationArray = combinationList.toArray(new CompletableFuture[combinationList.size()]);

	CompletableFuture<Void> allDone = CompletableFuture.allOf(combinationArray); // --(5) 
	return allDone.thenApply(v -> combinationList.stream()
			.map(CompletableFuture::join) 
			.collect(Collectors.toList()));
});

List<String> results = result.join(); // --(6)
assertThat(results).contains(
		"Name NameJoe has stats 103",
		"Name NameBart has stats 104",
		"Name NameHenry has stats 105",
		"Name NameNicole has stats 106",
		"Name NameABSLAJNFOAJNFOANFANSF has stats 121"
);
```

1. id의 목록을 반환하는 `CompletableFuture`를 정의한다.
2. Future 값을 바탕으로 정보를 가져오기 위해 `thenComposeAsync`를 사용하고 map을 수행하여 각 값을 가져온다.
3. 두 값을 합쳐서 결과값을 만든다.
4. `CompletableFuture.allOf`에 array를 넣어서 모든 작업이 수행한 결과값인 Future를 반환하도록 해준다.
5. 여기서 번거로운 부분이 하나 있는데, `allOf`는 `CompletableFuture<Void>`를 반환하기 때문에 우리는 `join()`을 사용해서 값을 다시 collecting하고 `thenApply` 해줘야한다.
6. 전체 비동기 파이프라인이 trigger되면 우리는 그것이 processing 되길 기다리고, 그 값이 실제로 반환되면 assert해볼 수 있다.

## reactor

다음은 reactor를 사용해서 코드를 작성한 예시이다.

```java
Flux<String> ids = ifhrIds(); // --(1)

Flux<String> combinations =
		ids.flatMap(id -> { // --(2)
			Mono<String> nameTask = ifhrName(id); 
			Mono<Integer> statTask = ifhrStat(id); 

			return nameTask.zipWith(statTask, (name, stat) -> "Name " + name + " has stats " + stat); // --(3)
		});

Mono<List<String>> result = combinations.collectList(); 

List<String> results = result.block(); // --(4)
assertThat(results).containsExactly( 
		"Name NameJoe has stats 103",
		"Name NameBart has stats 104",
		"Name NameHenry has stats 105",
		"Name NameNicole has stats 106",
		"Name NameABSLAJNFOAJNFOANFANSF has stats 121"
);
```

1. 이번엔 ids를 `Flux<String>`의 형태로 가져온다.
2. flatMap call 안에서 각 정보를 비동기적으로 가져온다.
3. 두 값을 합쳐서 결과값을 만든다.
4. 실제 production 코드라면 `Flux`를 추가로 결합하거나 구독해서 사용했겠지만, 여기선 List를 `Mono`로 묶어서 `blocking`한 다음 테스트해주었다.

코드량이 훨씬 줄어들었고, 중요한 흐름이 더 잘 명시된다.

## 결론

Callback과 Future를 사용한 코드를 살펴보았고, 그 코드를 reactor에서 어떻게 간소화할 수 있는지 알게 되었다.

reactor가 저 동작들을 어떻게 추상화하고 처리하는지에 대해서 더 알아보고 싶다는 생각이 들었다.

---

참고

- https://projectreactor.io/docs/core/release/reference/#_from_imperative_to_reactive_programming