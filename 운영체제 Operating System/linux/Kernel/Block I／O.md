# Block I/O

## 1. 버퍼 헤드

- 블록 장치는 고정된 크기의 데이터에 임의 접근하는 플래시 메모리 같은 HW 장치를 의미한다.
- 블록 장치가 물리적으로 접근하는 최소 단위는 섹터(sector, 약 512-byte)고, 논리적으로 접근하는 최소 단위는 블록(Block)이며 섹터 크기의 배수다.
- 디스크 상의 ‘블록’이 메모리 상에 나타나려면 객체 역할을 하는 ‘버퍼’가 필요하다.
- 커널은 버퍼가 어느 블록 장치의 어떤 블록에 해당하는지 등의 관련 제어 정보를 ‘버퍼 헤드’(buffer_head) 구조체를 사용해서 저장하고 표현하며 `<linux/buffer_head.h>`에 정의돼있다. 

  ```c
  // https://github.com/torvalds/linux/blob/f2e8a57ee9036c7d5443382b6c3c09b51a92ec7e/include/linux/buffer_head.h#L59
  /*
  * Historically, a buffer_head was used to map a single block
  * within a page, and of course as the unit of I/O through the
  * filesystem and block layers.  Nowadays the basic I/O unit
  * is the bio, and buffer_heads are used for extracting block
  * mappings (via a get_block_t call), for tracking state within
  * a page (via a page_mapping) and for wrapping bio submission
  * for backward compatibility reasons (e.g. submit_bh).
  */
  struct buffer_head {
    unsigned long b_state;		/* 해당 버퍼의 현재 상태를 의미하며 여러 플래그 중 하나의 값을 가진다. (see above) */
    struct buffer_head *b_this_page;/* circular list of page's buffers */
    union {
      struct page *b_page;	/* the page this bh is mapped to */
      struct folio *b_folio;	/* the folio this bh is mapped to */
    };

    sector_t b_blocknr;		/* start block number */
    size_t b_size;			/* 블록의 길이(크기) */
    char *b_data;			/* 버퍼가 가리키는 블록 */

    struct block_device *b_bdev;
    bh_end_io_t *b_end_io;		/* I/O completion */
    void *b_private;		/* reserved for b_end_io */
    struct list_head b_assoc_buffers; /* associated with another mapping */
    struct address_space *b_assoc_map;	/* mapping this buffer is
                associated with */
    atomic_t b_count;		/* 버퍼의 사용 횟수를 의미한다. get_bh(), put_bh() 함수로 증감한다. */
    spinlock_t b_uptodate_lock;	/* Used by the first bh in a page, to
            * serialise IO completion of other
            * buffers in the page */
  };
  ```

- 커널 2.6 버전 이전의 버퍼 헤드는 훨씬 크고 모든 블록 I/O 동작까지 책임지는 더 중요한 역할을 맡았다. 하지만, 버퍼 헤드로 블록 I/O를 하는 것은 크고 어려운 작업이었고, 페이지 관점에서 I/O를 하는 것이 보다 간단하고 더 좋은 성능을 보여줬으며, 페이지보다 작은 버퍼를 기술하기 위해 커다란 버퍼 헤드 자료구조를 사용하는 것은 비효율적이었다.
- 따라서 커널 2.6 버전 이후로 버퍼 헤드는 크게 간소화 됐으며, 상당수 커널 작업이 버퍼 대신 페이지와 주소 공간을 직접 다루는 방식으로 바뀌었다.
- 지금의 버퍼 헤드는 디스크 블록과 메모리의 페이지를 연결시켜주는 서술자 역할을 한다.

## 2. bio 구조체

- 거대한 버퍼 헤드의 기능이 간소화되며 블록 I/O 동작은 `<linux/bio.h>`의 bio 구조체가 담당한다.

```c
// https://litux.nl/mirror/kerneldevelopment/0672327201/ch13lev1sec3.html
struct bio {
        sector_t             bi_sector;         /* associated sector on disk */
        struct bio           *bi_next;          /* list of requests */
        struct block_device  *bi_bdev;          /* associated block device */
        unsigned long        bi_flags;          /* status and command flags */
        unsigned long        bi_rw;             /* read or write? */
        unsigned short       bi_vcnt;           /* number of bio_vecs off */
        unsigned short       bi_idx;            /* current index in bi_io_vec */
        unsigned short       bi_phys_segments;  /* number of segments after coalescing */
        unsigned short       bi_hw_segments;    /* number of segments after remapping */
        unsigned int         bi_size;           /* I/O count */
        unsigned int         bi_hw_front_size;  /* size of the first mergeable segment */
        unsigned int         bi_hw_back_size;   /* size of the last mergeable segment */
        unsigned int         bi_max_vecs;       /* maximum bio_vecs possible */
        struct bio_vec       *bi_io_vec;        /* bio_vec list */
        bio_end_io_t         *bi_end_io;        /* I/O completion method */
        atomic_t             bi_cnt;            /* usage counter */
        void                 *bi_private;       /* owner-private method */
        bio_destructor_t     *bi_destructor;    /* destructor method */
};
```

- bio 구조체는 scatter-gather I/O 방식을 사용하므로 개별 버퍼가 메모리 상에 연속되지 않더라도 bio_io_vec 이라는 세그먼트 리스트로 연결해서 표현한다.
  
  <img width="414" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/1be0a936-894d-4a70-85a2-027972ec1001">
  
## 3. 요청 큐 (Request Queue)

- 블록 장치는 대기 중인 블록 I/O 요청을 요청 큐에 저장한다.
- 요청 큐는 `<linux/blkdev.h>`의 request_queue 구조체를 사용해 표현한다.

```c
// https://github.com/torvalds/linux/blob/f2e8a57ee9036c7d5443382b6c3c09b51a92ec7e/include/linux/blkdev.h#L378
struct request_queue {
	struct request		*last_merge;
	struct elevator_queue	*elevator;

	struct percpu_ref	q_usage_counter;

	struct blk_queue_stats	*stats;
	struct rq_qos		*rq_qos;
	struct mutex		rq_qos_mutex;

	const struct blk_mq_ops	*mq_ops;

	/* sw queues */
	struct blk_mq_ctx __percpu	*queue_ctx;

	unsigned int		queue_depth;

	/* hw dispatch queues */
	struct xarray		hctx_table;
	unsigned int		nr_hw_queues;

	/*
	 * The queue owner gets to use this for whatever they like.
	 * ll_rw_blk doesn't touch it.
	 */
	void			*queuedata;

	/*
	 * various queue flags, see QUEUE_* below
	 */
	unsigned long		queue_flags;
	/*
	 * Number of contexts that have called blk_set_pm_only(). If this
	 * counter is above zero then only RQF_PM requests are processed.
	 */
	atomic_t		pm_only;

	/*
	 * ida allocated id for this queue.  Used to index queues from
	 * ioctx.
	 */
	int			id;

	spinlock_t		queue_lock;

	struct gendisk		*disk;

	refcount_t		refs;

	/*
	 * mq queue kobject
	 */
	struct kobject *mq_kobj;

#ifdef  CONFIG_BLK_DEV_INTEGRITY
	struct blk_integrity integrity;
#endif	/* CONFIG_BLK_DEV_INTEGRITY */

#ifdef CONFIG_PM
	struct device		*dev;
	enum rpm_status		rpm_status;
#endif

	/*
	 * queue settings
	 */
	unsigned long		nr_requests;	/* Max # of requests */

	unsigned int		dma_pad_mask;

#ifdef CONFIG_BLK_INLINE_ENCRYPTION
	struct blk_crypto_profile *crypto_profile;
	struct kobject *crypto_kobject;
#endif

	unsigned int		rq_timeout;

	struct timer_list	timeout;
	struct work_struct	timeout_work;

	atomic_t		nr_active_requests_shared_tags;

	struct blk_mq_tags	*sched_shared_tags;

	struct list_head	icq_list;
#ifdef CONFIG_BLK_CGROUP
	DECLARE_BITMAP		(blkcg_pols, BLKCG_MAX_POLS);
	struct blkcg_gq		*root_blkg;
	struct list_head	blkg_list;
	struct mutex		blkcg_mutex;
#endif

	struct queue_limits	limits;

	unsigned int		required_elevator_features;

	int			node;
#ifdef CONFIG_BLK_DEV_IO_TRACE
	struct blk_trace __rcu	*blk_trace;
#endif
	/*
	 * for flush operations
	 */
	struct blk_flush_queue	*fq;
	struct list_head	flush_list;

	struct list_head	requeue_list;
	spinlock_t		requeue_lock;
	struct delayed_work	requeue_work;

	struct mutex		sysfs_lock;
	struct mutex		sysfs_dir_lock;

	/*
	 * for reusing dead hctx instance in case of updating
	 * nr_hw_queues
	 */
	struct list_head	unused_hctx_list;
	spinlock_t		unused_hctx_lock;

	int			mq_freeze_depth;

#ifdef CONFIG_BLK_DEV_THROTTLING
	/* Throttle data */
	struct throtl_data *td;
#endif
	struct rcu_head		rcu_head;
	wait_queue_head_t	mq_freeze_wq;
	/*
	 * Protect concurrent access to q_usage_counter by
	 * percpu_ref_kill() and percpu_ref_reinit().
	 */
	struct mutex		mq_freeze_lock;

	int			quiesce_depth;

	struct blk_mq_tag_set	*tag_set;
	struct list_head	tag_set_list;

	struct dentry		*debugfs_dir;
	struct dentry		*sched_debugfs_dir;
	struct dentry		*rqos_debugfs_dir;
	/*
	 * Serializes all debugfs metadata operations using the above dentries.
	 */
	struct mutex		debugfs_mutex;

	bool			mq_sysfs_init_done;
};
```

- request_queue와 request 그리고 bio와 bio_vec 사이의 복잡한 구조를 도식화한 그림이다. 

  <img width="568" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/09cd5753-643d-4bc4-b902-1e659233e21e">

  - 요청 큐 request_queue 구조체에는 여러 블록 I/O 요청인 request 구조체가 들어있고,
  - 각 request는 (블록 I/O의 동작을 의미하는) 하나 이상의 bio 구조체를 멤버로 가지고 있고,
  - 각 bio 구조체는 bio_vec 배열을 가리키며 이 배열에는 여러 세그먼트가 들어 있을 수 있다.

## 4. 입출력 스케줄러

- 커널은 블록 I/O 요청을 받자마자 바로 요청 큐로 보내지 않고, ​입출력 스케줄러로 대기 중인 블록 I/O 요청들 중 병합할 수 있는 건 합치고 정렬해서 디스크 탐색시간을 최소화 해 시스템 성능을 크게 개선한다. 
- 요쳥 A가 접근하려는 섹터와 요청 B가 접근하려는 섹터가 인접하다면, 합쳐서 하나의 I/O 요청으로 만드는 것이 효율적이다. 한 번의 명령으로 추가 탐색 없이 여러 개의 요청을 처리할 수 있다.
- 병합할 수 있는 요청이 없을 때, 요청 큐 맨 끝에 넣는 것보다, 물리적으로 가까운 섹터에 접근하는 다른 요청 근처에 정렬해 추가한다면 효율적이다.
- 입출력 스케줄러 알고리즘은 우리의 일상생활 속의 ‘엘리베이터 알고리즘’과 상당히 흡사해 실제로 커널 2.4 버전까지 ‘리누스 엘리베이터’라는 이름으로 불렸다.
- 리눅스 커널 2.6 버전은 4가지 입출력 스케줄러 알고리즘​을 제공한다. 

- **데드라인 (Deadline)**
  - 대부분의 사용자는 쓰기보다 읽기 성능에 민감하다. 어떤 읽기 요청 하나가 미처리 상태에 머물면 정체 시스템 지연 시간이 어마어마하게 커질 것이다.
  - 이름 그대로 각 요청에 ‘만료 시간’을 설정한다. 읽기 요청은 0.5초, 쓰기 요청은 5초다.
  - 데드라인 방식은 요청 큐로 FIFO 큐를 사용하는데, 쓰기 FIFO 큐나 읽기 FIFO 큐의 맨 앞 요청이 만료되면 해당 요청을 가장 우선으로 처리한다.
- **예측 (Anticipatory)**
  - 데드라인 방식은 우수한 읽기 성능을 보장하지만 이는 전체 성능 저하의 대가를 감수한 것이다.
  - 예측 방식은 데드라인을 기반으로 휴리스틱하게 동작한다.
  - 읽기 요청이 발생하면 스케줄러는 요청을 처리한 뒤 바로 다른 요청을 처리하러 가지만, 예측 방식에선 수 ms 동안 아무 일도 하지 않는다.
  - 이 시간 동안 사용자로부터 다른 읽기 요청이 계속해서 들어오고, 병합되고, 정렬된다.
  - 대기 시간이 지난 뒤에 스케줄러는 다시 돌아가서 이전 요청 처리를 계속한다.
  - 한 번에 많은 읽기 요청을 처리하기 위해 요청이 추가로 더 들어올 것을 예측하면서 수 ms를 아무것도 안 하고 가만히 있는 이 전략은 의외로 성능을 크게 증가시켰다.
  - 특히, 스케줄러는 여러 입출력 양상 통계값과 휴리스틱을 이용해 애플리케이션과 파일시스템의 동작을 예측해 읽기 요청을 처리하기 때문에 필요한 탐색 시간을 허비하는 일을 크게 줄일 수 있었다.
  - 이 스케줄러는 서버에 이상적인 스케줄러다.
- **완전 공정 큐 (Completely Fair Queueing)**
  - 현재 리눅스의 기본 입출력 스케줄러로, 여러 부하 조건에서 가장 좋은 성능을 보여준다.
  - 입출력 요청을 각 프로세스 별로 할당한 큐에 저장하고, 병합하고, 정렬한다.
  - 각 요청 큐들 사이에서는 round-robin 방식으로 순서대로 미리 설정된 개수(기본값 4개)의 요청을 꺼내 처리한다.
- **무동작 (Noop)**
  - 플래시 메모리와 같이 완벽하게 random-access가 가능한 블록 장치를 위한 스케줄러다.
  - 병합만 하고 정렬이나 기타 탐색 시간 절약을 위한 어떤 동작도 수행하지 않는다.

---
참고
- https://product.kyobobook.co.kr/detail/S000000935348
- https://litux.nl/mirror/kerneldevelopment/0672327201/ch13lev1sec3.html
- https://github.com/torvalds/linux