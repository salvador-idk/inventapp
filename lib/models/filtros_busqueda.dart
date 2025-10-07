// lib/models/filtros_busqueda.dart
class FiltrosBusqueda {
  final String query;
  final double? precioMin;
  final double? precioMax;
  final int? stockMin;
  final int? stockMax;
  final int? categoriaId;
  final bool soloStockBajo;

  const FiltrosBusqueda({
    this.query = '',
    this.precioMin,
    this.precioMax,
    this.stockMin,
    this.stockMax,
    this.categoriaId,
    this.soloStockBajo = false,
  });

  FiltrosBusqueda copyWith({
    String? query,
    double? precioMin,
    double? precioMax,
    int? stockMin,
    int? stockMax,
    int? categoriaId,
    bool? soloStockBajo,
  }) {
    return FiltrosBusqueda(
      query: query ?? this.query,
      precioMin: precioMin ?? this.precioMin,
      precioMax: precioMax ?? this.precioMax,
      stockMin: stockMin ?? this.stockMin,
      stockMax: stockMax ?? this.stockMax,
      categoriaId: categoriaId ?? this.categoriaId,
      soloStockBajo: soloStockBajo ?? this.soloStockBajo,
    );
  }

  bool get tieneFiltros {
    return query.isNotEmpty ||
        precioMin != null ||
        precioMax != null ||
        stockMin != null ||
        stockMax != null ||
        categoriaId != null ||
        soloStockBajo;
  }
}