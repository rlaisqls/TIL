
Checkpoint shard는 대규모 모델의 가중치(weight) 파일을 여러 개의 작은 파일로 분할한 것이다. LLM처럼 수십~수백 GB에 달하는 모델을 학습하거나 배포할 때, 가중치를 단일 파일에 저장하면 여러 문제가 발생한다. Checkpoint shard는 이 문제를 해결하기 위해 모델 파라미터를 여러 파일에 나누어 저장하는 방식이다.

모델이 커지면서 단일 파일 저장 방식에는 아래같은 한계가 생긴다.

- 파일 크기 제한: GitHub LFS는 파일당 5GB, Hugging Face Hub도 단일 파일 업로드에 제한이 있다. 70B 모델의 FP16 가중치는 약 140GB에 달하기 때문에 하나의 파일로는 저장 자체가 불가능하다.
- 메모리 문제: 단일 파일을 로드하려면 파일 전체를 한 번에 메모리에 올려야 한다. 분할하면 shard 단위로 순차 로드하여 피크 메모리 사용량을 줄일 수 있다.
- 다운로드 안정성: 수십 GB 파일 하나를 받다가 실패하면 처음부터 다시 받아야 한다. 분할된 shard는 개별 파일 단위로 재시도할 수 있고, 병렬 다운로드도 가능하다.
- 분산 로딩: 멀티 GPU 환경에서 각 GPU가 필요한 shard만 로드하여 병렬로 모델을 구성할 수 있다.

## 파일 구조

PyTorch 기반 Hugging Face 모델을 예로 들면, 분할된 checkpoint는 다음과 같은 파일들로 구성된다.

```
model-00001-of-00012.safetensors
model-00002-of-00012.safetensors
...
model-00012-of-00012.safetensors
model.safetensors.index.json
```

이전에는 `.bin` (PyTorch pickle) 포맷이 사용되었지만, 보안과 로딩 속도 문제로 현재는 `safetensors` 포맷이 표준이다.

**인덱스 파일**

`model.safetensors.index.json`은 전체 shard의 매핑 정보를 담고 있다. 이 파일을 보면 어떤 파라미터가 어떤 shard에 있는지 알 수 있다.

```json
{
  "metadata": {
    "total_size": 141484843008
  },
  "weight_map": {
    "model.embed_tokens.weight": "model-00001-of-00012.safetensors",
    "model.layers.0.self_attn.q_proj.weight": "model-00001-of-00012.safetensors",
    "model.layers.0.self_attn.k_proj.weight": "model-00001-of-00012.safetensors",
    "model.layers.15.mlp.gate_proj.weight": "model-00007-of-00012.safetensors",
    "lm_head.weight": "model-00012-of-00012.safetensors"
  }
}
```

`weight_map`은 텐서 이름을 키로, 해당 텐서가 저장된 shard 파일명을 값으로 가진다. 로더는 이 맵을 먼저 읽고, 필요한 shard만 선택적으로 로드할 수 있다.

**shard 분할 기준**

Hugging Face transformers는 기본적으로 shard 하나의 크기를 약 5GB로 제한한다. `max_shard_size` 파라미터로 조절 가능하다.

```python
model.save_pretrained("output_dir", max_shard_size="5GB")
```

분할 시 하나의 텐서가 여러 shard에 걸치지 않도록 한다. 즉 레이어 단위로 텐서를 묶어서 shard 경계를 정한다. 현재 shard에 텐서를 추가했을 때 크기 제한을 넘으면 새로운 shard를 시작하는 방식이다. shard 하나를 로드하고 모델에 할당한 뒤 메모리에서 해제하는 방식이기 때문에, 전체 모델 크기의 2배가 아닌 `모델 크기 + shard 1개 크기` 정도의 메모리만 있으면 된다.

## device_map

`device_map="auto"`를 지정하면 accelerate 라이브러리가 사용 가능한 GPU/CPU 메모리를 확인하고, 각 레이어를 어디에 배치할지 자동으로 결정한다.

```python
from transformers import AutoModelForCausalLM

model = AutoModelForCausalLM.from_pretrained(
    "meta-llama/Llama-2-70b-hf",
    device_map="auto",  # 자동 디바이스 배치
    torch_dtype=torch.float16,  # 메모리 절약
)
```

이때 shard 단위 로딩이 활성화되어 있으면 shard를 하나씩 로드하면서 텐서를 즉시 목표 디바이스로 이동시키기 때문에, RAM에 전체 모델을 올려 복사할 필요가 없어진다.

---
참고

- <https://huggingface.co/docs/transformers/main_classes/model#large-model-loading>
- <https://huggingface.co/docs/safetensors>
- <https://huggingface.co/docs/accelerate/usage_guides/big_modeling>
