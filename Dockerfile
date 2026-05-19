# ================================
# Stage 1: Builder
# ================================
FROM node:18-alpine AS builder

WORKDIR /app

# Copiar solo package.json primero (optimiza cache de capas)
COPY package*.json ./

# Instalar dependencias
RUN npm ci --only=production

# ================================
# Stage 2: Production
# ================================
FROM node:18-alpine AS production

# Crear usuario no root (seguridad)
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# Copiar dependencias desde stage builder
COPY --from=builder /app/node_modules ./node_modules

# Copiar código fuente
COPY . .

# Asignar permisos al usuario no root
RUN chown -R appuser:appgroup /app

# Cambiar a usuario no root
USER appuser

# Puerto que expone el backend
EXPOSE 3000

# Comando de inicio
CMD ["node", "server.js"]