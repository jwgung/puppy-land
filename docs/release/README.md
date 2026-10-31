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

## 2. GitHub 시크릿

저장소 Settings → Secrets and variables → Actions:

| 이름 | 값 |
|---|---|
| `UPLOAD_KEYSTORE_BASE64` | `base64 -w0 upload.jks` 출력 |
| `UPLOAD_STORE_PASSWORD` | 키스토어(=키) 비밀번호 |

## 3. 빌드

**CI(권장)**: `git tag v0.1.1 && git push origin v0.1.1` → `.github/workflows/release.yml`이 서명된 AAB를 만들어 GitHub Release에 붙인다. 수동 실행(workflow_dispatch)은 아티팩트만 올린다.

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
- 매니페스트에 `uses-permission`이 없다(`internet` 권한도 꺼져 있음). 바뀌면 Data safety 답을 다시 본다.

## 5. Play Console 순서 (개인 계정)

1. 앱 만들기: 이름·기본 언어 한국어·앱(게임 아님/교육용인지 정책에 맞게 선택)·무료.
2. 앱 콘텐츠: 개인정보처리방침 URL `https://jwgung.github.io/puppy-land/privacy/`(`site/privacy`. **main에 머지돼 Pages 배포가 끝난 뒤에야 열리므로** 그 뒤에 입력한다), 광고 없음, 대상 연령(아동 포함 → Families 정책), 콘텐츠 등급(IARC), 데이터 보안(수집·공유 없음), 앱 액세스(로그인 없음).
3. 스토어 등록정보: `docs/release/store/` 의 그림·스크린샷.
4. **비공개 테스트** 트랙에 AAB 업로드 → 테스터 12명 이상이 **14일 연속** 참여해야 프로덕션을 신청할 수 있다(2023-11 이후 만든 개인 계정). 테스트를 가장 먼저 시작한다.
5. 프로덕션 신청 → 심사.

## 6. 정책 메모

- 광고·분석·추적 SDK를 넣지 않는다. 계정·서버·외부 결제 없음.
- 외부 링크·AI 앱으로 보내는 기능("AI에게 더 물어보기")은 보호자 확인(parental gate) 없이는 꺼 둔다(`ScienceNote.enabled = false`).
