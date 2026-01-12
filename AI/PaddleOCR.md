
> <https://www.paddlepaddle.org.cn/en/install/quick?docurl=undefined>

## macOS CPU 테스트

```sh
python -m pip install paddlepaddle==3.2.2 -i https://www.paddlepaddle.org.cn/packages/stable/cpu/
# Run PP-OCRv5 inference
paddleocr ocr -i https://paddle-model-ecology.bj.bcebos.com/paddlex/imgs/demo_image/general_ocr_002.png --use_doc_orientation_classify False --use_doc_unwarping False --use_textline_orientation False

# Run PP-StructureV3 inference
paddleocr pp_structurev3 -i https://paddle-model-ecology.bj.bcebos.com/paddlex/imgs/demo_image/pp_structure_v3_demo.png --use_doc_orientation_classify False --use_doc_unwarping False

# Get the Qianfan API Key at first, and then run PP-ChatOCRv4 inference
paddleocr pp_chatocrv4_doc -i https://paddle-model-ecology.bj.bcebos.com/paddlex/imgs/demo_image/vehicle_certificate-1.png -k 驾驶室准乘人数 --qianfan_api_key your_api_key --use_doc_orientation_classify False --use_doc_unwarping False

# Run PaddleOCR-VL inference
paddleocr doc_parser -i https://paddle-model-ecology.bj.bcebos.com/paddlex/imgs/demo_image/paddleocr_vl_demo.png

# Get more information about "paddleocr ocr"
paddleocr ocr --help
```

## 내부 모델 구조

pp_structurev3 등에선 내부적으로 여러 모델이 순차적으로 실행된다. 로그를 보면 `Creating model: (모델명, None)` 형태로 어떤 모델들이 로드되는지 확인할 수 있다. 처리 흐름은 대략 이렇다:

```
이미지 입력
  → 전처리 (왜곡 보정, 방향 보정)
  → 레이아웃 분석 (텍스트/표/수식 영역 구분)
  → 각 영역별 처리 (OCR, 표 구조 인식, 수식 인식 등)
  → (ChatOCR의 경우) LLM으로 정보 추출
```

### 전처리

- **UVDoc**: 문서 unwarping. 카메라로 찍은 문서가 휘어져 있으면 펴준다.
- **PP-LCNet_x1_0_doc_ori**: 문서가 90도, 180도 돌아가 있으면 바로잡는다.
- **PP-LCNet_x1_0_textline_ori**: 텍스트 라인 방향 분류. 세로쓰기 같은 거 처리할 때 쓴다.

`--use_doc_orientation_classify False --use_doc_unwarping False` 옵션으로 끌 수 있는데, 스캔 문서처럼 이미 정렬된 이미지면 끄는 게 빠르다.

### 레이아웃 분석

- **PP-DocBlockLayout**, **PP-DocLayout_plus-L**: 문서에서 텍스트, 표, 그림, 수식 영역을 찾는다. `_plus-L`은 더 큰 모델.

### OCR

- **PP-OCRv5_server_det**: 텍스트 영역 검출 (bounding box)
- **PP-OCRv5_server_rec**: 검출된 영역의 텍스트 인식

det(detection)이 위치 찾고, rec(recognition)이 실제로 읽는다.

### 표 인식

표에 대해선, 선이 있는 표(wired)와 없는 표(wireless)를 다르게 처리한다.

- **PP-LCNet_x1_0_table_cls**: 표 유형 분류
- **SLANeXt_wired**, **SLANet_plus**: 표 구조 인식 (행/열/병합셀)
- **RT-DETR-L_wired_table_cell_det**, **RT-DETR-L_wireless_table_cell_det**: 셀 위치 검출

### 수식/차트

- **PP-FormulaNet_plus-L**: 수식 → LaTeX 변환
- **PP-Chart2Table**: 차트 이미지에서 데이터 추출

### 모델 캐싱

모델은 `~/.paddlex/official_models/`에 캐싱된다.

```
Model files already exist. Using cached files.
```

재다운로드 하려면 해당 디렉토리를 삭제하면 된다.

### ChatOCR

PP-ChatOCRv4는 OCR 결과를 LLM(Qianfan API)에 넘겨서 특정 정보를 추출한다. `-k 운전면허번호`와 같이 키워드를 입력해 해당 값을 찾아낼 수 있다. 긴 문서는 블록 단위로 쪼개서 처리한다.

```
The LLM chat bot is not initialized, will initialize it now.
Split the original text into 1 blocks
Translating block 1/1...
```

---

- <https://d-ontory.tistory.com/20>

---
참고

- <https://github.com/PaddlePaddle/PaddleOCR>
- <https://paddlepaddle.github.io/PaddleOCR/latest/>
