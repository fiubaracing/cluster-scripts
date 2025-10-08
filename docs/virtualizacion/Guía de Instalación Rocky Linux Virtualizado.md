## Instalación del Sistema

Una vez elegido el dispositivo *SATA CDROM* como primera opción de booteo, e iniciada la máquina virtual, seleccionar *Install Rocky Linux 9.3* para dar comienzo a la instalación.

![Image](./screenshots/01.png)

Elegir el idioma inglés y confirmar haciendo click en `Continue`.

![Image](./screenshots/02.png)


> [!WARNING]
> Se recomienda seleccionar el idioma Inglés para la instalación del sistema operativo, para evitar problemas de configuración en algunos paquetes que asumen este idioma.

Una vez elegido el idioma, se mostrará en pantalla el menú de instalación.

![Image](./screenshots/03.png)

### Localization

Hacer click en el menú `Keyboard` para elegir la disposición de teclado adecuada. Se mostrará la siguiente interfaz.

![Image](./screenshots/04.png)

Hacer click en el botón `+` ubicado abajo a la izquierda.

![Image](./screenshots/05.png)

Escribir *Latin American* en la caja de texto y seleccionar la disposición `Spanish;Castilian (Spanish (Latin American))`. Hacer click en el botón `Add`.

![Image](./screenshots/06.png)

Hecho lo anterior, se mostrará en la interfaz que la disposición fue agregada.

![Image](./screenshots/07.png)

Seleccionar la disposición de teclado agregada y subirla una posición para establecerla como *por defecto*, haciendo click en el botón `∧`. Hacer click en el botón `Done` para confirmar los cambios.

![Image](./screenshots/08.png)

En el menú *Time & Date*, elegir la zona horaria correspondiente. La misma será asignada por defecto si se cuenta con una conexión a internet activa. Hacer click en el botón `Done` para volver al menú principal.

![Image](./screenshots/09.png)

### Software

En el menú *Software Selection*, elegir la opción `Server` y hacer click en el botón `Done`.

![Image](./screenshots/10.png)

### System

En el menú *Instalation Destination*, definir las particiones a utilizar para la instalación. Para esta guía, se utiliza la configuración automática (que ya está preestablecida). Confirmar la selección haciendo click en el botón `Done`.

![Image](./screenshots/11.png)

En el menú *Network & Hostname*, elegir un *hostname* para el nodo principal. Para esta guía, se elige el nombre `sms`. Aplicar los cambios haciendo click en `Apply` y luego en `Done`.

> [!WARNING]
> La elección de hostname debe hacerse de antemano y con cuidado ya que el mismo se utiliza en varios pasos de la instalación de OpenHPC.

![Image](./screenshots/12.png)

### User Settings

En el menú *Root Password* elegir una contraseña para el usuario root. Confirmarla haciendo click en `Done`.

![Image](./screenshots/13.png)

En el menú *User Creation*, elegir un nombre completo y un nombre de usuario para el usuario a crear. Seleccionar la opción `Make this user administrator` y elegir una contraseña segura. Confirmar la elección realizada haciendo click en `Done`.

![Image](./screenshots/14.png)

El estado final del menú principal debería ser similar al siguiente.

![Image](./screenshots/15.png)

Para dar comienzo a la instalación, hacer click en `Begin Installation`. Cuando el proceso de instalación esté completado, hacer click en `Reboot System` para reiniciar el sistema.

> [!NOTE]
> Al finalizar la instalación, debe retirarse el dispositivo `SATA CDROM` del menú *Boot Options* en la interfaz de virt-manager, para evitar que el booteo se produzca nuevamente desde la imagen de disco.

![Image](./screenshots/16.png)

Finalmente, iniciar sesión utilizando el usuario y contraseña elegidos. El proceso de instalación está ahora completo.

![Image](./screenshots/17.png)

---
