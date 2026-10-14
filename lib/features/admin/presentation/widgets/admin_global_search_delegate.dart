import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminGlobalSearchDelegate extends SearchDelegate<String> {
  @override
  String get searchFieldLabel => 'البحث الشامل (Users, Trips, Companies...)';

  @override
  ThemeData appBarTheme(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.black87),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(fontFamily: 'Cairo', color: Colors.grey),
      ),
      textTheme: theme.textTheme.copyWith(
        titleLarge: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 18,
          color: Colors.black87,
        ),
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.trim().isEmpty) {
      return const Center(
        child: Text(
          'الرجاء إدخال نص للبحث',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
      );
    }

    final String lowerQuery = query.toLowerCase().trim();

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _performFederatedSearch(lowerQuery),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'خطأ في البحث: ${snapshot.error}',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
          );
        }

        final results = snapshot.data ?? [];
        if (results.isEmpty) {
          return const Center(
            child: Text(
              'لم يتم العثور على نتائج تطابق بحثك',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
          );
        }

        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final doc = results[index];
            return ListTile(
              leading: _getIconForType(doc['_type']),
              title: Text(
                doc['name'] ?? doc['title'] ?? doc['id'] ?? 'Unknown',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                'النوع: ${doc['_type']}',
                style: const TextStyle(fontFamily: 'Cairo', color: Colors.grey),
              ),
              onTap: () {
                // In a real app, this would route to the specific details page based on _type and ID.
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('تم اختيار: ${doc['id']}')),
                );
                close(context, doc['id']);
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return const Center(
      child: Text(
        'اكتب للبحث عبر جميع قواعد البيانات',
        style: TextStyle(fontFamily: 'Cairo', color: Colors.grey),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _performFederatedSearch(String q) async {
    final firestore = FirebaseFirestore.instance;
    List<Map<String, dynamic>> combinedResults = [];

    // Note: Firestore doesn't support full-text search out of the box.
    // This is a simulated prefix search for demo/enterprise scale purposes.
    // In production, this should connect to Algolia, ElasticSearch, or Typesense.

    try {
      // 1. Search Users
      final userQuery = await firestore
          .collection('users')
          .where('name', isGreaterThanOrEqualTo: q)
          .where('name', isLessThanOrEqualTo: '$q\uf8ff')
          .limit(5)
          .get();
      for (var doc in userQuery.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        data['_type'] = 'User';
        combinedResults.add(data);
      }

      // 2. Search Companies
      final companyQuery = await firestore
          .collection('companies')
          .where('name', isGreaterThanOrEqualTo: q)
          .where('name', isLessThanOrEqualTo: '$q\uf8ff')
          .limit(5)
          .get();
      for (var doc in companyQuery.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        data['_type'] = 'Company';
        combinedResults.add(data);
      }

      // If query is an ID match, we could just check direct documents here...
    } catch (e) {
      // Return whatever we have so far
    }

    return combinedResults;
  }

  Widget _getIconForType(String type) {
    switch (type) {
      case 'User':
        return const Icon(Icons.person, color: Colors.blue);
      case 'Company':
        return const Icon(Icons.business, color: Colors.orange);
      case 'Trip':
        return const Icon(Icons.route, color: Colors.green);
      default:
        return const Icon(Icons.search);
    }
  }
}
