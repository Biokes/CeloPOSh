FROM node:20-alpine
WORKDIR /app

COPY package.json ./
COPY pmpm-lock.yaml ./

RUN npm install -g pnpm && pnpm install

COPY . .
CMD ["pnpm", "run", "dev"]