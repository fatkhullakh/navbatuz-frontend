import 'package:flutter/material.dart';
import '../../services/provider_service.dart';
import '../../models/provider.dart';
import '../../models/page_response.dart';

class CustomerHome extends StatefulWidget {
  const CustomerHome({super.key});

  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {
  final ProviderService _providerService = ProviderService();
  late Future<PageResponse<ProviderItem>> _futureProviders;

  @override
  void initState() {
    super.initState();
    _futureProviders = _providerService.getProviders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Providers'),
        centerTitle: true,
      ),
      body: FutureBuilder<PageResponse<ProviderItem>>(
        future: _futureProviders,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          final providers = snapshot.data?.content ?? [];
          if (providers.isEmpty) {
            return const Center(child: Text('No providers found'));
          }

          return ListView.builder(
            itemCount: providers.length,
            itemBuilder: (context, index) {
              final provider = providers[index];
              return GestureDetector(
                onTap: () {
                  // TODO: Navigate to provider details page
                  Navigator.pushNamed(context, '/test-customer-home');
                },
                child: Card(
                  elevation: 3,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      // Provider image or placeholder
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          bottomLeft: Radius.circular(12),
                        ),
                        child: Container(
                          width: 90,
                          height: 90,
                          color: Colors.grey[300],
                          child: const Icon(Icons.store,
                              size: 40, color: Colors.grey),
                        ),
                      ),
                      // Provider info
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                provider.name ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                provider.description ?? 'No description',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.star,
                                      color: Colors.amber, size: 18),
                                  const SizedBox(width: 4),
                                  Text(
                                    provider.avgRating.toStringAsFixed(1) ??
                                        '0.0',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(width: 12),
                                  if (provider.location != null)
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on,
                                            size: 16, color: Colors.red),
                                        Text(
                                          '${provider.location?.district ?? ''}, ${provider.location?.city ?? ''}',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
