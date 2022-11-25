# Object

코틀린에서 클래스를 정의하는 키워드는 class이다. 하지만 간혹 object 키워드로 클래스 정의하는 경우를 볼 수 있다. object로 클래스를 정의하면, 싱클턴(Singleton) 패턴이 적용되어 객체가 한번만 생성되도록 한다. 코틀린에서 object를 사용하면 싱글톰을 구현하기 위한 Boiler plate를 작성하지 않아도 된다. 또는, 익명 객체를 생성할 때 쓰이기도 한다.

#### object의 용도
- 싱글턴 클래스로 만들 때
- 익명 클래스 객체를 생성할 때

## 싱글턴 클래스 정의를 위한 Object

아까도 말했듯, object로 싱글턴 클래스를 정의할 수 있다. 원래 클래스를 정의할때 class가 있는 자리에 object를 입력해주면 이 클래스는 싱글턴으로 동작하게 된다.

```kotlin
object CarFactory {
    val cars = mutableListOf<Car>()
    
    fun makeCar(horsepowers: Int): Car {
        val car = Car(horsepowers)
        cars.add(car)
        return car
    }
}
```

object로 설정하면, 아래 코드처럼 CarFactory.makeCar 처럼 메소드에 접근하여 Car객체를 생성할 수 있다. 또한, CarFactory.cars 처럼 직접 변수에 접근할 수 있습니다. 마치 static처럼 사용하는 것 같지만, 인스턴스는 한개 만들어져있는 상태이다. 당연히 여러번 호출해도 CarFactory 객체는 한번만 생성된다.

```kotlin
val car = CarFactory.makeCar(150)
println(CarFactory.cars.size)
```

위에서 봤던 CarFactory 클래스를 자바로 변환한 코드는 아래와 같다.

```java
public final class CarFactory {
   private static final List cars;
   public static final CarFactory INSTANCE;

   public final List getCars() {
      return cars;
   }

   public final Car makeCar(int horsepowers) {
      Car car = new Car(horsepowers);
      cars.add(car);
      return car;
   }

   static {
      CarFactory var0 = new CarFactory();
      INSTANCE = var0;
      cars = (List)(new ArrayList());
   }
}
```

위의 자바로 변환된 코드를 보면 CarFactory 객체는 INSTANCE라는 static 객체를 생성한다. 그리고 이 객체에 접근할 때는 CarFactory.INSTANCE를 통해서 접근하게 된다. INSTANCE는 static으로 생성되기 때문에 프로그램이 로딩될 때 생성됩니다. 그래서 쓰레드 안전성(thread-safety)이 보장되지만, 내부적으로 공유자원을 사용하는 경우에는 쓰레드 안전성이 보장되지 않기 때문에 동기화(synchronization) 코드를 작성해야 한다.

아무튼, object를 사용하면 객체를 간단하게 싱글톤으로 만들 수 있다. companion object로도 싱글톤으로 구현하는 방법도 있긴 하다.

## 익명객체로 Object 사용

object는 익명객체를 정의할 때도 사용된다. 익명객체는 이름이 없는 객체로, 한번만 사용되고 재사용되지 않는 객체를 말한다. 한번만 쓰이기 때문에 이름조차 필요없다는 의미이다. 

예를들어, 아래와 같이 Vehicle 인터페이스, start() 메소드가 정의되어있다. start()는 Vehicle 객체를 인자로 전달받는다.

```kotlin
interface Vehicle {
    fun drive(): String
}

fun start(vehicle: Vehicle) = println(vehicle.drive())
```

아래 코드에서 start()의 인자로 전달되는 `object : Vehicle{...}`는 익명객체이다. 이 익명객체는 Vehicle 인터페이스를 상속받은 클래스를 객체로 생성된 것을 의미한다. 익명객체이기 때문에 클래스 이름은 없고, 구현부는 `{...}` 안에 정의해야한다.

```kotlin
//start 함수 호출하기 (익명객체 파라미터로 넣기)
start(object : Vehicle {
    override fun drive() = "Driving really fast"
})
```

자바로 변환한 코드는 다음과 같다.

```java
public final class VehicleKt {
   public static final void start(@NotNull Vehicle vehicle) {
      Intrinsics.checkNotNullParameter(vehicle, "vehicle");
      String var1 = vehicle.drive();
      System.out.println(var1);
   }
}
```

object의 사용방법에 대해서 알아보았다. 클래스를 정의할 때 object를 사용하면 싱글턴 패턴이 적용되고, object를 사용하여 익명객체를 생성할 수도 있다는 사실을 알 수 있었다.

java로 변환된 kotlin 코드를 보니, 원리가 더 잘 이해되는 것 같다.