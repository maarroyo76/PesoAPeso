# Documentación del proyecto

Documentación del marco ágil (Kanban) de Peso a Peso. Estos archivos son la
fuente: se leen directo en GitHub, con sus diagramas, y desde ellos se generan
los `.docx` que se entregan en
`Documentos Capstone/Fase 2/Evidencias Proyecto/Evidencias de documentación/`.

| Documento | Contenido |
|---|---|
| [01 Gestión ágil](01_Gestion_Agil.md) | Product Vision, Product Backlog, Sprint Backlog por iteración, Definition of Done y retrospectivas |
| [02 Documento de diseño](02_Documento_de_Diseno.md) | Arquitectura, componentes, modelo de datos, diagramas UML, requisitos no funcionales e innovación |
| [03 Plan de pruebas](03_Plan_de_Pruebas.md) | Pruebas unitarias, de integración, rendimiento, seguridad y accesibilidad, por iteración |
| [04 Manual técnico](04_Manual_Tecnico.md) | Instalación, despliegue, datos y por qué no se usa Docker |

**Regenerar los `.docx`** después de editar un `.md` (necesita Google Chrome
y conexión para dibujar los diagramas):

```
python3 -m venv /tmp/venv && /tmp/venv/bin/pip install python-docx pillow
/tmp/venv/bin/python tool/exportar_docs.py docs "Documentos Capstone/Fase 2/Evidencias Proyecto/Evidencias de documentación"
```
