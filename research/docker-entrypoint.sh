#!/bin/sh
set -e

# Tạo các thư mục upload cần thiết nếu chưa tồn tại
# Xử lý cả trường hợp volume mount
mkdir -p /app/uploads/researcher-cvs \
         /app/uploads/posters \
         /app/uploads/images \
         /app/uploads/documents \
         /app/uploads/attachments

# Fix quyền cho các thư mục (nếu có quyền root)
# Nếu chạy với user node, bỏ qua bước này (sẽ fail gracefully)
if [ "$(id -u)" = "0" ]; then
  chown -R node:node /app/uploads 2>/dev/null || true
  chmod -R 755 /app/uploads 2>/dev/null || true
fi

# Chuyển sang user node nếu đang chạy với root
if [ "$(id -u)" = "0" ]; then
  exec su-exec node "$@"
else
  exec "$@"
fi

