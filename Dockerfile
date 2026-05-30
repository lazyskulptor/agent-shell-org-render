FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Emacs + 필수 도구
RUN apt-get update && apt-get install -y \
    emacs-nox \
    nodejs npm \
    default-jre \
    texlive-latex-base texlive-latex-extra \
    imagemagick \
    xvfb \
    && npm install -g @mermaid-js/mermaid-cli \
    && apt-get install -y ditaa \
    && apt-get clean

WORKDIR /app
COPY . .

# E2E 테스트 실행
CMD ["make", "test-e2e"]
