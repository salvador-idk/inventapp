import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // ← Importar intl para DateFormat
import 'database_helper.dart';
import 'item_model.dart';
import 'ticket_service.dart';

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({Key? key}) : super(key: key);

  @override
  _TicketsScreenState createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  List<TicketVenta> _tickets = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarTickets();
  }

  Future<void> _cargarTickets() async {
    final dbHelper = DatabaseHelper();
    final tickets = await dbHelper.getTickets();
    setState(() {
      _tickets = tickets;
      _cargando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tickets de Compra'),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _tickets.isEmpty
              ? const Center(child: Text('No hay tickets registrados'))
              : ListView.builder(
                  itemCount: _tickets.length,
                  itemBuilder: (context, index) {
                    final ticket = _tickets[index];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        title: Text('Folio: ${ticket.folio}'),
                        subtitle: Text(
                          'Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(ticket.fecha)}\n'
                          'Total: \$${ticket.total.toStringAsFixed(2)}\n'
                          'Artículos: ${ticket.items.length}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.print),
                          onPressed: () => TicketService.imprimirTicket(ticket, context),
                        ),
                        onTap: () {
                          // Opcional: Mostrar detalles del ticket
                          _mostrarDetallesTicket(ticket, context);
                        },
                      ),
                    );
                  },
                ),
    );
  }

  void _mostrarDetallesTicket(TicketVenta ticket, BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ticket: ${ticket.folio}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Fecha: ${DateFormat('dd/MM/yyyy').format(ticket.fecha)}'),
              Text('Hora: ${DateFormat('HH:mm:ss').format(ticket.fecha)}'),
              Text('Total: \$${ticket.total.toStringAsFixed(2)}'),
              const SizedBox(height: 16),
              const Text('Artículos:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...ticket.items.map((item) => Text(
                '• ${item.nombre} - ${item.cantidad} x \$${item.precio.toStringAsFixed(2)} = \$${item.total.toStringAsFixed(2)}',
              )),
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
              TicketService.imprimirTicket(ticket, context);
            },
            child: const Text('Imprimir'),
          ),
        ],
      ),
    );
  }
}