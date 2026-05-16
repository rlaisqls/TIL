
우분투의 기본 비디오 플레이어인 GNOME Videos(Totem)는 GStreamer 백엔드를 쓰는데, 라이선스 이슈로 H.264 디코더 플러그인이 기본 설치에서 빠져 있다.

### 해결

GStreamer 코덱 패키지를 보강한다.

```bash
sudo apt install -y gstreamer1.0-libav gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly
```
