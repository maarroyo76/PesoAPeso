# Documentación del proyecto (marco ágil)

Cada documento está en Markdown (se lee directo en GitHub, con sus
diagramas) y en Word (`.docx`) para la entrega.

| Documento | Contenido |
|---|---|
| [01 Product Vision](01_Product_Vision.md) | Problema, usuarios, propuesta de valor y función estrella |
| [02 Product Backlog](02_Product_Backlog.md) | Historias de usuario priorizadas con criterios de aceptación |
| [03 Iteraciones](03_Iteraciones.md) | Sprint Backlog: qué se desarrolló en cada iteración |
| [04 Definition of Done](04_Definition_of_Done.md) | Criterios para dar una historia por terminada |
| [05 Documento de diseño](05_Documento_de_Diseno.md) | Arquitectura, componentes, modelo de datos, UML y requisitos no funcionales |
| [06 Retrospectivas](06_Retrospectivas.md) | Plantilla de acta y mejoras observadas en cada iteración |
| [07 Plan de pruebas](07_Plan_de_Pruebas.md) | Pruebas unitarias, de integración, rendimiento, seguridad y accesibilidad, por iteración |
| [08 Manual técnico](08_Manual_Tecnico.md) | Instalación, despliegue, datos y por qué no se usa Docker |
| [09 Innovación](09_Innovacion.md) | Qué problema resuelve, qué la hace diferente y qué valor agrega |

`Peso_a_Peso_Documento_de_Diseno.docx` es el documento de diseño entregado
en la Fase 2.

**Regenerar los `.docx`** después de editar un `.md` (necesita Google Chrome
y conexión para dibujar los diagramas):

```
python3 -m venv /tmp/venv && /tmp/venv/bin/pip install python-docx pillow
/tmp/venv/bin/python tool/exportar_docs.py "Documentos Capstone/Fase 2/Evidencias Proyecto/Evidencias de documentación"
```
