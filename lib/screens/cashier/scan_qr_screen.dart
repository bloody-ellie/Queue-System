import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../providers/queue_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';

class ScanQRScreen extends StatefulWidget {
  const ScanQRScreen({super.key});

  @override
  State<ScanQRScreen> createState() => _ScanQRScreenState();
}

class _ScanQRScreenState extends State<ScanQRScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: () => _controller.switchCamera(),
          ),
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: MobileScanner(
              controller: _controller,
              onDetect: (BarcodeCapture capture) {
                if (_isProcessing) return;
                
                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  final String? ticketId = barcode.rawValue;
                  if (ticketId != null) {
                    _isProcessing = true;
                    _controller.stop();
                    _showTicketAction(context, ticketId);
                    break;
                  }
                }
              },
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Scan the ticket QR code'),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () => _controller.start(),
                        child: const Text('Start Scanner'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () => _controller.stop(),
                        child: const Text('Stop Scanner'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTicketAction(BuildContext context, String ticketId) async {
    final provider = Provider.of<QueueProvider>(context, listen: false);
    final ticket = await provider.getTicketByQR(ticketId);
    _isProcessing = false;
    
    if (ticket == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ticket not found')),
        );
        _controller.start();
      }
      return;
    }
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text('Ticket #${ticket.queueNumber}'),
        content: Text('Status: ${ticket.status}\nStudent ID: ${ticket.studentId}'),
        actions: [
          if (ticket.status == 'waiting')
            ElevatedButton(
              onPressed: () async {
                await provider.updateTicketStatus(ticketId, 'serving');
                if (mounted) {
                  Navigator.pop(context);
                  _controller.start();
                }
              },
              child: const Text('Start Serving'),
            ),
          if (ticket.status == 'serving')
            ElevatedButton(
              onPressed: () async {
                await provider.updateTicketStatus(ticketId, 'served');
                final fs = FirestoreService();
                final auth = Provider.of<AuthProvider>(context, listen: false);
                await fs.confirmPayment(ticket.paymentId, auth.currentUser!.uid);
                if (mounted) {
                  Navigator.pop(context);
                  _controller.start();
                }
              },
              child: const Text('Mark Served & Confirm Payment'),
            ),
          if (ticket.status == 'waiting' || ticket.status == 'serving')
            ElevatedButton(
              onPressed: () async {
                await provider.updateTicketStatus(ticketId, 'passed');
                if (mounted) {
                  Navigator.pop(context);
                  _controller.start();
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Pass'),
            ),
          TextButton(
            onPressed: () {
              if (mounted) {
                Navigator.pop(context);
                _controller.start();
              }
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}