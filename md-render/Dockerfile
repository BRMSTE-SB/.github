# BRMSTE branded MD render — container image
# BRMSTE LTD · Companies House 15310393 · GB2607860
#
# Build from the REPO ROOT (it renders the repo's Markdown at build time):
#   docker build -f md-render/Dockerfile -t brmste-md-render .
#   docker run -p 8787:8787 brmste-md-render

FROM node:22-alpine AS build
WORKDIR /repo
COPY . /repo
WORKDIR /repo/md-render
RUN npm install --no-audit --no-fund && node build.mjs

FROM node:22-alpine AS run
WORKDIR /app
ENV PORT=8787 HOST=0.0.0.0 MD_RENDER_DIST=/app/dist NODE_ENV=production
COPY --from=build /repo/md-render/serve.mjs /repo/md-render/headers.mjs ./
COPY --from=build /repo/md-render/dist ./dist
EXPOSE 8787
HEALTHCHECK --interval=30s --timeout=5s CMD wget -qO- http://127.0.0.1:8787/healthz || exit 1
CMD ["node", "serve.mjs"]
