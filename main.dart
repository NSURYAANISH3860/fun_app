import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

void main() {
  runApp(RandomPetExplorerApp());
}

class RandomPetExplorerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Random Pet Explorer',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        brightness: Brightness.light,
      ),
      home: HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  String? imageUrl;
  String? credit;
  bool loading = false;
  String current = '';

  // Fetch a random dog image
  Future<void> fetchDog() async {
    setState(() {
      loading = true;
      current = 'Dog';
      imageUrl = null;
      credit = null;
    });
    try {
      final resp = await http.get(Uri.parse('https://dog.ceo/api/breeds/image/random'));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        setState(() {
          imageUrl = data['message'];
        });
      } else {
        setState(() => imageUrl = null);
        _showError('Failed to fetch dog image (${resp.statusCode})');
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  // Fetch a random cat image
  Future<void> fetchCat() async {
    setState(() {
      loading = true;
      current = 'Cat';
      imageUrl = null;
      credit = null;
    });
    try {
      final resp = await http.get(Uri.parse('https://api.thecatapi.com/v1/images/search'));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data is List && data.isNotEmpty) {
          setState(() {
            imageUrl = data[0]['url'];
            if (data[0].containsKey('breeds') && data[0]['breeds'] is List && data[0]['breeds'].isNotEmpty) {
              credit = data[0]['breeds'][0]['name'];
            }
          });
        } else {
          _showError('Malformed cat API response');
        }
      } else {
        _showError('Failed to fetch cat image (${resp.statusCode})');
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $message')),
    );
  }

  Widget _buildImageArea() {
    if (loading) {
      return Center(
        child: SpinKitFadingCube(
          color: Colors.indigo,
          size: 48.0,
        ),
      );
    }

    if (imageUrl == null) {
      return Center(
        child: Text(
          'Tap a button to fetch a random cat or dog!',
          style: TextStyle(fontSize: 16),
          textAlign: TextAlign.center,
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl!,
      fit: BoxFit.contain,
      placeholder: (context, url) => Center(
        child: SpinKitPulse(
          color: Colors.indigo,
          size: 40.0,
        ),
      ),
      errorWidget: (context, url, error) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
          SizedBox(height: 8),
          Text('Failed to load image.')
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        if (current.isNotEmpty) Text('Showing: $current', style: TextStyle(fontWeight: FontWeight.w600)),
        if (credit != null) SizedBox(height: 6),
        if (credit != null) Text('Breed: $credit', style: TextStyle(color: Colors.grey[700])),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isLarge = width > 600;
    return Scaffold(
      appBar: AppBar(
        title: Text('Random Pet Explorer'),
        centerTitle: true,
        elevation: 2,
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: () => showAboutDialog(
              context: context,
              applicationName: 'Random Pet Explorer',
              applicationVersion: '1.0',
              children: [
                Text('Fetch random cat and dog images from public APIs. Uses http, cached_network_image and flutter_spinkit packages.'),
              ],
            ),
          )
        ],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: isLarge ? 32.0 : 16.0, vertical: 18.0),
        child: Column(
          children: [
            // Image area
            Expanded(
              child: AnimatedSwitcher(
                duration: Duration(milliseconds: 400),
                child: Container(
                  key: ValueKey(imageUrl ?? 'empty'),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  padding: EdgeInsets.all(12),
                  child: _buildImageArea(),
                ),
              ),
            ),

            SizedBox(height: 12),
            _buildFooter(),
            SizedBox(height: 14),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  icon: Icon(Icons.pets),
                  label: Text('Random Dog'),
                  style: ElevatedButton.styleFrom(
                    primary: Colors.brown[400],
                    padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  ),
                  onPressed: loading ? null : fetchDog,
                ),
                SizedBox(width: 12),
                ElevatedButton.icon(
                  icon: Icon(Icons.pets_outlined),
                  label: Text('Random Cat'),
                  style: ElevatedButton.styleFrom(
                    primary: Colors.indigo,
                    padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  ),
                  onPressed: loading ? null : fetchCat,
                ),
                SizedBox(width: 12),
                OutlinedButton.icon(
                  icon: Icon(Icons.refresh),
                  label: Text('Clear'),
                  onPressed: loading
                      ? null
                      : () {
                          setState(() {
                            imageUrl = null;
                            current = '';
                            credit = null;
                          });
                        },
                )
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Data from dog.ceo and TheCatAPI',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            )
          ],
        ),
      ),
    );
  }
}
