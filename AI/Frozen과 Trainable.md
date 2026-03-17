
Frozen과 Trainable은 모델 학습 시 각 레이어의 가중치를 업데이트할지 여부를 나타내는 상태이다.

## Frozen

학습 중 가중치가 변하지 않도록 고정하는 것이다. 역전파 시 gradient가 전파되지 않으므로 가중치가 그대로 유지된다.

```python
# PyTorch
for param in model.backbone.parameters():
    param.requires_grad = False

# Keras
model.layers[0].trainable = False
```

Frozen으로 설정하면 해당 레이어의 gradient 계산을 건너뛰기 때문에 메모리와 연산량이 줄어든다. GPU 메모리가 부족하면 일부 레이어를 frozen해서 배치 사이즈를 늘리는 식으로 활용하기도 한다.

```python
for name, param in model.named_parameters():
    print(f"{name}: {'trainable' if param.requires_grad else 'frozen'}")

trainable = sum(p.numel() for p in model.parameters() if p.requires_grad)
frozen = sum(p.numel() for p in model.parameters() if not p.requires_grad)
print(f"Trainable: {trainable:,} / Frozen: {frozen:,}")
```

## Trainable

optimizer가 gradient를 계산하고 가중치를 업데이트하는 상태이다. 기본적으로 모든 파라미터는 trainable로 생성된다.

## Frozen/Trainable 분리

사전학습 모델을 새 태스크에 적용할 때 전체를 다시 학습시키면, ImageNet 등 대규모 데이터에서 익힌 범용적인 특징 추출 능력이 소규모 데이터에 의해 덮어써진다(Catastrophic Forgetting). 초기 레이어가 잡아내는 edge, texture 같은 저수준 특징은 대부분의 태스크에서 그대로 쓸 수 있는데, 굳이 다시 학습시키면 오히려 성능이 떨어진다. 파라미터가 수억~수십억 개인 모델 전체를 돌리는 연산 비용 문제도 있다.

그래서 이미 잘 학습된 부분은 frozen하고, 태스크에 맞게 바꿔야 할 부분만 trainable로 여는 것이 일반적이다.

## Fine-tuning 전략

- **Feature Extraction**: 사전학습 모델 전체를 frozen하고 새 분류 head만 trainable로 붙인다. 모델을 고정된 특징 추출기로만 쓰는 것이다. 데이터가 적을 때 유용한데, trainable 파라미터가 head뿐이라 과적합 위험이 낮다.

  ```python
  # pytorch
    for param in resnet.parameters():
                param.requires_grad = False
          
            resnet.fc = nn.Linear(2048, num_classes)  # head만 trainable
  ```

- **Partial Fine-tuning**: 앞쪽 레이어(저수준 특징)는 frozen으로 두고 뒤쪽 레이어(고수준 특징)만 열어서 학습한다.
  - CNN을 예로 들면, 초기 Conv 레이어는 edge나 texture 같은 범용 특징을 추출하므로 대부분의 태스크에서 그대로 쓸 수 있다. 반면 뒤쪽 레이어는 태스크에 특화된 고수준 특징을 학습하므로 이 부분만 열어주면 된다.
  - EasyOCR에서 CRAFT(검출)는 frozen, CRNN(인식)만 fine-tuning하는 것이 이 방식이다.

- **Gradual Unfreezing**: 처음에는 head만 trainable로 두고 학습하다가, 일정 epoch마다 바로 아래 레이어를 하나씩 unfreeze해 나간다.
  - ULMFiT에서 제안된 기법이다. 한꺼번에 전체를 열면 사전학습 가중치가 크게 흔들리는데, 위에서부터 점진적으로 열면 각 레이어가 이미 안정된 상위 레이어에 맞춰 조정되므로 catastrophic forgetting을 줄일 수 있다.

- **LoRA**: 원본 가중치 행렬 W는 frozen한 채로 두고, 옆에 작은 행렬 두 개(A, B)를 붙여서 학습한다.

  - 원래: `y = Wx` (W는 frozen)
  - LoRA: `y = Wx + BAx` (B, A만 trainable)

  - W가 (4096 × 4096)이면 파라미터가 약 1,600만 개인데, A를 (r × 4096), B를 (4096 × r)로 두고 r(rank)을 8로 설정하면 A+B 파라미터는 65,536개로 원본의 0.4% 수준이다. gradient를 저장할 메모리도 그만큼 줄어서 GPU 한 장으로도 LLM fine-tuning이 가능해진다. 학습이 끝나면 BA를 W에 합쳐버리면(`W' = W + BA`) 추론 시 추가 비용도 없다.

- **Adapter**: LoRA가 행렬을 옆에 붙이는 방식이라면, Adapter는 레이어 사이에 작은 bottleneck 모듈(축소 → 활성화 → 확장)을 끼워 넣는 방식이다.
  - 예를 들어 hidden size가 768인 Transformer 레이어 사이에 768→64→768 크기의 모듈을 삽입한다. 원본 레이어는 전부 frozen이고 이 작은 모듈만 학습한다.

---
참고

- [PyTorch - Finetuning Torchvision Models](https://pytorch.org/tutorials/beginner/finetuning_torchvision_models_tutorial.html)
- [ULMFiT - Universal Language Model Fine-tuning](https://arxiv.org/abs/1801.06146)
- [LoRA: Low-Rank Adaptation of Large Language Models](https://arxiv.org/abs/2106.09685)
