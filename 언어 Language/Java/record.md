# ☕ record

record란?
- 불변(immutable) 데이터 객체를 쉽게 생성할 수 있도록 하는 새로운 유형의 클래스이다.
- JDK14에서 preview로 등장하여 JDK16에서 정식 스펙으로 포함되었다.
- 묵시적으로 추상 클래스인 `Record`를 상속받는다. 

## 기존의 불변 데이터 객체

```java
public class Person {
    private final String name;
    private final int age;
    
    public Person(String name, int age) {
        this.name = name;
        this.age = age;
    }
    
    public String getName() {
        return name;
    }
    
    public int getAge() {
        return age;
    }
}
```

상태(name, age)를 보유하는 불변 객체를 생성하기 위해 많은 코드를 작성해야했다.

- 모든 필드에 final을 사용하여 명시적으로 정의
- 필드 값을 모두 포함한 생성자 
- 모든 필드에 대한 접근자 메서드(getter) 
- 상속을 방지하기 위해 클래스 자체를 final로 선언하기도함
- 로깅 출력을 제공하기 위한 `toString()` 재정의
- 두 개의 인스턴스를 비교하기 위한 `equals()`, `hashCode()` 재정의

하지만 레코드 클래스를 사용하면 훨씬 간결한 방식으로 동일한 불변 데이터 객체를 정의할 수 있다.

```java
public record Book(String title, String author, String isbn) { }
```

```java
이름(Person), 헤더(String name, int age), 바디({})
record 레코드명(컴포넌트1, 컴포넌트2, ...) { }
```

컴파일러는 헤더를 통해 내부 필드를 추론한다.

record class에 대해서는 생성자를 작성하지 않아도 되고, `toString()`, `equals()`, `hashCode()` 메소드에 대한 구현을 자동으로 제공한다.

## 일반 class와의 비교

일반 class와의 차이점은 아래와 같은 것들이 있다.

- 다른 클래스를 상속받을 수 없다.
- 레코드에는 인스턴스 필드를 선언할 수 없다. 다르게 말하면 정적 필드는 가능하다.
- 레코드를 abstract로 선언할 수 없으며 암시적으로 final로 선언된다.
- 레코드의 컴포넌트는 암시적으로 final로 선언된다.

클래스와 비슷한 점을 나열하면 다음과 같다.

- 클래스 내에서 레코드를 선언할 수 있다. 중첩된 레코드는 암시적으로 static으로 선언된다.
- 제네릭 레코드를 만들 수 있다.
- 레코드는 클래스처럼 인터페이스를 구현할 수 있다.
- new 키워드를 사용하여 레코드를 인스턴스화할 수 있다.
- 레코드의 본문(body)에는 정적 필드, 정적 메서드, 정적 이니셜라이저, 생성자, 인스턴스 메서드, 중첩 타입(클래스, 인터페이스, 열거형 등)을 선언할 수 있다.
- 레코드나 레코드의 각 컴포넌트에 어노테이션을 달 수 있다.

## 코드 비교

Book 레코드를 class와 바꾸면 아래와 같이 될 것 이다.

```java
// 레코드
public record Book(String title, String author, String isbn) { }
```

```java
// 클래스
// 암시적으로 추상 클래스인 java.lang.Record를 상속받는다.
public final class Book extends java.lang.Record {
    // 레코드의 각 컴포넌트는 내부에서 private final인 인스턴스 필드로 선언된다.
    private final String title;
    private final String author;
    private final String isbn;
 
    // 레코드 내부에서 표준 생성자(canonical constructor)가 만들어진다.
    // 암시적으로 선언된 표준 생성자의 접근 제어자는 레코드의 접근 제어자와 동일하다.
    public Book(String title, String author, String isbn) {
        super();
        this.title = title;
        this.author = author;
        this.isbn = isbn;
    }
 
    // 기본 구현 toString(), hashCode(), equals()은 원하면 변경할 수 있다.
    @Override
    public final String toString() {
        // 내부 구현의 정확한 문자열 포맷은 향후 변경될 수도 있다.
        return "Book[" + this.title + ", " + this.author + ", " + this.isbn + "]";
    }
 
    // 암시적 구현은 동일한 컴포넌트로부터 생성된 두 레코드는 해시 코드가 동일해야 한다.
    @Override
    public final int hashCode() {
        // 구현에 사용되는 정확한 알고리즘은 정해지지 않았으며 향후 변경될 수 있다.
        int result = title == null ? 0 : title.hashCode();  
        result = 31 * result + (author == null ? 0 : author.hashCode());  
        result = 31 * result + (isbn == null ? 0 : isbn.hashCode());  
        return result;  
    }
 
    // 암시적 구현은 두 레코드의 모든 컴포넌트가 서로 동일하면 true를 반환한다.
    @Override
    public final boolean equals(Object o) {
        // 구현에 사용되는 정확한 알고리즘은 정해지지 않았으며 향후 변경될 수 있다.
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        Book book = (Book) o;
        return Objects.equals(title, book.title) && Objects.equals(author, book.author) && Objects.equals(isbn, book.isbn);
    }
 
    // 컴포넌트명과 동일한 게터(getter)가 선언된다.
    public String title() {
        return this.title;
    }
 
    public String author() {
        return this.author;
    }
 
    public String isbn() {
        return this.isbn;
    }
}
```

## 컴팩트 생성자(Compact Constructor)

만약 별도의 초기화 로직이 필요하다면 레코드 안에 표준 생성자를 만들 수도 있다. 

```java
public record Book(String title, String author, String isbn) {    
    // 물론 이렇게 다른 생성자를 추가할 수도 있다.
    public Book(String title, String isbn) {
        this(title, "Unknown", isbn);
    }
 
    public Book(String title, String author, String isbn) {
        // 조금 더 복잡한 초기화 로직 ...
    }
}
```

여기서 이러한 표준 생성자 말고도 컴팩트 생성자를 사용할 수도 있다. 아래와 같이 생성자 매개변수를 받는 부분이 사라진 형태이다. 개발자가 일일이 명시적으로 인스턴스 필드를 초기화하지 않아도 컴팩트 생성자의 마지막에 초기화 구문이 자동으로 삽입된다. 그리고 표준 생성자와는 달리 컴팩트 생성자 내부에서는 인스턴스 필드에 접근을 할 수가 없으며, 접근하려고 하면 "final 변수 'x'에 값을 할당할 수 없습니다."와 같은 에러 메시지를 볼 수 있다.

```java
public record Book(String title, String author, String isbn) {
    // public Book(String title, String author, String isbn) { ... }과 동일
    public Book {
        Objects.requireNonNull(title);
        Objects.requireNonNull(author);
        Objects.requireNonNull(isbn);
        // this.title = title;
        // this.author = author;
        // this.isbn = isbn;
    }
 
    // 여전히 아래와 같이 표준 생성자와 컴팩트 생성자를 혼용해서 쓸 수 있다.
    public Book(String title, String isbn) {
        this(title, "Unknown", isbn);
    }
}
```

---
참고
- https://openjdk.java.net/jeps/359

