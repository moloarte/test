cat > index.html EOF<<
<H1>${server_text}</H1>
EOF

nohup busybox httpd -f -p "${server_port}" &
