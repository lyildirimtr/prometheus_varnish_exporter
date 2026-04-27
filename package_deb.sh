#!/bin/bash
set -e

# Versiyon ve mimari bilgileri
VERSION="1.33.0-varnish8"
ARCH="arm64"
PKG_DIR="prometheus-varnish-exporter_${VERSION}_${ARCH}"

echo "Paket dizin yapısı oluşturuluyor: ${PKG_DIR}"
mkdir -p ${PKG_DIR}/DEBIAN
mkdir -p ${PKG_DIR}/usr/bin
mkdir -p ${PKG_DIR}/lib/systemd/system

# Derlenen binary dosyasını kopyala
if [ ! -f "prometheus_varnish_exporter_linux_arm64" ]; then
    echo "Hata: prometheus_varnish_exporter_linux_arm64 dosyası bulunamadı."
    echo "Önce derleme işlemini yapmalısınız."
    exit 1
fi

cp prometheus_varnish_exporter_linux_arm64 ${PKG_DIR}/usr/bin/prometheus_varnish_exporter
chmod 755 ${PKG_DIR}/usr/bin/prometheus_varnish_exporter

# Debian control dosyasını oluştur
cat <<EOF > ${PKG_DIR}/DEBIAN/control
Package: prometheus-varnish-exporter
Version: ${VERSION}
Section: net
Priority: optional
Architecture: ${ARCH}
Maintainer: DevOps Team
Description: Prometheus exporter for Varnish Cache 8.x
 A Prometheus metrics exporter for Varnish Cache.
 Updated and customized to fully support Varnish 8.
EOF

# Systemd servis dosyasını oluştur
cat <<EOF > ${PKG_DIR}/lib/systemd/system/prometheus-varnish-exporter.service
[Unit]
Description=Prometheus Varnish Exporter
After=network.target varnish.service
Requires=varnish.service

[Service]
Type=simple
User=root
Group=root
Restart=on-failure
ExecStart=/usr/bin/prometheus_varnish_exporter

[Install]
WantedBy=multi-user.target
EOF

# Mac üzerinde dpkg kurulu değilse uyar, kuruluysa paketi yap
if ! command -v dpkg-deb &> /dev/null; then
    echo "Hata: Sisteminizde 'dpkg-deb' aracı bulunamadı."
    echo "macOS kullanıyorsanız kurmak için şu komutu çalıştırın: brew install dpkg"
    exit 1
fi

echo "DEB paketi derleniyor..."
dpkg-deb --build ${PKG_DIR}

echo "Başarılı! Paket oluşturuldu: ${PKG_DIR}.deb"
