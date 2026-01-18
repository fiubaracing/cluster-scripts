## Pasos Previos

Actualizar el sistema mediante:

```bash
sudo dnf upgrade -y
```

Al finalizar, reiniciar el sistema usando:

```bash
sudo reboot
```

Instalar perl:

```bash
sudo dnf -y install perl
```

## Instalación de OpenHPC

### Obtener archivos de instalación

Copiar los archivos `install_script.sh` y `variables.config` al directorio home. Debería verse así:

```shell
$ tree /home/admin
/home/admin
├── install_script.sh
└── variables.config
```

### Comenzar el proceso de instalación

> [!WARNING]
> Recordar cambiar las variables de entorno en .env

Ejecutar el script de instalación haciendo:

```shell
sudo bash install_script.sh
```

## Post Instalación

### Generar los archivos de configuración NHC

Con los nodos de cómputo iniciados, ejecutar en el nodo principal:

```shell
source variables.config
pdsh -w ${compute_prefix}1 "/usr/sbin/nhc-genconf -H '*' -c -" | dshbak -c
```

La instalación de OpenHPC está ahora completa.

### Instalar las herramientas

> [!WARNING]
> Recordar cambiar las variables de entorno en .env

```shell
    sudo bash install.sh
```

Esto instalara

- Configuracion de IPMI (+ slurm) para el manejo remoto de los nodos
- Notificaciones via email de slurm
- Tunnel ssh con cloudflared
- Montaje de discos en /mnt/cfd
- Paths de Helyx, OpenFOAM, Paraview, Basilisk y el alias `cfd` para abrir un menu interactivo
