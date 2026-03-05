# ASW Lab 3 - Despliegue Automatizado en Azure

Proyecto de automatización de infraestructura en Azure utilizando Terraform y Ansible para desplegar una máquina virtual preparada para ejecutar aplicaciones Docker.

**Autor**: UO302313 - David Fernando Bolaños López  
**Asignatura**: Arquitectura del Software 2025-26  
**Universidad**: Universidad de Oviedo

---

## 📋 Descripción

Implementación de infraestructura como código (IaC) que automatiza:

1. **Aprovisionamiento de infraestructura** en Azure mediante Terraform
2. **Configuración de software** mediante Ansible (Docker, firewall, herramientas)
3. **Preparación para despliegue** de aplicaciones containerizadas

El resultado es una máquina virtual Ubuntu lista para ejecutar aplicaciones con Docker Compose.

---

## 🏛️ Infraestructura Desplegada

### Recursos Azure

- **Resource Group**: Grupo de recursos para organizar componentes
- **Virtual Network**: Red virtual con subnet (10.10.0.0/16)
- **Network Security Group**: Reglas de firewall gestionadas
- **Public IP**: IP pública estática para acceso web
- **Network Interface**: Interfaz de red de la VM
- **Virtual Machine**: Ubuntu 22.04 LTS (Standard_B2ats_v2)

### Configuración de la VM

| Componente | Especificación |
|------------|------------------|
| **Sistema Operativo** | Ubuntu 22.04 LTS (Jammy) |
| **Tamaño** | Standard_B2ats_v2 (2 vCPUs, 1 GiB RAM) |
| **Ubicación** | France Central |
| **Almacenamiento** | Standard LRS (managed disk) |
| **Acceso** | SSH con clave pública |

### Puertos Abiertos

| Puerto | Protocolo | Uso |
|--------|-----------|-----|
| 22 | TCP | SSH |
| 80 | TCP | HTTP |
| 3000 | TCP | Aplicación |
| 4000 | TCP | Aplicación |
| 9090 | TCP | Monitoring |
| 9091 | TCP | Monitoring |

### Software Instalado

- ✓ **Docker Engine** (instalación oficial)
- ✓ **Docker Compose** (plugin moderno)
- ✓ **UFW Firewall** (configurado y activo)
- ✓ Herramientas esenciales (git, vim, curl, htop, jq, etc.)

---

## ⚙️ Requisitos Previos

### 1. Software Local

#### Azure CLI
```bash
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

#### Terraform >= 1.5
```bash
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
```

#### Ansible >= 2.14
```bash
sudo apt update
sudo apt install ansible
```

#### jq (procesamiento JSON)
```bash
sudo apt install jq
```

### 2. Clave SSH

Genera un par de claves SSH si aún no tienes:

```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
```

La clave pública se encuentra en `~/.ssh/id_rsa.pub`.

### 3. Autenticación en Azure

```bash
# Iniciar sesión
az login

# Verificar suscripción activa
az account show

# (Opcional) Cambiar suscripción
az account list --output table
az account set --subscription "Azure for Students"
```

---

## 🚀 Guía de Despliegue

### Paso 1: Configurar Variables

```bash
# Clonar repositorio (si no lo has hecho)
git clone https://github.com/BolanosDavid/3-ASW-uniovi.git
cd 3-ASW-uniovi

# Copiar archivo de ejemplo
cp terraform/terraform.tfvars.example terraform/terraform.tfvars

# Editar con tus valores
nano terraform/terraform.tfvars
```

**Valores importantes a configurar:**

```hcl
# terraform/terraform.tfvars

resource_group_name  = "rg-asw-lab3-uo302313"  # Nombre del Resource Group
location             = "francecentral"          # Región Azure
prefix               = "asw-lab3"               # Prefijo para recursos
vm_name              = "asw-lab3-vm"            # Nombre de la VM
vm_size              = "Standard_B2ats_v2"     # Tamaño de VM (Lab3)
admin_username       = "azureuser"             # Usuario admin
ssh_public_key_path  = "~/.ssh/id_rsa.pub"     # Ruta a tu clave pública
allowed_ssh_cidr     = "TU_IP/32"              # Restricción SSH (recomendado)
author_uo            = "UO302313"              # Tu UO
```

> **🔒 Seguridad SSH**: Reemplaza `allowed_ssh_cidr` con tu IP pública. Para obtenerla: `curl ifconfig.me`

### Paso 2: Desplegar Infraestructura (Terraform)

```bash
# Inicializar Terraform (solo primera vez)
./scripts/terraform-init.sh

# Ver plan de ejecución (opcional pero recomendado)
./scripts/terraform-plan.sh

# Aplicar configuración
./scripts/terraform-apply.sh
```

**Salida esperada:**

```
Apply complete! Resources: 7 added, 0 changed, 0 destroyed.

Outputs:

admin_username = "azureuser"
location = "francecentral"
private_ip = "10.10.1.4"
public_ip = "20.74.123.45"
resource_group_name = "rg-asw-lab3-uo302313"
ssh_command = "ssh azureuser@20.74.123.45"
vm_name = "asw-lab3-vm"
```

⏳ **Tiempo estimado**: 3-5 minutos

### Paso 3: Generar Inventario Ansible

```bash
# Generar inventario dinámico desde outputs de Terraform
./scripts/generate-inventory.sh
```

Esto crea `ansible/inventories/generated/inventory.ini` automáticamente.

### Paso 4: Configurar Software (Ansible)

```bash
# Ejecutar playbook de configuración
./scripts/ansible-run.sh
```

**Ansible instalará:**
- Docker Engine y Docker Compose
- Firewall UFW (con reglas configuradas)
- Paquetes esenciales del sistema

⏳ **Tiempo estimado**: 5-8 minutos

### Paso 5: Verificar Despliegue

```bash
# Script de verificación automática
./scripts/verify-deployment.sh
```

**Verificación manual:**

```bash
# Conectar por SSH
ssh azureuser@<PUBLIC_IP>

# Verificar Docker
docker --version
docker compose version

# Verificar grupo docker
groups

# Verificar firewall
sudo ufw status

# Test Docker
docker run --rm hello-world
```

---

## 📦 Desplegar una Aplicación (Ejemplo)

Una vez la VM esté configurada:

### Ejemplo 1: Servidor Web Nginx

```bash
# Conectar a la VM
ssh azureuser@<PUBLIC_IP>

# Crear directorio de proyecto
mkdir ~/webapp && cd ~/webapp

# Crear docker-compose.yml
cat > docker-compose.yml <<EOF
services:
  web:
    image: nginx:alpine
    ports:
      - "80:80"
    restart: unless-stopped
EOF

# Desplegar
docker compose up -d

# Verificar
curl http://localhost
```

Accede desde tu navegador: `http://<PUBLIC_IP>`

### Ejemplo 2: Aplicación Node.js

```bash
mkdir ~/myapp && cd ~/myapp

# Crear Dockerfile
cat > Dockerfile <<EOF
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
EOF

# Crear docker-compose.yml
cat > docker-compose.yml <<EOF
services:
  app:
    build: .
    ports:
      - "3000:3000"
    restart: unless-stopped
EOF

# Desplegar
docker compose up -d --build
```

### Comandos Útiles Docker Compose

```bash
docker compose up -d          # Iniciar en background
docker compose ps             # Ver contenedores activos
docker compose logs -f        # Ver logs en tiempo real
docker compose restart        # Reiniciar servicios
docker compose down           # Parar y eliminar contenedores
docker compose down -v        # Incluir volúmenes
```

---

## 🗂️ Estructura del Proyecto

```
3-ASW-uniovi/
├── terraform/                   # Infraestructura como código
│   ├── main.tf                  # Definición de recursos Azure
│   ├── variables.tf             # Variables de entrada
│   ├── outputs.tf               # Salidas (IPs, nombres, etc.)
│   ├── providers.tf             # Configuración de providers
│   ├── versions.tf              # Versiones mínimas requeridas
│   └── terraform.tfvars.example # Plantilla de configuración
├── ansible/                     # Gestión de configuración
│   ├── ansible.cfg              # Configuración de Ansible
│   ├── playbooks/
│   │   ├── site.yml             # Playbook principal (completo)
│   │   └── base.yml             # Playbook base (solo paquetes)
│   ├── roles/
│   │   ├── common/              # Paquetes y configuración base
│   │   ├── docker/              # Instalación de Docker
│   │   └── firewall/            # Configuración UFW
│   └── inventories/
│       ├── generated/           # Inventario auto-generado
│       └── static/              # Ejemplo de inventario estático
├── scripts/                     # Scripts de automatización
│   ├── terraform-init.sh        # Inicializar Terraform
│   ├── terraform-plan.sh        # Ver plan de cambios
│   ├── terraform-apply.sh       # Aplicar infraestructura
│   ├── generate-inventory.sh    # Generar inventario Ansible
│   ├── ansible-run.sh           # Ejecutar playbook
│   └── verify-deployment.sh     # Verificar despliegue
└── README.md                    # Esta documentación
```

---

## 🧹 Limpieza de Recursos

**⚠️ IMPORTANTE**: Esto eliminará **TODA** la infraestructura desplegada en Azure.

```bash
cd terraform
terraform destroy

# Confirmar escribiendo 'yes' cuando se solicite
```

Verifica en Azure Portal que todos los recursos se hayan eliminado.

---

## 🔍 Troubleshooting

### Error: "Authentication failed"

**Problema**: No estás autenticado en Azure o la sesión expiró.

**Solución**:
```bash
az login
az account show
```

### Error: "SSH connection refused"

**Problema**: La VM aún está iniciando o el firewall bloquea tu IP.

**Solución**:
1. Espera 1-2 minutos después de `terraform apply`
2. Verifica que tu IP esté permitida en `allowed_ssh_cidr`
3. Comprueba reglas NSG:
   ```bash
   az network nsg rule list --resource-group <RG_NAME> --nsg-name <NSG_NAME> -o table
   ```

### Error: "Permission denied (publickey)"

**Problema**: La clave SSH no coincide.

**Solución**:
1. Verifica la clave pública:
   ```bash
   cat ~/.ssh/id_rsa.pub
   ```
2. Asegúrate de que `ssh_public_key_path` en `terraform.tfvars` apunta a la clave correcta
3. Vuelve a aplicar:
   ```bash
   terraform taint azurerm_linux_virtual_machine.main
   terraform apply
   ```

### Ansible: "Host unreachable"

**Problema**: Inventario desactualizado o VM no accesible.

**Solución**:
```bash
# Regenerar inventario
./scripts/generate-inventory.sh

# Verificar inventario
cat ansible/inventories/generated/inventory.ini

# Test de conexión
cd ansible
ansible deployment_vm -m ping
```

### Docker: "permission denied while trying to connect"

**Problema**: El usuario no está en el grupo `docker`.

**Solución**:
```bash
# Cerrar sesión SSH y volver a entrar
exit
ssh azureuser@<PUBLIC_IP>

# Verificar pertenencia al grupo
groups

# Debe aparecer 'docker' en la lista
```

### Firewall: "Port is not accessible"

**Problema**: El puerto no está abierto en NSG o UFW.

**Solución NSG** (Azure):
```bash
az network nsg rule create \
  --resource-group <RG_NAME> \
  --nsg-name <NSG_NAME> \
  --name allow-port-XXXX \
  --priority 200 \
  --destination-port-ranges XXXX \
  --access Allow \
  --protocol Tcp
```

**Solución UFW** (VM):
```bash
ssh azureuser@<PUBLIC_IP>
sudo ufw allow XXXX/tcp
sudo ufw status
```

### Terraform: "Resource already exists"

**Problema**: Recursos previos no eliminados completamente.

**Solución**:
```bash
# Importar recurso existente
terraform import azurerm_resource_group.main /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/<RG_NAME>

# O eliminar manualmente desde Azure Portal y volver a aplicar
```

---

## 📚 Referencias

### Documentación Oficial

- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Ansible Documentation](https://docs.ansible.com/)
- [Docker Installation on Ubuntu](https://docs.docker.com/engine/install/ubuntu/)
- [Docker Compose Specification](https://docs.docker.com/compose/compose-file/)
- [Azure Virtual Machines](https://learn.microsoft.com/en-us/azure/virtual-machines/)
- [Azure CLI Documentation](https://learn.microsoft.com/en-us/cli/azure/)

### Recursos del Curso

- Diapositivas Lab3: ES.ASW.PL03_Despliegue.pdf
- GitHub Actions para despliegue continuo
- Docker Hub: https://hub.docker.com/

---

## 📝 Notas de Implementación

### Decisiones Técnicas

- **VM Size**: Standard_B2ats_v2 optimizado para cargas con bajo uso de CPU (burstable)
- **Docker Compose**: Plugin moderno (`docker compose`) en lugar de legacy (`docker-compose`)
- **Firewall**: Doble capa (NSG en Azure + UFW en VM) para máxima flexibilidad
- **Inventario dinámico**: Sincronización automática entre Terraform y Ansible
- **Tags**: Metadatos para organización y billing

### Seguridad

- SSH con clave pública (password authentication disabled)
- NSG con reglas restrictivas configurables
- UFW firewall activo por defecto
- Actualizaciones de paquetes gestionadas por Ansible

### Optimizaciones

- Ansible con pipelining SSH habilitado
- Idempotencia en todos los playbooks
- Outputs informativos en cada paso
- Scripts con validación de errores (`set -e`)

---

## 👤 Autor

**David Fernando Bolaños López**  
UO302313  
Arquitectura del Software 2025-26  
Escuela de Ingeniería Informática  
Universidad de Oviedo

---

## 📜 Licencia

Este proyecto es material educativo de la Universidad de Oviedo para la asignatura Arquitectura del Software.

---

## ❓ Soporte

Para problemas o preguntas:

1. Revisa la sección **Troubleshooting** de este README
2. Consulta la documentación oficial en **Referencias**
3. Verifica los logs:
   - Terraform: `terraform show`
   - Ansible: `ansible-playbook -vvv`
   - Docker: `docker logs <container_name>`

---

© 2026 Universidad de Oviedo - Todos los derechos reservados
