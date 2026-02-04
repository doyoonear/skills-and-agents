#!/bin/bash
# ============================================
# 자율 코딩 에이전트 - 개발 환경 시작 스크립트
# ============================================

set -e

echo "🚀 개발 환경을 시작합니다..."

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. 의존성 확인 및 설치
if [ ! -d "node_modules" ]; then
  echo -e "${YELLOW}📦 의존성을 설치합니다...${NC}"
  if command -v pnpm &> /dev/null; then
    pnpm install
  elif command -v npm &> /dev/null; then
    npm install
  else
    echo -e "${RED}❌ pnpm 또는 npm이 설치되어 있지 않습니다.${NC}"
    exit 1
  fi
fi

# 2. 환경 변수 확인
if [ ! -f ".env.local" ]; then
  if [ -f ".env.example" ]; then
    echo -e "${YELLOW}⚠️  .env.local 파일이 없습니다. .env.example을 복사합니다...${NC}"
    cp .env.example .env.local
    echo -e "${YELLOW}⚠️  .env.local 파일의 값을 설정해주세요.${NC}"
  else
    echo -e "${RED}❌ .env.local 및 .env.example 파일이 없습니다.${NC}"
    echo "환경 변수 파일을 먼저 생성해주세요."
    exit 1
  fi
fi

# 3. 데이터베이스 연결 확인 (선택적)
if command -v supabase &> /dev/null; then
  echo "🗄️  Supabase 상태 확인 중..."
  supabase status 2>/dev/null || echo -e "${YELLOW}⚠️  로컬 Supabase가 실행되지 않았습니다. 원격 DB를 사용합니다.${NC}"
fi

# 4. 기존 개발 서버 종료 (포트 3000)
if lsof -i :3000 &> /dev/null; then
  echo "🔄 기존 개발 서버를 종료합니다..."
  kill $(lsof -t -i:3000) 2>/dev/null || true
  sleep 1
fi

# 5. 개발 서버 시작
echo -e "${GREEN}✅ 개발 서버를 시작합니다...${NC}"
if command -v pnpm &> /dev/null; then
  pnpm dev &
else
  npm run dev &
fi

# 6. 서버 시작 대기
echo "⏳ 서버가 시작될 때까지 대기 중..."
sleep 3

# 7. 상태 확인
if curl -s http://localhost:3000 > /dev/null 2>&1; then
  echo -e "${GREEN}✅ 개발 서버가 정상적으로 시작되었습니다!${NC}"
  echo "📍 URL: http://localhost:3000"
else
  echo -e "${YELLOW}⚠️  서버가 아직 시작 중입니다. 잠시 후 확인해주세요.${NC}"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🤖 자율 코딩 에이전트 준비 완료!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
