# Instrucciones de Configuración - iOSWeather

## ⚠️ IMPORTANTE: Se Requieren Dependencias SPM

Este proyecto **NO COMPILARÁ** hasta que agregues las dependencias de Swift Package Manager. Sigue estas instrucciones cuidadosamente.

## Configuración Paso a Paso

### Paso 1: Abrir el Proyecto

```bash
cd /Users/juancarlossuarezmarin/Desktop/front/ios/iosWeather
open iosWeather.xcodeproj
```

### Paso 2: Agregar Alamofire (Requerido)

1. En Xcode, ve a **File → Add Package Dependencies...**
2. En el campo de búsqueda (arriba a la derecha), pega:
   ```
   https://github.com/Alamofire/Alamofire.git
   ```
3. Haz clic en **Add Package**
4. En el menú desplegable "Dependency Rule", selecciona **"Up to Next Major Version"**
5. Ingresa la versión: **5.0.0** (usará 5.x.x)
6. Haz clic en **Add Package**
7. En el diálogo "Add to Target":
   - ✅ Marca **iosWeather** (target de la app principal)
   - ❌ Desmarca **iosWeatherTests**
   - ❌ Desmarca **iosWeatherUITests**
8. Haz clic en **Add Package**

### Paso 3: Agregar Kingfisher (Requerido)

1. En Xcode, ve a **File → Add Package Dependencies...**
2. En el campo de búsqueda (arriba a la derecha), pega:
   ```
   https://github.com/onevcat/Kingfisher.git
   ```
3. Haz clic en **Add Package**
4. En el menú desplegable "Dependency Rule", selecciona **"Up to Next Major Version"**
5. Ingresa la versión: **7.0.0** (usará 7.x.x)
6. Haz clic en **Add Package**
7. En el diálogo "Add to Target":
   - ✅ Marca **iosWeather** (target de la app principal)
   - ❌ Desmarca **iosWeatherTests**
   - ❌ Desmarca **iosWeatherUITests**
8. Haz clic en **Add Package**

### Paso 4: Verificar Dependencias

Después de agregar ambos paquetes, verifica que estén instalados:

1. En el Navegador de Proyectos de Xcode (barra lateral izquierda), busca:
   ```
   iosWeather
   ├── Dependencies
   │   ├── Alamofire
   │   └── Kingfisher
   ```

2. O verifica en: **File → Packages → Package.resolved**

### Paso 5: Compilar el Proyecto

1. Selecciona un simulador: **iPhone 15** o **iPhone 15 Pro**
2. Presiona **Cmd+B** para compilar
3. Espera a que SPM resuelva y descargue los paquetes (solo la primera vez)
4. La compilación debería ser exitosa ✅

### Paso 6: Ejecutar la App

1. Presiona **Cmd+R** o haz clic en el botón ▶️ Run
2. Cuando se solicite, **permite** el acceso a la ubicación
3. ¡La app debería iniciarse exitosamente! 🎉

## Solución de Problemas

### ❌ Error "No such module 'Alamofire'"

**Solución:**
1. File → Packages → Reset Package Caches
2. File → Packages → Resolve Package Versions
3. Limpiar carpeta de build: Shift+Cmd+K
4. Compilar nuevamente: Cmd+B

### ❌ "Cannot find type 'Session' in scope"

**Solución:**
- Asegúrate de haber agregado Alamofire al target **iosWeather** (no a los targets de test)
- Verifica: Project Settings → target iosWeather → General → Frameworks, Libraries, and Embedded Content

### ❌ La resolución de paquetes tarda demasiado

**Solución:**
- Verifica tu conexión a internet
- Xcode puede estar descargando los paquetes (puede tardar 1-2 minutos la primera vez)
- Revisa el progreso en la barra superior de Xcode

### ❌ "Info.plist not found" o la ubicación no funciona

**Solución:**
El archivo `Info.plist` ya fue creado en:
```
iosWeather/Info.plist
```

Asegúrate de que esté agregado al target:
1. Selecciona `Info.plist` en el Navegador de Proyectos
2. En el Inspector de Archivos (barra lateral derecha), verifica que **Target Membership** incluya "iosWeather"

## Alternativa: Configuración por Línea de Comandos

Si prefieres la línea de comandos (avanzado):

```bash
# Esto no funcionará ya que los paquetes SPM deben agregarse a través de la UI de Xcode para proyectos de app
# DEBES usar la interfaz gráfica de Xcode para agregar paquetes
```

## Lista de Verificación

Antes de ejecutar la app, verifica:

- ✅ Alamofire aparece en el Navegador de Proyectos bajo Dependencies
- ✅ Kingfisher aparece en el Navegador de Proyectos bajo Dependencies
- ✅ El proyecto compila sin errores (Cmd+B)
- ✅ Info.plist existe en la carpeta iosWeather/
- ✅ Hay un simulador seleccionado (no "Any iOS Device")

## Siguientes Pasos

Una vez completada la configuración:

1. **Ejecuta la app** (Cmd+R)
2. **Otorga permisos de ubicación** cuando se solicite
3. **Explora las tres pestañas**:
   - Actual: Clima basado en GPS
   - Búsqueda: Búsqueda de ciudades
   - Historial: Historial de búsquedas

4. **Ejecuta los tests** (Cmd+U)
   - Todos los tests de ViewModel deberían pasar
   - Usa implementaciones mock

## ¿Necesitas Ayuda?

Si encuentras problemas:

1. Revisa el archivo **CLAUDE.md** para documentación detallada de la arquitectura
2. Revisa el archivo **README.md** para descripción general de características
3. Revisa cuidadosamente los mensajes de error
4. Intenta limpiar y recompilar

## Resumen

Este proyecto requiere agregar paquetes SPM manualmente porque:
- Es un proyecto de app de Xcode (no un paquete Swift)
- Las dependencias SPM para proyectos de app deben agregarse vía la UI de Xcode
- El archivo `.xcodeproj` se actualizará automáticamente

Después de agregar Alamofire y Kingfisher, ¡el proyecto está completamente listo para compilar y ejecutar! 🚀
