GeneratedValue는 jakarta에 정의되어있고, Id에 새로운 값을 자동으로 생성해줄 전략을 지정하기 위한 어노테이션이다.

```java
@Target({METHOD, FIELD})
@Retention(RUNTIME)

public @interface GeneratedValue {

    /**
     * (Optional) The primary key generation strategy
     * that the persistence provider must use to
     * generate the annotated entity primary key.
     */
    GenerationType strategy() default AUTO;

    /**
     * (Optional) The name of the primary key generator
     * to use as specified in the {@link SequenceGenerator} 
     * or {@link TableGenerator} annotation.
     * <p> Defaults to the id generator supplied by persistence provider.
     */
    String generator() default "";
}
```

실제로 `@GeneratedValue`가 등록되는 것은
- `org.hibernate.cfg.AnnotationBinder`의 `bindClass`라는 public method에서 호출하는
- `processIdPropertiesIfNotAlready`라는 private method에서 호출하는
- `processElementAnnotations`에서 호출하는 `processId`에서 호출하는
- `BinderHelper.makeIdGenerator`이다.

그 외에도 `bindClass`에서는 Entity를 등록하고 여러 어노테이션을 적용하기 위한 아주 많은 동작들이 이뤄진다.. 코드량이 워낙 방대해서 전부 보긴 힘들지만 한번 보면 괜찮을 것 같은 부분만 추려보았다.

우리의 목적인 **`GeneratedValue`가 어디서 어떻게 나오는지에 대해 유의**하며 코드를 읽어보자. [(javadoc 링크)](https://docs.jboss.org/hibernate/orm/4.3/javadocs/org/hibernate/cfg/AnnotationBinder.html)


```java
// AnnotationBinder.java
	public static void bindClass(
			XClass clazzToProcess,
			Map<XClass, InheritanceState> inheritanceStatePerClass,
			MetadataBuildingContext context) throws MappingException {
		//@Entity and @MappedSuperclass on the same class leads to a NPE down the road
		if ( clazzToProcess.isAnnotationPresent( Entity.class )
				&&  clazzToProcess.isAnnotationPresent( MappedSuperclass.class ) ) {
			throw new AnnotationException( "An entity cannot be annotated with both @Entity and @MappedSuperclass: "
					+ clazzToProcess.getName() );
		}

        // entity의 거의 모든 정보를 담아서 관리하는 객체.
		EntityBinder entityBinder = new EntityBinder(
				entityAnn,
				hibEntityAnn,
				clazzToProcess,
				persistentClass,
				context
		);

        // superEntity 가져옴

		if ( InheritanceType.SINGLE_TABLE.equals( inheritanceState.getType() ) ) {
			discriminatorColumn = processSingleTableDiscriminatorProperties(
					clazzToProcess,
					context,
					inheritanceState,
					entityBinder
			);
		} else if ( InheritanceType.JOINED.equals( inheritanceState.getType() ) ) {
			discriminatorColumn = processJoinedDiscriminatorProperties(
					clazzToProcess,
					context,
					inheritanceState,
					entityBinder
			);
		} else {
			discriminatorColumn = null;
		}

        // Proxy, BatchSize, Where 어노테이션이 있으면 등록해준다.
		entityBinder.setProxy( clazzToProcess.getAnnotation( Proxy.class ) );
		entityBinder.setBatchSize( clazzToProcess.getAnnotation( BatchSize.class ) );
		entityBinder.setWhere( clazzToProcess.getAnnotation( Where.class ) );
		applyCacheSettings( entityBinder, clazzToProcess, context );

        // Lazy, DynamicInsert, DynamicUpdate 등의 정보를 등록한다.
		entityBinder.bindEntity();

		if ( inheritanceState.hasTable() ) {
			Check checkAnn = clazzToProcess.getAnnotation( Check.class );
			String constraints = checkAnn == null
					? null
					: checkAnn.constraints();

			EntityTableXref denormalizedTableXref = inheritanceState.hasDenormalizedTable()
					? context.getMetadataCollector().getEntityTableXref( superEntity.getEntityName() )
					: null;

            // 스키마, Unique 제약조건 등의 table 정보도 entityBinder에 binding 된다.
			entityBinder.bindTable(
					schema,
					catalog,
					table,
					uniqueConstraints,
					constraints,
					denormalizedTableXref
			);
		}

		// todo : sucks that this is separate from RootClass distinction
		final boolean isInheritanceRoot = !inheritanceState.hasParents();
		final boolean hasSubclasses = inheritanceState.hasSiblings();

		if ( InheritanceType.JOINED.equals( inheritanceState.getType() ) ) {
            ...
        }

		Set<String> idPropertiesIfIdClass = new HashSet<>();
		boolean isIdClass = mapAsIdClass(
				inheritanceStatePerClass,
				inheritanceState,
				persistentClass,
				entityBinder,
				propertyHolder,
				elementsToProcess,
				idPropertiesIfIdClass,
				context
		);

		if ( !isIdClass ) {
			entityBinder.setWrapIdsInEmbeddedComponents( elementsToProcess.getIdPropertyCount() > 1 );
		}

        // 여기가 GeneratedValue와 연관있는 부분이다.
		processIdPropertiesIfNotAlready(
				inheritanceStatePerClass,
				context,
				persistentClass,
				entityBinder,
				propertyHolder,
				classGenerators,
				elementsToProcess,
				subclassAndSingleTableStrategy,
				idPropertiesIfIdClass
		);

        ...
        //add process complementary Table definition (index & all)
		entityBinder.processComplementaryTableDefinitions( clazzToProcess.getAnnotation( org.hibernate.annotations.Table.class ) );
		entityBinder.processComplementaryTableDefinitions( clazzToProcess.getAnnotation( org.hibernate.annotations.Tables.class ) );
		entityBinder.processComplementaryTableDefinitions( tabAnn );

		bindCallbacks( clazzToProcess, persistentClass, context ); // entity bind가 끝났음을 알려준다.
    }
```

```java
// AnnotationBinder.java
	private static void processIdPropertiesIfNotAlready(
			Map<XClass, InheritanceState> inheritanceStatePerClass,
			MetadataBuildingContext context,
			PersistentClass persistentClass,
			EntityBinder entityBinder,
			PropertyHolder propertyHolder,
			HashMap<String, IdentifierGeneratorDefinition> classGenerators,
			InheritanceState.ElementsToProcess elementsToProcess,
			boolean subclassAndSingleTableStrategy,
			Set<String> idPropertiesIfIdClass) {

        // IdClass에 지정된 Id List를 저장하고, 하나하나 지워가면서 마지막에 남은게 있으면 AnnotationException을 던진다.
		Set<String> missingIdProperties = new HashSet<>( idPropertiesIfIdClass );

		for ( PropertyData propertyAnnotatedElement : elementsToProcess.getElements() ) {

			String propertyName = propertyAnnotatedElement.getPropertyName();

			if ( !idPropertiesIfIdClass.contains( propertyName ) ) {

                // id인 필드들에 대해서 process 진행
				processElementAnnotations(
						propertyHolder,
						subclassAndSingleTableStrategy
								? Nullability.FORCED_NULL
								: Nullability.NO_CONSTRAINT,
						propertyAnnotatedElement,
						classGenerators,
						entityBinder,
						false,
						false,
						false,
						context,
						inheritanceStatePerClass
				);
			}
			else {
				missingIdProperties.remove( propertyName );
			}
		}

		if ( missingIdProperties.size() != 0 ) {
			StringBuilder missings = new StringBuilder();
			for ( String property : missingIdProperties ) {
				missings.append( property ).append( ", " );
			}
			throw new AnnotationException(
					"Unable to find properties ("
							+ missings.substring( 0, missings.length() - 2 )
							+ ") in entity annotated with @IdClass:" + persistentClass.getEntityName()
			);
		}
    }
```

```java
// AnnotationBinder.java
	private static void processElementAnnotations(
			PropertyHolder propertyHolder,
			Nullability nullability,
			PropertyData inferredData,
			HashMap<String, IdentifierGeneratorDefinition> classGenerators,
			EntityBinder entityBinder,
			boolean isIdentifierMapper,
			boolean isComponentEmbedded,
			boolean inSecondPass,
			MetadataBuildingContext context,
			Map<XClass, InheritanceState> inheritanceStatePerClass) throws MappingException {
            ...
				if ( isId ) {
					//components and regular basic types create SimpleValue objects
					final SimpleValue value = ( SimpleValue ) propertyBinder.getValue();
					if ( !isOverridden ) {
						processId( // Id에 대한 부분을 precess한다.
								propertyHolder,
								inferredData,
								value,
								classGenerators,
								isIdentifierMapper,
								context
						);
					}
				}
            ...
        }
```

```java
// AnnotationBinder.java
	private static void processId(
			PropertyHolder propertyHolder,
			PropertyData inferredData,
			SimpleValue idValue,
			HashMap<String, IdentifierGeneratorDefinition> classGenerators,
			boolean isIdentifierMapper,
			MetadataBuildingContext buildingContext) {
        ...
		//manage composite related metadata
		//guess if its a component and find id data access (property, field etc)
		final boolean isComponent = entityXClass.isAnnotationPresent( Embeddable.class )
				|| idXProperty.isAnnotationPresent( EmbeddedId.class );

		GeneratedValue generatedValue = idXProperty.getAnnotation( GeneratedValue.class );

		String generatorType = generatedValue != null
				? generatorType( generatedValue, buildingContext, entityXClass )
				: "assigned";

		String generatorName = generatedValue != null
				? generatedValue.generator()
				: BinderHelper.ANNOTATION_STRING_DEFAULT;

		if ( isComponent ) {
			//a component must not have any generator
			generatorType = "assigned";
		}
        		if ( isComponent ) {
			//a component must not have any generator
			generatorType = "assigned";
		}

		if ( isGlobalGeneratorNameGlobal( buildingContext ) ) { // global 설정이 있는 경우
			buildGenerators( idXProperty, buildingContext );
			SecondPass secondPass = new IdGeneratorResolverSecondPass(
					idValue,
					idXProperty,
					generatorType,
					generatorName,
					buildingContext
			);
			buildingContext.getMetadataCollector().addSecondPass( secondPass );
		}
		else { // 일반적인 경우
			//clone classGenerator and override with local values
			HashMap<String, IdentifierGeneratorDefinition> localGenerators = (HashMap<String, IdentifierGeneratorDefinition>) classGenerators
					.clone();
			localGenerators.putAll( buildGenerators( idXProperty, buildingContext ) );
			BinderHelper.makeIdGenerator( // BinderHelper를 통해 idGenerator를 만들고 등록시킨다.
					idValue,
					idXProperty,
					generatorType,
					generatorName,
					buildingContext,
					localGenerators
			);
		}
    }
```

```java
// BinderHelper.java
	public static void makeIdGenerator(
			SimpleValue id, // Any value that maps to columns.
			XProperty idXProperty, // reflection을 위한 타입
			String generatorType,
			String generatorName,
			MetadataBuildingContext buildingContext,
			Map<String, IdentifierGeneratorDefinition> localGenerators) {
		log.debugf( "#makeIdGenerator(%s, %s, %s, %s, ...)", id, idXProperty, generatorType, generatorName );

		Table table = id.getTable();
		table.setIdentifierValue( id );
		//generator settings
		id.setIdentifierGeneratorStrategy( generatorType );

		Properties params = new Properties();

		//always settable
		params.setProperty(
				PersistentIdentifierGenerator.TABLE, table.getName()
		);

		if ( id.getColumnSpan() == 1 ) {
			params.setProperty(
					PersistentIdentifierGenerator.PK,
					( (org.hibernate.mapping.Column) id.getColumnIterator().next() ).getName()
			);
		}
		// YUCK!  but cannot think of a clean way to do this given the string-config based scheme
		params.put( PersistentIdentifierGenerator.IDENTIFIER_NORMALIZER, buildingContext.getObjectNameNormalizer() );
		params.put( IdentifierGenerator.GENERATOR_NAME, generatorName );

		if ( !isEmptyAnnotationValue( generatorName ) ) {
			//we have a named generator
			IdentifierGeneratorDefinition gen = getIdentifierGenerator( // generator를 찾아옴
					generatorName,
					idXProperty,
					localGenerators,
					buildingContext
			);
			if ( gen == null ) {
				throw new AnnotationException( "Unknown named generator (@GeneratedValue#generatorName): " + generatorName );
			}
			//This is quite vague in the spec but a generator could override the generator choice
			String identifierGeneratorStrategy = gen.getStrategy(); // stratge를 가쳐옴

			//yuk! this is a hack not to override 'AUTO' even if generator is set
			final boolean avoidOverriding =
					identifierGeneratorStrategy.equals( "identity" )
							|| identifierGeneratorStrategy.equals( "seqhilo" )
							|| identifierGeneratorStrategy.equals( MultipleHiLoPerTableGenerator.class.getName() );

			if ( generatorType == null || !avoidOverriding ) {
				id.setIdentifierGeneratorStrategy( identifierGeneratorStrategy );
			}

			//checkIfMatchingGenerator(gen, generatorType, generatorName);
			for ( Object o : gen.getParameters().entrySet() ) {
				Map.Entry elt = (Map.Entry) o;
				if ( elt.getKey() == null ) {
					continue;
				}
				params.setProperty( (String) elt.getKey(), (String) elt.getValue() );
			}
		}
		if ( "assigned".equals( generatorType ) ) {
			id.setNullValue( "undefined" );
		}
		id.setIdentifierGeneratorProperties( params );
	}
```

위에서 `SimpleValue id`에 set했던 부분은 field로 저장된다. id가 값 세팅받는 부분들을 보면, 중요한 정보를 많이 담고있다는 것을 알 수 있다.

- `Table table = id.getTable(); table.setIdentifierValue( id );`
- `id.setIdentifierGeneratorStrategy( generatorType );`
- `id.setIdentifierGeneratorStrategy( identifierGeneratorStrategy );`
- `id.setIdentifierGeneratorProperties( params );`

```java
// SimpleValue.java
public class SimpleValue implements KeyValue {
	private static final CoreMessageLogger log = CoreLogging.messageLogger( SimpleValue.class );

	public static final String DEFAULT_ID_GEN_STRATEGY = "assigned";

	private final MetadataImplementor metadata;

	private final List<Selectable> columns = new ArrayList<>();
	private final List<Boolean> insertability = new ArrayList<>();
	private final List<Boolean> updatability = new ArrayList<>();

	private String typeName;
	private Properties typeParameters;
	private boolean isVersion;
	private boolean isNationalized;
	private boolean isLob;

	private Properties identifierGeneratorProperties;
	private String identifierGeneratorStrategy = DEFAULT_ID_GEN_STRATEGY;
	private String nullValue;
	private Table table;
	private String foreignKeyName;
	private String foreignKeyDefinition;
	private boolean alternateUniqueKey;
	private boolean cascadeDeleteEnabled;

	private ConverterDescriptor attributeConverterDescriptor;
	private Type type;
	...
}
```

이렇게 생성된 SimpleValue는 `SessionFactoryImpl`의 생성자에서 가져오고, `IdentifierGenerator`의 `identifierGeneratorProperties`에 SimpleValue param들이 넣어져서 `identifierGenerators`로 등록된다. 이렇게 생성된 SessionFactory는 애플리케이션 전체에서 Session을 만들때 사용되므로, 전체에 적용된다 생각할 수 있다.

```java
// SessionFactoryImpl.java
	public SessionFactoryImpl(
			final MetadataImplementor metadata,
			SessionFactoryOptions options,
			QueryPlanCache.QueryPlanCreator queryPlanCacheFunction) {
		LOG.debug( "Building session factory" );

		this.sessionFactoryOptions = options;
		this.settings = new Settings( options, metadata );
		...
		try {
			for ( Integrator integrator : serviceRegistry.getService( IntegratorService.class ).getIntegrators() ) {
				integrator.integrate( metadata, this, this.serviceRegistry );
				integratorObserver.integrators.add( integrator );
			}
			//Generators:
			this.identifierGenerators = new HashMap<>();
			metadata.getEntityBindings().stream().filter( model -> !model.isInherited() ).forEach( model -> {
				// 이 createIdentifierGenerator라는 함수에서 SimpleValue에 있던 param들을 IdentifierGenerator의 identifierGeneratorProperties로 등록시킨다.
				IdentifierGenerator generator = model.getIdentifier().createIdentifierGenerator(
						metadata.getIdentifierGeneratorFactory(),
						jdbcServices.getJdbcEnvironment().getDialect(),
						(RootClass) model
				);
				generator.initialize( sqlStringGenerationContext );
				identifierGenerators.put( model.getEntityName(), generator );
			} );
			metadata.validate();
		}
		...
	}
```

이렇게 저장된 `identifierGenerators`는 엔티티에서 사용될 기본 정보인 `EntityMetamodel`에 `IdentifierProperty`(ID에 대한 설정 정보 클래스) 형태로 담긴다.

원래 String으로 저장되어있던 설정 정보가 `createIdentifierGenerator`에서 클래스 참조로 바뀐다. `IdentifierGenerator`를 상속받아서 구현한 경우, 저 안에서 스캔되어서 들어간다고 생각하면 된다.

<details>
<summary>`IdentigierGenerator` 코드 보기</summary>

```java
/**
 * The general contract between a class that generates unique
 * identifiers and the <tt>Session</tt>. It is not intended that
 * this interface ever be exposed to the application. It <b>is</b>
 * intended that users implement this interface to provide
 * custom identifier generation strategies.<br>
 * <br>
 * Implementors should provide a public default constructor.<br>
 * <br>
 * Implementations that accept configuration parameters should
 * also implement <tt>Configurable</tt>.
 * <br>
 * Implementors <em>must</em> be thread-safe
 *
 * @author Gavin King
 *
 * @see PersistentIdentifierGenerator
 */
public interface IdentifierGenerator extends Configurable, ExportableProducer {

	String ENTITY_NAME = "entity_name";
	String JPA_ENTITY_NAME = "jpa_entity_name";
	String GENERATOR_NAME = "GENERATOR_NAME";

	@Override
	default void configure(Type type, Properties params, ServiceRegistry serviceRegistry) throws MappingException {
	}

	@Override
	default void registerExportables(Database database) {
	}

	default void initialize(SqlStringGenerationContext context) {
	}

	Serializable generate(SharedSessionContractImplementor session, Object object) throws HibernateException;

	default boolean supportsJdbcBatchInserts() {
		return true;
	}
}
```

</details>

그 entity metadata는 `EntityPersister`라는 곳에 담겨서 `StatelessSession`에서 `insert`가 호출될때, 같이 generate된다.

```java
public abstract class AbstractEntityPersister
		implements OuterJoinLoadable, Queryable, ClassMetadata, UniqueKeyLoadable,
		SQLLoadable, LazyPropertyInitializer, PostInsertIdentityPersister, Lockable {
	...
	public IdentifierGenerator getIdentifierGenerator() throws HibernateException {
		return entityMetamodel.getIdentifierProperty().getIdentifierGenerator();
	}
	...
}
```

```java
// StatelessSessionImpl.java
	@Override
	public Serializable insert(String entityName, Object entity) {
		checkOpen();
		EntityPersister persister = getEntityPersister( entityName, entity );
		Serializable id = persister.getIdentifierGenerator().generate( this, entity ); // 호출되는 부분

		Object[] state = persister.getPropertyValues( entity );
		if ( persister.isVersioned() ) {
			boolean substitute = Versioning.seedVersion(
					state,
					persister.getVersionProperty(),
					persister.getVersionType(),
					this
			);
			if ( substitute ) {
				persister.setPropertyValues( entity, state );
			}
		}
		if ( id == IdentifierGeneratorHelper.POST_INSERT_INDICATOR ) {
			id = persister.insert( state, entity, this );
		}
		else {
			persister.insert( id, state, entity, this );
		}
		persister.setIdentifier( entity, id, this );
		return id;
	}
```