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

El resultado es una máquina virtual Ubuntu lista para ejecutar aplicaciones con Docker Compose, **incluyendo Nginx como proxy inverso containerizado**.

---

## 🏛️ Infraestructura Desplegada

### Recursos Azure (Optimizados para Coste Mínimo)

- **Resource Group**: Grupo de recursos para organizar componentes
- **Virtual Network**: Red virtual mínima (requerida por Azure para VMs)
- **Public IP**: IP pública estática para acceso web
- **Network Interface**: Interfaz de red de la VM
- **Network Security Group**: Asociado a la NIC (no a subnet) para eficiencia
- **Virtual Machine**: Ubuntu 22.04 LTS (Standard_B2ats_v2)

> **💰 Optimización de Costes**: La infraestructura está diseñada con el mínimo de recursos necesarios. La VNet/Subnet son requisitos técnicos de Azure (sin coste adicional), y el NSG está asociado directamente a la NIC en lugar de a la subnet para evitar cobros por reglas redundantes.

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
| 80 | TCP | HTTP (Nginx proxy inverso) |
| 3000 | TCP | Aplicación / Servicio |
| 4000 | TCP | Aplicación / Servicio |
| 9090 | TCP | Monitoring |
| 9091 | TCP | Monitoring |

### Software Instalado

- ✓ **Docker Engine** (instalación oficial)
- ✓ **Docker Compose** (plugin moderno)
- ✓ **UFW Firewall** (configurado y activo)
- ✓ Herramientas esenciales (git, vim, curl, htop, jq, etc.)

> **⚠️ Nginx NO se instala en el sistema**: Nginx corre como contenedor Docker gestionado por tu `docker-compose.yml`. No es necesario instalarlo con Ansible.

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
author_uo            = "UO302313"              # Tu UO
```

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

## 📦 Desplegar tu Aplicación con GitHub Actions

### Configuración de Secrets en GitHub

Tu workflow de GitHub Actions ya está preparado. Solo necesitas configurar estos secrets en tu repositorio:

1. Ve a: **Settings → Secrets and variables → Actions**
2. Añade los siguientes secrets:

```
DEPLOY_HOST  → La IP pública de tu VM (obtenida de terraform output)
DEPLOY_USER  → azureuser
DEPLOY_KEY   → Contenido de tu clave privada SSH (~/.ssh/id_rsa)
```

### Flujo de Despliegue Automático

Cuando crees un **release** en GitHub:

1. ✅ Se ejecutan tests de Node.js (webapp, users, auth)
2. ✅ Se ejecutan tests de Rust (gamey)
3. ✅ Se ejecutan tests E2E con Playwright
4. ✅ Se construyen y publican imágenes Docker a GitHub Container Registry
5. ✅ Se despliega automáticamente en tu VM vía SSH

### ¿Necesitas instalar Nginx en la VM?

**NO** ❌. Tu workflow ya incluye Nginx como contenedor Docker:

```yaml
# Tu workflow descarga estos archivos:
wget ... docker-compose.yml
wget ... nginx/nginx.conf

# Y ejecuta:
docker compose up -d
```

Nginx correrá como un contenedor más, actuando como **proxy inverso** para tus servicios (webapp, users, auth, gamey). La configuración actual de Ansible (que solo instala Docker Engine + Compose) es perfecta para tu caso de uso.

### Arquitectura de tu Despliegue

```
Internet
    |
    v
[Azure VM: 20.74.123.45]
    |
    +-- Docker Compose
         |
         +-- nginx:latest (puerto 80) ← Proxy inverso
         |     ↓ /api/users → users:3000
         |     ↓ /api/gamey → gamey:8080
         |     ↓ / → webapp:3000
         |
         +-- users:latest (puerto 3000)
         +-- auth:latest (puerto 4000)
         +-- gamey:latest (puerto 8080)
         +-- webapp:latest (puerto 3000)
```

---

## 📦 Ejemplo de Despliegue Manual (Opcional)

Si quieres desplegar manualmente sin GitHub Actions:

```bash
# Conectar a la VM
ssh azureuser@<PUBLIC_IP>

# Crear directorio de proyecto
mkdir ~/myapp && cd ~/myapp

# Descargar tu docker-compose.yml y configuración
wget https://raw.githubusercontent.com/<TU_USUARIO>/<TU_REPO>/main/docker-compose.yml
mkdir -p nginx
wget https://raw.githubusercontent.com/<TU_USUARIO>/<TU_REPO>/main/nginx/nginx.conf -O nginx/nginx.conf

# Autenticar en GitHub Container Registry
echo $GITHUB_TOKEN | docker login ghcr.io -u <TU_USUARIO> --password-stdin

# Desplegar
docker compose pull
docker compose up -d

# Verificar
docker compose ps
curl http://localhost/health
```

### Comandos Útiles Docker Compose

```bash
docker compose up -d          # Iniciar en background
docker compose ps             # Ver contenedores activos
docker compose logs -f        # Ver logs en tiempo real
docker compose logs nginx     # Ver logs de Nginx
docker compose restart        # Reiniciar servicios
docker compose down           # Parar y eliminar contenedores
docker compose pull           # Actualizar imágenes
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

**Problema**: La VM aún está iniciando.

**Solución**:
1. Espera 1-2 minutos después de `terraform apply`
2. Verifica el estado de la VM en Azure Portal
3. Comprueba que el puerto 22 esté abierto:
   ```bash
   az network nsg rule list \
     --resource-group <RG_NAME> \
     --nsg-name <NSG_NAME> \
     -o table
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

### GitHub Actions: "Deploy over SSH failed"

**Problema**: Los secrets no están configurados correctamente.

**Solución**:
1. Verifica que `DEPLOY_HOST`, `DEPLOY_USER`, `DEPLOY_KEY` estén en GitHub Secrets
2. Asegúrate de que `DEPLOY_KEY` contenga la clave privada completa (incluye `-----BEGIN ... END-----`)
3. Prueba la conexión SSH manualmente:
   ```bash
   ssh -i ~/.ssh/id_rsa azureuser@<PUBLIC_IP>
   ```

### Nginx: "502 Bad Gateway"

**Problema**: Los servicios backend no están corriendo o tienen problemas.

**Solución**:
```bash
# Ver estado de contenedores
docker compose ps

# Ver logs de servicios
docker compose logs users
docker compose logs auth
docker compose logs gamey
docker compose logs webapp

# Reiniciar servicios problemáticos
docker compose restart <service_name>
```

---

## 📚 Referencias

### Documentación Oficial

- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Ansible Documentation](https://docs.ansible.com/)
- [Docker Installation on Ubuntu](https://docs.docker.com/engine/install/ubuntu/)
- [Docker Compose Specification](https://docs.docker.com/compose/compose-file/)
- [Azure Virtual Machines](https://learn.microsoft.com/en-us/azure/virtual-machines/)
- [GitHub Actions - SSH Deploy](https://github.com/marketplace/actions/ssh-remote-commands)

### Recursos del Curso

- Diapositivas Lab3: ES.ASW.PL03_Despliegue.pdf
- GitHub Actions para despliegue continuo
- GitHub Container Registry: https://ghcr.io/

---

## 📝 Notas de Implementación

### Decisiones Técnicas

- **Networking mínimo**: VNet/Subnet son requisitos de Azure pero no generan costes adicionales. NSG asociado a NIC en lugar de subnet para eficiencia.
- **Sin Nginx en sistema**: Nginx corre como contenedor Docker, gestionado por docker-compose.yml del proyecto.
- **Docker Compose moderno**: Plugin (`docker compose`) en lugar de legacy (`docker-compose`)
- **Firewall doble capa**: NSG en Azure + UFW en VM para máxima flexibilidad
- **Inventario dinámico**: Sincronización automática entre Terraform y Ansible
- **Tags informativos**: Metadatos para organización y billing

### Seguridad

- SSH con clave pública (password authentication disabled)
- NSG con reglas para puertos específicos (sin restricción de IP origen por simplicidad)
- UFW firewall activo por defecto en la VM
- Actualizaciones de paquetes gestionadas por Ansible
- Imágenes Docker privadas en GitHub Container Registry

### Optimizaciones

- Ansible con pipelining SSH habilitado
- Idempotencia en todos los playbooks
- Outputs informativos en cada paso
- Scripts con validación de errores (`set -e`)
- Despliegue automatizado vía GitHub Actions

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
   - Docker: `docker compose logs <service>`
   - GitHub Actions: Pestaña "Actions" en tu repositorio

---

© 2026 Universidad de Oviedo - Todos los derechos reservados
