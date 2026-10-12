# Ejemplos

`documentos-es/` es un expediente español **con datos inventados**: dos libros registro y una
liquidación trimestral con etiquetas de transporte. Tiene dos usos:

1. **Modelo.** Cuando `alta` da de alta España, crea `documentos-es/` con este mismo formato.
   Para otro país define el suyo y lo declara en `scripts/libros.conf`.
2. **Caso de prueba del control.** Está declarado en `scripts/libros.conf`, así que el control
   lo revisa en cada commit, y `scripts/probar-check.sh` lo rompe a propósito en una copia para
   comprobar que el control lo detecta.

Se puede borrar cuando ya tengas tus propios libros: quitá también su línea de `libros.conf`.
