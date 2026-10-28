import '../../data/local/app_database.dart';

/// RF53: categorías que se ofrecen al registrar o asignar: las no
/// archivadas, más [keep] si es una archivada que ya está en uso (al editar
/// algo que la tiene), para no cambiarla sin que el usuario lo pida.
List<Category> selectableCategories(List<Category> all, {String? keep}) =>
    all.where((c) => !c.archived || c.id == keep).toList();
