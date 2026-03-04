
## Long-Context Embedding

임베딩 모델 입력에 문서 텍스트를 최대한 많이 넣는다고 검색 정확도가 떨어지지는 않는다. 다만 long-context 임베딩 모델은 문서 앞부분에 집중하는 경향이 있다. 제목이나 소개 같은 핵심 내용이 앞에 오기 때문인데, 문서 중간 내용을 놓칠 수 있다는 단점이 있다.

## Naive Chunking

문서가 여러 주제를 다루거나, 사용자 쿼리가 문서 내 특정 정보를 대상으로 하는 경우 청킹을 적용하면 일반적으로 검색 성능이 향상된다.

결국 분할 결정은 여러 요소에 따라 달라진다. 사용자에게 부분 텍스트를 표시해야 하는 경우(예: Google이 검색 결과 미리보기에서 관련 구절을 보여주는 것)에는 분할이 필수적이다. 반면, 컴퓨팅 및 메모리 제약 상황에서는 검색 오버헤드와 리소스 사용량 증가로 인해 분할이 오히려 불리할 수 있다.

## Late Chunking

Late Chunking은 다음과 같은 순서로 동작한다.

1. 전체 문서를 먼저 임베딩
2. 그 이후에 임베딩을 청킹

청크를 나누기 전에 전체 문서를 먼저 인코딩하므로, 컨텍스트가 빠져서 생기는 의미 손실 문제를 보완한다. 각 부분이 전체와 맞물리는 일관된 문서에서 특히 효과적이며, 텍스트를 작은 덩어리로 나눌수록 더 빛난다. 다만 문서 내 섹션들이 서로 무관한 경우, 넓은 컨텍스트가 오히려 임베딩에 노이즈를 추가해 검색 성능을 떨어뜨릴 수 있다.

---

## Late Chunking 예제

jina embedding API 사용

참고: <https://colab.research.google.com/drive/15vNZb6AsU7byjYoaEtXuNu567JWNzXOz?usp=sharing#scrollTo=da0cec59a3ece76>

```go
package main

import (
 "bytes"
 "context"
 "encoding/json"
 "fmt"
 "net/http"
    "os"
 "time"

 "gonum.org/v1/gonum/mat"
)

func main() {
 chunks := []string{
  "Berlin is the capital and largest city of Germany, both by area and by population.",
  "Its more than 3.85 million inhabitants make it the European Union's most populous city, as measured by population within city limits.",
  "The city is also one of the states of Germany, and is the third smallest state in the country in terms of area.",
 }

 // 'Berlin' 임베딩 생성
 berlinEmbedding := convertToVecDense(getEmbedding([]string{"Berlin"}, false)[0].Embedding)

 // 새로운 청킹 방식의 임베딩 생성
 embeddingsNew := getEmbedding(chunks, true)
 embeddings := make([]*mat.VecDense, len(embeddingsNew))
 for i, embeddingData := range embeddingsNew {
  embeddings[i] = convertToVecDense(embeddingData.Embedding)
 }

 // 전통적인 청킹 방식의 임베딩 생성
 embeddingsTraditional := getEmbedding(chunks, false)
 embeddingsTraditionalChunking := make([]*mat.VecDense, len(embeddingsTraditional))
 for i, embeddingData := range embeddingsTraditional {
  embeddingsTraditionalChunking[i] = convertToVecDense(embeddingData.Embedding)
 }

 // 유사도 계산 및 출력
 for i := 0; i < len(chunks); i++ {
  chunk := chunks[i]
  newEmbedding := embeddings[i]
  tradEmbedding := embeddingsTraditionalChunking[i]

  fmt.Printf("similarity_new(\"Berlin\", \"%s\"): %f\n",
   chunk,
   cosineSimilarity(berlinEmbedding, newEmbedding))

  fmt.Printf("similarity_trad(\"Berlin\", \"%s\"): %f\n",
   chunk,
   cosineSimilarity(berlinEmbedding, tradEmbedding))
 }
}

func getEmbedding(input []string, lateChunking bool) []EmbeddingData {
 url := "https://api.jina.ai/v1/embeddings"
 requestBody := EmbeddingRequest{
  Model:         "jina-embeddings-v3",
  Task:          "text-matching",
  LateChunking:  lateChunking,
  Dimensions:    1024,
  EmbeddingType: "float",
  Input:         input,
 }

 jsonBody, err := json.Marshal(requestBody)
 if err != nil {
  fmt.Println("Error marshaling request body:", err)
  return []EmbeddingData{}
 }

 req, err := http.NewRequestWithContext(context.TODO(), http.MethodPost, url, bytes.NewBuffer(jsonBody))
 if err != nil {
  fmt.Println("Error creating request:", err)
  return []EmbeddingData{}
 }
 req.Header.Set("Authorization", fmt.Sprintf("Bearer %s", os.getEnv("JINA_API_KEY")))
 req.Header.Set("Content-Type", "application/json")

 response, err := NewHTTPClient().Do(req)
 if err != nil {
  fmt.Println("Error sending request:", err)
  return []EmbeddingData{}
 }
 defer response.Body.Close()

 if response.StatusCode < http.StatusOK || response.StatusCode >= http.StatusBadRequest {
  fmt.Println("Error response status:", response.Status)
  return []EmbeddingData{}
 }

 var embeddingResponse EmbeddingResponse
 if err := json.NewDecoder(response.Body).Decode(&embeddingResponse); err != nil {
  fmt.Println("Error decoding response:", err)
  return []EmbeddingData{}
 }

 return embeddingResponse.Data
}

func cosineSimilarity(x, y *mat.VecDense) float64 {
 dotProduct := mat.Dot(x, y)
 normX := mat.Norm(x, 2)
 normY := mat.Norm(y, 2)
 if normX == 0 || normY == 0 {
  return 0
 }
 return dotProduct / (normX * normY)
}

type EmbeddingRequest struct {
 Model         string   `json:"model"`
 Task          string   `json:"task"`
 LateChunking  bool     `json:"late_chunking"`
 Dimensions    int      `json:"dimensions"`
 EmbeddingType string   `json:"embedding_type"`
 Input         []string `json:"input"`
}

type EmbeddingResponse struct {
 Model  string `json:"model"`
 Object string `json:"object"`
 Usage  struct {
  TotalTokens  int `json:"total_tokens"`
  PromptTokens int `json:"prompt_tokens"`
 } `json:"usage"`
 Data []EmbeddingData `json:"data"`
}

type EmbeddingData struct {
 Object    string    `json:"object"`
 Index     int       `json:"index"`
 Embedding []float32 `json:"embedding"`
}

func NewHTTPClient() *http.Client {
 t := http.DefaultTransport.(*http.Transport).Clone()
 httpClient := &http.Client{
  Timeout:   time.Second * 60,
  Transport: t,
 }
 return httpClient
}

func convertToVecDense(embedding []float32) *mat.VecDense {
 data := make([]float64, len(embedding))
 for i, v := range embedding {
  data[i] = float64(v)
 }
 return mat.NewVecDense(len(data), data)
}
```

## 실행 결과

```
similarity_new("Berlin", "Berlin is the capital and largest city of Germany, both by area and by population."): 0.603828
similarity_trad("Berlin", "Berlin is the capital and largest city of Germany, both by area and by population."): 0.622085
similarity_new("Berlin", "Its more than 3.85 million inhabitants make it the European Union's most populous city, as measured by population within city limits."): 0.596051
similarity_trad("Berlin", "Its more than 3.85 million inhabitants make it the European Union's most populous city, as measured by population within city limits."): 0.375543
similarity_new("Berlin", "The city is also one of the states of Germany, and is the third smallest state in the country in terms of area."): 0.557390
similarity_trad("Berlin", "The city is also one of the states of Germany, and is the third smallest state in the country in terms of area."): 0.392474
```

```
similarity_new("Germany's third smallest state", "Berlin is the capital and largest city of Germany, both by area and by population."): 0.466292
similarity_trad("Germany's third smallest state", "Berlin is the capital and largest city of Germany, both by area and by population."): 0.386494
similarity_new("Germany's third smallest state", "Its more than 3.85 million inhabitants make it the European Union's most populous city, as measured by population within city limits."): 0.498799
similarity_trad("Germany's third smallest state", "Its more than 3.85 million inhabitants make it the European Union's most populous city, as measured by population within city limits."): 0.393707
similarity_new("Germany's third smallest state", "The city is also one of the states of Germany, and is the third smallest state in the country in terms of area."): 0.610985
similarity_trad("Germany's third smallest state", "The city is also one of the states of Germany, and is the third smallest state in the country in terms of area."): 0.834924
```

**한국어 쿼리 결과 (Jina vs OpenAI)**

- **"독일에서 세 번째로 작은 주"** → "베를린은 독일의 수도이자 면적과 인구 면에서 가장 큰 도시입니다."
  - Jina (new): 0.463484 / Jina (traditional): 0.376677 / OpenAI: 0.762629
- **"독일에서 세 번째로 작은 주"** → "385만 명 이상의 주민이 거주하는 이 도시는 EU에서 인구 기준으로 가장 인구가 많은 도시입니다."
  - Jina (new): 0.464881 / Jina (traditional): 0.352404 / OpenAI: 0.755278
- **"독일에서 세 번째로 작은 주"** → "이 도시는 독일의 주 중 하나이며 면적 기준으로 독일에서 세 번째로 작습니다."
  - Jina (new): 0.589742 / Jina (traditional): 0.805602 / OpenAI: 0.822122
- **"베를린"** → "베를린은 독일의 수도이자 면적과 인구 면에서 가장 큰 도시입니다."
  - Jina (new): 0.686351 / Jina (traditional): 0.686258 / OpenAI: 0.881540
- **"베를린"** → "385만 명 이상의 주민이 거주하는 이 도시는 EU에서 인구 기준으로 가장 인구가 많은 도시입니다."
  - Jina (new): 0.645858 / Jina (traditional): 0.444751 / OpenAI: 0.766704
- **"베를린"** → "이 도시는 독일의 주 중 하나이며 면적 기준으로 독일에서 세 번째로 작습니다."
  - Jina (new): 0.648850 / Jina (traditional): 0.426982 / OpenAI: 0.776623
- **"독일"** → "베를린은 독일의 수도이자 면적과 인구 면에서 가장 큰 도시입니다."
  - Jina (new): 0.439323 / Jina (traditional): 0.462919 / OpenAI: 0.839182
- **"독일"** → "385만 명 이상의 주민이 거주하는 이 도시는 EU에서 인구 기준으로 가장 인구가 많은 도시입니다."
  - Jina (new): 0.396040 / Jina (traditional): 0.312176 / OpenAI: 0.798267
- **"독일"** → "이 도시는 독일의 주 중 하나이며 면적 기준으로 독일에서 세 번째로 작습니다."
  - Jina (new): 0.462900 / Jina (traditional): 0.535105 / OpenAI: 0.866817
- **"베를린은 독일의 수도이자..."** → 동일 문장
  - Jina (new): 0.924848 / Jina (traditional): 0.999999 / OpenAI: 1.000000
- **"베를린은 독일의 수도이자..."** → "385만 명 이상의 주민이 거주하는 이 도시는..."
  - Jina (new): 0.874741 / Jina (traditional): 0.628405 / OpenAI: 0.875833
- **"베를린은 독일의 수도이자..."** → "이 도시는 독일의 주 중 하나이며..."
  - Jina (new): 0.822390 / Jina (traditional): 0.550218 / OpenAI: 0.903619

**영문 쿼리 결과 (Jina vs OpenAI)**

- **"Germany's third smallest state"** → "Berlin is the capital..."
  - Jina (new): 0.466266 / Jina (traditional): 0.386458 / OpenAI: 0.817986
- **"Germany's third smallest state"** → "More than 3.85 million..."
  - Jina (new): 0.498805 / Jina (traditional): 0.393753 / OpenAI: 0.770222
- **"Germany's third smallest state"** → "City is one of the states..."
  - Jina (new): 0.610991 / Jina (traditional): 0.834926 / OpenAI: 0.918847
- **"Berlin"** → "Berlin is the capital..."
  - Jina (new): 0.603828 / Jina (traditional): 0.622085 / OpenAI: 0.845207
- **"Berlin"** → "More than 3.85 million..."
  - Jina (new): 0.596051 / Jina (traditional): 0.375543 / OpenAI: 0.763775
- **"Berlin"** → "City is one of the states..."
  - Jina (new): 0.557390 / Jina (traditional): 0.392474 / OpenAI: 0.789531
- **"Germany"** → "Berlin is the capital..."
  - Jina (new): 0.458062 / Jina (traditional): 0.443456 / OpenAI: 0.816565
- **"Germany"** → "More than 3.85 million..."
  - Jina (new): 0.442322 / Jina (traditional): 0.272800 / OpenAI: 0.749585
- **"Germany"** → "City is one of the states..."
  - Jina (new): 0.497072 / Jina (traditional): 0.519139 / OpenAI: 0.812687
- **"Berlin is the capital..."** → 동일 문장
  - Jina (new): 0.924933 / Jina (traditional): 0.999999 / OpenAI: 1.000000
- **"Berlin is the capital..."** → "More than 3.85 million..."
  - Jina (new): 0.831721 / Jina (traditional): 0.494498 / OpenAI: 0.840680
- **"Berlin is the capital..."** → "City is one of the states..."
  - Jina (new): 0.796556 / Jina (traditional): 0.525294 / OpenAI: 0.881854

---
참고

- <https://www.elastic.co/search-labs/blog/jina-embeddings-chunking-elasticsearch>
- <https://github.com/jina-ai/late-chunking>
- <https://jina.ai/news/jina-embeddings-v3-a-frontier-multilingual-embedding-model/#parameter-task>
- <https://blog.stackademic.com/late-chunking-embedding-first-chunk-later-long-context-retrieval-in-rag-applications-3a292f6443bb>
