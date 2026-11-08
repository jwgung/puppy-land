# Play 스토어 출시 가이드

앱: 빵고양이 과학섬 (`apps/lab3d`) · 패키지 ID `jwgung.puppyland`(Play에 올리면 바꿀 수 없다) · 개인 계정 · 대상 연령 아동+보호자 겸용(Families 정책 전면 적용) · 스토어 등록정보 기본 언어 한국어.

## 1. 업로드 키 만들기 (한 번만)

Play App Signing을 쓴다. 우리는 **업로드 키**로 서명하고, 스토어에 배포하는 앱의 서명 키는 Google이 보관한다. 업로드 키를 잃으면 Play Console에서 재설정을 신청할 수 있지만 며칠 걸린다.

```bash
keytool -genkeypair -v -keystore upload.jks -alias upload \
  -keyalg RSA -keysize 2048 -validity 10000
```

- 별칭은 반드시 `upload`. 키 비밀번호는 저장소 비밀번호와 같게 한다(워크플로가 하나만 받는다).
- `upload.jks`는 **저장소에 넣지 않는다**. 비밀번호 관리자 등 두 곳 이상에 백업한다.
- 이 파일을 repo 안에 두더라도 `.gitignore`가 `*.jks`·`*.keystore`를 막는지 먼저 확인한다.

## 2. GitHub 시크릿 (Environment `play-release`)

서명 시크릿은 저장소 전체 시크릿이 아니라 **Environment `play-release`** 에 둔다. 저장소에 쓰기 권한이 있는 사람이나 다른 브랜치의 워크플로가 읽지 못하게 하려는 것이다. 저장소 Settings → Environments → `play-release`:

| 이름 | 값 |
|---|---|
| `UPLOAD_KEYSTORE_BASE64` | `base64 -w0 upload.jks` 출력 |
| `UPLOAD_STORE_PASSWORD` | 키스토어(=키) 비밀번호 |
| `PLAY_SERVICE_ACCOUNT_JSON` | Play 업로드용 서비스 계정 JSON 키(3절의 'Play 업로드') |

- Deployment branches and tags: **Selected branches and tags** → 태그 규칙 `v*` 하나만. 브랜치(`main` 포함)에서 돈 워크플로는 시크릿을 읽지 못한다.
- 저장소 수준 시크릿에 같은 이름이 남아 있으면 지운다(Environment가 있어도 저장소 시크릿은 모든 워크플로가 읽는다).
- **Required reviewers**에 본인을 넣는다. 쓰기 권한이 있는 사람이 워크플로를 고쳐 `v*` 태그로 실행하면 `v*` 규칙만으로는 시크릿을 읽을 수 있다. 승인 한 번을 거치게 해 그 경로를 막는다. 혼자 쓰는 저장소라면 "Prevent self-review"는 끈다(켜면 본인이 승인하지 못해 릴리스가 멈춘다). 태그를 만들 수 있는 사람을 제한하려면 Settings → Rules → Rulesets에서 `v*` 태그 규칙을 추가한다.
- 명령으로 만들 때(승인자까지 한 번에 넣는다. 이미 있는 Environment에 다시 실행하면 승인자·규칙이 이 내용으로 덮어써진다):

```bash
me=$(gh api user -q .id)   # 승인자로 넣을 계정의 id (소유자 본인)
gh api -X PUT repos/<owner>/<repo>/environments/play-release --input - <<EOF
{"prevent_self_review":false,"reviewers":[{"type":"User","id":$me}],"deployment_branch_policy":{"protected_branches":false,"custom_branch_policies":true}}
EOF
gh api -X POST repos/<owner>/<repo>/environments/play-release/deployment-branch-policies \
  -f name='v*' -f type=tag
base64 -w0 upload.jks | gh secret set UPLOAD_KEYSTORE_BASE64 --env play-release
gh secret set UPLOAD_STORE_PASSWORD --env play-release --body "$(cat upload.password)"   # $(...)가 끝의 개행을 지운다
gh secret set PLAY_SERVICE_ACCOUNT_JSON --env play-release < play-service-account.json
gh api repos/<owner>/<repo>/environments/play-release   # 승인자·규칙이 들어갔는지 확인
```

## 3. 빌드

**CI(권장)**: `git tag v0.1.1 && git push origin v0.1.1` → `.github/workflows/release.yml`이 서명된 AAB를 만들어 GitHub Release에 붙인다. 수동 실행(workflow_dispatch)도 **태그를 골라서** 실행해야 한다(브랜치에서 실행하면 Environment(`play-release`)의 배포 규칙에 막혀 job이 시작되지 않는다). 수동 실행은 아티팩트만 올리고, GitHub Release는 태그 push로만 만들어진다. CI는 Godot 편집기 설정(SDK·Java 경로)을 워크플로가 직접 기록한다.

필수 승인자를 두었으므로 태그를 push(또는 수동 실행)하면 `bundle` job이 Actions 화면에서 승인을 기다린다. 승인하면 빌드가 시작된다.

**Play 업로드(자동)**: 태그 push로 Release가 만들어지면 `play` job이 그 AAB를 Play 비공개 테스트 트랙(`alpha`)에 올린다(`r0adkll/upload-google-play`, 상태 `completed`). 이 job도 `play-release` Environment 승인을 따로 기다린다. 필요한 것:

- Play Console → 사용자 및 권한에서 서비스 계정을 초대하고 `jwgung.puppyland` 앱에 **출시 관리(릴리스 올리기)** 권한을 준다. 서비스 계정은 Google Cloud에서 만들고 Play Developer API를 켠다.
- 그 계정의 JSON 키를 Environment 시크릿 `PLAY_SERVICE_ACCOUNT_JSON`에 넣는다(`gh secret set PLAY_SERVICE_ACCOUNT_JSON --env play-release < key.json`). 저장소 수준 시크릿으로 두지 않는다.
- 출시 노트는 `docs/release/whatsnew/whatsnew-ko-KR`·`whatsnew-en-US`(각 500자 이내)이다. 이전 태그 이후 이 폴더가 그대로면 job이 실패한다(이전 `v*` 태그가 없는 첫 릴리스는 검사를 건너뛴다). 태그를 찍기 전에 고친다.
- 같은 versionCode는 거부된다. Google 검토는 그대로 남는다.
- 서비스 계정에는 이 앱의 릴리스 관리 권한만 준다(재무·사용자 관리 권한은 주지 않는다). 키는 가끔 새로 만들고, 승인할 때는 태그가 가리키는 커밋이 `main`·`dev`에 있는 것인지 본다.
- 시크릿이 없으면 `play` job만 실패한다. Release는 이미 만들어졌으므로 AAB를 내려받아 Console에 직접 올려도 된다.

CI는 빌드 전에 versionCode가 이전 GitHub Release 제목 끝의 `-v<코드>`보다 큰지 검사하고, 빌드 뒤에는 `build.sh`가 만든 코드가 검사한 값과 같은지 대조한다. 같거나 작으면 Play가 거부하므로 거기서 실패한다(히스토리를 줄이는 정리 뒤에도 안전망이 된다). 릴리스가 있는데 어느 제목에서도 코드를 읽지 못하면(제목 형식이 바뀐 경우) 검사가 눈먼 채 통과하지 않도록 실패한다. 이미 Release가 만들어진 같은 커밋을 다시 돌리면 코드가 같아 검사에서 실패하는 것이 정상이다(새 커밋과 새 태그로 올린다).

**로컬**:

```bash
export GODOT=/path/to/Godot_v4.7.2-stable_linux.x86_64
.github/scripts/install-godot-templates.sh /tmp/godot-tpz     # 안드로이드 템플릿 (SHA-512 확인)
export GODOT_ANDROID_KEYSTORE_RELEASE_PATH=/path/to/upload.jks
export GODOT_ANDROID_KEYSTORE_RELEASE_USER=upload
export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD=...
apps/lab3d/tools/build.sh play
```

- 결과: `apps/lab3d/exports/android/puppy-land-<versionName>-v<versionCode>.aab`
- versionCode = HEAD까지의 커밋 수, versionName = 가장 가까운 `v*` 태그(`v0.1.1` → `0.1.1`, 없으면 `0.1.0`). `VERSION_CODE`·`VERSION_NAME`으로 덮어쓸 수 있다.
- 키 환경변수 3개가 없거나, 키스토어 파일이 없거나, 별칭이 `androiddebugkey`이면 빌드가 거부된다.
- Godot 편집기 설정의 Android SDK·Java 경로가 맞아야 한다(`export/android/android_sdk_path`, `java_sdk_path`).

## 4. 올리기 전 확인 (2026-11-02 시험용 키로 확인함)

값은 Godot 4.7.2 Android 템플릿 기본값이다(`export_presets.cfg`에 따로 적지 않음). 확인 방법: AAB를 `unzip`해 `base/lib/arm64-v8a/*.so`의 `readelf -lW` LOAD 정렬이 `0x4000`인지, `base/manifest/AndroidManifest.xml`의 `uses-permission`을, 빌드 뒤 `apps/lab3d/android/build/config.gradle`의 `targetSdk`·`minSdk`를 본다.

- `targetSdk` 36, `minSdk` 24, arm64-v8a만, 네이티브 라이브러리 16KB 정렬.
- 매니페스트의 `uses-permission`은 결제 플러그인(#77, GodotGooglePlayBilling 3.3.0, Play Billing Library 9.1.0)이 가져온 것뿐이다: `com.android.vending.BILLING`, 그리고 결제 라이브러리의 의존성(`com.google.android.datatransport:transport-backend-cct`)이 넣는 `INTERNET`·`ACCESS_NETWORK_STATE`. 프리셋의 `permissions/internet`은 꺼져 있다(2026-11-08 Play 빌드로 확인). 바뀌면 Data safety 답을 다시 본다.
- 두 Android 프리셋 모두 `user_data_backup/allow=true`(Android 자동 백업, #77): 새 기기·재설치 때 진행 기록이 돌아온다. 구매는 Play에 다시 묻는다(IslandStore).
- "Android" 프리셋(기기 확인용, Gradle 아님)에는 결제 플러그인이 들어가지 않는다(`addons/GodotGooglePlayBilling/export_plugin.gd`가 Gradle 빌드에서만 AAR을 넣게 고침). 결제는 "Android Play" 빌드에서만 된다.

## 5. Play Console 순서 (개인 계정)

1. 앱 만들기: 이름·기본 언어 한국어·앱(게임 아님/교육용인지 정책에 맞게 선택)·무료.
2. 앱 콘텐츠: 개인정보처리방침 URL `https://jwgung.github.io/puppy-land/privacy/`(`site/privacy`. **main에 머지돼 Pages 배포가 끝난 뒤에야 열리므로** 그 뒤에 입력한다), 광고 없음, 대상 연령(아동 포함 → Families 정책), 콘텐츠 등급(IARC), 데이터 보안(수집·공유 없음. 구매 내역도 "수집 안 함": 구매 확인은 기기와 Google Play 사이에서만 한다. 결제 라이브러리의 인터넷 권한과 Android 백업이 '수집'에 드는지는 Console 도움말 전문으로 확인한다, #77), 앱 액세스(로그인 없음).
3. 스토어 등록정보: `docs/release/store/` 의 그림·스크린샷. 한국어(기본)는 `feature-graphic-ko.png`·`screenshots/ko-*.png`, 영어(en-US)는 `feature-graphic-en.png`·`screenshots/en-*.png`를 쓴다. 그래픽은 Pillow가 필요하다(`pip install pillow`). `python3 docs/release/store/make_store_art.py`로 만든다(영어는 `scene-throw-en.png`가 있을 때). ko 그림은 `capture_store_shots.gd`가 만들고, 영어 그림은 영어 빌드를 태블릿에서 손으로 찍은 것이다.
4. **비공개 테스트** 트랙에 AAB 업로드(태그를 push하면 3절의 `play` job이 올린다. 같은 versionCode를 Console에서 또 올리지 않는다. 서비스 계정을 아직 안 만들었다면 Console에서 직접 올린다) → 테스터 12명 이상이 **14일 연속** 참여해야 프로덕션을 신청할 수 있다(2023-11 이후 만든 개인 계정). 테스트를 가장 먼저 시작한다.
5. 프로덕션 신청 → 심사.

## 6. 정책 메모

- 광고·분석·추적 SDK를 넣지 않는다. 계정·서버 없음. 결제는 Google Play 결제만(ADR 0005, #77): 둘째 섬부터 섬마다 일회성 상품 `island_<섬 id>`.
- 결제 안내는 보호자 확인(`a × b + c`, ParentalGate) 뒤에만 나온다. 아이에게 사라고 권하는 말을 쓰지 않는다(Families 정책: 감정을 이용한 결제 유도 금지).
- 출시(Play) 빌드는 실행 인자 중 `--quality=`·`--q-*`·`--fps=`·`--ui-size=`만 읽는다(`Quality.PLAY_ARGS`). 측정·개발용 인자(`--experiment=`, `--demo-*`, `--islands=open`, `--store=` 등)는 "Android" 빌드에서만 된다.
- 외부 링크·AI 앱으로 보내는 기능("AI에게 더 물어보기")은 보호자 확인(parental gate) 없이는 꺼 둔다(`ScienceNote.enabled = false`).
