# Seed de datos iniciales

Para empezar a desarrollar necesitamos al menos:

- 12 mesas (con `name`, `capacity`, `x`, `y`, `status`)
- 18 platos de la carta
- 1 usuario admin (Rubén) + 1 usuario waiter de prueba

Los datos están en `tables.json` y `menu_items.json` (misma carpeta).

---

## Opción A — Crearlos a mano por la consola (más rápida para empezar)

1. Entra en https://console.firebase.google.com/ → tu proyecto → Firestore.
2. Crea la colección `tables`. Para cada entrada del JSON, pulsa
   **+ Añadir documento**, usa el `id` del JSON como ID del documento y
   copia los campos restantes (`name`, `capacity`, `x`, `y`, `status`).
3. Igual con `menu_items` desde `menu_items.json`.
4. Crea **al menos** un usuario en Authentication → Users (Email/Password).
   Copia su UID y créale un doc en `users/{uid}` con:
   ```
   role: "admin"
   ```
   Crea también un segundo usuario con `role: "waiter"` para probar la
   ofuscación de datos de contacto.

> Tiempo total: 30-40 min. Aburrido pero seguro.

---

## Opción B — Importar de golpe con un script Node

Solo si tienes ganas. Requiere tener instalado Node y la CLI de Firebase
(`npm i -g firebase-tools`) y haber hecho `firebase login`.

1. Descarga una **clave de cuenta de servicio**: Console → ⚙️ Configuración
   del proyecto → Cuentas de servicio → "Generar nueva clave privada". Guarda
   el JSON como `serviceAccount.json` **fuera del repo** (añádelo a
   `.gitignore` por si acaso).

2. Crea un archivo `seed.js` en la raíz del repo (no subir al git):

```js
// seed.js  —  uso: node seed.js
const admin = require('firebase-admin');
const fs = require('fs');

admin.initializeApp({
  credential: admin.credential.cert(require('./serviceAccount.json')),
});
const db = admin.firestore();

async function seedCollection(name, file) {
  const data = JSON.parse(fs.readFileSync(file, 'utf8'));
  const batch = db.batch();
  for (const { id, ...rest } of data) {
    batch.set(db.collection(name).doc(id), rest);
  }
  await batch.commit();
  console.log(`✔ ${name}: ${data.length} docs`);
}

(async () => {
  await seedCollection('tables',     'seed/tables.json');
  await seedCollection('menu_items', 'seed/menu_items.json');
  console.log('Done.');
})();
```

3. Instala el SDK y ejecuta:

```bash
npm init -y
npm i firebase-admin
node seed.js
```

4. Borra `serviceAccount.json` cuando termines (o asegúrate de que está en
   `.gitignore`).

---

## Roles de los usuarios staff

Los usuarios se crean en **Authentication → Users**. Luego, en Firestore,
cada uno necesita un documento en la colección `users` con su UID como ID
del doc y un campo `role`:

| Email                  | role     |
|------------------------|----------|
| admin@enseru.local     | admin    |
| camarero@enseru.local  | waiter   |

Usa contraseñas tontas (`123456` vale) — esto no se publica, es solo para
desarrollo. Cuando llegue el momento de la entrega, se cambian.
