# words-Demo - 沃茲場地租借 demo - 靜態網頁服務
FROM nginx:alpine

# 把 rental-page 整個複製到 nginx 預設根目錄
COPY rental-page/ /usr/share/nginx/html/

# 容器內部 nginx 預設 80 port
EXPOSE 80
