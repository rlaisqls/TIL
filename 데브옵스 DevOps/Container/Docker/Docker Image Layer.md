도커는 **Dockerfile을 읽어들여, 파일 시스템에 변화를 주는 커맨드마다 새로운 이미지 레이어를 만듭니다**. 즉, Dockerfile을 읽어들여 각 줄마다 이미지 레이어를 만든다는 말은 틀린 말은 아닙니다. 하지만, 모든 줄마다 레이어를 만드는 것이 아닌 파일 시스템에 변화가 발생하는 경우만 이미지 레이어를 생성합니다.

또한, 도커 빌드 엔진은 이미지 레이어의 공간 효율과 안정성을 위해 꾸준히 빌드 방식을 변경하고 개선해가고 있습니다. 따라서, **도커 엔진 버전, 빌드 라이브러리의 종류에 따라 결과물은 조금씩 차이가 있을 수 있습니다**. (Docker 엔진 23 버전부터는 buildx 를 default builder로 사용합니다)  
도커 공식문서에서는 이미지 레이어를 만들 수 있는 상황들에 대해 아래와 같이 설명했습니다.

> Each layer is only a set of differences from the layer before it. Note that both adding, and removing files will result in a new layer.  
> (https://docs.docker.com/storage/storagedriver/)

파일 시스템에 변화를 주지 않는 무의미한 커맨드의 반복이나, echo와 같이 stdout을 발생시키는 커맨드, ‘LABEL’ 과 같은 메타 데이터를 수정하는 명령들은 새로운 이미지를 만들지 않습니다. 메타 데이터의 경우 이미지의 별도 메타 데이터 저장 공간에 JSON 형식으로 저장됩니다.
