#!/bin/bash

# Script test kết nối SMTP và gửi email
# Cấu hình email trực tiếp trong file này

set -e

# Màu sắc cho output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ============================================
# CẤU HÌNH EMAIL - Sửa các thông tin bên dưới
# ============================================
MAIL_HOST="smtp.gmail.com"
MAIL_PORT="587"
MAIL_USER="contactasean@passagetoasean.org"
MAIL_PASSWORD="budjjnjvjpnidmwu"
MAIL_FROM="noreply@p2a-asean.org"
MAIL_FROM_NAME="P2A ASEAN Platform"
TEST_TO_EMAIL="conghuancse@gmail.com"
# ============================================

# Kiểm tra các biến có giá trị không
if [ -z "$MAIL_HOST" ] || [ -z "$MAIL_PORT" ] || [ -z "$MAIL_USER" ] || [ -z "$MAIL_PASSWORD" ]; then
    echo -e "${RED}❌ Thiếu cấu hình email trong script${NC}"
    echo "Vui lòng cấu hình MAIL_HOST, MAIL_PORT, MAIL_USER, MAIL_PASSWORD trong file này"
    exit 1
fi

echo -e "${GREEN}✅ Cấu hình email:${NC}"
echo "  MAIL_HOST: $MAIL_HOST"
echo "  MAIL_PORT: $MAIL_PORT"
echo "  MAIL_USER: $MAIL_USER"
echo "  MAIL_FROM: ${MAIL_FROM:-$MAIL_USER}"
echo "  MAIL_FROM_NAME: ${MAIL_FROM_NAME:-P2A ASEAN Platform}"
echo "  Gửi đến: $TEST_TO_EMAIL"
echo ""

# Test DNS resolution
echo -e "${YELLOW}🔍 Đang test DNS resolution cho $MAIL_HOST...${NC}"
if command -v nslookup &> /dev/null; then
    if nslookup "$MAIL_HOST" &> /dev/null; then
        echo -e "${GREEN}✅ DNS resolution thành công${NC}"
    else
        echo -e "${RED}❌ DNS resolution thất bại${NC}"
        echo "Kiểm tra kết nối mạng và DNS settings"
    fi
elif command -v host &> /dev/null; then
    if host "$MAIL_HOST" &> /dev/null; then
        echo -e "${GREEN}✅ DNS resolution thành công${NC}"
    else
        echo -e "${RED}❌ DNS resolution thất bại${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Không tìm thấy nslookup/host, bỏ qua DNS test${NC}"
fi

echo ""

# Test kết nối SMTP bằng telnet (nếu có)
if command -v telnet &> /dev/null || command -v nc &> /dev/null; then
    echo -e "${YELLOW}🔌 Đang test kết nối SMTP đến $MAIL_HOST:$MAIL_PORT...${NC}"
    if command -v nc &> /dev/null; then
        if timeout 5 nc -zv "$MAIL_HOST" "$MAIL_PORT" 2>&1 | grep -q "succeeded\|open"; then
            echo -e "${GREEN}✅ Kết nối SMTP thành công${NC}"
        else
            echo -e "${RED}❌ Không thể kết nối đến $MAIL_HOST:$MAIL_PORT${NC}"
        fi
    elif command -v telnet &> /dev/null; then
        if timeout 5 bash -c "echo > /dev/tcp/$MAIL_HOST/$MAIL_PORT" 2>/dev/null; then
            echo -e "${GREEN}✅ Kết nối SMTP thành công${NC}"
        else
            echo -e "${RED}❌ Không thể kết nối đến $MAIL_HOST:$MAIL_PORT${NC}"
        fi
    fi
    echo ""
fi

# Tạo script Node.js tạm thời để test gửi email
TEST_SCRIPT=$(mktemp)

# Xử lý MAIL_FROM và MAIL_FROM_NAME với giá trị mặc định
MAIL_FROM_VALUE="${MAIL_FROM:-$MAIL_USER}"
MAIL_FROM_NAME_VALUE="${MAIL_FROM_NAME:-P2A ASEAN Platform}"

cat > "$TEST_SCRIPT" << 'NODE_SCRIPT_END'
const nodemailer = require('nodemailer');

const config = {
  host: process.env.MAIL_HOST,
  port: parseInt(process.env.MAIL_PORT || '587', 10),
  secure: process.env.MAIL_PORT === '465',
  auth: {
    user: process.env.MAIL_USER,
    pass: process.env.MAIL_PASSWORD,
  },
};

const fromEmail = process.env.MAIL_FROM || process.env.MAIL_USER;
const fromName = process.env.MAIL_FROM_NAME || 'P2A ASEAN Platform';
const toEmail = process.env.TEST_TO_EMAIL || 'conghuancse@gmail.com';

console.log('📧 Cấu hình SMTP:');
console.log(`  Host: ${config.host}`);
console.log(`  Port: ${config.port}`);
console.log(`  Secure: ${config.secure}`);
console.log(`  User: ${config.auth.user}`);
console.log(`  From: "${fromName}" <${fromEmail}>`);
console.log(`  To: ${toEmail}`);
console.log('');

// Tạo transporter
const transporter = nodemailer.createTransport(config);

async function testEmail() {
  try {
    console.log('🔍 Đang verify SMTP connection...');
    await transporter.verify();
    console.log('✅ SMTP connection verified successfully!\n');

    console.log('📤 Đang gửi test email...');
    const info = await transporter.sendMail({
      from: `"${fromName}" <${fromEmail}>`,
      to: toEmail,
      subject: 'Test Email từ P2A Core System',
      html: `
        <h2>Test Email từ P2A Core System</h2>
        <p>Đây là email test để kiểm tra cấu hình SMTP.</p>
        <p><strong>Thông tin:</strong></p>
        <ul>
          <li>Host: ${config.host}</li>
          <li>Port: ${config.port}</li>
          <li>User: ${config.auth.user}</li>
          <li>Time: ${new Date().toISOString()}</li>
        </ul>
        <p>Nếu bạn nhận được email này, cấu hình SMTP đã hoạt động đúng!</p>
      `,
      text: `
Test Email từ P2A Core System

Đây là email test để kiểm tra cấu hình SMTP.

Thông tin:
- Host: ${config.host}
- Port: ${config.port}
- User: ${config.auth.user}
- Time: ${new Date().toISOString()}

Nếu bạn nhận được email này, cấu hình SMTP đã hoạt động đúng!
      `,
    });

    console.log('✅ Email đã được gửi thành công!');
    console.log(`   Message ID: ${info.messageId}`);
    console.log(`   Response: ${info.response}`);
    console.log('');
    console.log('📬 Vui lòng kiểm tra hộp thư của bạn tại:', toEmail);
    process.exit(0);
  } catch (error) {
    console.error('❌ Lỗi khi gửi email:');
    console.error(`   Code: ${error.code || 'N/A'}`);
    console.error(`   Message: ${error.message || error}`);
    if (error.response) {
      console.error(`   Response: ${error.response}`);
    }
    process.exit(1);
  }
}

testEmail();
NODE_SCRIPT_END

# Kiểm tra xem có Node.js và nodemailer không
if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ Node.js không được cài đặt${NC}"
    rm -f "$TEST_SCRIPT"
    exit 1
fi

# Kiểm tra nodemailer trong node_modules
NODEMAILER_PATH=""
if [ -f "node_modules/nodemailer/package.json" ]; then
    NODEMAILER_PATH="node_modules/nodemailer"
elif [ -f "../node_modules/nodemailer/package.json" ]; then
    NODEMAILER_PATH="../node_modules/nodemailer"
elif [ -f "../../p2a-core-system/node_modules/nodemailer/package.json" ]; then
    NODEMAILER_PATH="../../p2a-core-system/node_modules/nodemailer"
else
    echo -e "${YELLOW}⚠️  Không tìm thấy nodemailer trong node_modules${NC}"
    echo "Đang cài đặt nodemailer tạm thời..."
    npm install nodemailer --no-save --silent
    NODEMAILER_PATH="node_modules/nodemailer"
fi

echo -e "${YELLOW}📧 Đang test gửi email đến $TEST_TO_EMAIL...${NC}"
echo ""

# Export các biến môi trường cho Node.js script
export MAIL_HOST
export MAIL_PORT
export MAIL_USER
export MAIL_PASSWORD
export MAIL_FROM="$MAIL_FROM_VALUE"
export MAIL_FROM_NAME="$MAIL_FROM_NAME_VALUE"
export TEST_TO_EMAIL

# Chạy script
if node "$TEST_SCRIPT"; then
    echo -e "${GREEN}✅ Test email thành công!${NC}"
    rm -f "$TEST_SCRIPT"
    exit 0
else
    echo -e "${RED}❌ Test email thất bại!${NC}"
    rm -f "$TEST_SCRIPT"
    exit 1
fi