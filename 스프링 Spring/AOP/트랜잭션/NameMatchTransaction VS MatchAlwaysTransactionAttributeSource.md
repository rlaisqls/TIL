# 🍃 MatchAlwaysTransactionAttributeSource<br/>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;VS NameMatchTransactionAttributeSource

위 두개의 클래스는 모두 `TransactionAttributeSource` 인터페이스의 구현체이다

`TransactionAttributeSource`는 TransactionInterceptor의 메타 데이터 검색에 사용되는 전략 인터페이스인데, 트렌잭션의 메타데이터나 속성을 소싱하는 역할을 한다.

```java
public interface TransactionAttributeSource {

	default boolean isCandidateClass(Class<?> targetClass) {
		return true;
	}

	@Nullable
	TransactionAttribute getTransactionAttribute(Method method, @Nullable Class<?> targetClass);

}
```

코드를 보면 트랜잭션 속성의 후보인지(트랜잭션을 적용할 클래스인지) 여부를 반환하는 `isCandidateClass`와, 트랜잭션의 속성(TracsactionAttribute)을 반환하는 `getTransactionAttribute`라는 메서드가 있는 것을 볼 수 있다.

그렇다면 각각의 구현 클래스는 어떤 특징을 가지고 있을까?

# `MatchAlwaysTransactionAttributeSource`

TransactionAttributeSource의 매우 간단한 구현으로, 공급된 모든 메서드에 대해 항상 동일한 TransactionAttribute를 반환하는 구현체이다. TransactionAttribute를 지정할 수 있지만 그렇지 않으면 PRAGATION_REQUERED로 기본 설정된다. 트랜잭션 인터셉터에 의해 처리되는 모든 메서드와 동일한 트랜잭션 속성을 사용하려는 경우에 사용할 수 있다.

```java
public class MatchAlwaysTransactionAttributeSource implements TransactionAttributeSource, Serializable {

	private TransactionAttribute transactionAttribute = new DefaultTransactionAttribute();

	public void setTransactionAttribute(TransactionAttribute transactionAttribute) {
		if (transactionAttribute instanceof DefaultTransactionAttribute) {
			((DefaultTransactionAttribute) transactionAttribute).resolveAttributeStrings(null);
		}
		this.transactionAttribute = transactionAttribute;
	}

	@Override
	@Nullable
	public TransactionAttribute getTransactionAttribute(Method method, @Nullable Class<?> targetClass) {
		return (ClassUtils.isUserLevelMethod(method) ? this.transactionAttribute : null);
	}

    ...
}
```

## `NameMatchTransactionAttributeSource`

등록된 이름으로 속성을 일치시킬 수 있는 간단한 구현체이다. 여러개의 트랜잭션 규칙을 이름을 통해 구분짓는다.

```java
public class NameMatchTransactionAttributeSource
		implements TransactionAttributeSource, EmbeddedValueResolverAware, InitializingBean, Serializable {

	protected static final Log logger = LogFactory.getLog(NameMatchTransactionAttributeSource.class);

	/** Keys are method names; values are TransactionAttributes. */
	private final Map<String, TransactionAttribute> nameMap = new HashMap<>();

	@Nullable
	private StringValueResolver embeddedValueResolver;

	public void setNameMap(Map<String, TransactionAttribute> nameMap) {
		nameMap.forEach(this::addTransactionalMethod);
	}

	public void setProperties(Properties transactionAttributes) {
		TransactionAttributeEditor tae = new TransactionAttributeEditor();
		Enumeration<?> propNames = transactionAttributes.propertyNames();
		while (propNames.hasMoreElements()) {
			String methodName = (String) propNames.nextElement();
			String value = transactionAttributes.getProperty(methodName);
			tae.setAsText(value);
			TransactionAttribute attr = (TransactionAttribute) tae.getValue();
			addTransactionalMethod(methodName, attr);
		}
	}

	public void addTransactionalMethod(String methodName, TransactionAttribute attr) {
		if (logger.isDebugEnabled()) {
			logger.debug("Adding transactional method [" + methodName + "] with attribute [" + attr + "]");
		}
		if (this.embeddedValueResolver != null && attr instanceof DefaultTransactionAttribute) {
			((DefaultTransactionAttribute) attr).resolveAttributeStrings(this.embeddedValueResolver);
		}
		this.nameMap.put(methodName, attr);
	}

	@Override
	public void setEmbeddedValueResolver(StringValueResolver resolver) {
		this.embeddedValueResolver = resolver;
	}

	@Override
	public void afterPropertiesSet()  {
		for (TransactionAttribute attr : this.nameMap.values()) {
			if (attr instanceof DefaultTransactionAttribute) {
				((DefaultTransactionAttribute) attr).resolveAttributeStrings(this.embeddedValueResolver);
			}
		}
	}

	@Override
	@Nullable
	public TransactionAttribute getTransactionAttribute(Method method, @Nullable Class<?> targetClass) {
		if (!ClassUtils.isUserLevelMethod(method)) {
			return null;
		}

		// Look for direct name match.
		String methodName = method.getName();
		TransactionAttribute attr = this.nameMap.get(methodName);

		if (attr == null) {
			// Look for most specific name match.
			String bestNameMatch = null;
			for (String mappedName : this.nameMap.keySet()) {
				if (isMatch(methodName, mappedName) &&
						(bestNameMatch == null || bestNameMatch.length() <= mappedName.length())) {
					attr = this.nameMap.get(mappedName);
					bestNameMatch = mappedName;
				}
			}
		}

		return attr;
	}

	protected boolean isMatch(String methodName, String mappedName) {
		return PatternMatchUtils.simpleMatch(mappedName, methodName);
	}

    ...
}
```


