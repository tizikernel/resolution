# UNKNOWNTEAM Resolution Manager

`UNKNOWNTEAM.sh` es el fuente Bash para Termux. La versión actual autentica la key de resolución con el Android ID del teléfono conectado, queda vinculada al primer dispositivo que la activa y comprueba que las operaciones posteriores sigan usando ese mismo dispositivo.

El archivo `UNKNOWNTEAM.bin` que ya está publicado no se recompiló en este cambio. Para que el binario distribuido incorpore el vínculo permanente por dispositivo, hay que compilar una nueva versión a partir de `UNKNOWNTEAM.sh` y reemplazar el binario por ese artefacto. No guardes claves de administración del backend dentro del script.
