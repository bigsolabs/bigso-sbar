# ScriptBar

Un lanzador pequeño para la barra de menús de macOS. Cada acción ejecuta un programa con argumentos y una carpeta de trabajo elegidos por ti. Por ejemplo, `cd ../../ && node main.mjs` se configura como `executable: "node"`, `arguments: ["main.mjs"]` y `workingDirectory: "../../"`.

## Instalar desde Terminal

En macOS 13 o posterior, con Swift 5.9 o posterior instalado, ejecuta:

```sh
curl -fsSL https://raw.githubusercontent.com/bigsolabs/bigso-sbar/main/scripts/install.sh | bash
```

El instalador descarga el código de `main`, compila la app en tu Mac y la instala en `~/Applications/ScriptBar.app`; no requiere `sudo`. Después la abre. Para instalar otra rama, puedes definir `SCRIPTBAR_REF` antes de ejecutar el instalador, por ejemplo: `curl -fsSL https://raw.githubusercontent.com/bigsolabs/bigso-sbar/main/scripts/install.sh | SCRIPTBAR_REF=nombre-rama bash`. Revisa el script antes de ejecutarlo si quieres inspeccionar qué hará.

## Crear la app

Requiere macOS 13 o posterior y Swift 5.9 o posterior.

```sh
./scripts/build-app.sh
open .build/ScriptBar.app
```

La app aparece en la barra de menús y no añade un icono al Dock. El lanzador no inicia scripts automáticamente al abrirse. GitHub Actions compila el bundle en macOS en cada push y pull request.

## Configurar scripts

La primera vez crea `~/Library/Application Support/ScriptBar/scripts.json` y lo abre para que agregues tus comandos. Ejemplo:

```json
{
  "baseDirectory": "~/BIGSO/beta-lab",
  "scripts": [
    {
      "id": "floorplan",
      "name": "Iniciar Floorplan",
      "executable": "npm",
      "arguments": ["start"],
      "workingDirectory": "pco-floorplan"
    },
    {
      "id": "mi-script",
      "name": "Mi script Node",
      "executable": "node",
      "arguments": ["main.mjs"],
      "workingDirectory": "../../"
    }
  ]
}
```

Las rutas relativas de `workingDirectory` se resuelven desde `baseDirectory`; `~` apunta a tu carpeta de usuario. El ejecutable se busca en el PATH de tu shell de inicio de sesión, así que puede encontrar Node instalado con fnm, nvm o Homebrew. También puedes poner una ruta absoluta.

Al seleccionar un script, se ejecuta en segundo plano sin abrir Terminal. La app guarda la salida en `~/Library/Logs/ScriptBar/`. Los procesos activos muestran una acción para detenerlos; **Detener todos** termina los que lanzó ScriptBar. Edita el JSON desde **Editar scripts** y elige **Recargar scripts** para aplicar cambios.

La configuración ejecuta comandos que tú escribes en tu Mac. Usa solo scripts de confianza.
