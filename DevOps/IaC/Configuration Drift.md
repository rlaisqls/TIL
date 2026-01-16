Configuration Drift는 수동적이고 임시방편적인 변경, 업데이트, 그리고 일반적인 엔트로피로 인해 인프라의 서버들이 시간이 지남에 따라 서로 점점 더 달라지는 현상이다.

자동화된 서버 프로비저닝 프로세스는 머신이 생성될 때 일관성을 보장하는 데 도움이 되지만, 특정 머신의 생명주기 동안 기준선(baseline)과 다른 머신들로부터 표류(drift)하게 된다.

Configuration drift에 대응하는 두 가지 주요 방법이 있다. 하나는 Puppet이나 Chef와 같은 자동화된 구성 도구를 사용하여 머신을 일관되게 유지하기 위해 자주 반복적으로 실행하는 것이다. 다른 하나는 머신 인스턴스를 자주 재구축하여 기준선에서 표류할 시간을 주지 않는 것이다.

Configuration drift가 발생하면 아래와 같은 문제가 생긴다

- 보안 취약점
  - 구성 오류나 무단 변경은 권한 상승, 취약한 오픈소스 컴포넌트 사용, 취약한 컨테이너 이미지, 신뢰할 수 없는 저장소에서 가져온 이미지, root로 실행되는 컨테이너 등의 문제
- 비효율적인 리소스 활용
  - 과도하게 프로비저닝된 워크로드나 더 이상 필요하지 않은데도 계속 실행되는 오래된 워크로드가 많아질 수 있다.
- 복원력 및 안정성 감소
  - 디버깅과 해결이 어려운 크래시, 버그, 성능 문제를 유발할 수 있다.

IaC는 drift 문제를 완화하는 데 도움이 되지만, 추가적인 drift 관리가 중요하다.

- Ansible은 drift를 감지하도록 설정할 수 있는 Ansible Playbook(자동화 워크플로우)을 통해 drift에 대응하는 데 도움을 준다.
- Drift가 감지되면 적절한 담당자에게 알림을 보내어 필요한 수정을 수행하고 시스템을 기준선으로 되돌릴 수 있다.

---
참고

- <https://opensourceforu.com/2015/03/ten-tools-for-configuration-management/>
- <http://kief.com/configuration-drift.html>
- <https://www.aquasec.com/cloud-native-academy/vulnerability-management/configuration-drift/#:~:text=Configuration%20drift%20is%20when%20the%20configuration%20of%20an%20environment%20%E2%80%9Cdrifts,without%20being%20recorded%20or%20tracked>.
