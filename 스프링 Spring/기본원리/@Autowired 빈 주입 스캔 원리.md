
```java
    // AutowiredAnnotationBeanPostProcessor#buildAutowiringMetadata
    // Autowiring을 해야하는지 여부를 확인하고, 주입 메타데이터를 반환하는 함수

	private InjectionMetadata buildAutowiringMetadata(Class<?> clazz) { 
		if (!AnnotationUtils.isCandidateClass(clazz, this.autowiredAnnotationTypes)) {
			return InjectionMetadata.EMPTY; // Autowired 어노테이션을 가지고 있지 않은 클래스는 Empty를 반환한다.
		}

		List<InjectionMetadata.InjectedElement> elements = new ArrayList<>();
		Class<?> targetClass = clazz;

		do {
			final List<InjectionMetadata.InjectedElement> currElements = new ArrayList<>();

			ReflectionUtils.doWithLocalFields(targetClass, field -> {
				MergedAnnotation<?> ann = findAutowiredAnnotation(field); // Autowired 어노테이션이 붙은 필드를 찾아온다.
				if (ann != null) { // Autowired 어노테이션이 존재하는 필드라면
					if (Modifier.isStatic(field.getModifiers())) { // static이 아닌지 확인하고, static이면 빈 값을 반환한다.
						if (logger.isInfoEnabled()) {
							logger.info("Autowired annotation is not supported on static fields: " + field);
						}
						return;
					}
					boolean required = determineRequiredStatus(ann); // requeired인지 (꼭 여기서 주입해야하는지) 확인
					currElements.add(new AutowiredFieldElement(field, required)); // 주입할 필드로 저장해놓는다.
				}
			});

			ReflectionUtils.doWithLocalMethods(targetClass, method -> {
				Method bridgedMethod = BridgeMethodResolver.findBridgedMethod(method);
				if (!BridgeMethodResolver.isVisibilityBridgeMethodPair(method, bridgedMethod)) {
					return;
				}
				MergedAnnotation<?> ann = findAutowiredAnnotation(bridgedMethod); // Autowired 어노테이션이 붙은 bridgedMethod를 찾아온다.
				if (ann != null && method.equals(ClassUtils.getMostSpecificMethod(method, clazz))) { // abstact가 아니면
					if (Modifier.isStatic(method.getModifiers())) { // static이 아닌지 확인하고,
						if (logger.isInfoEnabled()) {
							logger.info("Autowired annotation is not supported on static methods: " + method);
						}
						return;
					}
					if (method.getParameterCount() == 0) { // 파라미터가 존재하는지 확인하고,
						if (logger.isInfoEnabled()) {
							logger.info("Autowired annotation should only be used on methods with parameters: " +
									method);
						}
					}
					boolean required = determineRequiredStatus(ann); // requeired인지를 확인해서
					PropertyDescriptor pd = BeanUtils.findPropertyForMethod(bridgedMethod, clazz); // 빈이 존재하는지 조회하고 정보를 받아온다음
					currElements.add(new AutowiredMethodElement(method, required, pd));  // 주입할 메서드로 저장해놓는다.
				}
			});

			elements.addAll(0, currElements); // elements에 옮긴다.
			targetClass = targetClass.getSuperclass(); // 상위클래스로 올라가면서 탐색한다. (Object에서 멈춤)
		}
		while (targetClass != null && targetClass != Object.class);

		return InjectionMetadata.forElements(elements, clazz); // metadata로 변환하여 반환.
	}

    protected boolean determineRequiredStatus(MergedAnnotation<?> ann) { // requeired인지 (꼭 여기서 주입해야하는지) 확인하는 메서드
		return determineRequiredStatus(ann.<AnnotationAttributes> asMap(
			mergedAnnotation -> new AnnotationAttributes(mergedAnnotation.getType())));
	}
```