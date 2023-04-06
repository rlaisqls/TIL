# MongoDB Document로 POJO 상속받기

REPO 코드를 짜던중, Document로 설정할 객체가 POJO를 상속받는 구조가 필요해졌다.

Querydsl과 mongoDB 설정에 대한 이해 부족으로 긴 삽질을 경험했다.

## 첫번째 시도 : 생성자로 받기

```kotlin
class DocumentJpaEntity(
    id: UUID,
    year: Int,
    writer: WriterInfoElement,
    status: DocumentStatus,
    introduce: IntroduceElement,
    skillSet: MutableList<String>,
    projectList: MutableList<ProjectElement>,
    awardList: MutableList<AwardElement>,
    certificateList: MutableList<CertificateElement>,
    isDeleted: Boolean
) : Document(
    id = id,
    year = year,
    writer = writer,
    status = status,
    introduce = introduce,
    skillSet = skillSet,
    projectList = projectList,
    awardList = awardList,
    certificateList = certificateList,
    isDeleted = isDeleted
)
```

mongoDB에서 Document 필드 인식할때 그냥 이런식으로 생성자로만 받도록 짜면 부모의 필드까지 스캔해서 만들어주기 때문에 이렇게 하려고 했는데 queryDSL 쪽에서 문제가 생겼다.

Qclass가 embeded된 별도 객체로 생성이 돼야하는데 SimplePath로 만들어져서 dsl을 통한 퀴리가 불가능해졌다. 필드가 @Document 어노테이션을 단 클래스랑 다른 곳에 정의되어 있어서 스캔이 잘못 되는 것 아닐까 싶었다.

## 두번째 시도 : override

두번째로 `override val`로 `@Document` 어노테이션이 달린 클래스에서 재정의 하는 방법을 생각했다. 

이렇게 하는 경우 Querydsl Qclass는 잘 생성되지만 `MongoPersistentProperty`를 생성하는 과정에서 부모 필드와, 자식에서 override한 필드를 또 다시 스캔하는 문제가 생겼다.

Kotlin tool을 사용해 decompile해보면 실제로는 아래와 같이 생성된다.

<img width="852" alt="image" src="https://user-images.githubusercontent.com/81006587/230023411-01650afb-aa89-4e3d-9c8e-eaec00e946bb.png">

사실 곰곰히 생각해보니까 필드 재정의라는 것은 자바에 존재하지 않는 개념이었다. `override val`을 사용하면 필드가 따로 생겨서 super 생성자를 호출할때 똑같이 넣어주는건 맞지만, 내부를 살펴보면 그냥 동일한 이름의 필드가 생성되는 것이다.

하지만 Querydsl Qclass 상에는 필드가 정상적으로 하나만 생긴다. 굉장히 모순적인 일이 아닐 수가 없다.

자세히 살펴보니, Querydsl에서는 도메인인 부모 클래스만 스캔해서 필드를 넣고, Spring data mongoDB에선 부모와 자식 클래스의 필드를 모두 스캔해서 필드를 넣기 때문에 문제가 생기는 것 같았다. Domain에 `@Transient`를 붙이면 Querydsl에 writer에 대한 정보가 등록되지 않고 있었다.

```kotlin
    @field:Transient
    val writer: WriterInfoElement,
```

이에 착안하여, 다른 방법을 생각해보기로 했다.

## 세번째 시도 : @QueryEmbedded

> https://stackoverflow.com/questions/41391206/querydsl-4-stringexpression-of-a-field-inside-a-simplepath

SimplePath에 대해 검색하다 `@QueryEmbedded`와 `@QueryEmbeddable`에 대한 글을 발견했다. 해당 어노테이션을 써주면 SimplePath로 등록되지 않고 별도의 Qclass로 생성되어 쿼리가 가능해진다는 것 이었다.

하지만 이 어노테이션을 사용하려면 Entity 클래스에서 필드를 override 해야 했기 때문에 재정의 오류는 동일하게 발생했다. 

머리가 아파지기 시작했다.. 그냥 POJO Domain을 상속 받는 구조를 포기하면 문제가 없을 것이다. Querydsl은 상위 필드를 스캔하고, spring data는 상하위의 모든 필드를 스캔하는데, 이 구조를 유지할 수 있는 방법이 있을까? 

지금 상태에서 찾을 수 있는 방향은 두가지가 있다.

### 1. 필드를 `override` 하고 `@QueryEmbedded` 붙이기. 그리고 필드 재정의 막기.
   - 하지만 막을 수 있는 방법이 과연 있을지 모르겠다.
   - mongoDB에서 프로퍼티 등록하는 프로세스를 보니, Getter와 Setter가 둘다 없으면 프로퍼티로 등록하지 않는 것 같아 보였다. 근데 Document 도메인에 Getter Setter가 있으면 그걸 상속받는 엔티티에서도 Getter Setter를 가질 수 밖에 없디.

```java
		/**
		 * Adds {@link PersistentProperty} instances for all suitable {@link PropertyDescriptor}s without a backing
		 * {@link Field}.
		 *
		 * @see PersistentPropertyFilter
		 */
		public void addPropertiesForRemainingDescriptors() {

			remainingDescriptors.values().stream() //
					.filter(Property::supportsStandalone) //
					.map(it -> Property.of(entity.getTypeInformation(), it)) //
					.filter(PersistentPropertyFilter.INSTANCE::matches) //
					.forEach(this::createAndRegisterProperty);
		}
```

```kotlin
		/**
		 * Returns whether the given {@link PropertyDescriptor} is one to create a {@link PersistentProperty} for.
		 *
		 * @param property must not be {@literal null}.
		 * @return
		 */
		public boolean matches(Property property) {

			Assert.notNull(property, "Property must not be null");

			if (!property.hasAccessor()) {
				return false;
			}

			return !UNMAPPED_PROPERTIES.stream()//
					.anyMatch(it -> it.matches(property.getName(), property.getType()));
		}
```

```kotlin
	public boolean hasAccessor() {
		return getGetter().isPresent() || getSetter().isPresent();
	}
```

2. 필드를 `override` 하지 않고 스캔을 통해 `@QueryEmbedded`이나 `@QueryEmbeddable` 어노테이션을 간접적으로 주입하기.
- 스프링에서 빈 주입하는 부분을 `ComponentScanConfig`로 처리해주는 것 처럼, 이 친구로 runtime에 어노테이션을 동적으로 삽입 혹은 주입해줄 수 있다면 되지 않을까? 라는 생각이 떠올랐다.
- 하지만 빈 주입은 스프링에서 자동으로 처리해주는 작업이고, 그냥 어노테이션을 runtime에 주입해주려면 또 다른 라이브러리를 사용해야했다.

3. 그냥 Entity용 Element를 따로 만들기

기존에 Document가 아닌 Element들은 도메인 모듈에서 구현했던 클래스를 그대로 사용했었는데, 이걸 엔티티처럼 분리해주면 되는거 아닐까? 하는 생각이 들었다.

## 네번째 시도 : 클래스 분리

최종적으로 짠 코드는 아래와 같다.

사실 논리적으로는 MongoDB Entity로 들어가는 class를 따로 정의한다는 것이 이상하진 않아서, 나름 타협할만한 방안이라고 생각한다.

spring data mongoDB는 모든 필드를 스캔하고, Querydsl은 일부 필드만 스캔하는 이유가 무엇인지, 그리고 `@QueryEmbeddable`을 붙였을떄 Querydsl에서 스캔하는 필드 대상이 달라지는 것인지 여부는 아직 잘 모르겠다. 정확한 원인에 대한 해결 없이 넘어가는 느낌이라 찝찝하다.

```kotlin
@org.springframework.data.mongodb.core.mapping.Document(collection = "documents")
@Where(clause = "is_deleted is false")
class DocumentJpaEntity(
    id: UUID,
    year: Int,
    writer: WriterInfoJpaElement,
    status: DocumentStatus,
    introduce: IntroduceJpaElement,
    skillSet: MutableList<String>,
    projectList: MutableList<ProjectJpaElement>,
    awardList: MutableList<AwardJpaElement>,
    certificateList: MutableList<CertificateJpaElement>,
    isDeleted: Boolean
) : Document(
    id = id,
    year = year,
    writer = writer as WriterInfoElement,
    status = status,
    introduce = introduce as IntroduceElement,
    skillSet = skillSet,
    projectList = projectList as MutableList<ProjectElement>,
    awardList = awardList as MutableList<AwardElement>,
    certificateList = certificateList as MutableList<CertificateElement>,
    isDeleted = isDeleted
) {
    companion object {
        fun of(document: Document) = document.run {
            DocumentJpaEntity(
                id = id,
                year = year,
                writer = WriterInfoJpaElement.of(writer),
                status = status,
                introduce = IntroduceJpaElement.of(introduce),
                skillSet = skillSet,
                projectList = projectList.map { ProjectJpaElement.of(it) }.toMutableList(),
                awardList = awardList.map { AwardJpaElement.of(it) }.toMutableList(),
                certificateList = certificateList.map { CertificateJpaElement.of(it) }.toMutableList(),
                isDeleted = isDeleted
            )
        }
    }
}
```

```kotlin
@QueryEmbeddable
class WriterInfoJpaElement(

    elementId: UUID,

    studentId: UUID,
    name: String,
    email: String,
    profileImagePath: String,

    grade: String,
    classNum: String,
    number: String,

    majorId: UUID,
    majorName: String

) : WriterInfoElement(
    elementId, studentId, name, email, profileImagePath, grade, classNum, number, majorId, majorName
) {
    companion object {
        fun of(writer: WriterInfoElement) = writer.run {
            WriterInfoJpaElement(
                elementId, studentId, name, email, profileImagePath, grade, classNum, number, majorId, majorName
            )
        }
    }
}
```

## 느낀점

처음에 도메인을 나누고 Hexagonal Architecture로 책임을 분리하면서 똑같은 필드를 매핑하는 코드를 줄이고 싶었는데, 결국 상속과 클래스 변환 때문에 똑같이 이런 코드를 작성하게 되었다. 오류를 해결하게 되어서 기쁘긴 하지만, 뭔가 더 깔끔하게 할 수 있는 방법이 있지 않았을까 하는 생각이 든다.

low level 원리에 대한 이해가 더 있다면 보다 근본적인 접근이 가능했을텐데 우회책만 찾은 것 같아 아쉽다. 나중에 더 생각해볼 부분이 있는 것 같다.