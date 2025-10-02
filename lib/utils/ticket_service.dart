import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '/models/item_model.dart';
import '/models/ticket_model.dart';

class TicketService {
  static Future<void> imprimirTicket(TicketVenta ticket, BuildContext context) async {
    try {
      final pdf = pw.Document();
      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat(70 * PdfPageFormat.mm, 200 * PdfPageFormat.mm),
          build: (pw.Context context) {
            return _buildTicketContent(ticket);
          },
        ),
      );

      final resultado = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Imprimir Ticket'),
          content: const Text('¿Deseas imprimir el ticket de la compra?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Solo Guardar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Imprimir'),
            ),
          ],
        ),
      );

      if (resultado == true) {
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdf.save(),
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ticket enviado a impresión')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al imprimir ticket: $e')),
      );
    }
  }

  static pw.Widget _buildTicketContent(TicketVenta ticket) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm:ss');
    
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          // Encabezado de la empresa
          pw.Text(
            'ALMACEN MRO',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Sistema de Inventario',
            style: pw.TextStyle(fontSize: 10),
          ),
          pw.Divider(),
          
          // Información del ticket
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Fecha: ${dateFormat.format(ticket.fecha)}', style: pw.TextStyle(fontSize: 9)),
              pw.Text('Hora: ${timeFormat.format(ticket.fecha)}', style: pw.TextStyle(fontSize: 9)),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Folio: ${ticket.folio}', style: pw.TextStyle(fontSize: 9)),
              pw.Text('Ticket #${ticket.id ?? "N/A"}', style: pw.TextStyle(fontSize: 9)),
            ],
          ),
          pw.Divider(),
          
          // Items de la compra
          pw.Text(
            'ARTÍCULOS COMPRADOS',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          
          // Tabla de items
          pw.Table(
            border: pw.TableBorder.all(width: 0.5),
            children: [
              // Encabezado de la tabla
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text('Artículo', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text('Cant', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text('Precio', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text('Total', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  ),
                ],
              ),
              
              // Items
              ...ticket.items.map((item) => pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(_truncarTexto(item.nombre, 15), style: pw.TextStyle(fontSize: 8)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(item.cantidad.toString(), style: pw.TextStyle(fontSize: 8)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text('\$${item.precio.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 8)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text('\$${item.total.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 8)),
                  ),
                ],
              )),
            ],
          ),
          
          pw.Divider(),
          
          // Total
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'TOTAL:',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                '\$${ticket.total.toStringAsFixed(2)}',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
          
          pw.SizedBox(height: 16),
          pw.Text(
            '¡Gracias por su compra!',
            style: pw.TextStyle(
              fontSize: 10,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  static String _truncarTexto(String texto, int maxLength) {
    if (texto.length <= maxLength) return texto;
    return '${texto.substring(0, maxLength)}...';
  }

  // Generar folio único
  static String generarFolio() {
    final now = DateTime.now();
    final fecha = DateFormat('yyMMdd').format(now);
    final hora = DateFormat('HHmmss').format(now);
    return 'MRO-$fecha-$hora';
  }
}