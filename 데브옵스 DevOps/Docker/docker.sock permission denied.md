## docker 설치 후 /var/run/docker.sock의 permission denied 발생하는 경우

docker 설치 후 usermod로 사용자를 docker 그룹에 추가해도 permission denied가 발생했다.

```
# docker ps -a
Got permission denied while trying to connect to the Docker daemon socket at unix:///var/run/docker.sock: Get http://%2Fvar%2Frun%2Fdocker.sock/v1.40/containers/json?all=1: dial unix /var/run/docker.sock: connect: permission denied
```

### 해결
/var/run/docker.sock 파일의 권한을 666으로 변경하여 그룹 내 다른 사용자도 접근 가능하게 변경한다!
```
sudo chmod 666 /var/run/docker.sock
```
또는 chown 으로 group ownership 변경
```
sudo chown root:docker /var/run/docker.sock
```


- [Got permission denied while trying to connect to the Docker daemon socket at unix:///var/run/docker.sock](https://stackoverflow.com/a/58433757/7110084)
- [Docker socket file ownership is set to root:docker](https://docs.datadoghq.com/security_monitoring/default_rules/cis-docker-1.2.0-3.15/#default-value)
- [Docker socket file permissions are set to 660 or more restrictively](https://docs.datadoghq.com/security_monitoring/default_rules/cis-docker-1.2.0-3.16/#default-value)
- [docker in docker의 Permission denied 문제](https://blog.dasomoli.org/docker-docker-in-docker%ec%9d%98-permission-denied-%eb%ac%b8%ec%a0%9c/)