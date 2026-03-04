import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import 'models/customer.dart';
import 'services/customer_service.dart';

/// Standalone screen (kept for potential deep-link usage)
class CustomerListScreen extends ConsumerWidget {
  const CustomerListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customers')),
      body: const CustomersTab(),
    );
  }
}

/// Embeddable tab widget used inside the Dashboard TabBarView
class CustomersTab extends ConsumerWidget {
  const CustomersTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(customersStreamProvider);

    return customersAsync.when(
      data: (customers) {
        if (customers.isEmpty) {
          return const Center(child: Text('No customers found.'));
        }
        return ListView.separated(
          itemCount: customers.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final customer = customers[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
                child: Text(customer.name.isNotEmpty
                    ? customer.name[0].toUpperCase()
                    : '?'),
              ),
              title: Text(customer.name),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(customer.email),
                  if (customer.phoneNumber != null &&
                      customer.phoneNumber!.isNotEmpty)
                    Text('Phone: ${customer.phoneNumber}',
                        style: const TextStyle(fontSize: 12)),
                  if (customer.address != null && customer.address!.isNotEmpty)
                    Text('Addr: ${customer.address}',
                        style: const TextStyle(fontSize: 12)),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${customer.discountPercent.toStringAsFixed(0)}% Off',
                    style: const TextStyle(
                      color: AppTheme.accentTeal,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () {
                      _showEditDiscountDialog(context, ref, customer);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  void _showEditDiscountDialog(
      BuildContext context, WidgetRef ref, Customer customer) {
    final controller =
        TextEditingController(text: customer.discountPercent.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Discount: ${customer.name}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Discount Percentage',
            suffixText: '%',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final val = int.tryParse(controller.text);
              if (val != null && val >= 0 && val <= 100) {
                try {
                  log('UI: Attempting to update discount for ${customer.id}');
                  await ref
                      .read(customerServiceProvider)
                      .updateDiscount(customer.id, val);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Discount updated!')),
                    );
                    Navigator.pop(context);
                  }
                } catch (e) {
                  log('UI: Error updating discount: $e');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid percentage')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
