import 'dart:io';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:ui' as ui;
import '/models/item_model.dart';

class EtiquetaService {
  static Future<void> imprimirEtiqueta(Item item, BuildContext context) async {
    try {
      // Crear el PDF de la etiqueta
      final pdf = pw.Document();
      
      // Tamaño de etiqueta: 2.5cm x 5cm
      //1cm = 28.35 puntos
      final etiquetaAlto = 7141.75; // 7cm
      final etiquetaAncho = 70.875; // 5cm
      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat(etiquetaAncho, etiquetaAlto),
          build: (pw.Context context) {
            return pw.Container(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  // Nombre del item (truncado si es muy largo)
                  pw.Text(
                    _truncarTexto(item.nombre, 20),
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    maxLines: 2,
                  ),
                  pw.SizedBox(height: 2),
                  
                  // Número de serie
                  pw.Text(
                    'Serial: ${item.serial}',
                    style: const pw.TextStyle(fontSize: 6),
                  ),
                  pw.SizedBox(height: 4),
                  
                  // Código QR (más pequeño para caber en la etiqueta)
                  pw.Center(
                    child: pw.Container(
                      width: 40,
                      height: 40,
                      child: pw.BarcodeWidget(
                        data: 'Nombre: ${item.nombre}\n'
                              'Serial: ${item.serial}\n'
                              'ID: ${item.numeroIdentificacion}',
                        barcode: pw.Barcode.qrCode(),
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  
                  // Número de identificación
                  pw.Text(
                    'ID: ${item.numeroIdentificacion}',
                    style: const pw.TextStyle(fontSize: 6),
                  ),
                ],
              ),
            );
          },
        ),
      );

      // Mostrar diálogo de impresión
      final resultado = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Imprimir Etiqueta'),
          content: const Text('¿Deseas imprimir una etiqueta para este artículo?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Imprimir'),
            ),
          ],
        ),
      );

      if (resultado == true) {
        // Imprimir el PDF
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdf.save(),
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Etiqueta enviada a impresión')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al imprimir: $e')),
      );
    }
  }

  static String _truncarTexto(String texto, int maxLength) {
    if (texto.length <= maxLength) return texto;
    return '${texto.substring(0, maxLength)}...';
  }

  // Método alternativo para previsualizar la etiqueta
  static Future<void> previsualizarEtiqueta(Item item, BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vista Previa de Etiqueta'),
        content: Container(
          width: 200, // 2cm en pixels de pantalla
          height: 600, // 6cm en pixels de pantalla
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _truncarTexto(item.nombre, 20),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 4),
              Text(
                'Serial: ${item.serial}',
                style: const TextStyle(fontSize: 10),
              ),
              const SizedBox(height: 8),
              Center(
                child: QrImageView(
                  data: 'Nombre: ${item.nombre}\n'
                        'Serial: ${item.serial}\n'
                        'ID: ${item.numeroIdentificacion}',
                  version: QrVersions.auto,
                  size: 80,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'ID: ${item.numeroIdentificacion}',
                style: const TextStyle(fontSize: 10),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              imprimirEtiqueta(item, context);
            },
            child: const Text('Imprimir'),
          ),
        ],
      ),
    );
  }
}