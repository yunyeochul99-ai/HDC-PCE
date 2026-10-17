# HDC PCE 설비보전 통합 앱

휴대폰 현장 점검과 PC 대시보드가 같은 Supabase 자료를 사용하는 React·Vite 앱입니다. 통합 대시보드, 현장 점검, 정비 작업, 설비 자산, 수선비 분석, 경영 보고와 계정 승인을 제공합니다.

소스 버전은 `3.0.0`입니다. 이 README는 배포 구성을 설명하며 실제 운영 배포 여부를 증명하지 않습니다.

## 배포 대상

| 구분 | 값 |
| --- | --- |
| 공개 저장소 | [yunyeochul99-ai/HDC-PCE](https://github.com/yunyeochul99-ai/HDC-PCE) |
| 배포 브랜치 | `main` |
| 앱 URL | [hdc-pce.netlify.app](https://hdc-pce.netlify.app) |
| Supabase 프로젝트 URL | `https://mfqnaopqlerqddyomscv.supabase.co` |
| Node | `22` 이상, 패키지 요구 버전 `22.13.0` 이상 |
| 패키지 관리 | `pnpm` · `pnpm-lock.yaml` 포함 |
| 빌드 / 배포 폴더 | `pnpm run build` / `dist` |

## 개발과 빌드

이 폴더의 내용을 저장소 루트로 사용합니다. Node와 pnpm이 설치된 환경에서 실행합니다.

```sh
pnpm install --frozen-lockfile
pnpm run dev
pnpm run build
pnpm run preview
```

`build`는 TypeScript 검사 후 정적 파일을 `dist`에 생성합니다. `netlify.toml`이 빌드와 SPA 경로 처리를 지정합니다. 저장소와 연결한 Netlify는 `main` 커밋을 받아 새로 빌드하도록 설정합니다.

## 주요 파일

| 파일 | 용도 |
| --- | --- |
| `src/Workspace.tsx` | 점검·작업·대시보드·분석·보고 화면 |
| `src/AuthGate.tsx` | Supabase 로그인, 가입 요청, 프로필과 관리자 화면 |
| `src/backend.ts` | Supabase DB·사진 업로드·서명 URL 연결 |
| `public-config.ts` | 프로젝트 URL과 브라우저용 publishable key |
| `public/manifest.webmanifest`, `public/sw.js` | 홈 화면 설치와 앱 화면 캐시 |
| `netlify.toml` | Node·빌드·배포·경로 설정 |
| `pnpm-lock.yaml` | 설치 의존성 잠금 파일 |

## 계정과 저장 권한

기존 아이디는 `아이디@hdc-pce.netlify.app` 형태의 기존 Supabase 계정으로 로그인합니다. 신규 가입은 실제 이메일을 사용하고 이메일 확인·공장 관리자 승인을 거칩니다. Google 계정 로그인과는 별개입니다.

승인된 공장 구성원은 공장 기준자료, 점검·작업 기록과 현장 사진을 조회합니다. 기록 수정은 작성자 또는 관리자만 수행합니다. 관리자만 사용자 승인과 기준자료 가져오기를 수행하며 첫 가입자에게 관리자 권한을 자동 부여하지 않습니다. 앱 프로필의 표시 이름은 계정 설정에서 `윤공장장` 등으로 변경합니다.

기준자료는 로그인 후 `hdc_v2_seed`에서 가져옵니다. 실제 수선비 원장·설비 자료를 `public/data.json`이나 JavaScript 번들에 넣지 않습니다. 사진은 Supabase 비공개 버킷에 저장하고 필요한 동안만 유효한 서명 URL로 표시합니다.

네트워크 연결이 끊긴 기기 임시 기록은 해당 계정·기기에 남습니다. 다시 연결한 뒤 전송을 완료해야 다른 기기에서 보이며, 사진 첨부에는 네트워크가 필요합니다. 계정 로그아웃 전 기기 임시 기록 상태를 확인합니다.

## 공개 저장소에 넣는 범위

공개 저장소에는 이 폴더의 앱 소스·정적 아이콘·설정·잠금 파일만 반영합니다. 다음 자료를 포함하지 않습니다.

- 실제 회사 원본·수선비 원장·기준자료 JSON
- `03_Supabase` 비공개 전달 폴더와 원본 JSON 내장 SQL
- 점검·작업 백업 JSON과 현장 사진
- service role key, secret key, DB 비밀번호, 로그인 토큰
- `node_modules`, 빌드 산출물 `dist`, 로컬 `.env`

`public-config.ts`의 publishable key는 브라우저 연결에 사용하는 공개 키입니다. 데이터 접근은 DB의 승인·역할·RLS와 Storage 정책으로 제한해야 합니다. 실제 SQL 적용과 권한 검증은 별도 비공개 운영 패키지의 `README_SETUP.md`를 따릅니다.

기존 `check_records`와 Sites D1·R2 기록은 별도로 보존합니다. 새 테이블로 자동 변환하는 배포가 아니며, 이전 JSON에 있는 사진 ID만으로 사진 파일을 옮길 수 없습니다.

## 운영 확인

배포 후 PC에서 점검 1건을 저장하고 휴대폰에서 같은 기록을 확인합니다. 사진 저장·재조회, 작성자·관리자 수정, 일반 구성원의 타인 기록 수정 차단, 미승인 계정의 자료 차단을 확인합니다. 같은 기록의 오래된 버전을 저장하면 충돌을 표시하고 최신 내용을 확인해야 합니다.

참고: [Supabase API 키](https://supabase.com/docs/guides/getting-started/api-keys), [RLS](https://supabase.com/docs/guides/database/postgres/row-level-security), [Netlify Vite 배포](https://docs.netlify.com/build/frameworks/framework-setup-guides/vite/).
