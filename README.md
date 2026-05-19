# Backend - API REST con Node.js y Express
## Innovatech Chile — Evaluación Parcial N°2

![Docker](https://img.shields.io/badge/Docker-2496ED?style=flat&logo=docker&logoColor=white)
![Node.js](https://img.shields.io/badge/Node.js-18-339933?style=flat&logo=node.js&logoColor=white)
![MySQL](https://img.shields.io/badge/MySQL-8.0-4479A1?style=flat&logo=mysql&logoColor=white)
![GitHub Actions](https://img.shields.io/badge/GitHub_Actions-CI/CD-2088FF?style=flat&logo=github-actions&logoColor=white)

---

## Descripción

Backend API REST desarrollado en Node.js con Express. Proporciona endpoints RESTful para la gestión de usuarios con conexión a base de datos MySQL. Desplegado en AWS EC2 mediante contenedores Docker con pipeline CI/CD automatizado a través de GitHub Actions.

---

## Arquitectura

```
Internet → EC2 Frontend (Flask) → EC2 Backend (Node.js) → EC2 Data (MySQL)
                                        Puerto 3000              Puerto 3306
```

Este servicio opera en una **subred privada** de AWS, accesible únicamente desde la instancia Frontend, cumpliendo el principio de mínimo privilegio.

---

## Tecnologías utilizadas

| Tecnología | Versión | Uso |
|---|---|---|
| Node.js | 18.x | Runtime |
| Express | ^4.18.2 | Framework web |
| mysql2 | ^3.6.0 | Driver MySQL |
| cors | ^2.8.5 | Middleware CORS |
| dotenv | ^16.3.1 | Variables de entorno |
| Docker | latest | Contenedorización |
| GitHub Actions | — | CI/CD pipeline |

---

## Endpoints de la API

| Método | Endpoint | Descripción |
|---|---|---|
| GET | `/api/usuarios` | Obtener todos los usuarios |
| POST | `/api/usuarios` | Crear un nuevo usuario |
| PUT | `/api/usuarios/:id` | Actualizar un usuario |
| DELETE | `/api/usuarios/:id` | Eliminar un usuario |

### Ejemplo de uso

```bash
# Obtener todos los usuarios
curl http://localhost:3000/api/usuarios

# Crear un nuevo usuario
curl -X POST http://localhost:3000/api/usuarios \
  -H "Content-Type: application/json" \
  -d '{"nombre":"Juan Pérez","email":"juan@example.com","edad":25}'
```

---

## Estructura del proyecto

```
Back_EVAL2/
├── server.js                      # Servidor principal Express
├── package.json                   # Dependencias del proyecto
├── Dockerfile                     # Imagen Docker multi-stage
├── docker-compose.yml             # Stack de servicios
├── .env.example                   # Ejemplo de variables de entorno
├── .env                           # Variables de entorno (no incluir en git)
├── .github/
│   └── workflows/
│       └── deploy.yml             # Pipeline CI/CD GitHub Actions
└── README.md                      # Este archivo
```

---

## Contenedorización

### Dockerfile (Multi-stage build)

El Dockerfile implementa un **multi-stage build** para optimizar el tamaño de la imagen:

- **Stage 1 (builder):** Instala las dependencias de producción
- **Stage 2 (production):** Copia solo lo necesario, ejecuta con usuario no root

Beneficios:
- Imagen final más liviana
- Sin herramientas de desarrollo en producción
- Usuario no root para mayor seguridad (`appuser`)

### docker-compose.yml

Define el stack completo con:
- Servicio `backend` con variables de entorno
- Volumen `backend_logs` para persistencia de logs
- Red interna `innovatech-network`

---

## Persistencia de datos

Se utiliza un **named volume** (`backend_logs`) para persistir los logs del Backend:

```yaml
volumes:
  backend_logs:
    driver: local
```

**¿Por qué named volume y no bind mount?**
- El named volume es gestionado por Docker, más portable entre entornos
- No depende de una ruta específica del sistema host
- Sobrevive a reinicios y recreaciones del contenedor

---

## Pipeline CI/CD

El pipeline de GitHub Actions se activa automáticamente con cada `push` a la rama `deploy` y ejecuta tres etapas:

```
push a rama deploy
        ↓
1. BUILD  → Construye la imagen Docker
        ↓
2. PUSH   → Publica en Docker Hub (patatan7/backend-innovatech:latest)
        ↓
3. DEPLOY → Conecta al Frontend (Jump Host) → despliega en EC2 Backend
```

### GitHub Secrets requeridos

| Secret | Descripción |
|---|---|
| `DOCKERHUB_USERNAME` | Usuario de Docker Hub |
| `DOCKERHUB_TOKEN` | Token de acceso Docker Hub |
| `EC2_HOST` | IP pública del Frontend (Jump Host) |
| `EC2_USER` | Usuario SSH (ec2-user) |
| `EC2_SSH_KEY` | Llave privada SSH (.pem) |
| `EC2_BACKEND_HOST` | IP privada del Backend |
| `DB_HOST` | IP privada del Data |
| `DB_USER` | Usuario MySQL |
| `DB_PASSWORD` | Contraseña MySQL |
| `DB_NAME` | Nombre base de datos |

> **Nota de seguridad:** El Backend se despliega a través del Frontend como Jump Host, ya que opera en subred privada sin IP pública expuesta a internet.

---

## Configuración local

### Prerrequisitos

- Node.js 18+
- Docker Desktop
- MySQL corriendo (o usar docker-compose)

### Instalación

```bash
# Clonar el repositorio
git clone https://github.com/TU_USUARIO/Back_EVAL2
cd Back_EVAL2

# Instalar dependencias
npm install

# Copiar variables de entorno
cp .env.example .env
# Editar .env con tus credenciales
```

### Variables de entorno

```env
PORT=3000
DB_HOST=localhost
DB_USER=appuser
DB_PASSWORD=tu_contraseña
DB_NAME=proyecto_db
DB_PORT=3306
```

### Ejecución local

```bash
# Producción
npm start

# Desarrollo (con recarga automática)
npm run dev

# Con Docker
docker-compose up -d
```

---

## Despliegue en AWS EC2

### Requisitos previos en la instancia

```bash
sudo yum update -y
sudo yum install -y docker git
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker ec2-user
```

### Despliegue manual

```bash
docker pull patatan7/backend-innovatech:latest
docker run -d \
  --name backend-innovatech \
  --restart always \
  -p 3000:3000 \
  -e DB_HOST=<IP_DATA> \
  -e DB_USER=appuser \
  -e DB_PASSWORD=<PASSWORD> \
  -e DB_NAME=proyecto_db \
  -e DB_PORT=3306 \
  patatan7/backend-innovatech:latest
```

---

## Principios DevOps aplicados

- **Contenedorización:** Docker con multi-stage build y usuario no root
- **CI/CD:** Pipeline automatizado con GitHub Actions
- **Control de versiones:** Git con rama `deploy` como trigger
- **Infraestructura segura:** Subred privada, acceso restringido por Security Groups
- **Persistencia:** Volúmenes Docker para continuidad operativa
- **Mínimo privilegio:** Usuario no root, acceso solo desde Frontend
