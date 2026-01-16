### Long-Context Embedding

In general, it doesn’t harm retrieval accuracy to include as much text of your documents as you can to the input of your embedding model. However, long-context embedding models often focus on the beginning of documents, as they contain content like titles and introduction which are more important for judging relevance, but the models might miss content in the middle of the document.

일반적으로 임베딩 모델의 입력에 문서의 텍스트를 최대한 많이 포함하는 것은 검색 정확도에 해를 끼치지 않습니다. 그러나 긴 컨텍스트 임베딩 모델은 관련성을 판단하는 데 더 중요한 제목 및 소개와 같은 콘텐츠를 포함하기 때문에 문서의 시작 부분에 초점을 맞추는 경우가 많지만 모델이 문서 중간에 있는 콘텐츠를 놓칠 수 있습니다.

### Naive Chunking

When documents cover multiple aspects, or user queries target specific information within a document, chunking generally improves retrieval performance.

문서가 여러 측면을 다루거나 사용자 쿼리가 문서 내의 특정 정보를 대상으로 하는 경우 일반적으로 청크를 사용하면 검색 성능이 향상됩니다.

Eventually, segmentation decisions depend on factors like the need to display partial text to users (e.g. as Google presents the relevant passages in the previews of the search results), which makes segmentation essential, or constraints on compute and memory, where segmentation may be less favorable due to increased retrieval overhead and resource usage.

결국 분할 결정은 사용자에게 부분 텍스트를 표시해야 하는 필요성(예: Google이 검색 결과 미리보기에 관련 구절을 표시하는 경우)과 같은 요소에 따라 달라집니다. 이로 인해 분할이 필수적이거나 분할이 덜할 수 있는 컴퓨팅 및 메모리에 대한 제약이 발생할 수 있습니다. 검색 오버헤드 및 리소스 사용량 증가로 인해 유리합니다.

### Late Chunking

Late Chunking do:

1. Embedding the Entire Document First
2. Chunking the Embeddings Afterwards:

By encoding the full document before creating chunks, late chunking solves the problem of text segments losing their meaning due to missing context. This works particularly well with coherent documents, where each part relates to the whole. Our experiments show that late chunking is especially effective when dividing text into smaller chunks, as demonstrated in our paper. However, there's one caveat: if parts of the document are unrelated to each other, including this broader context can actually make retrieval performance worse, as it adds noise to the embeddings.

청크를 생성하기 전에 전체 문서를 인코딩함으로써 늦은 청킹은 컨텍스트 누락으로 인해 텍스트 세그먼트의 의미가 손실되는 문제를 해결합니다. 이는 각 부분이 전체와 관련되어 있는 일관된 문서에 특히 효과적입니다. 우리의 실험에서는 논문에서 설명한 것처럼 텍스트를 더 작은 덩어리로 나눌 때 늦은 청킹이 특히 효과적인 것으로 나타났습니다. 그러나 한 가지 주의할 점이 있습니다. 문서의 일부가 서로 관련되지 않은 경우 이러한 더 넓은 컨텍스트를 포함하면 임베딩에 노이즈가 추가되므로 실제로 검색 성능이 저하될 수 있습니다.

---

### Late Chunking 예제

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

| 쿼리 | 문장 | Jina similarity (new) | Jina similarity (traditional) | OpenAI similarity |
|------|------|----------------------|------------------------------|-------------------|
| "독일에서 세 번째로 작은 주" | 베를린은 독일의 수도이자 면적과 인구 면에서 가장 큰 도시입니다. | 0.463484 | 0.376677 | 0.762629 |
| | 385만 명 이상의 주민이 거주하는 이 도시는 EU에서 인구 기준으로 가장 인구가 많은 도시입니다. | 0.464881 | 0.352404 | 0.755278 |
| | 이 도시는 독일의 주 중 하나이며 면적 기준으로 독일에서 세 번째로 작습니다. | 0.589742 | 0.805602 | 0.822122 |
| "베를린" | 베를린은 독일의 수도이자 면적과 인구 면에서 가장 큰 도시입니다. | 0.686351 | 0.686258 | 0.881540 |
| | 385만 명 이상의 주민이 거주하는 이 도시는 EU에서 인구 기준으로 가장 인구가 많은 도시입니다. | 0.645858 | 0.444751 | 0.766704 |
| | 이 도시는 독일의 주 중 하나이며 면적 기준으로 독일에서 세 번째로 작습니다. | 0.648850 | 0.426982 | 0.776623 |
| "독일" | 베를린은 독일의 수도이자 면적과 인구 면에서 가장 큰 도시입니다. | 0.439323 | 0.462919 | 0.839182 |
| | 385만 명 이상의 주민이 거주하는 이 도시는 EU에서 인구 기준으로 가장 인구가 많은 도시입니다. | 0.396040 | 0.312176 | 0.798267 |
| | 이 도시는 독일의 주 중 하나이며 면적 기준으로 독일에서 세 번째로 작습니다. | 0.462900 | 0.535105 | 0.866817 |
| "베를린은 독일의 수도이자 면적과 인구 면에서 가장 큰 도시입니다." | 베를린은 독일의 수도이자 면적과 인구 면에서 가장 큰 도시입니다. | 0.924848 | 0.999999 | 1.000000 |
| | 385만 명 이상의 주민이 거주하는 이 도시는 EU에서 인구 기준으로 가장 인구가 많은 도시입니다. | 0.874741 | 0.628405 | 0.875833 |
| | 이 도시는 독일의 주 중 하나이며 면적 기준으로 독일에서 세 번째로 작습니다. | 0.822390 | 0.550218 | 0.903619 |

| 쿼리 | 문장 | Jina similarity (new) | Jina similarity (traditional) | OpenAI similarity |
|------|------|----------------------|------------------------------|-------------------|
| "Germany's third smallest state" | Berlin is the capital and largest city of Germany | 0.466266 | 0.386458 | 0.817986 |
| | More than 3.85 million inhabitants | 0.498805 | 0.393753 | 0.770222 |
| | City is one of the states of Germany | 0.610991 | 0.834926 | 0.918847 |
| "Berlin" | Berlin is the capital and largest city of Germany | 0.603828 | 0.622085 | 0.845207 |
| | More than 3.85 million inhabitants | 0.596051 | 0.375543 | 0.763775 |
| | City is one of the states of Germany | 0.557390 | 0.392474 | 0.789531 |
| "Germany" | Berlin is the capital and largest city of Germany | 0.458062 | 0.443456 | 0.816565 |
| | More than 3.85 million inhabitants | 0.442322 | 0.272800 | 0.749585 |
| | City is one of the states of Germany | 0.497072 | 0.519139 | 0.812687 |
| "Berlin is the capital..." | Same text | 0.924933 | 0.999999 | 1.000000 |
| | More than 3.85 million inhabitants | 0.831721 | 0.494498 | 0.840680 |
| | City is one of the states of Germany | 0.796556 | 0.525294 | 0.881854 |

---
참고

- <https://www.elastic.co/search-labs/blog/jina-embeddings-chunking-elasticsearch>
- <https://github.com/jina-ai/late-chunking>
- <https://jina.ai/news/jina-embeddings-v3-a-frontier-multilingual-embedding-model/#parameter-task>
- <https://blog.stackademic.com/late-chunking-embedding-first-chunk-later-long-context-retrieval-in-rag-applications-3a292f6443bb>
