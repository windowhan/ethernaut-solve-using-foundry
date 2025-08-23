# 환경 설정
1. 본인의 컴퓨터에 node.js 22버전 이상의 버전으로 설치 + yarn 설치 (이건 LLM에 os알려주고 어떻게 하는지 물어보면 친절히 가르쳐줍니다)
2. `git clone https://github.com/jskimm/ethernaut.git`
3. `yarn install;yarn network` (이것까지 하시면 한 터미널에 anvil 세팅됨)
4. 다른 터미널 띄우기
5. `yarn compile:contracts`
6. `client/src/constants.js`에 `export const ACTIVE_NETWORK = NETWORKS.LOCAL;` 이부분 주석제거
7. 다른 터미널에서 `export NODE_OPTIONS="--openssl-legacy-provider"` 명령어 실행
8. `yarn deploy:contracts`
9. `yarn start:ethernaut`