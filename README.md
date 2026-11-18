# ScriptBar

Un lanzador pequeño para la barra de menús de macOS. Cada acción ejecuta un programa con argumentos y una carpeta de trabajo elegidos por ti. Por ejemplo, `cd ../../ && node main.mjs` se configura como `executable: "node"`, `arguments: ["main.mjs"]` y `workingDirectory: "../../"`.

## Instalar desde Terminal

En macOS 13 o posterior, con Swift 5.9 o posterior instalado, ejecuta:

```sh
curl -fsSL https://raw.githubusercontent.com/bigsolabs/bigso-sbar/main/scripts/install.sh | bash
```

El instalador descarga el código de `main`, compila la app en tu Mac y la instala en `~/Applications/ScriptBar.app`; no requiere `sudo`. Después la abre. Para instalar otra rama, puedes definir `SCRIPTBAR_REF` antes de ejecutar el instalador, por ejemplo: `curl -fsSL https://raw.githubusercontent.com/bigsolabs/bigso-sbar/main/scripts/install.sh | SCRIPTBAR_REF=nombre-rama bash`. Revisa el script antes de ejecutarlo si quieres inspeccionar qué hará.

## Instalar la skill de Hermes (opcional)

Si usas Hermes Agent, puedes instalar por separado el conocimiento para que el agente lo cargue cuando la tarea trate de ScriptBar:

```sh
curl -fsSL https://raw.githubusercontent.com/bigsolabs/bigso-sbar/main/scripts/install-hermes-skill.sh | bash
```

La skill queda instalada en Hermes, no dentro de la app ni en otros agentes. No se instala automáticamente; si usas otro agente, copia `skills/scriptbar/SKILL.md` a su ubicación de skills. Para instalar desde otra rama, define `SCRIPTBAR_REF` en el comando como en el instalador de la app.

## Instalar la skill en GitHub Copilot o Codex

El GitHub CLI ofrece `gh skill install` para ambos agentes. Los scripts de abajo instalan la skill en el scope de usuario por defecto; configura `SCRIPTBAR_SKILL_SCOPE=project` para instalarla en el repo actual. Si GitHub CLI avisa que la skill no está verificada, revisa su contenido antes de usarla.

GitHub Copilot:

```sh
curl -fsSL https://raw.githubusercontent.com/bigsolabs/bigso-sbar/main/scripts/install-copilot-skill.sh | bash
```

Codex:

```sh
curl -fsSL https://raw.githubusercontent.com/bigsolabs/bigso-sbar/main/scripts/install-codex-skill.sh | bash
```

En ambos casos necesitas GitHub CLI 2.90.0 o posterior; `gh skill` está en public preview. Para fijar una versión/commit concreto, define `SCRIPTBAR_SKILL_PIN`; para el scope de proyecto, ejecuta el instalador desde el repo y reemplaza el `| bash` final por `| SCRIPTBAR_SKILL_SCOPE=project bash`. En un repo, project scope usa `.agents/skills` y una sola instalación la comparte Copilot y Codex. Si ya está instalada, el script no la sobrescribe; actualízala con `gh skill update scriptbar`.

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
