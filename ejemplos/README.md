# Ejemplos

`documentos-es/` es un expediente español **con datos inventados**: dos libros registro y una
liquidación trimestral con etiquetas de transporte. Tiene dos usos:

1. **Modelo.** Cuando `alta` da de alta España, crea `documentos-es/` con este mismo formato.
   Para otro país define el suyo y lo declara en `scripts/libros.conf`.
2. **Caso de prueba del control.** Está declarado en `scripts/libros.conf`, así que el control
   lo revisa en cada commit, y `scripts/probar-check.sh` lo rompe a propósito en una copia para
   comprobar que el control lo detecta.

**No lo borres aunque ya tengas tus propios libros:** es el caso de prueba de
`probar-check.sh`, y `alta` lo usa como modelo. No interfiere con tus datos: el control lo
revisa como un expediente más.
