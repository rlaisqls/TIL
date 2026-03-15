
  tracemalloc 구현 계획: CPython vs RustPython

  CPython 구조

  [Python 레벨]  Lib/tracemalloc.py    ← Snapshot, Filter, 통계 등 순수
  Python API
                      │
                      ▼
  [C 레벨]       _tracemalloc.c        ← start/stop/get_traces 등
  네이티브 함수
                      │
                      ▼
  [할당자 훅]    PyMem_SetAllocator()  ← malloc/realloc/free 래핑
                      │
                      ▼
  [저장소]       hashtable (ptr → trace_t{size, traceback})

  CPython은 PyMem_SetAllocator()로 3개 도메인(RAW/MEM/OBJ)의 할당자를
  래핑합니다. 모든 malloc/free가 이 래퍼를 통과하면서 자동으로
  추적됩니다.

  RustPython 대응 구조

  [Python 레벨]  Lib/tracemalloc.py      ← CPython에서 복사 (그대로
  재사용)
                      │
                      ▼
  [Rust 모듈]    _tracemalloc.rs         ← 새로 작성 (10개 함수)
                      │
                      ▼
  [할당 훅]      PyRef::new_ref() 내부   ← AtomicBool 가드 +
  record_alloc()
                 PyObject::drop_slow()   ← record_dealloc()
                      │
                      ▼
  [저장소]       TraceMallocState (전역)  ← HashMap<usize, TraceEntry>

  ---
  수정 대상 파일 목록

  1. 새로 생성하는 파일

  crates/vm/src/stdlib/_tracemalloc.rs — 핵심 모듈

  ```python
  #[pymodule]
        mod _tracemalloc {
            // 10개 함수 구현
            #[pyfunction]
            fn start(nframe: OptionalArg<i32>, vm: &VirtualMachine) ->
        PyResult<()>;
            #[pyfunction]
            fn stop(vm: &VirtualMachine) -> PyResult<()>;
            #[pyfunction]
            fn is_tracing() -> bool;
            #[pyfunction]
            fn clear_traces();
            #[pyfunction]
            fn get_traces(vm: &VirtualMachine) -> PyResult;          // list
        of (domain, size, traceback_tuple)
            #[pyfunction]
            fn get_object_traceback(obj: PyObjectRef) -> Option<PyTupleRef>;
            #[pyfunction]
            fn get_traced_memory() -> (usize, usize);                //
        (current, peak)
            #[pyfunction]
            fn reset_peak();
            #[pyfunction]
            fn get_traceback_limit() -> i32;
            #[pyfunction]
            fn get_tracemalloc_memory() -> usize;
        }
  ```

  crates/vm/src/stdlib/tracemalloc_state.rs — 추적 상태 관리

  ```python
  use std::sync::atomic::{AtomicBool, AtomicUsize, Ordering};
        use parking_lot::Mutex;
      
        /// 전역 활성화 플래그 — hot path에서 체크
        /// PyRef::new_ref()에서 Ordering::Relaxed로 읽음
        pub static TRACEMALLOC_ENABLED: AtomicBool = AtomicBool::new(false);
      
        pub struct TraceEntry {
            pub size: usize,
            pub domain: u8,
            pub traceback: Vec<FrameInfo>,  // (filename, lineno) 목록
        }
      
        pub struct FrameInfo {
            pub filename: String,   // interning은 추후 최적화
            pub lineno: u32,
        }
      
        pub struct TraceMallocState {
            pub nframe: u32,                              // traceback 프레임
        수 제한
            pub traces: HashMap<usize, TraceEntry>,       // ptr_addr →
        TraceEntry
            pub traced_memory: usize,                     // 현재 추적 중인
        메모리
            pub peak_traced_memory: usize,                // 피크 메모리
        }
      
        /// Mutex로 보호 — 할당/해제 시에만 접근 (활성화 상태에서만)
        static TRACEMALLOC_STATE: Mutex<TraceMallocState> = ...;
  ```

  2. 수정하는 파일

  crates/vm/src/object/core.rs — 할당 훅 (2곳)

  ```python
  PyRef::new_ref() (line ~2224, GC 추적 후):
        // 기존 코드 끝 부분:
        if <T as MaybeTraverse>::HAS_TRAVERSE || has_dict || is_heaptype {
            let gc = gc_state();
            unsafe { gc.track_object(ptr.cast()); }
            gc.maybe_collect();
        }
      
        // 추가할 코드:
        if crate::stdlib::tracemalloc_state::TRACEMALLOC_ENABLED.load(Ordering
        ::Relaxed) {
            let size = core::mem::size_of::<PyInner<T>>();
            let ptr_addr = ptr.as_ptr() as usize;
            crate::stdlib::tracemalloc_state::record_allocation(ptr_addr,
        size);
        }
      
        Self { ptr }
      
        PyObject::drop_slow() (line ~1654):
        unsafe fn drop_slow(ptr: NonNull<Self>) {
            // 추가할 코드:
            if crate::stdlib::tracemalloc_state::TRACEMALLOC_ENABLED.load(Orde
        ring::Relaxed) {
                let ptr_addr = ptr.as_ptr() as usize;
      
        crate::stdlib::tracemalloc_state::record_deallocation(ptr_addr);
            }
      
            // 기존 코드:
            let dealloc = unsafe { ptr.as_ref().0.vtable.dealloc };
            unsafe { dealloc(ptr.as_ptr()) }
        }
  ```

  crates/vm/src/stdlib/mod.rs — 모듈 등록 (2곳)

  ```python
  // 파일 상단에 mod 선언 추가:
        mod _tracemalloc;
        pub(crate) mod tracemalloc_state;
      
        // builtin_module_defs() 함수 내에 추가:
        _tracemalloc::module_def(ctx),
  ```

  Lib/tracemalloc.py — CPython에서 복사

  CPython v3.14.3의 Lib/tracemalloc.py를 그대로 복사. 이 파일은
  _tracemalloc을 import해서 Python 레벨 API(Snapshot, Filter, Statistic
  등)를 제공합니다.

  ---
  CPython과 RustPython의 차이점 상세

  ┌───────────┬──────────────────────┬──────────────────────────────┐
  │   항목    │       CPython        │          RustPython          │
  ├───────────┼──────────────────────┼──────────────────────────────┤
  │           │ PyMem_SetAllocator() │ PyRef::new_ref() +           │
  │ 할당자 훅 │  —                   │ drop_slow() — 객체 생성/해제 │
  │           │ malloc/realloc/free  │  2곳                         │
  │           │ 3개를 래핑           │                              │
  ├───────────┼──────────────────────┼──────────────────────────────┤
  │ 훅 지점   │ C 할당자 레벨        │ Rust 객체 레벨 (Python       │
  │           │ (바이트 단위 정확)   │ 객체만 추적)                 │
  ├───────────┼──────────────────────┼──────────────────────────────┤
  │ 비활성 시 │ 훅 자체를 설치/제거  │ AtomicBool 체크로 건너뜀     │
  ├───────────┼──────────────────────┼──────────────────────────────┤
  │ 프레임    │ PyEval_GetFrame() —  │ thread::get_current_frame()  │
  │ 접근      │ 항상 사용 가능       │ — AtomicPtr, VM 없이 접근    │
  ├───────────┼──────────────────────┼──────────────────────────────┤
  │ 프레임    │ frame->f_back 체인   │ frame.previous_frame()       │
  │ 워킹      │                      │ AtomicPtr 체인               │
  ├───────────┼──────────────────────┼──────────────────────────────┤
  │ 크기 계산 │ malloc에 전달된      │ mem::size_of::<PyInner<T>>() │
  │           │ 정확한 size          │  (내부 힙 할당 미포함)       │
  ├───────────┼──────────────────────┼──────────────────────────────┤
  │ 도메인    │ RAW/MEM/OBJ 3개      │ 도메인 0 하나만 (Python      │
  │           │ 도메인               │ 객체만)                      │
  ├───────────┼──────────────────────┼──────────────────────────────┤
  │ 동기화    │ TABLES_LOCK + GIL    │ Mutex<TraceMallocState>      │
  ├───────────┼──────────────────────┼──────────────────────────────┤
  │ interning │ filename + traceback │ 1단계에서는 생략, 추후       │
  │           │  interning           │ 최적화                       │
  ├───────────┼──────────────────────┼──────────────────────────────┤
  │ realloc   │ realloc 훅으로 크기  │ 미지원 (Vec capacity 변경    │
  │ 추적      │ 변경 추적            │ 등은 추적 불가)              │
  └───────────┴──────────────────────┴──────────────────────────────┘

  ---
  record_allocation() 구현 세부

  ```python
  pub fn record_allocation(ptr_addr: usize, size: usize) {
          // 1. 현재 프레임 가져오기 (signal-safe AtomicPtr 사용)
          let frame_ptr = crate::vm::thread::get_current_frame();
    
          // 2. 프레임 체인 워킹 → traceback 수집
          let mut frames = Vec::new();
          let mut current = frame_ptr;
          let state = TRACEMALLOC_STATE.lock();
          let nframe = state.nframe;
          drop(state);
    
          let mut count = 0;
          while !current.is_null() && count < nframe {
              let frame = unsafe { &*current };
              // frame.code.source_path (filename)
              // frame.current_location() (lineno) — 여기서 접근 가능한지
      확인 필요
              frames.push(FrameInfo {
                  filename: frame.code.source_path.to_string(),
                  lineno: /*current instruction의 line number*/,
              });
              current = frame.previous_frame();
              count += 1;
          }
    
          // 3. 저장
          let mut state = TRACEMALLOC_STATE.lock();
          state.traces.insert(ptr_addr, TraceEntry {
              size,
              domain: 0,
              traceback: frames,
          });
          state.traced_memory += size;
          if state.traced_memory > state.peak_traced_memory {
              state.peak_traced_memory = state.traced_memory;
          }
      }
  ```

  get_object_traceback() 구현 방식

  CPython은 id(obj) = 메모리 주소이므로 hashtable에서 바로 조회합니다.
  RustPython도 동일하게:

  ```python
  fn get_object_traceback(obj: PyObjectRef) -> Option<...> {
        let ptr_addr = obj.as_raw() as *const _ as usize;
        let state = TRACEMALLOC_STATE.lock();
        state.traces.get(&ptr_addr).map(|entry| /* traceback 변환 */)
    }
  ```

  ---
  제한사항 (CPython 대비)

  1. Vec/HashMap 내부 힙 할당 미추적 — list.append()로 Vec이 grow할 때의
   realloc은 추적 불가
  2. Rust 내부 할당 미추적 — Box, Arc 등 Python 객체가 아닌 Rust 내부
  할당
  3. 크기 정확도 — mem::size_of::<PyInner<T>>()는 고정 크기만 반영, 가변
   길이(str 내용, list 요소) 미포함
  4. 도메인 — CPython의 RAW/MEM/OBJ 구분 없이 도메인 0만 지원

  ---
  단계별 구현 순서

  ┌─────┬─────────────────────────────────────────────────────┬──────┐
  │ 단  │                        내용                         │ PR   │
  │ 계  │                                                     │ 범위 │
  ├─────┼─────────────────────────────────────────────────────┼──────┤
  │ 1단 │ tracemalloc_state.rs + TRACEMALLOC_ENABLED          │ 인프 │
  │ 계  │ AtomicBool + record_allocation/deallocation         │ 라만 │
  ├─────┼─────────────────────────────────────────────────────┼──────┤
  │ 2단 │_tracemalloc.rs 모듈 — start/stop/is_tracing/get_tr │ 기본 │
  │ 계  │ aced_memory/reset_peak/get_traceback_limit/get_trac │      │
  │     │ emalloc_memory/clear_traces                         │ 함수 │
  ├─────┼─────────────────────────────────────────────────────┼──────┤
  │     │                                                     │ trac │
  │ 3단 │ get_traces(), get_object_traceback() + 프레임 워킹  │ ebac │
  │ 계  │                                                     │ k    │
  │     │                                                     │ 수집 │
  ├─────┼─────────────────────────────────────────────────────┼──────┤
  │     │                                                     │ 통합 │
  │ 4단 │ Lib/tracemalloc.py 복사 + object/core.rs 훅 삽입    │  +   │
  │ 계  │                                                     │ 테스 │
  │     │                                                     │ 트   │
  └─────┴─────────────────────────────────────────────────────┴──────┘

  하나의 PR로 합칠 수도 있고, 메인테이너 선호에 따라 나눌 수도 있습니다.
   이슈에 올릴 영어 버전을 작성할까요?

✻ Baked for 2m 57s

❯   제한사항 (CPython 대비)

  1. Vec/HashMap 내부 힙 할당 미추적 — list.append()로 Vec이 grow할
때의
   realloc은 추적 불가
  2. Rust 내부 할당 미추적 — Box, Arc 등 Python 객체가 아닌 Rust 내부
  할당
  3. 크기 정확도 — mem::size_of::<PyInner<T>>()는 고정 크기만 반영,
가변
   길이(str 내용, list 요소) 미포함
  4. 도메인 — CPython의 RAW/MEM/OBJ 구분 없이 도메인 0만 지원
 이거를 개선할 방법은 없어?

✢ Blanching…

────────────────────────────────────────────────────────────────────────
❯
────────────────────────────────────────────────────────────────────────
  opus-4-6[1 RustPython product max fix/itertools-map-islice *3 !2 ?2…
  -- INSERT -- ⏵⏵ accept edits on (shift+tab to cycle)
